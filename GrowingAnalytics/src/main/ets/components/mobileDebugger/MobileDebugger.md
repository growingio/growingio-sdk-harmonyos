# MobileDebugger（移动调试器）逻辑详解

> **模块归属**: 移动调试器模块 (mobiledebugger)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/mobileDebugger/MobileDebugger.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 中 `MobileDebugger` 模块的逻辑实现。移动调试器功能允许开发者在 Web 端实时查看移动端的事件数据、日志信息和屏幕截图，方便 SDK 集成调试和事件验证。

## 目录

- [概述](#概述)
- [核心架构](#核心架构)
- [调试器连接建立](#调试器连接建立)
- [WebSocket 通信协议](#websocket-通信协议)
- [事件数据流](#事件数据流)
- [日志数据流](#日志数据流)
- [屏幕截图机制](#屏幕截图机制)
- [队列管理](#队列管理)
- [状态管理与异常处理](#状态管理与异常处理)

---

## 概述

MobileDebugger 是 GrowingIO SDK 的实时调试工具，主要功能包括：

1. **实时事件监控**：在 Web 端实时查看 SDK 采集的事件数据
2. **日志查看**：捕获 SDK 内部日志和自定义日志
3. **屏幕截图**：实时查看移动端当前界面
4. **设备信息**：查看设备、应用、SDK 等详细信息

### 与 Circle（圈选）的区别

| 功能 | MobileDebugger | Circle（圈选） |
|------|---------------|---------------|
| 主要用途 | 事件调试、日志查看 | 可视化埋点配置 |
| 实时截图 | ✅ 支持 | ✅ 支持 |
| 事件数据 | ✅ 实时发送 | ❌ 不发送 |
| 日志数据 | ✅ 实时发送 | ❌ 不发送 |
| 元素圈选 | ❌ 不支持 | ✅ 支持 |
| 页面元素 | ❌ 不采集 | ✅ 详细采集 |

### 调试流程概览

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Web 端    │────▶│  WebSocket  │────▶│  移动端 SDK  │────▶│  开始调试   │
│  发起调试   │     │   服务器    │     │  建立连接   │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                    │
                       ┌────────────────────────────────────────────┤
                       │                                            │
                       ▼                                            ▼
              ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
              │  事件数据    │     │   日志数据   │     │  屏幕截图   │
              │  实时发送    │     │   实时发送   │     │  实时刷新   │
              └─────────────┘     └─────────────┘     └─────────────┘
```

---

## 核心架构

### 类关系图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MobileDebugger                                  │
│           (调试器主控制器，实现 PluginsInterface)                        │
├─────────────────────────────────────────────────────────────────────────┤
│  属性                                                                   │
│  ├── ws: WebSocket                    // WebSocket 连接管理             │
│  ├── eventQueue: Queue<EventData>     // 事件数据队列（容量50）         │
│  ├── logQueue: Queue<LogData>         // 日志数据队列（容量100）        │
│  ├── statusView?: StatusView          // 调试状态浮窗                   │
│  ├── snapshotProvider?: SnapshotProvider // 截图提供者                  │
│  ├── timer: number                    // 定时器ID                       │
│  └── loggerOpen: boolean              // 日志开关状态                   │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  ├── constructor()                    // 初始化，设置日志回调           │
│  ├── connect(url)                     // 建立 WebSocket 连接            │
│  ├── stop(error?)                     // 停止调试                       │
│  ├── startSendDebuggerData()          // 启动定时发送                   │
│  ├── handleOpenURL()                  // 处理 URL 启动                  │
│  └── onEventsDidSend()                // 事件发送回调                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ 使用
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                             Queue<T>                                    │
│                         (循环队列实现)                                   │
├─────────────────────────────────────────────────────────────────────────┤
│  属性                                                                   │
│  ├── data: Array<T>                   // 数据存储数组                   │
│  ├── isLimit: boolean                 // 是否限制容量                   │
│  └── limitSize: number                // 容量限制                       │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  ├── enqueue(d: T)                    // 入队（超限时淘汰旧数据）       │
│  └── dequeue(): Array<T>              // 出队（清空队列返回所有）       │
└─────────────────────────────────────────────────────────────────────────┘
```

### 核心数据结构

```typescript
// 事件数据
class EventData {
  url: string                    // 上报地址
  deviceId?: string              // 设备ID
  userId?: string                // 用户ID
  eventType?: string             // 事件类型
  timestamp?: number             // 时间戳
  path?: string                  // 页面路径
  xpath?: string                 // 元素XPath
  textValue?: string             // 文本内容
  // ... 更多事件字段
}

// 日志数据
class LogData {
  type: string                   // 日志类型
  subType: string                // 子类型
  message: string                // 日志内容
  time: number                   // 时间戳
}

// 截图刷新消息
class RefreshScreenshot {
  msgType: string = 'refreshScreenshot'
  scale: number                  // 屏幕缩放比例
  screenWidth: number            // 屏幕宽度
  screenHeight: number           // 屏幕高度
  snapshotKey: number            // 截图序号
  screenshot: string             // Base64 图片数据
}
```

---

## 调试器连接建立

### 启动方式

调试器通过 URL Scheme 触发，SDK 作为插件集成：

```typescript
// MobileDebugger 实现 PluginsInterface
class MobileDebugger implements PluginsInterface, WebSocketCallbackInterface {
  
  // 处理 URL 打开事件
  handleOpenURL(uri: string): boolean {
    if (uri) {
      let urlObject = niceTry(() => url.URL.parseURL(uri))
      if (!urlObject) {
        return false
      }
      let serviceType = urlObject.params.get('serviceType')
      let wsUrl = urlObject.params.get('wsUrl')
      
      // 检查是否为调试器服务
      if (serviceType == 'debugger' && wsUrl && wsUrl.length > 0) {
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

### 与圈选的启动区别

| 特性 | MobileDebugger | Circle |
|------|---------------|--------|
| serviceType | `debugger` | `circle` |
| 事件队列 | ✅ 启用 | ❌ 不启用 |
| 日志队列 | ✅ 启用 | ❌ 不启用 |
| 元素采集 | ❌ 不启用 | ✅ 启用 |

---

## WebSocket 通信协议

### 消息类型

| 消息类型 | 方向 | 说明 |
|---------|------|------|
| `ready` | 双向 | 连接就绪通知 |
| `client_info` | 移动端→Web | 设备信息 |
| `logger_open` | Web→移动端 | 开启日志发送 |
| `logger_close` | Web→移动端 | 关闭日志发送 |
| `logger_data` | 移动端→Web | 日志数据 |
| `debugger_data` | 移动端→Web | 事件数据 |
| `refreshScreenshot` | 移动端→Web | 截图数据 |
| `incompatible_version` | Web→移动端 | SDK 版本不兼容 |
| `quit` | 双向 | 断开连接 |

### 就绪消息（ReadyInfo）

```typescript
class ReadyInfo implements Message {
  msgType: string = 'ready'
  os: string = 'HarmonyOS'
  projectId: string              // 项目 ID
  timestamp: number              // 时间戳
  domain: string                 // 应用包名
  sdkVersion: string             // SDK 版本
  sdkVersionCode: string         // SDK 版本号
  screenWidth: number            // 屏幕宽度
  screenHeight: number           // 屏幕高度
  urlScheme: string              // URL Scheme
}
```

### 设备信息消息（ClientInfo）

```typescript
class ClientInfo implements Message {
  msgType: string = 'client_info'
  sdkVersion: string
  data: ClientInfoData
}

class ClientInfoData {
  os: string = 'HarmonyOS'
  osVersion: string              // 系统版本
  appVersion: string             // 应用版本
  appChannel: string             // 应用渠道
  deviceType: string             // 设备类型
  deviceBrand: string            // 设备品牌
  deviceModel: string            // 设备型号
}
```

### 消息处理流程

```
WebSocket 连接成功
        │
        ▼
┌───────────────┐
│ 发送 ready    │
│ ReadyInfo     │
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
│ 发送 ClientInfo         │
│ 设备信息                │
└───────┬─────────────────┘
        │
        ▼
┌─────────────────────────┐
│ 启动 SnapshotProvider   │
│ 开始监听布局变化        │
└───────┬─────────────────┘
        │
        ▼
┌─────────────────────────┐
│ 启用事件/日志队列       │
│ isLimit = false         │
└───────┬─────────────────┘
        │
        ▼
┌─────────────────────────┐
│ 启动定时发送（1s）      │
│ startSendDebuggerData() │
└───────┬─────────────────┘
        │
        ▼
┌─────────────────────────┐
│ 显示调试状态浮窗        │
│ StatusView              │
└─────────────────────────┘
```

### 日志开关控制

Web 端可以动态控制日志发送：

```typescript
if (message.msgType == 'logger_open') {
  // 开启日志发送
  this.loggerOpen = true
} else if (message.msgType == 'logger_close') {
  // 关闭日志发送
  this.loggerOpen = false
}
```

---

## 事件数据流

### 事件拦截机制

MobileDebugger 通过 `EventPersistence` 回调拦截即将发送的事件：

```typescript
onEventsDidSend(events: EventPersistence[], request: rcp.Request) {
  let url = request.url.toString()
  
  for (let i = 0; i < events.length; i++) {
    let e = events[i]
    // 解析事件数据
    let eventData = new EventData(url, e.data)
    // 加入事件队列
    this.eventQueue.enqueue(eventData)
  }
}
```

### 事件数据结构

```typescript
class EventData {
  url: string                    // 上报地址
  
  // 设备信息
  deviceId?: string
  userId?: string
  sessionId?: string
  
  // 事件基本信息
  eventType?: string
  timestamp?: number
  platform?: string
  domain?: string
  
  // 页面信息
  path?: string
  title?: string
  referralPage?: string
  
  // 元素信息（点击事件）
  textValue?: string
  xpath?: string
  xcontent?: string
  index?: number
  
  // 屏幕信息
  screenHeight?: number
  screenWidth?: number
  orientation?: string
  
  // SDK 信息
  sdkVersion?: string
  appVersion?: string
  
  // 自定义事件
  eventName?: string
  attributes?: AttributesType
  
  constructor(url: string, event: string) {
    this.url = url
    this.parseEvent(event)  // 解析 JSON 事件数据
  }
}
```

### 事件发送流程

```
事件产生
    │
    ▼
┌───────────────┐
│ EventBuilder  │
│ 构建事件      │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ EventSender   │
│ 发送事件      │
└───────┬───────┘
        │
        ▼
┌─────────────────────┐
│ onEventsDidSend()   │
│ 回调拦截            │
└───────┬─────────────┘
        │
        ▼
┌─────────────────────┐
│ eventQueue.enqueue()│
│ 加入事件队列        │
└───────┬─────────────┘
        │
        ▼
┌─────────────────────┐
│ 定时器（1s）        │
│ dequeue()           │
└───────┬─────────────┘
        │
        ▼
┌─────────────────────┐
│ ws.sendEvents()     │
│ WebSocket 发送      │
└───────┬─────────────┘
        │
        ▼
┌─────────────────────┐
│     Web 端          │
│   实时展示事件      │
└─────────────────────┘
```

---

## 日志数据流

### 日志捕获机制

MobileDebugger 在初始化时注册日志回调：

```typescript
constructor() {
  if (!LogUtil.logDebugger) {
    LogUtil.logDebugger = (type: string, message: string) => {
      let log = new LogData(type, message)
      this.logQueue.enqueue(log)
    }
  }
}
```

### 日志数据结构

```typescript
class LogData {
  type: string                   // 日志类型（error/warn/info/debug）
  subType: string                // 子类型
  message: string                // 日志内容
  time: number                   // 时间戳

  constructor(type: string, message: string) {
    this.type = type
    this.subType = ''
    this.message = message
    this.time = Date.now()
  }
}
```

### 日志发送流程

```
SDK 内部调用 LogUtil
    │
    ▼
┌─────────────────────┐
│ LogUtil.info()      │
│ LogUtil.error()     │
│ ...                 │
└───────┬─────────────┘
        │
        ▼
┌─────────────────────┐
│ logDebugger 回调    │
│（如果已注册）        │
└───────┬─────────────┘
        │
        ▼
┌─────────────────────┐
│ logQueue.enqueue()  │
│ 加入日志队列        │
└───────┬─────────────┘
        │
        ▼
┌─────────────────────┐
│ 定时器（1s）        │
│ loggerOpen == true? │
└───────┬─────────────┘
        │
   ┌────┴────┐
   ▼         ▼
【开启】   【关闭】
   │         │
   ▼         ▼
 发送      不发送
   │
   ▼
┌─────────────────────┐
│ ws.sendLogs()       │
│ WebSocket 发送      │
└───────┬─────────────┘
        │
        ▼
┌─────────────────────┐
│     Web 端          │
│   实时展示日志      │
└─────────────────────┘
```

---

## 屏幕截图机制

### 与圈选截图的区别

| 特性 | MobileDebugger 截图 | Circle 截图 |
|------|-------------------|-------------|
| 用途 | 界面预览 | 元素圈选 |
| 元素数据 | ❌ 不采集 | ✅ 详细采集 |
| 截图频率 | 布局变化时 | 布局变化时 |
| 防抖机制 | ✅ 1秒防抖 | ✅ 1秒防抖 |

### 截图实现

MobileDebugger 复用与 Circle 相同的 `SnapshotProvider` 类：

```typescript
if (!this.snapshotProvider) {
  this.snapshotProvider = new SnapshotProvider(
    (screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) => {
      let screenshot = new RefreshScreenshot(screenWidth, screenHeight, snapshotKey, snapshot)
      this.ws.sendScreenshot(screenshot)
    }
  )
}
this.snapshotProvider.startObserver()
```

截图功能详见 [Circle 文档](./circle_logic.md#屏幕截图机制)。

---

## 队列管理

### 队列设计

MobileDebugger 使用自定义的 `Queue` 类管理事件和日志数据：

```typescript
export class Queue<T> {
  data: Array<T> = []           // 数据存储
  isLimit: boolean              // 是否限制容量
  limitSize: number             // 容量限制

  constructor(limitSize: number) {
    this.isLimit = true
    this.limitSize = limitSize > 0 ? limitSize : 50
  }
}
```

### 队列特性

| 队列 | 容量限制 | 用途 |
|------|---------|------|
| `eventQueue` | 50 | 存储事件数据 |
| `logQueue` | 100 | 存储日志数据 |

### 入队操作（enqueue）

```typescript
enqueue(d: T) {
  if (this.isLimit) {
    // 循环淘汰：超出容量时移除最旧数据
    while (this.data.length > this.limitSize) {
      this.data.shift()
    }
  }
  this.data.push(d)
}
```

**特点**：
- 当队列满时，自动淘汰最早的数据（FIFO）
- 避免内存无限增长
- 确保在 WebSocket 断开期间不会溢出

### 出队操作（dequeue）

```typescript
dequeue(): Array<T> {
  // 取出所有数据并清空队列
  let data = [...this.data]
  this.data = []
  return data
}
```

**特点**：
- 一次性取出队列中所有数据
- 清空队列准备接收新数据
- 返回数组便于批量发送

### 队列状态控制

```typescript
// 调试器就绪后，解除队列限制（仍然保持容量上限）
this.eventQueue.isLimit = false
this.logQueue.isLimit = false

// 调试器停止后，启用限制（此时不接收新数据）
this.eventQueue.isLimit = true
this.logQueue.isLimit = true
```

### 定时发送机制

```typescript
startSendDebuggerData() {
  if (this.timer > 0) {
    return  // 避免重复启动
  }
  
  this.timer = setInterval(() => {
    // 发送事件数据
    let events = this.eventQueue.dequeue()
    this.ws.sendEvents(events)

    // 发送日志数据（仅在开启时）
    if (this.loggerOpen) {
      let logs = this.logQueue.dequeue()
      this.ws.sendLogs(logs)
    }
  }, 1000)  // 每秒发送一次
}
```

---

## 状态管理与异常处理

### 调试状态浮窗

```typescript
if (!this.statusView) {
  this.statusView = new StatusView('正在进行Debugger(上下拖曳移动)', () => {
    // 点击浮窗显示对话框
    StatusView.showDialog({
      title: '正在进行Debugger',
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

### 状态浮窗特点

1. **可拖动**：支持上下拖曳移动位置
2. **点击交互**：点击显示详细信息对话框
3. **安全区域**：自动避开系统状态栏和导航栏
4. **视觉提示**：蓝色背景，白色文字

### 停止调试处理

```typescript
stop(error?: string) {
  // 1. 停止截图监听
  this.snapshotProvider?.stopObserver()
  
  // 2. 隐藏状态浮窗
  this.statusView?.hide()

  // 3. 显示断开连接提示
  if (error && error.length > 0) {
    StatusView.showDialog({
      title: '设备已断开连接',
      message: error,
      buttons: [{ text: '知道了', color: '#000000' }]
    })
  }

  // 4. 启用队列限制（停止接收新数据）
  this.eventQueue.isLimit = true
  this.logQueue.isLimit = true
  
  // 5. 停止定时发送
  clearInterval(this.timer)
  this.timer = -1
}
```

### 异常场景处理

| 异常场景 | 处理方式 |
|---------|---------|
| WebSocket 连接失败 | 显示"服务器链接失败"对话框 |
| WebSocket 断开 | 显示"设备已断开连接"提示 |
| 版本不兼容 | 显示升级 SDK 提示，自动断开连接 |
| 窗口未就绪 | 延迟 300ms 重试连接 |
| 用户点击退出 | 断开 WebSocket 连接 |

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

MobileDebugger 模块通过 WebSocket 与 Web 端实时通信，为开发者提供了强大的 SDK 调试能力。其核心设计要点包括：

1. **双队列机制**：事件队列和日志队列分别管理，容量限制防止内存溢出
2. **定时批量发送**：1秒间隔批量发送，平衡实时性和性能
3. **日志动态控制**：Web 端可实时开启/关闭日志接收
4. **复用截图能力**：与 Circle 共享 SnapshotProvider，保持一致的截图体验
5. **完善的异常处理**：连接断开、版本不兼容等场景都有用户提示

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
