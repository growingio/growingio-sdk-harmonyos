#!/usr/bin/env python3
"""比对两次 verify26 采集结果，输出结论表。

用法：
    # 两台设备对照（推荐）
    python3 scripts/verify26/compare.py verify26-api20.json verify26-api26.json

    # 只看单次采集的固有检查
    python3 scripts/verify26/compare.py verify26-api26.json

产物：stdout 的结论表 + verify26-compare.md + verify26-compare.json。
退出码 0 = 全部 PASS，1 = 有 FAIL 或跨版本 CHANGED。
"""

import argparse
import json
import os
import sys

# 与 GrowingAnalytics/src/main/ets/components/utils/Constants.ts 保持一致
DIALOG_PATH_PREFIXES = [
    '/root/AlertDialog', '/root/Dialog', '/root/Keyboard', '/root/MenuWrapper',
    '/root/ModalPage', '/root/Popup', '/root/SheetWrapper', '/root/SelectOverlay', '/root/Video',
]
LIST_COMPONENTS = ['ListItem', 'GridItem', 'GridCol', 'FlowItem']

DIALOG_CLICKS = [
    'click-in-alert-dialog', 'click-in-custom-dialog', 'click-in-popup',
    'click-in-menu', 'click-in-sheet', 'click-in-modal',
]
LIST_CLICKS = ['ListItem-2', 'GridItem-3', 'FlowItem-1', 'GridCol-4']
NAV_CLICKS = ['click-in-home-navdestination', 'click-in-detail-navdestination']

COMPARE_FIELDS = ['path', 'xpath', 'xcontent', 'index']


def load(path):
    with open(path, 'r', encoding='utf-8') as handle:
        return json.load(handle)


def events_of(report, event_type):
    out = []
    for record in report.get('events', []):
        if record.get('eventType') != event_type:
            continue
        data = record.get('data') or {}
        if isinstance(data, dict):
            out.append(data)
    return out


def clicks_by_text(report):
    table = {}
    for data in events_of(report, 'VIEW_CLICK'):
        text = data.get('textValue')
        if text:
            table.setdefault(text, []).append(data)
    return table


def page_paths(report):
    return [data.get('path') for data in events_of(report, 'PAGE')]


def field(data, name):
    value = data.get(name)
    return '—' if value is None else str(value)


def check_dialogs(report):
    rows = []
    table = clicks_by_text(report)
    for text in DIALOG_CLICKS:
        hits = table.get(text)
        if not hits:
            rows.append((text, 'MISSING', '没采到这条点击事件', '', ''))
            continue
        data = hits[0]
        xpath = data.get('xpath') or ''
        prefix = next((p for p in DIALOG_PATH_PREFIXES if xpath.startswith(p)), None)
        path = data.get('path') or ''
        if prefix and path:
            verdict = 'PASS'
            note = '前缀 %s，path=%s' % (prefix, path)
        elif prefix and not path:
            verdict = 'FAIL'
            note = '前缀命中 %s，但 path 为空（未回退到宿主页面）' % prefix
        else:
            verdict = 'FAIL'
            note = 'xpath 前缀不在 DIALOG_PATH_PREFIXES 内，需要更新 Constants.ts'
        rows.append((text, verdict, note, xpath, path))
    return rows


def check_lists(report):
    rows = []
    table = clicks_by_text(report)
    for text in LIST_CLICKS:
        hits = table.get(text)
        if not hits:
            rows.append((text, 'MISSING', '没采到这条点击事件', '', ''))
            continue
        data = hits[0]
        xpath = data.get('xpath') or ''
        index = data.get('index')
        ordinal = int(text.split('-')[1])
        expected = ordinal + 1  # NewSaaS 模式下列表内 index 会 +1
        component = next((c for c in LIST_COMPONENTS if c in xpath), None)
        if component is None:
            verdict = 'FAIL'
            note = 'xpath 里没有 %s 这类列表节点，LIST_COMPONENTS 可能要更新' % '/'.join(LIST_COMPONENTS)
        elif index == expected:
            verdict = 'PASS'
            note = 'index=%s（序号 %d + 1），列表节点 %s' % (index, ordinal, component)
        else:
            verdict = 'FAIL'
            note = 'index=%s，期望 %d（序号 %d + 1）' % (index, expected, ordinal)
        rows.append((text, verdict, note, xpath, str(index)))
    return rows


def check_nav(report):
    rows = []
    table = clicks_by_text(report)
    for text in NAV_CLICKS:
        hits = table.get(text)
        if not hits:
            rows.append((text, 'MISSING', '没采到这条点击事件', '', ''))
            continue
        data = hits[0]
        path = data.get('path') or ''
        verdict = 'PASS' if path else 'FAIL'
        note = 'path=%s' % (path or '（空）')
        rows.append((text, verdict, note, data.get('xpath') or '', path))
    return rows


def render_table(title, header, rows):
    lines = ['### %s' % title, '', '| ' + ' | '.join(header) + ' |',
             '|' + '|'.join([' --- '] * len(header)) + '|']
    for row in rows:
        cells = [str(c).replace('|', '\\|') for c in row]
        lines.append('| ' + ' | '.join(cells) + ' |')
    lines.append('')
    return lines


def screen_of(report):
    for record in report.get('events', []):
        data = record.get('data') or {}
        if isinstance(data, dict) and data.get('screenWidth'):
            return '%sx%s' % (data.get('screenWidth'), data.get('screenHeight'))
    return '未知'


def single_report(report, label):
    lines = ['## 单次采集检查：%s' % label, '']
    device = report.get('device') or {}
    lines += ['- 设备：%s / %s' % (device.get('osFullName', '未知'), device.get('productModel', '未知')),
              '- 设备 API：%s，应用 targetVersion：%s' % (device.get('sdkApiVersion', '未知'),
                                                        device.get('targetVersion', '未知')),
              '- 屏幕分辨率：%s（两次采集分辨率不同时，组件内部布局差异可能被误读成版本差异）' % screen_of(report),
              '- 事件总数：%d' % len(report.get('events', [])),
              '- 页面事件 path 序列：%s' % ' → '.join([str(p) for p in page_paths(report)]) or '（无）',
              '']
    verdicts = []
    sections = (
        ('弹窗 xpath 前缀', check_dialogs(report), ['点击目标', '结论', '说明', 'xpath', 'path']),
        ('列表 index', check_lists(report), ['点击目标', '结论', '说明', 'xpath', 'index']),
        ('NavDestination path 归属', check_nav(report), ['点击目标', '结论', '说明', 'xpath', 'path']),
    )
    for title, rows, header in sections:
        lines += render_table(title, header, rows)
        verdicts += [r[1] for r in rows]
    return lines, verdicts


def cross_report(base, target, base_label, target_label):
    lines = ['## 跨版本对照：%s → %s' % (base_label, target_label), '']

    base_pages = page_paths(base)
    target_pages = page_paths(target)
    page_same = base_pages == target_pages
    lines += ['### PAGE 事件 path 序列', '',
              '- %s：%s' % (base_label, ' → '.join([str(p) for p in base_pages]) or '（无）'),
              '- %s：%s' % (target_label, ' → '.join([str(p) for p in target_pages]) or '（无）'),
              '- 结论：**%s**' % ('一致' if page_same else 'CHANGED —— 页面归属发生变化，需要人工确认是否影响数据口径'),
              '']

    base_clicks = clicks_by_text(base)
    target_clicks = clicks_by_text(target)
    rows = []
    changed = 0
    for text in sorted(set(list(base_clicks.keys()) + list(target_clicks.keys()))):
        left = (base_clicks.get(text) or [{}])[0]
        right = (target_clicks.get(text) or [{}])[0]
        if not left:
            rows.append((text, 'ONLY-IN-' + target_label, '', ''))
            changed += 1
            continue
        if not right:
            rows.append((text, 'ONLY-IN-' + base_label, '', ''))
            changed += 1
            continue
        diffs = [name for name in COMPARE_FIELDS if field(left, name) != field(right, name)]
        if not diffs:
            rows.append((text, 'SAME', '', ''))
            continue
        changed += 1
        detail_base = ', '.join('%s=%s' % (n, field(left, n)) for n in diffs)
        detail_target = ', '.join('%s=%s' % (n, field(right, n)) for n in diffs)
        rows.append((text, 'CHANGED: ' + ','.join(diffs), detail_base, detail_target))

    lines += render_table('VIEW_CLICK 字段对照（path / xpath / xcontent / index）',
                          ['点击目标', '结论', base_label, target_label], rows)
    return lines, page_same, changed


def main():
    parser = argparse.ArgumentParser(description='比对 verify26 采集结果')
    parser.add_argument('reports', nargs='+', help='1 个报告=单次检查，2 个报告=跨版本对照（先基线后新版）')
    parser.add_argument('--out', default='.', help='输出目录，默认当前目录')
    args = parser.parse_args()

    if len(args.reports) > 2:
        sys.exit('最多两个报告：先基线，后新版。')

    reports = [load(p) for p in args.reports]
    labels = [r.get('label') or os.path.basename(p) for r, p in zip(reports, args.reports)]

    lines = ['# HarmonyOS 26.0.0 适配验证结果', '']
    verdicts = []
    for report, label in zip(reports, labels):
        block, block_verdicts = single_report(report, label)
        lines += block
        verdicts += block_verdicts

    page_same = True
    changed = 0
    if len(reports) == 2:
        block, page_same, changed = cross_report(reports[0], reports[1], labels[0], labels[1])
        lines += block

    failed = [v for v in verdicts if v in ('FAIL', 'MISSING')]
    summary = {
        'labels': labels,
        'failedChecks': len(failed),
        'changedClicks': changed,
        'pageSequenceSame': page_same,
        'verdict': 'PASS' if not failed and not changed and page_same else 'NEEDS-ATTENTION',
    }
    lines += ['## 总结', '',
              '- 固有检查失败/缺失：%d' % len(failed),
              '- 跨版本字段变化：%d' % changed,
              '- PAGE 序列一致：%s' % ('是' if page_same else '否'),
              '- 总体：**%s**' % summary['verdict'], '']

    text = '\n'.join(lines)
    print(text)
    with open(os.path.join(args.out, 'verify26-compare.md'), 'w', encoding='utf-8') as handle:
        handle.write(text)
    with open(os.path.join(args.out, 'verify26-compare.json'), 'w', encoding='utf-8') as handle:
        json.dump(summary, handle, ensure_ascii=False, indent=2)

    sys.exit(0 if summary['verdict'] == 'PASS' else 1)


if __name__ == '__main__':
    main()
