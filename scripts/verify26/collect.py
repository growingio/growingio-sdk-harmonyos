#!/usr/bin/env python3
"""采集 HarmonyOS 26.0.0 适配验证数据。

用法：
    # 自动模式：脚本通过 uitest 自己点，全程无人值守（推荐先试这个）
    python3 scripts/verify26/collect.py --label api26 --auto

    # 手动模式：脚本负责抓日志，屏幕上按提示点，点完回车
    python3 scripts/verify26/collect.py --label api20

产物：verify26-<label>.json —— 直接把它交给别人分析，或者用 compare.py 比对两次采集。

依赖：hdc（DevEco Studio 自带，或 Command Line Tools）。设备需要开启 USB 调试。
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from steps import STEPS  # noqa: E402

BUNDLE = 'com.growingio.analytics'
ABILITY = 'EntryAbility'
TAG = 'GIOV26'
CHUNK_RE = re.compile(r'GIOV26 s=(\d+) i=(\d+) n=(\d+) (.*)$')
BOUNDS_RE = re.compile(r'\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]')

HDC_CANDIDATES = [
    os.environ.get('HDC'),
    shutil.which('hdc'),
    '/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc',
    os.path.expanduser('~/Library/OpenHarmony/Sdk/12/toolchains/hdc'),
    'C:\\Program Files\\Huawei\\DevEco Studio\\sdk\\default\\openharmony\\toolchains\\hdc.exe',
]


def find_hdc():
    for candidate in HDC_CANDIDATES:
        if candidate and os.path.exists(candidate):
            return candidate
        if candidate and shutil.which(candidate):
            return candidate
    sys.exit('找不到 hdc，请把它加进 PATH，或用环境变量 HDC=/path/to/hdc 指定。')


def run(hdc, args, timeout=60, check=False):
    """hdc 是一个命令前缀列表，例如 ['/path/to/hdc'] 或 ['/path/to/hdc', '-t', '<connectKey>']。"""
    proc = subprocess.run(list(hdc) + args, capture_output=True, text=True, timeout=timeout)
    if check and proc.returncode != 0:
        sys.exit('hdc %s 失败: %s' % (' '.join(args), proc.stderr.strip() or proc.stdout.strip()))
    return proc


def shell(hdc, cmd, timeout=60, check=False):
    return run(hdc, ['shell'] + cmd, timeout=timeout, check=check)


def pick_device(hdc, requested):
    proc = run(hdc, ['list', 'targets'], check=True)
    targets = [line.strip() for line in proc.stdout.splitlines() if line.strip() and 'Empty' not in line]
    if not targets:
        sys.exit('没有检测到设备，确认已连接并允许调试（hdc list targets 为空）。')
    if requested:
        if requested not in targets:
            sys.exit('指定的设备 %s 不在已连接列表里：\n  %s' % (requested, '\n  '.join(targets)))
        return requested
    if len(targets) > 1:
        sys.exit('检测到多台设备，请用 --device 指定这次采哪一台（或者只插一台）：\n  %s\n\n'
                 '例如：--device %s' % ('\n  '.join(targets), targets[0]))
    return targets[0]


class LogCapture(object):
    """后台线程持续读取 hilog，把 GIOV26 分片行收集起来。"""

    def __init__(self, hdc):
        self.hdc = hdc
        self.lines = []
        self.proc = None
        self.thread = None

    def start(self):
        shell(self.hdc, ['hilog', '-r'])
        shell(self.hdc, ['hilog', '-G', '16M'])
        self.proc = subprocess.Popen(
            list(self.hdc) + ['shell', 'hilog', '-T', TAG],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)
        self.thread = threading.Thread(target=self._pump, daemon=True)
        self.thread.start()

    def _pump(self):
        for line in self.proc.stdout:
            if TAG in line:
                self.lines.append(line.rstrip('\n'))

    def stop(self):
        time.sleep(1.5)
        if self.proc:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.proc.kill()
        if self.thread:
            self.thread.join(timeout=5)


def reassemble(lines):
    """把分片日志按 seq 拼回完整 JSON 记录。"""
    buckets = {}
    for line in lines:
        match = CHUNK_RE.search(line)
        if not match:
            continue
        seq = int(match.group(1))
        idx = int(match.group(2))
        total = int(match.group(3))
        payload = match.group(4)
        bucket = buckets.setdefault(seq, {'total': total, 'parts': {}})
        bucket['parts'][idx] = payload

    records = []
    for seq in sorted(buckets):
        bucket = buckets[seq]
        if len(bucket['parts']) != bucket['total']:
            records.append({'type': 'incomplete', 'seq': seq,
                            'got': len(bucket['parts']), 'want': bucket['total']})
            continue
        text = ''.join(bucket['parts'][i] for i in range(bucket['total']))
        try:
            record = json.loads(text)
        except ValueError:
            records.append({'type': 'unparsable', 'seq': seq, 'raw': text})
            continue
        record['seq'] = seq
        records.append(record)
    return records


# ---------------------------------------------------------------- uitest 驱动

def dump_layout(hdc):
    remote = '/data/local/tmp/verify26_layout.json'
    shell(hdc, ['rm', '-f', remote])
    proc = shell(hdc, ['uitest', 'dumpLayout', '-p', remote], timeout=60)
    output = (proc.stdout or '') + (proc.stderr or '')
    match = re.search(r'(/data/local/tmp/\S+\.json)', output)
    if match:
        remote = match.group(1)
    local = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.layout.json')
    if os.path.exists(local):
        os.remove(local)
    run(hdc, ['file', 'recv', remote, local], timeout=60)
    if not os.path.exists(local):
        raise RuntimeError('dumpLayout 失败，设备可能不支持 uitest 命令行：%s' % output.strip())
    with open(local, 'r', encoding='utf-8') as handle:
        return json.load(handle)


def iter_nodes(node):
    if isinstance(node, list):
        for item in node:
            for found in iter_nodes(item):
                yield found
        return
    if not isinstance(node, dict):
        return
    yield node
    for child in node.get('children') or []:
        for found in iter_nodes(child):
            yield found


def node_attrs(node):
    attrs = node.get('attributes')
    return attrs if isinstance(attrs, dict) else node


def center_of(node):
    attrs = node_attrs(node)
    bounds = attrs.get('bounds')
    if isinstance(bounds, str):
        match = BOUNDS_RE.search(bounds)
        if not match:
            return None
        left, top, right, bottom = (int(match.group(i)) for i in range(1, 5))
    elif isinstance(bounds, dict):
        left = bounds.get('left', 0)
        top = bounds.get('top', 0)
        right = bounds.get('right', 0)
        bottom = bounds.get('bottom', 0)
    else:
        return None
    if right <= left or bottom <= top:
        return None
    return ((left + right) // 2, (top + bottom) // 2)


def find_center(tree, key):
    hits = []
    for node in iter_nodes(tree):
        attrs = node_attrs(node)
        text = str(attrs.get('text') or '')
        if key and key in text:
            point = center_of(node)
            if point:
                hits.append(point)
    return hits[0] if hits else None


def screen_size(tree):
    width = 0
    height = 0
    for node in iter_nodes(tree):
        attrs = node_attrs(node)
        bounds = attrs.get('bounds')
        if isinstance(bounds, str):
            match = BOUNDS_RE.search(bounds)
            if match:
                width = max(width, int(match.group(3)))
                height = max(height, int(match.group(4)))
        elif isinstance(bounds, dict):
            width = max(width, int(bounds.get('right') or 0))
            height = max(height, int(bounds.get('bottom') or 0))
    return (width or 1260), (height or 2720)


_SCREEN = {}


def get_screen(hdc):
    """屏幕尺寸只探一次，之后缓存。用默认值猜坐标会滑出屏幕外，手势就没效果了。"""
    if not _SCREEN:
        width, height = screen_size(dump_layout(hdc))
        _SCREEN['width'] = width
        _SCREEN['height'] = height
    return _SCREEN['width'], _SCREEN['height']


def swipe(hdc, x_from, y_from, x_to, y_to, velocity=800):
    shell(hdc, ['uitest', 'uiInput', 'swipe', str(int(x_from)), str(int(y_from)),
                str(int(x_to)), str(int(y_to)), str(velocity)], timeout=30)
    time.sleep(0.6)


def wait_for(hdc, key, retries=3, interval=0.6):
    """先原地等几次（等动画/弹窗出现），再上下滚动找，控件在 Scroll 里被顶出屏幕时也能命中。"""
    tree = None
    for _ in range(retries):
        tree = dump_layout(hdc)
        point = find_center(tree, key)
        if point:
            return point
        time.sleep(interval)

    width, height = get_screen(hdc)
    center_x = width // 2
    top_y = int(height * 0.30)
    bottom_y = int(height * 0.75)

    # 先尽量滚到顶部，再逐屏向下找
    for _ in range(6):
        swipe(hdc, center_x, top_y, center_x, bottom_y)
    for _ in range(10):
        tree = dump_layout(hdc)
        point = find_center(tree, key)
        if point:
            return point
        swipe(hdc, center_x, bottom_y, center_x, top_y)
    return None


# 页面模型：goto 靠它判断"现在在哪一页"，并决定该往回退还是往前点。
# anchor 取各页顶部的稳定文案；detect 之前会先把页面滚回顶部，所以滚动位置不影响判断。
PAGES = {
    'home': {'anchor': 'getDeviceId', 'parent': None, 'enter_key': None},
    'verify26': {'anchor': 'go-nav-home', 'parent': 'home', 'enter_key': 'verify26'},
    'navhome': {'anchor': 'click-in-home-navdestination', 'parent': 'verify26', 'enter_key': 'go-nav-home'},
    'dialogs': {'anchor': 'open-alert-dialog', 'parent': 'verify26', 'enter_key': 'go-dialogs'},
    'lists': {'anchor': '列表 index 验证', 'parent': 'verify26', 'enter_key': 'go-lists'},
}


def scroll_to_top(hdc):
    """把当前页滚回顶部。已经在顶部时是无害的空操作。"""
    width, height = get_screen(hdc)
    center_x = width // 2
    for _ in range(4):
        swipe(hdc, center_x, int(height * 0.30), center_x, int(height * 0.75))


def detect_page(tree):
    for name in PAGES:
        if find_center(tree, PAGES[name]['anchor']):
            return name
    return None


def ancestors_of(page):
    chain = []
    node = PAGES[page]['parent']
    while node:
        chain.append(node)
        node = PAGES[node]['parent']
    return chain


def press_back(hdc):
    shell(hdc, ['uitest', 'uiInput', 'keyEvent', 'Back'], timeout=30)
    time.sleep(1.0)


def goto(hdc, target, max_moves=8, max_backs=3):
    """把应用导航到 target 页。

    比"盲按返回"稳的地方：认得出当前在哪一页，目标在上层就退、在下层就点进去，
    识别不出来（弹窗盖着 / 未知界面）才退一步。在首页时绝不按返回，所以不会退到桌面。
    """
    backs = 0
    for _ in range(max_moves):
        scroll_to_top(hdc)
        tree = dump_layout(hdc)
        current = detect_page(tree)

        if current == target:
            return True

        if current is None:
            # 认不出来：可能有弹窗盖着，退一步再看。
            # 但认不出来时不能无限退，否则万一在首页就会退到桌面。
            if backs >= max_backs:
                return False
            backs += 1
            press_back(hdc)
            continue

        if current in ancestors_of(target):
            # 目标在下层：沿着链路往前点一层
            step_page = target
            while PAGES[step_page]['parent'] != current:
                step_page = PAGES[step_page]['parent']
            point = wait_for(hdc, PAGES[step_page]['enter_key'])
            if not point:
                return False
            shell(hdc, ['uitest', 'uiInput', 'click', str(point[0]), str(point[1])], timeout=30)
            time.sleep(1.0)
            continue

        if current == 'home':
            # 已经在最外层还没到目标，再退就出应用了
            return False

        if backs >= max_backs:
            return False
        backs += 1
        press_back(hdc)
    return False


def do_step(hdc, item, auto):
    kind = item['kind']
    if kind == 'wait':
        time.sleep(item['ms'] / 1000.0)
        return True, ''
    if not auto:
        return True, ''

    if kind == 'back':
        shell(hdc, ['uitest', 'uiInput', 'keyEvent', 'Back'], timeout=30)
        time.sleep(0.8)
        return True, ''

    if kind == 'dismiss':
        # 弹窗/气泡/菜单点完后可能还开着，也可能已经自己关了。
        # 只在它确实还在屏幕上时按一次返回，避免多退一层把页面也退掉。
        tree = dump_layout(hdc)
        if find_center(tree, item['key']):
            press_back(hdc)
        return True, ''

    if kind == 'goto':
        if goto(hdc, item['key']):
            return True, ''
        return False, '没能导航到页面 "%s"，后续步骤可能错位' % item['key']

    point = wait_for(hdc, item['key'])
    if not point:
        return False, '界面上找不到 "%s"' % item['key']
    action = 'longClick' if kind == 'longClick' else 'click'
    shell(hdc, ['uitest', 'uiInput', action, str(point[0]), str(point[1])], timeout=30)
    time.sleep(0.8)
    return True, ''


def drive_auto(hdc):
    problems = []
    total = len(STEPS)
    for number, item in enumerate(STEPS, 1):
        print('[%2d/%d] %s' % (number, total, item['desc']))
        ok, reason = do_step(hdc, item, True)
        if not ok:
            print('       ! %s（跳过该步）' % reason)
            problems.append({'step': number, 'desc': item['desc'], 'reason': reason})
    return problems


def drive_manual():
    print('\n请按下面的顺序在设备上操作（每步之间不用等，正常节奏点即可）：\n')
    number = 0
    for item in STEPS:
        if item['kind'] == 'wait':
            continue
        number += 1
        print('  %2d. %s' % (number, item['desc']))
    print('\n另外这两项脚本驱动不了，需要的话手动补：')
    print('   - Hybrid：首页 → verify26 → [4. Hybrid]，在 H5 页面里点几下')
    print('   - 圈选：按正常流程连上圈选，观察 verify26 入口页底部的表单组件与阴影卡片')
    input('\n全部点完后按回车结束采集…')
    return []


def main():
    parser = argparse.ArgumentParser(description='采集 HarmonyOS 26.0.0 适配验证数据')
    parser.add_argument('--label', required=True, help='本次采集的标签，例如 api26 / api20')
    parser.add_argument('--auto', action='store_true', help='用 uitest 自动点，不加则手动点')
    parser.add_argument('--out', default='.', help='报告输出目录，默认当前目录')
    parser.add_argument('--device', help='指定设备（hdc list targets 里的 connectKey）；只插一台时可省略')
    parser.add_argument('--keep-running', action='store_true', help='采集前不重启应用')
    args = parser.parse_args()

    hdc = [find_hdc()]
    device = pick_device(hdc, args.device)
    hdc = hdc + ['-t', device]
    print('设备：%s' % device)

    capture = LogCapture(hdc)
    capture.start()

    if not args.keep_running:
        shell(hdc, ['aa', 'force-stop', BUNDLE])
        time.sleep(1)
    shell(hdc, ['aa', 'start', '-a', ABILITY, '-b', BUNDLE], check=False)
    time.sleep(3)

    problems = drive_auto(hdc) if args.auto else drive_manual()

    capture.stop()
    records = reassemble(capture.lines)

    meta = next((r for r in records if r.get('type') == 'meta'), {})
    events = [r for r in records if r.get('type') == 'event']
    broken = [r for r in records if r.get('type') in ('incomplete', 'unparsable')]

    report = {
        'label': args.label,
        'collectedAt': int(time.time() * 1000),
        'mode': 'auto' if args.auto else 'manual',
        'device': meta,
        'stepProblems': problems,
        'brokenRecords': broken,
        'events': events,
    }
    out_path = os.path.join(args.out, 'verify26-%s.json' % args.label)
    with open(out_path, 'w', encoding='utf-8') as handle:
        json.dump(report, handle, ensure_ascii=False, indent=2)

    print('\n采集完成：%s' % out_path)
    print('  设备 API 版本  : %s' % meta.get('osFullName', '未知'))
    print('  targetVersion : %s' % meta.get('targetVersion', '未知'))
    print('  事件条数       : %d' % len(events))
    if broken:
        print('  ! 有 %d 条日志分片不完整，如果数量多，重跑一次' % len(broken))
    if not events:
        print('  ! 一条事件都没抓到：确认装的是带 Verify26Recorder 的 debug 包，且 hdc hilog 正常')
    print('\n下一步：python3 scripts/verify26/compare.py verify26-<基线>.json %s' % out_path)


if __name__ == '__main__':
    main()
