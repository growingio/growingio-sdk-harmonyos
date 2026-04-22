# AutotrackClick 逻辑详解

> **模块归属**: 无埋点模块 (autotrack)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/autotrack/AutotrackClick.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 中 `AutotrackClick` 模块的逻辑实现，该模块负责自动采集用户点击事件（VIEW_CLICK 事件）。

## 目录

- [概述](#概述)
- [核心架构](#核心架构)
- [点击事件监听](#点击事件监听)
- [点击处理流程](#点击处理流程)
- [页面信息获取](#页面信息获取)
- [XPath 生成算法](#xpath-生成算法)
- [文本内容提取](#文本内容提取)
- [事件生成与发送](#事件生成与发送)
- [弹窗特殊处理](#弹窗特殊处理)
- [配置与限制](#配置与限制)

---

## 概述

`AutotrackClick` 是 HarmonyOS SDK 无埋点功能的核心模块之一，主要功能包括：

1. **自动监听用户点击**：通过 ArkUI 的 UIObserver 监听全量点击事件
2. **生成点击事件**：在检测到有效点击时自动生成 VIEW_CLICK 事件
3. **元素路径追踪**：构建组件的 XPath 路径，用于唯一标识点击元素
4. **页面上下文关联**：将点击事件与当前页面关联

### 支持的模式

| 模式 | 支持状态 | 说明 |
|------|---------|------|
| NewSaaS | 支持 | 完整功能支持 |
| CDP | 支持 | 完整功能支持，XPath 格式不同 |
| SaaS | 支持 | 完整功能支持，XPath 格式与 CDP 相同 |

---

## 核心架构

### 类关系图

```
┌─────────────────────────────────────────────────────────────┐
│                     AutotrackClick                          │
├─────────────────────────────────────────────────────────────┤
│  核心方法                                                    │
│  ├── startObserver()          // 启动点击监听                │
│  ├── onWillClick()            // 点击事件回调                │
│  ├── getPageInfo()            // 获取页面信息                │
│  ├── getXpathInfo()           // 获取 XPath 信息             │
│  ├── setXpathInfo()           // 设置 XPath 节点信息         │
│  ├── getXcontent()            // 计算节点索引                │
│  ├── getCustomId()            // 获取自定义 ID               │
│  └── getTextValue()           // 获取文本内容                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      _PageInfo                              │
├─────────────────────────────────────────────────────────────┤
│  path: string                 // 页面路径                    │
│  pageShowTimestamp: number    // 页面显示时间戳(CDP/SaaS模式) │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      _XpathInfo                             │
├─────────────────────────────────────────────────────────────┤
│  xpath: string[]              // 节点类型路径                │
│  xcontent: string[]           // 节点索引/ID路径             │
│  index: number                // 列表项索引                  │
│  eventType: EventType         // 事件类型                    │
│  inList: boolean              // 是否在列表中                │
└─────────────────────────────────────────────────────────────┘
```

### 与系统的交互

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│   用户点击    │────▶│  ArkUI 系统   │────▶│  UIObserver      │
│              │     │              │     │  willClick 事件  │
└──────────────┘     └──────────────┘     └────────┬─────────┘
                                                   │
                                                   ▼
                                          ┌──────────────────┐
                                          │ onWillClick()    │
                                          │                  │
                                          │ 1. 有效性检查    │
                                          │ 2. 页面信息获取  │
                                          │ 3. XPath 生成    │
                                          │ 4. 文本提取      │
                                          │ 5. 事件发送      │
                                          └──────────────────┘
```

---

## 点击事件监听

### 监听器注册

```typescript
static startObserver(context: UIContext) {
  context.getUIObserver().on('willClick', AutotrackClick.onWillClick)
}
```

使用 `'willClick'` 事件类型，在点击实际触发前拦截，确保事件采集的实时性。

### 回调函数签名

```typescript
static onWillClick(event: ClickEvent, frameNode?: FrameNode)
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `event` | `ClickEvent` | 点击事件对象（当前未使用） |
| `frameNode` | `FrameNode` | 被点击组件的帧节点（核心参数） |

---

## 点击处理流程

### 入口方法: onWillClick()

```
┌─────────────────────────────────────────────────────────────┐
│                    onWillClick 流程图                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ frameNode 存在？ │
                    └────────┬─────────┘
                             │否
                             ▼
                    【返回，不处理】
                             │是
                             ▼
                    ┌──────────────────┐
                    │ uniqueId > 0？   │
                    │ (有效节点)       │
                    └────────┬─────────┘
                             │否
                             ▼
                    【返回，不处理】
                             │是
                             ▼
                    ┌──────────────────┐
                    │ SDK 初始化完成？ │
                    └────────┬─────────┘
                             │否
                             ▼
                    【返回，不处理】
                             │是
                             ▼
                    ┌──────────────────┐
                    │ autotrackEnabled │
                    │ == true？        │
                    └────────┬─────────┘
                             │否
                             ▼
                    【返回，不处理】
                             │是
                             ▼
                    ┌──────────────────┐
                    │ dataCollection   │
                    │ Enabled == true？│
                    └────────┬─────────┘
                             │否
                             ▼
                    【返回，不处理】
                             │是
                             ▼
              【开始采集点击事件】
                             │
                             ▼
                    ┌──────────────────┐
                    │ 1. 获取页面信息  │
                    │ getPageInfo()    │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ 2. 获取文本内容  │
                    │ getTextValue()   │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ 3. 获取 XPath    │
                    │ getXpathInfo()   │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ 4. 处理弹窗场景  │
                    │ (如需要)         │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ 5. 生成并发送    │
                    │ 点击事件         │
                    └──────────────────┘
```

### 前置检查条件

```typescript
static onWillClick(event: ClickEvent, frameNode?: FrameNode) {
  // 1. 节点存在性检查
  if (!frameNode) {
    return
  }

  // 2. 节点有效性检查（uniqueId <= 0 为无效节点）
  if (frameNode.getUniqueId() <= 0) {
    return
  }

  // 3. SDK 初始化状态检查
  if (!AnalyticsCore.core.isInitializedSuccessfully()) {
    return
  }

  let context = GrowingContext.getDefaultContext() as GrowingContext

  // 4. 无埋点总开关检查
  if (!context.config.autotrackEnabled) {
    return
  }

  // 5. 数据采集开关检查
  if (!context.config.dataCollectionEnabled) {
    return
  }

  // ... 继续处理
}
```

---

## 页面信息获取

### getPageInfo() 方法

根据被点击元素所在的页面类型，获取对应的页面信息：

```
┌─────────────────────────────────────────────────────────────┐
│                     getPageInfo 流程                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ 通过 uniqueId    │
                    │ 获取页面信息     │
                    │ getPageInfoBy    │
                    │ UniqueId()       │
                    └────────┬─────────┘
                             │
            ┌────────────────┼────────────────┐
            ▼                ▼                ▼
    ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
    │navDestination │ │  routerPage   │ │     其他      │
    │    Info       │ │    Info       │ │  (弹窗等)     │
    └───────┬───────┘ └───────┬───────┘ └───────────────┘
            │                 │
            ▼                 ▼
    ┌───────────────┐ ┌───────────────┐
    │ 提取 name     │ │ 提取 name     │
    │ 构建 path     │ │ 构建 path     │
    │ (/{name})     │ │ (/{name})     │
    └───────┬───────┘ └───────┬───────┘
            │                 │
            ▼                 ▼
    ┌───────────────┐ ┌───────────────┐
    │ 检查 alias    │ │ 从 Router     │
    │ 参数          │ │ 获取参数      │
    └───────┬───────┘ └───────┬───────┘
            │                 │
            ▼                 ▼
    ┌───────────────┐ ┌───────────────┐
    │ 有 alias？    │ │ 检查 alias    │
    └───────┬───────┘ └───────┬───────┘
            │                 │
       ┌────┴────┐       ┌────┴────┐
       ▼         ▼       ▼         ▼
    【有】    【无】   【有】    【无】
       │         │       │         │
       ▼         ▼       ▼         ▼
    path =    path =  path =    path =
    /{alias}  /{name} /{alias}  /{name}
       │         │       │         │
       └─────────┴───────┴─────────┘
                   │
                   ▼
        ┌──────────────────┐
        │ CDP 模式特殊处理 │
        │ 获取页面时间戳   │
        └──────────────────┘
```

### 代码实现

```typescript
static getPageInfo(frameNode: FrameNode): _PageInfo {
  let info = new _PageInfo()

  // 通过 UIContext 获取页面信息
  let pageInfo = Autotrack.uiContent.getPageInfoByUniqueId(frameNode.getUniqueId())
  let realPath: string | undefined = undefined

  if (pageInfo.navDestinationInfo) {
    // Navigation 页面
    realPath = PATH_SEPARATOR + pageInfo.navDestinationInfo.name.toString()
    let alias = Util.getAliasFromNavInfoParameter(pageInfo.navDestinationInfo.param)
    if (alias.length > 0) {
      realPath = PATH_SEPARATOR + alias  // 使用别名替换路径
    }
  } else if (pageInfo.routerPageInfo) {
    // Router 页面
    realPath = PATH_SEPARATOR + pageInfo.routerPageInfo.name.toString()
    let param = Autotrack.uiContent.getRouter().getParams()
    let alias = Util.getAliasFromNavInfoParameter(param)
    if (alias.length > 0) {
      realPath = PATH_SEPARATOR + alias
    }
  }

  if (realPath) {
    info.path = realPath

    // CDP/SaaS 模式：获取页面显示时间戳
    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (context.config.mode == ConfigMode.CDP || context.config.mode == ConfigMode.SaaS) {
      let lastNativePage = AutotrackPage.lastNativePage
      let path = lastNativePage?.path
      if (path == realPath) {
        info.pageShowTimestamp = lastNativePage?.timestamp ?? 0
      }
    }
  }

  return info
}
```

---

## XPath 生成算法

### XPath 结构

XPath 用于唯一标识页面中的元素，由两部分组成：

1. **xpath**: 组件类型层级路径（如 `["root", "Column", "Button"]`）
2. **xcontent**: 组件索引/ID 层级路径（如 `["0", "0", "0"]`）

### 不同模式的 XPath 格式

| 模式 | XPath 格式示例 |
|------|---------------|
| NewSaaS | xpath: `/root/Column/Button` <br> xcontent: `/0/0/0` |
| CDP | `/root[0]/Column[0]/Button[0#submitBtn]` |
| SaaS | `/root[0]/Column[0]/Button[0#submitBtn]` |（与 CDP 格式相同）

### getXpathInfo() 方法

```
┌─────────────────────────────────────────────────────────────┐
│                    getXpathInfo 流程                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ 从 frameNode     │
                    │ 开始向上遍历     │
                    │ 父节点           │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ 对每个节点调用   │
                    │ setXpathInfo()   │
                    │ 收集信息         │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ 遍历到根节点？   │
                    └────────┬─────────┘
                             │否
                             │
                             ▼
                    ┌──────────────────┐
                    │ 继续向上遍历     │
                    │ f = f.getParent()│
                    └────────┬─────────┘
                             │是
                             ▼
                    ┌──────────────────┐
                    │ 检查并添加 root  │
                    │ 节点（如需要）   │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ 返回 _XpathInfo  │
                    └──────────────────┘
```

### setXpathInfo() 方法

```typescript
static setXpathInfo(info: _XpathInfo, frameNode: FrameNode) {
  // 1. 获取当前节点类型
  let curNodeType = frameNode.getNodeType()
  info.xpath.push(curNodeType)

  // 2. 计算节点索引
  let xcontent = AutotrackClick.getXcontent(frameNode)

  // 3. 列表组件特殊处理
  if (!info.inList && LIST_COMPONENTS.includes(curNodeType)) {
    // 列表项标记为 "-"，记录列表内索引
    info.xcontent.push('-')
    info.index = xcontent
    info.inList = true
  } else {
    // 普通节点：索引 + 自定义ID
    info.xcontent.push(String(xcontent) + AutotrackClick.getCustomId(frameNode))
  }
}
```

### getXcontent() - 计算兄弟节点索引

```typescript
static getXcontent(frameNode: FrameNode) {
  let xcontent = 0

  if (frameNode.getParent()) {
    let curNodeType = frameNode.getNodeType()
    let preSibling = frameNode.getPreviousSibling()

    // 向前遍历兄弟节点，统计同类型节点数量
    while (preSibling) {
      let nodeType = preSibling.getNodeType()
      if (nodeType.length > 0 && nodeType == curNodeType) {
        xcontent++
      }
      preSibling = preSibling.getPreviousSibling()
    }
  }

  return xcontent
}
```

**示例**：

```
Column
├── Button (索引: 0)
├── Button (索引: 1)  <-- 点击这个
└── Text   (索引: 0)

计算过程：
1. 当前节点类型: Button
2. 前一个兄弟: Button (类型匹配，xcontent = 1)
3. 再前一个: 无
4. 最终索引: 1
```

### getCustomId() - 获取自定义 ID

```typescript
static getCustomId(frameNode: FrameNode) {
  let customId = frameNode.getId()
  if (customId && customId.length > 0) {
    // 移除路径分隔符避免冲突
    customId = customId.replace(/\//g, '')
    return '#' + customId
  }
  return ''
}
```

**用途**：开发者可通过 `id()` 属性为组件设置唯一标识，增强 XPath 的稳定性。

**示例**：
```typescript
Button('提交')
  .id('submitBtn')  // XPath 将包含 #submitBtn
```

### 列表组件特殊处理

```typescript
export const LIST_COMPONENTS: Array<string> = [
  "ListItem",    // 列表项
  "GridItem",    // 网格项
  "GridCol",     // 网格列
  "FlowItem",    // 瀑布流项
]
```

**处理方式**：
- 首次遇到列表组件时，`xcontent` 标记为 `"-"`
- `index` 字段记录该组件在列表中的索引（从 0 开始，上报时 +1）
- 后续在列表内的组件使用正常索引

**XPath 示例**：
```
List
└── ListItem (index: 0)
    └── Button (xcontent: "0")

NewSaaS XPath: 
- xpath: "/root/List/ListItem/Button"
- xcontent: "/0/-/0"
- index: 1 (0+1)
```

---

## 文本内容提取

### getTextValue() 方法

使用 BFS（广度优先搜索）算法从被点击元素及其子元素中提取文本内容。

```
┌─────────────────────────────────────────────────────────────┐
│                    getTextValue 流程                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ 初始化队列       │
                    │ queue = [frameNode]
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ 队列不为空？     │
                    └────────┬─────────┘
                             │否
                             ▼
                    【返回空字符串】
                             │是
                             ▼
                    ┌──────────────────┐
                    │ 取出队列首部节点 │
                    │ f = queue.shift()│
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ 获取组件文本标签 │
                    │ getComponentLabel│
                    └────────┬─────────┘
                             │
                    ┌────────┴────────┐
                    ▼                 ▼
                【有文本】        【无文本】
                    │                 │
                    ▼                 ▼
                【返回文本】    ┌──────────────────┐
                                │ 遍历子节点       │
                                │ 加入队列         │
                                └────────┬─────────┘
                                         │
                                         ▼
                                ┌──────────────────┐
                                │ 继续循环         │
                                └──────────────────┘
```

### 代码实现

```typescript
static getTextValue(frameNode: FrameNode): string {
  try {
    // 使用队列实现 BFS
    let queue: Array<FrameNode> = [frameNode]

    while (queue.length > 0) {
      let f = queue.shift()!

      // 尝试从当前节点获取文本
      let textValue = Util.getComponentLabel(f.getInspectorInfo())
      if (textValue.length > 0) {
        return textValue
      }

      // 将子节点加入队列
      let count = f.getChildrenCount()
      for (let i = 0; i < count; i++) {
        let child = f.getChild(i)
        if (child) {
          queue.push(child)
        }
      }
    }

    return ''
  } catch (e) {
    return ''
  }
}
```

### 文本提取优先级

```typescript
static getComponentLabel(inspectorInfo: any): string {
  return niceTry(() => {
    // 优先级：label > content
    return inspectorInfo['$attrs']['label'] || 
           inspectorInfo['$attrs']['content'] || 
           ''
  }, '')
}
```

---

## 事件生成与发送

### 不同模式的 XPath 构建

```typescript
let xpathInfo = AutotrackClick.getXpathInfo(frameNode)
let xpath = ''
let xcontent = ''
let index = xpathInfo.index

if (context.config.mode == ConfigMode.NewSaaS) {
  // NewSaaS 模式：简单路径拼接
  xpath = PATH_SEPARATOR + xpathInfo.xpath.reverse().join(PATH_SEPARATOR)
  xcontent = PATH_SEPARATOR + xpathInfo.xcontent.reverse().join(PATH_SEPARATOR)
  if (xpathInfo.inList) {
    index = index + 1  // 列表索引从 1 开始
  }
} else if (context.config.mode == ConfigMode.CDP || context.config.mode == ConfigMode.SaaS) {
  // CDP/SaaS 模式：带索引的完整路径
  for (let i = xpathInfo.xpath.length - 1; i >= 0; i--) {
    xpath = xpath + PATH_SEPARATOR + xpathInfo.xpath[i] + '[' + xpathInfo.xcontent[i] + ']'
  }
}
```

### 事件创建

```typescript
let e = ViewElementEvent.create(
  path,           // 页面路径
  ptm,            // 页面显示时间戳（CDP）
  textValue,      // 文本内容
  xpath,          // XPath
  xcontent,       // XContent
  index,          // 列表索引
  {},             // 属性（当前未使用）
  eventType,      // 事件类型（VIEW_CLICK）
  context         // SDK 上下文
)
AnalyticsCore.writeEventToDisk(e, context)
```

### ViewElementEvent 结构

| 字段 | 类型 | 说明 |
|------|------|------|
| `path` | string | 页面路径 |
| `pageShowTimestamp` | number | 页面显示时间戳（CDP/SaaS 模式） |
| `textValue` | string | 点击元素的文本内容 |
| `xpath` | string | 元素 XPath 路径 |
| `xcontent` | string | 元素索引路径 |
| `index` | number | 列表项索引（从 1 开始） |
| `eventType` | EventType | VIEW_CLICK |
| `attributes` | AttributesType | 自定义属性 |

---

## 弹窗特殊处理

### 问题背景

弹窗（AlertDialog、Dialog、Menu 等）不是通过 Navigation 或 Router 跳转的，因此 `getPageInfo()` 无法获取到有效的页面路径。

### 解决方案

```typescript
if (!path || path.length == 0) {
  // 该 frameNode 所在页面并不是通过 Navigation 或 Router 跳转，可能是弹窗视图
  for (let i = 0; i < DIALOG_PATH_PREFIXES.length; i++) {
    let prefix = DIALOG_PATH_PREFIXES[i]
    if (xpath.startsWith(prefix)) {
      // 使用最后记录的原生页面作为当前页面
      let lastNativePage = AutotrackPage.lastNativePage
      path = lastNativePage?.path ?? ''
      if (context.config.mode == ConfigMode.CDP) {
        ptm = lastNativePage?.timestamp ?? 0
      }
      break
    }
  }
}
```

### 支持的弹窗类型

```typescript
export const DIALOG_PATH_PREFIXES: Array<string> = [
  "/root/AlertDialog",      // 警告对话框
  "/root/Dialog",           // 自定义对话框
  "/root/Keyboard",         // 键盘
  "/root/MenuWrapper",      // 菜单
  "/root/ModalPage",        // 模态页面
  "/root/Popup",            // 弹出层
  "/root/SheetWrapper",     // 底部弹层
  "/root/SelectOverlay",    // 选择覆盖层
  "/root/Video",            // 视频播放器
]
```

### 处理逻辑

```
获取页面路径
    │
    ├── path 有效？
    │       ├── 是 → 使用获取到的 path
    │       └── 否 → 弹窗处理流程
    │               │
    │               ▼
    │       ┌──────────────────┐
    │       │ XPath 匹配弹窗   │
    │       │ 前缀列表？       │
    │       └───────┬──────────┘
    │               │
    │       ┌───────┴───────┐
    │       ▼               ▼
    │   【匹配成功】    【不匹配】
    │       │               │
    │       ▼               ▼
    │   使用 lastNative    path = ''
    │   .path              (无页面信息)
    │       │
    │       ▼
    │   CDP 模式下同时
    │   获取时间戳
```

---

## 配置与限制

### 支持的组件分类

```typescript
// 按钮类组件
export const BUTTON_COMPONENTS: Array<string> = [
  "Button", "Toggle", "Checkbox", "CheckboxGroup",
  "CalendarPicker", "DatePicker", "TextPicker", "TimePicker",
  "Radio", "Rating", "Select", "Slider",
  "DownloadFileButton", "ProgressButton", "SegmentButton", "Filter"
]

// 文本类组件
export const TEXT_COMPONENTS: Array<string> = [
  "Text", "Span", "ImageSpan", "ContainerSpan",
  "SymbolSpan", "SymbolGlyph", "Hyperlink", "RichText", "SelectionMenu"
]

// 输入类组件
export const INPUT_COMPONENTS: Array<string> = [
  "TextArea", "TextInput", "RichEditor", "Search"
]

// 列表类组件
export const LIST_COMPONENTS: Array<string> = [
  "ListItem", "GridItem", "GridCol", "FlowItem"
]

// Web 组件
export const WEB_COMPONENTS: Array<string> = ["Web"]

// 容器类组件
export const CONTAINER_COMPONENTS: Array<string> = [
  "RelativeContainer", "GridRow", "ColumnSplit", "RowSplit",
  "SplitLayout", "FoldSplitContainer", "SideBarContainer",
  "List", "Grid", "Scroll", "WaterFlow", "Refresh",
  "Navigation", "NavigationContent", "NavDestination", "NavDestinationContent"
]
```

### 配置检查清单

| 检查项 | 说明 |
|--------|------|
| `frameNode` 存在 | 确保点击事件包含有效的节点信息 |
| `uniqueId > 0` | 过滤无效节点（系统节点通常为负值） |
| SDK 初始化完成 | 避免在 SDK 未就绪时采集数据 |
| `autotrackEnabled` | 无埋点总开关 |
| `dataCollectionEnabled` | 数据采集总开关 |

### 最佳实践

1. **设置组件 ID**：为关键组件设置 `id()` 属性，增强 XPath 稳定性
   ```typescript
   Button('提交')
     .id('submitBtn')
   ```

2. **列表项点击**：列表组件会自动记录索引，无需额外处理

3. **弹窗点击**：弹窗内的点击会自动关联到触发弹窗的页面

4. **文本获取**：SDK 会自动从被点击元素及其子元素中提取文本内容

---

## 总结

`AutotrackClick` 模块通过监听 ArkUI 的 `willClick` 事件，实现了对用户点击行为的自动采集。其核心设计要点包括：

1. **全量监听**：监听所有点击事件，通过多层级检查过滤无效事件
2. **XPath 生成**：向上遍历组件树构建唯一路径，支持列表索引和自定义 ID
3. **页面关联**：自动识别 Navigation 和 Router 页面，弹窗关联到触发页面
4. **文本提取**：使用 BFS 算法从组件树中提取文本内容
5. **模式适配**：根据 NewSaaS/CDP 模式生成不同格式的 XPath

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
