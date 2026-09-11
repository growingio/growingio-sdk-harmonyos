"""HarmonyOS 26.0.0 验证流程的操作步骤定义（collect.py 的手动模式与自动模式共用）。

每个 step:
  kind    : click / longClick / goto / dismiss / wait
            - goto:    导航到指定页面（collect.py 的 PAGES 模型）。认得出当前在哪一页，
                       目标在上层就退、在下层就点进去；在首页绝不按返回，不会退到桌面。
            - dismiss: 只在指定的弹窗内容还在屏幕上时按一次返回，避免多退一层。
  key     : goto 是页面名；其余是 uitest dumpLayout 里按 text 子串匹配的控件文案，
            也可以给一个候选列表（例如系统菜单的中英文文案），命中任意一个即可
  desc    : 手动模式下打印给操作者看的说明
  scenario: 归属的验证场景，写进报告，便于 compare.py 分组

控件文案都用短且唯一的 ASCII 标识（go-* / open-* / click-in-* / close-*），
避免同名控件（比如多个"关闭"）导致点错。
"""


def step(kind, scenario, desc, key=None, ms=800):
    return {'kind': kind, 'scenario': scenario, 'desc': desc, 'key': key, 'ms': ms}


STEPS = [
    step('goto', 'entry', '进入 verify26 入口页（首页点 [verify26]）', 'verify26'),

    # ---------- 场景 1：主页 NavDestination ----------
    step('goto', 'nav_home', '点击 [go-nav-home] 进入主页 NavDestination 页', 'navhome'),
    step('wait', 'nav_home', '等待页面事件上报', ms=1200),
    step('click', 'nav_home', '点击 [click-in-home-navdestination]', 'click-in-home-navdestination'),
    step('click', 'nav_home', '点击 [push -> Verify26NavDetail]', 'push -> Verify26NavDetail'),
    step('wait', 'nav_home', '等待页面事件上报', ms=1200),
    step('click', 'nav_home', '点击 [click-in-detail-navdestination]', 'click-in-detail-navdestination'),
    step('click', 'nav_home', '点击 [pop -> 返回主页 NavDestination]', 'pop -> 返回主页'),
    step('wait', 'nav_home', '等待页面事件上报', ms=1200),
    step('goto', 'nav_home', '返回 verify26 入口页', 'verify26'),
    step('wait', 'nav_home', '等待页面事件上报', ms=1000),

    # ---------- 场景 2：弹窗族 ----------
    step('goto', 'dialog', '点击 [go-dialogs] 进入弹窗页', 'dialogs'),
    step('wait', 'dialog', '等待页面事件上报', ms=1200),

    step('click', 'dialog', '点击 [open-alert-dialog]', 'open-alert-dialog'),
    step('click', 'dialog', '在弹窗里点击 [click-in-alert-dialog]', 'click-in-alert-dialog'),
    step('goto', 'dialog', '回到弹窗页', 'dialogs'),

    step('click', 'dialog', '点击 [open-custom-dialog]', 'open-custom-dialog'),
    step('click', 'dialog', '在弹窗里点击 [click-in-custom-dialog]', 'click-in-custom-dialog'),
    step('click', 'dialog', '点击 [close-custom-dialog]', 'close-custom-dialog'),
    step('goto', 'dialog', '回到弹窗页', 'dialogs'),

    step('click', 'dialog', '点击 [open-popup]', 'open-popup'),
    step('click', 'dialog', '在气泡里点击 [click-in-popup]', 'click-in-popup'),
    step('dismiss', 'dialog', '气泡若还开着，按返回关掉', 'click-in-popup'),
    step('goto', 'dialog', '回到弹窗页', 'dialogs'),

    step('click', 'dialog', '点击 [open-menu]', 'open-menu'),
    step('click', 'dialog', '在菜单里点击 [click-in-menu]', 'click-in-menu'),
    step('dismiss', 'dialog', '菜单若还开着，按返回关掉', 'click-in-menu'),
    step('goto', 'dialog', '回到弹窗页', 'dialogs'),

    step('click', 'dialog', '点击 [open-sheet]', 'open-sheet'),
    step('click', 'dialog', '在半模态里点击 [click-in-sheet]', 'click-in-sheet'),
    step('click', 'dialog', '点击 [close-sheet]', 'close-sheet'),
    step('goto', 'dialog', '回到弹窗页', 'dialogs'),

    step('click', 'dialog', '点击 [open-modal]', 'open-modal'),
    step('click', 'dialog', '在全模态里点击 [click-in-modal]', 'click-in-modal'),
    step('click', 'dialog', '点击 [close-modal]', 'close-modal'),
    step('goto', 'dialog', '回到弹窗页', 'dialogs'),

    step('click', 'dialog', '点击 [open-select] 下拉框', 'open-select'),
    step('click', 'dialog', '选择 [select-option-1]', 'select-option-1'),
    step('goto', 'dialog', '回到弹窗页', 'dialogs'),

    step('longClick', 'dialog', '长按 [long-press-me] 那段文字，唤起文本选择菜单', 'long-press-me'),
    step('wait', 'dialog', '等待选择菜单出现', ms=1200),
    # 系统文本选择菜单的按钮文案跟设备语言走，中英文都试一遍
    step('click', 'dialog', '在文本选择菜单里点击 [复制 / Copy]', ['复制', 'Copy']),
    step('goto', 'dialog', '回到弹窗页', 'dialogs'),

    step('click', 'dialog', '点击输入框 [focus-textinput]（弹出键盘）', 'focus-textinput'),
    step('goto', 'dialog', '收起键盘并返回 verify26 入口页', 'verify26'),
    step('wait', 'dialog', '等待页面事件上报', ms=1000),

    # ---------- 场景 3：列表 index ----------
    step('goto', 'list', '点击 [go-lists] 进入列表页', 'lists'),
    step('wait', 'list', '等待页面事件上报', ms=1200),
    step('click', 'list', '点击 [ListItem-2]', 'ListItem-2'),
    step('click', 'list', '点击 [GridItem-3]', 'GridItem-3'),
    step('click', 'list', '点击 [FlowItem-1]', 'FlowItem-1'),
    step('click', 'list', '点击 [GridCol-4]', 'GridCol-4'),
    step('goto', 'list', '返回 verify26 入口页', 'verify26'),
    step('wait', 'list', '等待页面事件上报', ms=1000),
]
