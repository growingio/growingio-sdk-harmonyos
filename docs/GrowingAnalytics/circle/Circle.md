# Circle（无埋点圈选）逻辑详解

> **模块归属**: 圈选模块 (circle)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/circle/Circle.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 中 `Circle`（无埋点圈选）模块的逻辑实现。圈选功能允许用户在 Web 端可视化地选择移动端界面元素，自动生成埋点事件配置。

## 目录

- [概述](#概述)
- [核心架构](#核心架构)
- [圈选连接建立](#圈选连接建立)
- [WebSocket 通信协议](#websocket-通信协议)
- [屏幕截图机制](#屏幕截图机制)
- [页面元素采集](#页面元素采集)
- [XPath 生成算法](#xpath-生成算法)
- [WebView 圈选支持](#webview-圈选支持)
- [Flutter 圈选支持](#flutter-圈选支持)
- [状态管理与异常处理](#状态管理与异常处理)

---

## 概述

Circle（圈选）是 GrowingIO 无埋点 SDK 的核心功能之一，允许用户：

1. **可视化埋点**：在 Web 端圈选移动端界面元素，无需代码集成
2. **实时预览**：实时查看移动端界面截图和元素层级
3. **XPath 自动识别**：自动生成元素的唯一标识路径
4. **多平台支持**：支持原生页面、WebView、Flutter 的圈选

### 圈选流程概览

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Web 端    │────▶│  WebSocket  │────▶│  移动端 SDK  │────▶│  截图+元素  │
│  发起圈选   │     │   服务器    │     │  建立连接   │     │  数据采集   │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                    │
                                                                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Web 端    │◀────│  WebSocket  │◀────│   数据发送   │◀────│  页面遍历   │
│  展示界面   │     │   服务器    │     │  (JSON)     │     │  XPath生成  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

---

## 核心架构

### 类关系图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Circle                                     │
│  (圈选主控制器，实现 PluginsInterface 和 WebSocketCallbackInterface)    │
├─────────────────────────────────────────────────────────────────────────┤
│  属性                                                                   │
│  ├── ws: WebSocket                    // WebSocket 连接管理             │
│  ├── statusView?: StatusView          // 圈选状态浮窗                   │
│  ├── snapshotProvider?: SnapshotProvider // 截图提供者                  │
│  └── _lastSnapshotKey: number         // 最新截图序号（用于 SaaS 圈选） │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  ├── connect(url)                     // 建立 WebSocket 连接            │
│  ├── stop(error?)                     // 停止圈选                       │
│  ├── sendScreenshot()                 // 发送截图和元素数据             │
│  ├── sendScreenshotForFlutter()       // Flutter 截图发送               │
│  └── onWebViewSaaSCircleEvent()       // SaaS WebView 圈选事件处理      │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ 使用
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           CircleElement                                 │
│                    (元素解析和 XPath 生成)                              │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  ├── setPagesAndElements()            // 原生页面元素采集               │
│  ├── setPagesAndElementsForFlutter()  // Flutter 元素采集               │
│  ├── _parseJsonTreeToElementsTree()   // JSON 树解析                    │
│  ├── _parseElementsTreeAndSetToScreenshot() // 元素树处理               │
│  ├── _traverseAllNodes()              // 遍历所有节点                   │
│  ├── _parseRectString()               // 解析位置信息                   │
│  ├── _getNodeType()                   // 获取节点类型                   │
│  ├── _isVisible()                     // 可见性检查                     │
│  └── _isClickable()                   // 可点击性检查                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ 使用
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         SnapshotProvider                                │
│                         (屏幕截图管理)                                   │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  ├── startObserver()                  // 启动布局监听                   │
│  ├── stopObserver()                   // 停止监听                       │
│  ├── refreshSnapshotIfNeeded()        // 刷新截图（带防抖）             │
│  ├── refreshSnapshot()                // 立即刷新                       │
│  ├── getSnapshot()                    // 获取截图                       │
│  └── pixmapToBase64()                 // 图片转 Base64                  │
└─────────────────────────────────────────────────────────────────────────┘
```

### 核心数据结构

```typescript
// 圈选元素（内部使用）
class _Element {
  ID: number                    // 唯一标识
  type: string                  // 组件类型
  rect: string                  // 位置信息 [x1,y1],[x2,y2]
  children: Array<_Element>     // 子元素
  attrs: _ElementAttrs          // 属性
  xpath: Array<string>          // XPath 路径数组
  xcontent: Array<string>       // XContent 路径数组
  index: number                 // 列表索引
  inList: boolean               // 是否在列表中
  content?: string              // 文本内容
  nodeType: string              // 节点类型（TEXT/BUTTON/INPUT/LIST/WEBVIEW）
  parent?: WeakRef<_Element>    // 父节点弱引用
}

// 截图元素（发送给 Web 端）
class _ScreenshotElement {
  nodeType: string              // 节点类型
  domain: string                // 应用包名
  zLevel: number                // 层级
  xpath: string                 // XPath 路径
  xcontent: string              // XContent 路径
  index?: number                // 列表索引
  content?: string              // 文本内容
  parentXPath?: string          // 父 XPath
  parentXContent?: string       // 父 XContent
  isContainer?: boolean         // 是否容器
  left/top/width/height: number // 位置尺寸
  page: string                  // 所属页面
  webView?: object              // WebView DOM 树
}

// 截图页面信息
class _ScreenshotPage {
  left/top/width/height: number // 页面位置尺寸
  path: string                  // 页面路径
  title?: string                // 页面标题
}
```

---

## 圈选连接建立

### 启动方式

圈选通过 URL Scheme 触发，SDK 作为插件集成：

```typescript
// Circle 实现 PluginsInterface
class Circle implements PluginsInterface, WebSocketCallbackInterface {
  
  // 处理 URL 打开事件
  handleOpenURL(uri: string): boolean {
    if (uri) {
      let urlObject = url.URL.parseURL(uri)
      let serviceType = urlObject.params.get('serviceType')
      let wsUrl = urlObject.params.get('wsUrl')
      
      // 检查是否为圈选服务
      if (serviceType == 'circle' && wsUrl && wsUrl.length > 0) {
        this.connect(wsUrl)
        return true
      }
    }
    return false
  }
}
```

### 连接建立流程

```
用户扫码/点击链接
        │
        ▼
┌───────────────┐
│ 解析 URL 参数 │
│ • serviceType │
│ • wsUrl       │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ 检查窗口就绪  │
│ mainWindow    │
│ uiContent     │
└───────┬───────┘
        │
   ┌────┴────┐
   ▼         ▼
【就绪】  【未就绪】
   │         │
   │         ▼
   │    延迟 300ms
   │    重试连接
   │
   ▼
┌───────────────┐
│ 创建 WebSocket│
│ 连接 wsUrl    │
└───────────────┘
```

### 连接代码

```typescript
connect(url: string) {
  if (AnalyticsCore.mainWindow && AnalyticsCore.uiContent) {
    this.ws.connect(url, this)
    return
  }
  // 窗口未就绪，延迟重试
  setTimeout(() => {
    this.connect(url)
  }, 300)
}
```

---

## WebSocket 通信协议

### 消息类型

| 消息类型 | 方向 | 说明 |
|---------|------|------|
| `ready` | 双向 | 连接就绪通知 |
| `client_info` | 移动端→Web | 设备信息 |
| `logger_data` | 移动端→Web | 日志数据 |
| `debugger_data` | 移动端→Web | 事件数据 |
| `refreshScreenshot` | 移动端→Web | 截图和元素数据 |
| `incompatible_version` | Web→移动端 | SDK 版本不兼容 |
| `quit` | 双向 | 断开连接 |
| `hybridEvent` | Web→移动端 | SaaS WebView 圈选事件（含坐标信息） |

### 圈选就绪消息（CircleReadyInfo）

```typescript
class CircleReadyInfo implements Message {
  msgType: string = 'ready'
  os: string = 'HarmonyOS'
  projectId: string              // 项目 ID
  timestamp: number              // 时间戳
  domain: string                 // 应用包名
  sdkVersion: string             // SDK 版本
  appVersion: string             // 应用版本
  screenWidth: number            // 屏幕宽度
  screenHeight: number           // 屏幕高度
  urlScheme: string              // URL Scheme
}
```

### 截图刷新消息（RefreshScreenshot）

```typescript
class RefreshScreenshot implements Message {
  msgType: string = 'refreshScreenshot'
  scale: number = 1              // 屏幕缩放比例
  screenWidth: number            // 屏幕宽度
  screenHeight: number           // 屏幕高度
  snapshotKey: number            // 截图序号（递增）
  screenshot: string             // Base64 图片数据
  pages?: Array<object>          // 页面信息数组
  elements?: Array<object>       // 元素信息数组
}
```

### WebSocket 状态回调

```typescript
interface WebSocketCallbackInterface {
  onWebSocketOpen(err: BusinessError, value: Object): void
  onWebSocketReceive(err: BusinessError, value: string | ArrayBuffer): void
  onWebSocketClose(err: BusinessError, value: webSocket.CloseResult): void
  onWebSocketError(err: BusinessError): void
}
```

### 消息处理流程

```
WebSocket 连接成功
        │
        ▼
┌───────────────┐
│ 发送 ready    │
│ CircleReadyInfo
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ 等待 Web 端   │
│ ready 消息    │
└───────┬───────┘
        │
        ▼
┌─────────────────────────┐
│ 启动 SnapshotProvider   │
│ 开始监听布局变化        │
└───────┬─────────────────┘
        │
        ▼
┌─────────────────────────┐
│ 显示圈选状态浮窗        │
│ StatusView              │
└─────────────────────────┘
```

---

## 屏幕截图机制

### SnapshotProvider 架构

```typescript
class SnapshotProvider {
  sendSnapshot: Function        // 发送截图回调
  observer?: DidLayoutObserver // 布局观察者
  timer?: number               // 防抖定时器
  lastRefreshTime: number = 0  // 上次刷新时间
  snapshotKey: number = 0      // 截图序号
  onScroll: boolean = false    // 是否正在滚动
}
```

### 布局监听

```typescript
startObserver() {
  let didLayoutCallback = () => {
    this.refreshSnapshotIfNeeded()  // 布局变化时刷新
  }
  let onScrollEventCallback = (info: uiObserver.ScrollEventInfo) => {
    // 记录滚动状态，滚动期间暂停截图
    this.onScroll = info.scrollEvent == uiObserver.ScrollEventType.SCROLL_START
  }

  this.observer = new DidLayoutObserver(didLayoutCallback, onScrollEventCallback)
  this.observer.on()
  this.refreshSnapshotIfNeeded()
}
```

监听事件：
- `didLayout`：布局完成时触发
- `scrollEvent`：滚动开始/结束时触发

### 防抖机制

```
触发刷新
    │
    ▼
┌───────────────┐
│ 检查定时器    │
│ 存在则清除    │
└───────┬───────┘
        │
        ▼
┌─────────────────────┐
│ 距离上次刷新 > 1s？ │
└─────────┬───────────┘
          │
     ┌────┴────┐
     ▼         ▼
   【是】    【否】
     │         │
     ▼         ▼
 立即刷新   设置 1s 定时器
              │
              ▼
           延迟刷新
```

### 截图生成流程

```typescript
getSnapshot(callback) {
  AnalyticsCore.mainWindow.snapshot((error, pixmap) => {
    if (error.code) {
      return
    }
    let size = pixmap.getImageInfoSync().size
    
    this.pixmapToBase64(pixmap).then(snapshot => {
      pixmap.release()
      this.snapshotKey += 1
      
      callback(
        px2vp(size.width),      // 转换为 vp 单位
        px2vp(size.height),
        this.snapshotKey,
        snapshot                // Base64 图片
      )
    })
  })
}
```

### 图片压缩

```typescript
pixmapToBase64(pixmap: image.PixelMap): Promise<string> {
  let packOpts: image.PackingOption = {
    format: 'image/jpeg',
    quality: 50              // JPEG 质量 50%，平衡清晰度与大小
  }
  let imagePackerApi = image.createImagePacker()
  
  return imagePackerApi.packing(pixmap, packOpts).then((data: ArrayBuffer) => {
    let result = buffer.from(data).toString('base64')
    result = 'data:image/jpeg;base64,' + result
    return result
  })
}
```

---

## 页面元素采集

### 整体流程

```
获取截图
    │
    ▼
┌─────────────────┐
│ 获取 Inspector  │
│ Tree（组件树）  │
│ 过滤指定属性    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 解析 JSON 树    │
│ 转换为 _Element │
│ 结构            │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 遍历元素树      │
│ • 生成 XPath    │
│ • 过滤可见元素  │
│ • 检查可点击性  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 构建截图数据    │
│ • pages         │
│ • elements      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 发送 WebSocket  │
│ 消息            │
└─────────────────┘
```

### 获取组件树

```typescript
static async setPagesAndElements(screenshot: RefreshScreenshot) {
  // 过滤需要的属性，减少数据量
  let filter = ['id', 'content', 'focusable', 'label', 'opacity', 'visibility']
  let inspectorTreeString = AnalyticsCore.uiContent.getFilteredInspectorTree(filter)
  let inspectorTree = JSON.parse(inspectorTreeString)

  // 解析为内部元素树
  let elementsTree = CircleElement._parseJsonTreeToElementsTree(inspectorTree)
  
  // 遍历并生成截图数据
  await CircleElement._parseElementsTreeAndSetToScreenshot(elementsTree, screenshot)
}
```

### JSON 树解析

```typescript
private static _parseJsonTreeToElementsTree(json: object): _Element {
  let element = new _Element()
  
  // 解析基础信息
  if (json["$ID"] !== undefined) {
    element.ID = json["$ID"]
  }
  if (json["$type"] !== undefined) {
    element.type = json["$type"]
  }
  if (json["$rect"] !== undefined) {
    element.rect = json["$rect"]
  }

  // 解析属性
  element.attrs = new _ElementAttrs()
  if (json["$attrs"] !== undefined) {
    element.attrs.id = json["$attrs"].id
    element.attrs.content = json["$attrs"].content || json["$attrs"].label
    element.attrs.focusable = json["$attrs"].focusable
    element.attrs.visibility = json["$attrs"].visibility
    element.attrs.opacity = json["$attrs"].opacity
  }

  // 递归解析子元素
  if (json["$children"] && Array.isArray(json["$children"])) {
    element.children = json["$children"].map(child => 
      CircleElement._parseJsonTreeToElementsTree(child)
    )
  }

  return element
}
```

### 节点遍历策略

使用 DFS（深度优先搜索）遍历元素树：

```typescript
private static async _traverseAllNodes(
  rootElement: _Element, 
  callback: (element: _Element) => Promise<void>
) {
  let stack: _Element[] = [rootElement]

  while (stack.length > 0) {
    let element = stack.pop()!
    
    // 只处理可见且可点击的元素
    if (CircleElement._isVisible(element) && CircleElement._isClickable(element)) {
      await callback(element)
    }

    // 处理子元素...
    if (element.type == 'root') {
      element.xpath.push('root')
      element.xcontent.push('0')
    }

    // 构建子元素 XPath 并压栈
    if (CircleElement._isVisible(parent) && parent.children && parent.children.length > 0) {
      let children: _Element[] = []
      
      for (let i = 0; i < parent.children.length; i++) {
        let e = parent.children[i]
        e.nodeType = CircleElement._getNodeType(e.type)
        e.xpath = [...parent.xpath]      // 继承父路径
        e.xcontent = [...parent.xcontent]
        
        // 计算 xcontent...
        
        // 设置 XPath 信息
        e.xpath.push(e.type)
        if (LIST_COMPONENTS.includes(e.type)) {
          // 列表组件特殊处理
          e.xcontent.push('-')
          e.index = xcontent
          e.inList = true
        } else {
          // 普通组件
          let customId = ''
          if (e.attrs.id && e.attrs.id.length > 0) {
            customId = '#' + e.attrs.id.replace(/\//g, '')
            if (customId.includes(AUTOTRACK_ELEMENT_ID)) {
              // 标记为可点击的组件
              e.attrs.focusable = true
            }
          }
          e.xcontent.push(String(xcontent) + customId)
        }
        
        e.content = e.attrs.content
        children.push(e)
      }

      // 反转后压栈（保持顺序）
      children = children.reverse()
      stack.push(...children)
    }
  }
}
```

### 可见性检查

```typescript
private static _isVisible(element: _Element): boolean {
  if (element.type == 'root') {
    return true
  }
  let visibility = element.attrs.visibility
  let opacity = element.attrs.opacity
  
  // 可见性：Visibility.Visible 且透明度 > 0
  return visibility == 'Visibility.Visible' && opacity > 0
}
```

### 可点击性检查

```typescript
private static _isClickable(element: _Element): boolean {
  let type = element.type
  
  // overlay 层不可点击
  if (type == 'overlay') {
    return false
  }
  
  // Button 类型组件默认可点击
  if (element.nodeType == CIRCLE_NODE_BUTTON) {
    return true
  }
  
  // 自定义组件默认可点击
  if (type == '__Common__') {
    return true
  }
  
  // 通过 focusable 判断是否可交互
  if (element.attrs.focusable) {
    // 排除容器组件
    if (!CONTAINER_COMPONENTS.includes(type)) {
      return true
    }
  }
  
  return false
}
```

---

## XPath 生成算法

### 算法概述

XPath 生成与 `AutotrackClick` 中的逻辑类似，但在圈选场景下需要：
1. **遍历所有节点**：不只是点击时的单个节点
2. **优化性能**：使用快速索引计算，必要时才调用系统 API
3. **支持列表**：正确处理 ListItem、GridItem 等列表组件

### 快速索引计算

```typescript
// 使用 Map 缓存同类型兄弟节点的索引
let previousSiblingXContents: Map<string, number> = new Map()

// 快速计算 xcontent
let n = previousSiblingXContents.get(e.type)
if (n == undefined) {
  n = -1
}
let xcontent = n + 1
previousSiblingXContents.set(e.type, xcontent)
```

### 索引校正机制

当 Inspector Tree 与实际 FrameNode 不一致时，需要校正索引：

```typescript
xcontent = xcontent + childOffset

if (parentType != 'root') {
  let frameNode = AnalyticsCore.uiContent.getFrameNodeByUniqueId(e.ID)
  let parentFrameNode = AnalyticsCore.uiContent.getFrameNodeByUniqueId(parent.ID)
  
  if (!frameNode || !parentFrameNode) {
    continue
  }
  
  // 检查快速计算是否正确
  if (parentFrameNode.getChild(i + childOffset) != frameNode) {
    // 使用慢速方法重新计算
    let actualXContent = AutotrackClick.getXcontent(frameNode)
    childOffset = actualXContent - xcontent
    xcontent = actualXContent
  }
}
```

### 不同模式的 XPath 格式

| 模式 | XPath | XContent |
|------|-------|----------|
| NewSaaS | `/root/Column/Button` | `/0/0/0` |
| CDP | `/root[0]/Column[0]/Button[0]` | （与 xpath 合并） |

### 列表组件处理

```typescript
if (LIST_COMPONENTS.includes(e.type)) {
  if (parent.inList) {
    // 父节点已在列表中，更新父索引
    let j = e.xcontent.indexOf('-')
    if (j !== -1) {
      e.xcontent[j] = String(parent.index)
    }
  }
  // 标记为列表节点
  e.xcontent.push('-')
  e.index = xcontent
  e.inList = true
}
```

### 页面信息获取

```typescript
let pageInfo = AnalyticsCore.uiContent.getPageInfoByUniqueId(e.ID)
let realPath: string | undefined = undefined

if (pageInfo.navDestinationInfo) {
  // Navigation 页面
  realPath = PATH_SEPARATOR + pageInfo.navDestinationInfo.name.toString()
  alias = Util.getAliasFromNavInfoParameter(pageInfo.navDestinationInfo.param)
} else if (pageInfo.routerPageInfo) {
  // Router 页面
  let param = AnalyticsCore.uiContent.getRouter().getParams()
  realPath = PATH_SEPARATOR + pageInfo.routerPageInfo.name.toString()
  alias = Util.getAliasFromNavInfoParameter(param)
}

// 使用别名替换路径
if (alias.length > 0) {
  pagePath = PATH_SEPARATOR + alias
}
element.page = pagePath
```

### 弹窗处理

```typescript
if (!realPath) {
  // 该 frameNode 所在页面并不是通过 Navigation 或 Router 跳转，可能是弹窗视图
  for (let i = 0; i < DIALOG_PATH_PREFIXES.length; i++) {
    let prefix = DIALOG_PATH_PREFIXES[i]
    if (element.xpath.startsWith(prefix)) {
      // 使用最后记录的原生页面
      let lastNativePage = AutotrackPage.lastNativePage
      element.page = lastNativePage?.path ?? ''
      break
    }
  }
}
```

---

## WebView 圈选支持

### Hybrid 页面圈选

对于 WebView 组件，需要额外获取 H5 页面的 DOM 树：

```typescript
if (nodeType == CIRCLE_NODE_WEBVIEW) {
  let webviewId = ''
  if (e.attrs.id && e.attrs.id.length > 0) {
    webviewId = e.attrs.id
    
    // 获取 H5 DOM 树
    let domTree = await Hybrid.getDomTreeById(
      webviewId, 
      element.left, 
      element.top, 
      element.width, 
      element.height
    )
    
    try {
      element.webView = JSON.parse(domTree) ?? undefined
    } catch {
      element.webView = undefined
    }
  }
}
```

### WebView 元素数据结构

```typescript
element.webView = {
  // H5 页面的 DOM 树结构
  // 由 Hybrid 模块提供
}
```

### SaaS 模式 WebView 圈选

SaaS 模式下，WebView 圈选通过双向通信实现：

**移动端 → 服务端（上报）**：`SaaSHybrid.webCircleHybridEvent()` 收到 H5 页面的圈选事件后，经坐标转换（WebView 本地 CSS 坐标 → 服务端截图 vp 坐标）后由 `Circle.onWebViewSaaSCircleEvent()` 转发给服务端，并附带当前 `snapshotKey`。

**服务端 → 移动端（下发）**：服务端下发 `hybridEvent` 消息（含圈选坐标），由 `Hybrid.handleSaaSCircleEventFromServer()` 路由到命中该坐标的 WebView，经坐标反变换（vp → WebView 本地 CSS px）后通过 `window._vds_hybrid.helper.handleWebEvent()` 传递给 H5 页面。

---

## Flutter 圈选支持

### Flutter 数据格式

Flutter 页面由 Flutter SDK 提供元素数据，通过 Platform Channel 传递：

```typescript
static setPagesAndElementsForFlutter(
  screenshot: RefreshScreenshot, 
  data: Map<string, Object>
) {
  // 屏幕信息
  let width = data.get("width") as number
  let height = data.get("height") as number
  let scale = data.get("scale") as number
  
  screenshot.screenWidth = width
  screenshot.screenHeight = height
  screenshot.scale = scale

  // 页面信息
  let pages: Array<_ScreenshotPage> = []
  let pagesData = data.get("pages") as Array<Map<string, Object>>
  for (let pageData of pagesData) {
    let page = new _ScreenshotPage(
      pageData.get("left"),
      pageData.get("top"),
      pageData.get("width"),
      pageData.get("height"),
      pageData.get("path"),
      pageData.get("title")
    )
    pages.push(page)
  }
  screenshot.pages = pages

  // 元素信息
  let elements: Array<_ScreenshotElement> = []
  let elementsData = data.get("elements") as Array<Map<string, Object>>
  for (let elementData of elementsData) {
    let element = new _ScreenshotElement(
      elementData.get("nodeType"),
      AppInfo.domain,
      elementData.get("zLevel"),
      elementData.get("xpath"),
      elementData.get("xcontent")
    )
    // 设置其他属性...
    elements.push(element)
  }
  screenshot.elements = elements
}
```

### Flutter 与原生协同

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ Flutter SDK │────────▶│  Platform   │────────▶│  Native SDK │
│ 生成元素数据 │         │   Channel   │         │ 转发给 Web  │
└─────────────┘         └─────────────┘         └──────┬──────┘
                                                       │
                                                       ▼
                                               ┌─────────────┐
                                               │   Web 端    │
                                               │  展示圈选   │
                                               └─────────────┘
```

---

## 状态管理与异常处理

### 圈选状态浮窗

```typescript
if (!this.statusView) {
  this.statusView = new StatusView('正在进行圈选(上下拖曳移动)', () => {
    // 点击浮窗显示对话框
    StatusView.showDialog({
      title: '正在进行圈选',
      message: `APP版本: ${AppInfo.appVersion}\nSDK版本: ${SDK_VERSION}`,
      buttons: [
        { text: '继续', color: '#000000' },
        { text: '退出', color: '#000000' }
      ]
    }).then(r => {
      if (r.index == 1) {
        this.ws.disconnect()  // 点击退出，断开连接
      }
    })
  })
}
this.statusView.show()
```

### 连接断开处理

```typescript
stop(error?: string) {
  // 通知 Flutter 圈选关闭
  Flutter.onCircleClosed()

  // 关闭 SaaS hybrid 圈选
  Hybrid.saasCircleEnabled = false
  // 重置截图序号
  this._lastSnapshotKey = 0

  // 停止截图监听
  this.snapshotProvider?.stopObserver()
  
  // 隐藏状态浮窗
  this.statusView?.hide()

  // 显示断开连接提示
  if (error && error.length > 0) {
    StatusView.showDialog({
      title: '设备已断开连接',
      message: error,
      buttons: [{ text: '知道了', color: '#000000' }]
    })
  }
}
```

### 异常场景处理

| 异常场景 | 处理方式 |
|---------|---------|
| WebSocket 连接失败 | 显示"服务器链接失败"对话框 |
| WebSocket 断开 | 显示"设备已断开连接"提示 |
| 版本不兼容 | 显示升级 SDK 提示，自动断开连接 |
| 窗口未就绪 | 延迟 300ms 重试连接 |
| 滚动中 | 暂停截图，滚动结束后再刷新 |

### 版本兼容性检查

```typescript
if (message.msgType == 'incompatible_version') {
  // 版本号不适配
  StatusView.showDialog({
    title: '抱歉',
    message: '您使用的SDK版本号过低，请升级SDK后再使用',
    buttons: [{ text: '知道了', color: '#000000' }]
  })
  this.ws.disconnect()
}
```

---

## 总结

Circle 圈选模块通过 WebSocket 与 Web 端实时通信，实现了移动端界面的可视化圈选。其核心设计要点包括：

1. **实时通信**：WebSocket 双向通信，支持截图和元素数据的实时同步
2. **性能优化**：防抖机制避免频繁截图，快速索引计算减少系统 API 调用
3. **多平台支持**：原生 ArkUI、WebView、Flutter 的统一圈选支持
4. **智能识别**：自动识别可点击元素，支持列表组件和自定义 ID
5. **异常处理**：完善的连接管理和用户提示，确保用户体验

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
