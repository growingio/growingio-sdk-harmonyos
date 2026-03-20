# GrowingAnalyticsAtomicService vs GrowingAnalytics 差异分析

> GrowingAnalyticsAtomicService 是面向 HarmonyOS 元服务（AtomicService）的精简版 SDK，由主 SDK GrowingAnalytics 裁剪改造而来，以适应元服务平台的 API 限制和包体积要求。

---

## 目录

- [功能模块对比总览](#功能模块对比总览)
- [网络层改造](#网络层改造)
- [插件系统裁剪](#插件系统裁剪)
- [删除的功能模块](#删除的功能模块)
- [公开接口差异](#公开接口差异)
- [事件发送层差异](#事件发送层差异)
- [设备信息采集差异](#设备信息采集差异)
- [EventTimer 计时差异](#eventtimer-计时差异)
- [初始化流程差异](#初始化流程差异)
- [依赖与包配置差异](#依赖与包配置差异)
- [文件结构对比](#文件结构对比)

---

## 功能模块对比总览

| 功能模块 | GrowingAnalytics | AtomicService | 状态 |
|---------|:---:|:---:|:---:|
| 基础事件追踪（Custom/Visit/Page） | ✓ | ✓ | 保留 |
| 自动化追踪（Autotrack） | ✓ | ✓ | 保留 |
| MobileDebugger | ✓ | ✓ | 保留 |
| Circle（圈选） | ✓ | ✓ | 保留 |
| 存储层（Preferences） | ✓ | ✓ | 保留 |
| 网络传输 | RCP 协议 | 标准 HTTP | **改造** |
| 插件生命周期钩子 | 13 个 | 2 个 | **裁剪 85%** |
| Flutter 支持 | ✓ | ✗ | **删除** |
| Hybrid/WebView 支持 | ✓ | ✗ | **删除** |
| UniApp 支持 | ✓ | ✗ | **删除** |

---

## 网络层改造

这是两者最核心的差异，原因是元服务平台限制了对 `@hms.collaboration.rcp` 模块的使用。

### GrowingAnalytics（原版）

使用 `@hms.collaboration.rcp` 模块：

```typescript
// Network.ets
import rcp from '@hms.collaboration.rcp'

export class Network {
  private static session: rcp.Session

  static initNetwork(context: common.Context) {
    // 需要在 SDK 初始化时预先创建 Session
    let config: rcp.SessionConfiguration = { ... }
    Network.session = rcp.createSession(config)
  }

  static async request(events, urlPath, context): Promise<rcp.Response> {
    let request = new rcp.Request(url, 'POST', headers, body)
    let response = await Network.session.fetch(request)
    // 通过 response.statusCode 判断状态
    // 可获取 response.request.url / response.request.content
    return response
  }
}
```

### GrowingAnalyticsAtomicService（改造版）

改用 `@ohos.net.http` 标准 HTTP 模块：

```typescript
// Network.ets
import http from '@ohos.net.http'

export interface NetworkResult {
  response: http.HttpResponse
  url: string
}

export class Network {
  // 删除了 initNetwork() 方法，无需预先创建 Session

  static async request(events, urlPath, context): Promise<NetworkResult> {
    let time = Date.now()          // curTime 在内部生成，不对外暴露
    let url = Network.generateUrl(time, urlPath, context)
    let httpRequest = http.createHttp()
    let response = await httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: headers,
      extraData: body,
      connectTimeout: ...,
      readTimeout: ...
    })
    httpRequest.destroy()
    // 通过 response.responseCode（不是 statusCode）判断状态
    return { response, url }       // 将 url 随响应一并返回
  }
}
```

### 关键差异点

| 对比项 | GrowingAnalytics | AtomicService |
|-------|-----------------|---------------|
| 依赖模块 | `@hms.collaboration.rcp` | `@ohos.net.http` |
| 需要初始化 | `Network.initNetwork(context)` | 无需初始化 |
| 响应状态码字段 | `response.statusCode` | `result.response.responseCode` |
| 请求上下文 | `rcp.Session` 复用 | 每次创建/销毁 `HttpRequest` |
| 返回类型 | `rcp.Response`（含 request 引用） | `NetworkResult { response, url }` |
| 可获取请求详情 | `response.request.url/content` | 仅 URL（通过 `NetworkResult.url`） |

---

## 插件系统裁剪

### GrowingAnalytics（完整版）—— 13 个生命周期钩子

```typescript
// Plugins.ets
import rcp from '@hms.collaboration.rcp'

export interface PluginsInterface {
  onSDKWillInitialize?(): void
  onSDKDidInitialize?(config: GrowingConfig, version: string): void
  onStartSubTracker?(trackerId: string, config: GrowingConfig): void
  setAutotrackStatusFetcher?(fetcher: () => boolean): void
  onDeferStart?(): void
  afterWindowStageCreate?(abilityContext: common.UIAbilityContext, windowStage: window.WindowStage): void
  handleOpenURL?(uri: string): boolean
  onEventWroteToDisk?(event: EventPersistence, eventScene: number): void
  onEventsRemoveFromDisk?(events: string[]): void
  onResponseReceive?(response: rcp.Response): void        // RCP 类型
  onEventsDidSend?(events: EventPersistence[], request: rcp.Request): void  // RCP 类型
  onWebViewDomTreeChanged?(): void
}
```

### GrowingAnalyticsAtomicService（精简版）—— 2 个生命周期钩子

```typescript
// Plugins.ets
// 不再依赖 rcp 模块

export interface PluginsInterface {
  handleOpenURL?(uri: string): boolean
  onEventsDidSend?(events: EventPersistence[], url: string): void  // 改为 string 类型
}
```

**被删除的钩子：**
- `onSDKWillInitialize` — SDK 初始化前回调
- `onSDKDidInitialize` — SDK 初始化后回调（携带 config 和 version）
- `onStartSubTracker` — 子 Tracker 启动回调
- `setAutotrackStatusFetcher` — 自动追踪状态获取器
- `onDeferStart` — 延迟启动回调
- `afterWindowStageCreate` — WindowStage 创建后回调
- `onEventWroteToDisk` — 事件写入磁盘回调
- `onResponseReceive` — 网络响应接收回调
- `onEventsRemoveFromDisk` — 与 `onEventsDidSend` 完全重叠，无独立实现方
- `onWebViewDomTreeChanged` — AtomicService 不支持 Hybrid/WebView，无调用方

**类型变化：** `onEventsDidSend` 的第二个参数从 `rcp.Request` 改为 `string`（仅 URL）。

---

## 删除的功能模块

### Flutter 支持

**删除的文件：**
- `core/Flutter.ets`
- `event/flutter/FlutterPageEvent.ets`

**删除的接口：**
```typescript
// 以下 API 在 AtomicService 中不存在
GrowingAnalytics.trackFlutterPage(argument: Map<string, Object>)
GrowingAnalytics.trackFlutterClickEvent(argument: Map<string, Object>)
GrowingAnalytics.trackFlutterCircleData(argument: Map<string, Object>)
export { Flutter as GrowingFlutterPlugin }
```

### Hybrid/WebView 支持

**删除的文件：**
- `core/Hybrid.ets`
- `event/hybrid/HybridEvent.ets`
- `event/hybrid/HybridPageEvent.ets`
- `event/hybrid/HybridViewElementEvent.ets`
- `event/hybrid/HybridCustomEvent.ets`

**删除的接口：**
```typescript
// 以下 API 在 AtomicService 中不存在
GrowingAnalytics.createHybridProxy(controller: webview.WebviewController, webviewId?: string)
GrowingAnalytics.javaScriptOnDocumentStart(scriptRules?, saasJavaScriptConfig?)
GrowingAnalytics.javaScriptOnDocumentEnd(scriptRules?)
```

**删除的类型导出：**
- `GrowingJSProxyType`（原 `JavaScriptProxyType`）
- `SaaSJavaScriptConfigType`

### UniApp 支持

**删除的文件：**
- `core/UniApp.ets`
- `event/uniapp/UniAppPageEvent.ets`

**删除的导出：**
```typescript
export { UniApp as GrowingUniAppPlugin }  // 不再导出
```

---

## 公开接口差异

### index.ets 导出对比

| 导出项 | GrowingAnalytics | AtomicService |
|-------|:---:|:---:|
| `GrowingAnalytics` | ✓ | ✓ |
| `GrowingConfig` | ✓ | ✓ |
| `GrowingFlutterPlugin` | ✓ | ✗ |
| `GrowingUniAppPlugin` | ✓ | ✗ |
| `GrowingJSProxyType` | ✓ | ✗ |
| `SaaSJavaScriptConfigType` | ✓ | ✗ |

### GrowingAnalytics 类 API 对比

| API 方法 | GrowingAnalytics | AtomicService |
|---------|:---:|:---:|
| `start()` | ✓ | ✓ |
| `track()` | ✓ | ✓ |
| `setLoginUserId()` | ✓ | ✓ |
| `setUserAttributes()` | ✓ | ✓ |
| `trackTimerStart/End/Pause()` | ✓ | ✓ |
| `createHybridProxy()` | ✓ | ✗ |
| `javaScriptOnDocumentStart()` | ✓ | ✗ |
| `javaScriptOnDocumentEnd()` | ✓ | ✗ |
| `trackFlutterPage()` | ✓ | ✗ |
| `trackFlutterClickEvent()` | ✓ | ✗ |
| `trackFlutterCircleData()` | ✓ | ✗ |

---

## 事件发送层差异

`EventSender.ets` 中因网络层类型变化带来的差异：

```typescript
// GrowingAnalytics
let response = await Network.request(events, this.urlPath, context)
Plugins.onResponseReceive(response)                    // rcp.Response
if (response.statusCode >= 200 && response.statusCode < 400) {
  Plugins.onEventsDidSend(events, response.request)    // 传 rcp.Request 对象
  // ...
}
```

```typescript
// GrowingAnalyticsAtomicService
let result = await Network.request(events, this.urlPath, context)  // curTime 在 Network 内部生成
// ✗ 删除 Plugins.onResponseReceive 调用
if (result.response.responseCode >= 200 && result.response.responseCode < 400) {
  Plugins.onEventsDidSend(events, result.url)          // 只传 URL 字符串
  // ✗ 删除 Plugins.onEventsRemoveFromDisk 调用
}
```

---

## 设备信息采集差异

`DeviceInfo.ets` 中 `platformVersion` 字段的数据源不同：

```typescript
// GrowingAnalytics
DeviceInfo.platformVersion = deviceInfo.displayVersion  // 如 "5.0.0"

// GrowingAnalyticsAtomicService
DeviceInfo.platformVersion = deviceInfo.osFullName      // 如 "HarmonyOS 5.0.0"
```

`displayVersion` 在元服务平台不可用，改用 `osFullName`。二者语义相近但格式不同，`osFullName` 会携带系统名称前缀。

---

## EventTimer 计时差异

`EventTimer.ets` 中获取当前时间的方式不同：

```typescript
// GrowingAnalytics
import systemDatetime from '@ohos.systemDateTime'
let currentTime = systemDatetime.getUptime(systemDatetime.TimeType.STARTUP, false)
// 系统启动以来的单调时钟（毫秒），不受用户手动调时或 NTP 校时影响

// GrowingAnalyticsAtomicService
let currentTime = Date.now()
// 挂钟时间（Unix 时间戳毫秒），用户或系统校时期间可能产生计时偏差
```

`@ohos.systemDateTime` 在元服务平台不可用，降级为 `Date.now()`。在计时期间发生系统校时的极端情况下，AtomicService 上报的事件时长可能存在偏差。

---

## 初始化流程差异

`AnalyticsCore.ets` 初始化序列的关键差异：

```typescript
// GrowingAnalytics
Plugins.registerPlugins([...config.plugins, new MobileDebugger(), ...])
Plugins.onSDKWillInitialize()          // ← AtomicService 中删除
// ...
Network.initNetwork(gContext)          // ← AtomicService 中删除（HTTP 无需预初始化）
// ...
Plugins.onSDKDidInitialize(config, SDK_VERSION)   // ← AtomicService 简化为无参
```

```typescript
// GrowingAnalyticsAtomicService
Plugins.registerPlugin(new MobileDebugger())       // ← 方法名也有变化
Plugins.registerPlugin(new Circle())
// ✗ 不调用 onSDKWillInitialize
// ✗ 不调用 Network.initNetwork
// ...
Plugins.onSDKDidInitialize()                       // ← 无参数版本
```

---

## 依赖与包配置差异

### oh-package.json5

| 配置项 | GrowingAnalytics | AtomicService |
|-------|-----------------|---------------|
| `name` | `@growingio/analytics` | `@growingio/analytics-atomic-service` |
| `description` | `GrowingIO Analytics ...` | `GrowingIO Analytics ... (AtomicService)` |
| 第三方依赖 | 完全相同 | 完全相同 |

两者均依赖：`snappyjs@0.7.0`、`@ohos/protobufjs@2.1.0`、`long@5.2.1`

### 系统 API 依赖对比

| 模块 | GrowingAnalytics | AtomicService |
|------|:---:|:---:|
| `@hms.collaboration.rcp` | ✓ | ✗ |
| `@ohos.net.http` | ✗ | ✓ |
| `@ohos.web.webview` | ✓ | ✗ |
| `@ohos.data.preferences` | ✓ | ✓ |

---

## 文件结构对比

```
GrowingAnalytics/src/main/ets/components/
├── autotrack/
│   ├── Autotrack.ets          ✓ 保留
│   ├── AutotrackClick.ets     ✓ 保留
│   └── AutotrackPage.ets      ✓ 保留
├── circle/
│   ├── Circle.ets             ✓ 保留
│   └── CircleElement.ets      ✓ 保留
├── core/
│   ├── AnalyticsCore.ets      ✓ 保留（有改动）
│   ├── AppInfo.ets            ✓ 保留
│   ├── Context.ets            ✓ 保留
│   ├── DeviceInfo.ets         ✓ 保留
│   ├── DummyTracker.ets       ✓ 保留
│   ├── EventTimer.ets         ✓ 保留
│   ├── Flutter.ets            ✗ AtomicService 中删除
│   ├── GeneralProps.ets       ✓ 保留
│   ├── Hybrid.ets             ✗ AtomicService 中删除
│   ├── Network.ets            ✓ 保留（网络层改造）
│   ├── Session.ets            ✓ 保留
│   ├── UniApp.ets             ✗ AtomicService 中删除
│   └── UserIdentifier.ets     ✓ 保留
├── event/
│   ├── AppClosedEvent.ets     ✓ 保留
│   ├── CustomEvent.ets        ✓ 保留
│   ├── Event.ets              ✓ 保留
│   ├── EventBuilder.ets       ✓ 保留
│   ├── EventDatabase.ets      ✓ 保留
│   ├── EventPersistence.ets   ✓ 保留
│   ├── EventSender.ets        ✓ 保留（有改动）
│   ├── LoginUserAttributesEvent.ets ✓ 保留
│   ├── PageEvent.ets          ✓ 保留
│   ├── ViewElementEvent.ets   ✓ 保留
│   ├── VisitEvent.ets         ✓ 保留
│   ├── flutter/               ✗ AtomicService 中删除（整目录）
│   ├── hybrid/                ✗ AtomicService 中删除（整目录）
│   ├── uniapp/                ✗ AtomicService 中删除（整目录）
│   └── saas/                  ✓ 保留
├── interfaces/
│   ├── GrowingAnalytics.ets   ✓ 保留（大幅精简）
│   └── GrowingConfig.ets      ✓ 保留
├── mobileDebugger/            ✓ 保留
├── plugins/
│   └── Plugins.ets            ✓ 保留（精简 75%）
└── utils/
    ├── Concurrent.ets         ✓ 保留
    ├── Constants.ts           ✓ 保留（删除 webview 导入）
    ├── LogUtil.ts             ✓ 保留
    ├── SharedPreferences.ets  ✓ 保留
    ├── Util.ts                ✓ 保留
    └── protobuf/              ✓ 保留
```

---

## 改造动机总结

| 改造方向 | 原因 |
|---------|------|
| RCP → HTTP | 元服务平台限制，无法使用 `@hms.collaboration.rcp` |
| 删除 Hybrid/WebView | 元服务不支持内嵌 WebView 场景 |
| 删除 Flutter/UniApp | 元服务为纯原生 HarmonyOS 环境 |
| 精简插件钩子（13→2） | 删除无实现方的冗余钩子及不支持场景（Hybrid/WebView）的钩子 |
| 删除 Network.initNetwork | HTTP 模块按需创建，无需预初始化 |
