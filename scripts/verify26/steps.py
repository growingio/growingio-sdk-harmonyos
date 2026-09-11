"""HarmonyOS 26.0.0 验证流程的操作步骤定义（collect.py 的手动模式与自动模式共用）。

每个 step:
  kind    : click / longClick / back / wait / note
  key     : 用于在 uitest dumpLayout 结果里按 text 子串定位控件（自动模式）
  desc    : 手动模式下打印给操作者看的说明
  scenario: 归属的验证场景，写进报告，便于 compare.py 分组
"""


def step(kind, scenario, desc, key=None, ms=800):
    return {'kind': kind, 'scenario': scenario, 'desc': desc, 'key': key, 'ms': ms}


STEPS = [
    step('click', 'entry', '在首页点击 [verify26]', 'verify26'),

    # ---------- 场景 1：主页 NavDestination ----------
    step('click', 'nav_home', '点击 [1. 主页 NavDestination]', '1. 主页 NavDestination'),
    step('wait', 'nav_home', '等待页面事件上报', ms=1200),
    step('click', 'nav_home', '点击 [click-in-home-navdestination]', 'click-in-home-navdestination'),
    step('click', 'nav_home', '点击 [push -> Verify26NavDetail]', 'push -> Verify26NavDetail'),
    step('wait', 'nav_home', '等待页面事件上报', ms=1200),
    step('click', 'nav_home', '点击 [click-in-detail-navdestination]', 'click-in-detail-navdestination'),
    step('click', 'nav_home', '点击 [pop -> 返回主页 NavDestination]', 'pop -> 返回主页'),
    step('wait', 'nav_home', '等待页面事件上报', ms=1200),
    step('back', 'nav_home', '返回上一页（回到 verify26 入口页）'),
    step('wait', 'nav_home', '等待页面事件上报', ms=1000),

    # ---------- 场景 2：弹窗族 ----------
    step('click', 'dialog', '点击 [2. 弹窗族]', '2. 弹窗族'),
    step('wait', 'dialog', '等待页面事件上报', ms=1200),

    step('click', 'dialog', '点击 [AlertDialog]', 'AlertDialog（预期'),
    step('click', 'dialog', '在弹窗里点击 [click-in-alert-dialog]', 'click-in-alert-dialog'),
    step('wait', 'dialog', '等待弹窗关闭', ms=800),

    step('click', 'dialog', '点击 [CustomDialog]', 'CustomDialog（预期'),
    step('click', 'dialog', '在弹窗里点击 [click-in-custom-dialog]', 'click-in-custom-dialog'),
    step('click', 'dialog', '点击 [关闭]', '关闭'),
    step('wait', 'dialog', '等待弹窗关闭', ms=800),

    step('click', 'dialog', '点击 [Popup]', 'Popup（预期'),
    step('click', 'dialog', '在气泡里点击 [click-in-popup]', 'click-in-popup'),
    step('back', 'dialog', '返回键关掉气泡'),
    step('wait', 'dialog', '等待气泡关闭', ms=800),

    step('click', 'dialog', '点击 [Menu]', 'Menu（预期'),
    step('click', 'dialog', '在菜单里点击 [click-in-menu]', 'click-in-menu'),
    step('back', 'dialog', '返回键关掉菜单'),
    step('wait', 'dialog', '等待菜单关闭', ms=800),

    step('click', 'dialog', '点击 [Sheet 半模态]', 'Sheet 半模态（预期'),
    step('click', 'dialog', '在半模态里点击 [click-in-sheet]', 'click-in-sheet'),
    step('click', 'dialog', '点击 [关闭]', '关闭'),
    step('wait', 'dialog', '等待半模态关闭', ms=800),

    step('click', 'dialog', '点击 [ContentCover 全模态]', 'ContentCover 全模态（预期'),
    step('click', 'dialog', '在全模态里点击 [click-in-modal]', 'click-in-modal'),
    step('click', 'dialog', '点击 [关闭]', '关闭'),
    step('wait', 'dialog', '等待全模态关闭', ms=800),

    step('click', 'dialog', '点击 [Select] 下拉框', 'Select'),
    step('click', 'dialog', '选择 [option-1]', 'option-1'),
    step('wait', 'dialog', '等待下拉收起', ms=800),

    step('longClick', 'dialog', '长按那段长文本，唤起文本选择菜单', '长按选中这段文字'),
    step('wait', 'dialog', '等待选择菜单出现', ms=1000),
    step('click', 'dialog', '在文本选择菜单里点击 [复制]', '复制'),
    step('wait', 'dialog', '等待菜单关闭', ms=800),

    step('click', 'dialog', '点击输入框（弹出键盘）', '点击弹出键盘'),
    step('back', 'dialog', '返回键收起键盘'),
    step('back', 'dialog', '返回上一页（回到 verify26 入口页）'),
    step('wait', 'dialog', '等待页面事件上报', ms=1000),

    # ---------- 场景 3：列表 index ----------
    step('click', 'list', '点击 [3. 列表族]', '3. 列表族'),
    step('wait', 'list', '等待页面事件上报', ms=1200),
    step('click', 'list', '点击 [ListItem-2]', 'ListItem-2'),
    step('click', 'list', '点击 [GridItem-3]', 'GridItem-3'),
    step('click', 'list', '点击 [FlowItem-1]', 'FlowItem-1'),
    step('click', 'list', '点击 [GridCol-4]', 'GridCol-4'),
    step('back', 'list', '返回上一页（回到 verify26 入口页）'),
    step('wait', 'list', '等待页面事件上报', ms=1000),
]
