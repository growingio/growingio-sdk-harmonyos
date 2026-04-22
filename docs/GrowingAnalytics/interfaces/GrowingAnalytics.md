# GrowingAnalytics 接口 - 公共 API

> **模块归属**: 对外接口模块 (interfaces)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/interfaces/GrowingAnalytics.ets`  

`GrowingAnalytics` 是 GrowingIO HarmonyOS SDK 的入口类，提供所有公共 API 供开发者调用。本文档介绍其接口设计和使用方式。

## 架构定位

```
应用层
    │
    ▼
GrowingAnalytics (静态 API 入口)
    │
    ├─ GrowingConfig (配置)
    ├─ AnalyticsCore (核心)
    │   ├─ Tracker (主实例)
    │   └─ Map<string, Tracker> (子实例)
    │
    └─ Autotrack / Flutter / ... (功能模块)
```

## 接口分类

### 1. 初始化相关

#### configure() - 预配置

```typescript
static configure(configuration: GrowingConfig): void
```

**用途：**
- 在 `start()` 之前预先配置 SDK
- 适用于需要在 `UIAbility.onCreate()` 之前配置的场景

**示例：**
```typescript
const config = new GrowingConfig()
    .NewSaaS('accountId', 'dataSourceId', 'urlScheme')

GrowingAnalytics.configure(config)
```

**注意：**
- 只能调用一次，重复调用会输出警告
- 配置的 `copy()` 方法会被调用，确保配置不可变

#### start() - 启动 SDK

```typescript
static start(context: Context, configuration: GrowingConfig): void
```

**用途：**
- 启动 SDK 主 Tracker（默认实例）
- 完整的初始化流程，包括数据库、网络、会话等模块

**示例：**
```typescript
// EntryAbility.ets
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const config = new GrowingConfig()
        .NewSaaS('accountId', 'dataSourceId', 'urlScheme')
    
    GrowingAnalytics.start(this.context, config)
}
```

**注意：**
- 重复调用会输出警告，不会重复初始化
- 必须先配置 `accountId`、`dataSourceId`、`urlScheme` 等必需参数

#### startAnalytics() - 使用预配置启动

```typescript
static startAnalytics(context: Context): void
```

**用途：**
- 使用之前 `configure()` 的配置启动 SDK
- 简化启动调用

**示例：**
```typescript
// 先配置
GrowingAnalytics.configure(config)

// 后启动
GrowingAnalytics.startAnalytics(context)
```

#### deferStart() - 延迟启动

```typescript
static deferStart(context: UIAbilityContext, configuration?: GrowingConfig): void
```

**用途：**
- 支持延迟初始化场景
- 确保传入的 context 是 `UIAbilityContext`

**使用场景：**
- 用户同意隐私协议后再初始化
- 动态获取配置后初始化

#### startSubTracker() - 启动子 Tracker

```typescript
static startSubTracker(trackerId: string, configuration: GrowingConfig): void
```

**用途：**
- 创建额外的 Tracker 实例
- 支持多数据源、多项目同时上报

**示例：**
```typescript
// 主 Tracker 已启动后
GrowingAnalytics.startSubTracker('tracker2', subConfig)
```

**注意：**
- 必须先初始化主 Tracker
- `trackerId` 必须唯一
- `accountId` + `dataSourceId` 组合必须唯一

---

### 2. Tracker 实例获取

#### tracker() - 获取子 Tracker

```typescript
static tracker(trackerId: string): GrowingAnalyticsInterface
```

**用途：**
- 获取指定 trackerId 的 Tracker 实例
- 用于对子 Tracker 进行操作

**示例：**
```typescript
const subTracker = GrowingAnalytics.tracker('tracker2')
subTracker.track('event_name')
```

**注意：**
- 如果 trackerId 不存在，返回 `DummyTracker`（空实现）
- 调用时会输出错误日志提示需要先 `startSubTracker()`

---

### 3. 用户标识

#### setLoginUserId() - 设置登录用户 ID

```typescript
static setLoginUserId(userId: string, userKey?: string): void
```

**参数：**
| 参数 | 类型 | 说明 |
|------|------|------|
| `userId` | `string` | 登录用户 ID |
| `userKey` | `string?` | 用户 key（启用 ID Mapping 时使用）|

**示例：**
```typescript
// 普通模式
GrowingAnalytics.setLoginUserId('user123')

// ID Mapping 模式
GrowingAnalytics.setLoginUserId('user123', 'phone')
```

#### cleanLoginUserId() - 清除登录用户 ID

```typescript
static cleanLoginUserId(): void
```

**用途：**
- 用户退出登录时调用
- 清除后会生成新的匿名用户 ID

#### setLoginUserAttributes() - 设置登录用户属性

```typescript
static setLoginUserAttributes(attributes: GrowingAttrType): void
```

**示例：**
```typescript
GrowingAnalytics.setLoginUserAttributes({
    'userType': 'VIP',
    'level': 5
})
```

#### getDeviceId() - 获取设备 ID

```typescript
static getDeviceId(): string
```

**用途：**
- 获取 SDK 生成的唯一设备标识
- 可用于与业务系统关联

---

### 4. 事件追踪

#### track() - 发送自定义事件

```typescript
static track(
    eventName: string,
    attributes?: GrowingAttrType,
    sendTo?: string[]
): void
```

**参数：**
| 参数 | 类型 | 说明 |
|------|------|------|
| `eventName` | `string` | 事件名称 |
| `attributes` | `GrowingAttrType?` | 事件属性 |
| `sendTo` | `string[]?` | 指定接收的子 Tracker ID 列表 |

**示例：**
```typescript
// 简单事件
GrowingAnalytics.track('purchase')

// 带属性的事件
GrowingAnalytics.track('purchase', {
    'productId': 'SKU001',
    'price': 99.9
})

// 发送到指定子 Tracker
GrowingAnalytics.track('purchase', { 'price': 99.9 }, ['tracker2'])
```

**sendTo 参数说明：**
- 不传或传空数组：仅发送到主 Tracker
- 传 `['tracker2']`：发送到主 Tracker + tracker2
- 用于跨项目/跨数据源的事件共享

---

### 5. 计时器

#### trackTimerStart() - 开始计时

```typescript
static trackTimerStart(eventName: string): string
```

**返回：**
- `timerId` - 计时器唯一标识，用于后续操作

**示例：**
```typescript
const timerId = GrowingAnalytics.trackTimerStart('page_stay')
```

#### trackTimerPause() - 暂停计时

```typescript
static trackTimerPause(timerId: string): void
```

#### trackTimerResume() - 恢复计时

```typescript
static trackTimerResume(timerId: string): void
```

#### trackTimerEnd() - 结束计时并发送事件

```typescript
static trackTimerEnd(
    timerId: string,
    attributes?: GrowingAttrType,
    sendTo?: string[]
): void
```

**完整示例：**
```typescript
// 页面进入时开始计时
const timerId = GrowingAnalytics.trackTimerStart('page_stay')

// 页面隐藏时暂停
growingAnalytics.trackTimerPause(timerId)

// 页面恢复时继续
growingAnalytics.trackTimerResume(timerId)

// 页面销毁时结束并发送事件
growingAnalytics.trackTimerEnd(timerId, { 'pageName': 'home' })
```

#### removeTimer() / clearTrackTimer() - 移除计时器

```typescript
static removeTimer(timerId: string): void
static clearTrackTimer(): void
```

---

### 6. 通用属性

#### setGeneralProps() - 设置静态通用属性

```typescript
static setGeneralProps(props: GrowingAttrType): void
```

**用途：**
- 设置后会附加到所有后续事件
- 适合设置全局不变的属性

**示例：**
```typescript
GrowingAnalytics.setGeneralProps({
    'appVersion': '2.0.0',
    'channel': 'AppStore'
})
```

#### removeGeneralProps() - 移除通用属性

```typescript
static removeGeneralProps(keys: string[]): void
```

#### clearGeneralProps() - 清空通用属性

```typescript
static clearGeneralProps(): void
```

#### setDynamicGeneralProps() - 设置动态通用属性

```typescript
static setDynamicGeneralProps(generator: () => GrowingAttrType): void
```

**用途：**
- 设置一个生成器函数，每次发送事件时动态获取属性
- 适合需要实时计算的值

**示例：**
```typescript
GrowingAnalytics.setDynamicGeneralProps(() => {
    return {
        'batteryLevel': getBatteryLevel(),
        'networkType': getNetworkType()
    }
})
```

---

### 7. 位置信息

#### setLocation() - 设置位置

```typescript
static setLocation(latitude: number, longitude: number): void
```

#### cleanLocation() - 清除位置

```typescript
static cleanLocation(): void
```

---

### 8. 采集控制

#### setDataCollectionEnabled() - 设置采集开关

```typescript
static setDataCollectionEnabled(enabled: boolean): void
```

**用途：**
- 动态开启/关闭数据采集
- 关闭后事件不再入库，但已入库的数据会继续发送

#### isInitializedSuccessfully() - 检查初始化状态

```typescript
static isInitializedSuccessfully(trackerId?: string): boolean
```

**参数：**
- `trackerId` - 可选，不传则检查主 Tracker

---

### 9. SaaS 模式专用

#### setPeopleVariable() - 设置用户变量

```typescript
static setPeopleVariable(attributes: GrowingAttrType): void
```

#### setEvar() - 设置转化变量

```typescript
static setEvar(attributes: GrowingAttrType): void
```

#### setVisitor() - 设置访问用户变量

```typescript
static setVisitor(attributes: GrowingAttrType): void
```

---

### 10. WebView/Hybrid 支持

#### createHybridProxy() - 创建 JSBridge 代理

```typescript
static createHybridProxy(
    controller: WebviewController,
    webviewId?: string
): GrowingJSProxyType | undefined
```

**示例：**
```typescript
Web({
    controller: this.webviewController,
    javaScriptProxy: GrowingAnalytics.createHybridProxy(this.webviewController)
})
```

#### javaScriptOnDocumentStart/End() - 注入脚本

```typescript
static javaScriptOnDocumentStart(
    scriptRules?: Array<string>,
    saasJavaScriptConfig?: SaaSJavaScriptConfigType
): Array<ScriptItem>

static javaScriptOnDocumentEnd(scriptRules?: Array<string>): Array<ScriptItem>
```

**示例：**
```typescript
Web({
    controller: this.webviewController,
    javaScriptOnDocumentStart: GrowingAnalytics.javaScriptOnDocumentStart()
})
```

#### onPageEnd() - WebView 页面加载完成回调（SaaS 圈选）

```typescript
static onPageEnd(
    controller: webview.WebviewController,
    webviewId?: string
): Promise<void>
```

**作用：** 仅在 SaaS 模式且开启 `hybridAutotrackEnabled` 并处于圈选状态时生效。在 WebView `onPageEnd` 回调时调用，向 H5 页面注入圈选插件脚本，并将 WebView 的 Native xpath 更新到 `window._vds_hybrid_native_info.x`。

**示例：**
```typescript
Web({ src: url, controller: this.controller })
  .onPageEnd(() => {
    GrowingAnalytics.onPageEnd(this.controller, 'myWebviewId')
  })
```

---

### 11. Flutter 支持

#### trackFlutterPage() - 追踪 Flutter 页面

```typescript
static trackFlutterPage(argument: Map<string, Object>): void
```

#### trackFlutterClickEvent() - 追踪 Flutter 点击

```typescript
static trackFlutterClickEvent(argument: Map<string, Object>): void
```

#### trackFlutterCircleData() - Flutter 圈选数据

```typescript
static trackFlutterCircleData(argument: Map<string, Object>): void
```

---

### 12. 无埋点支持

#### onWindowStageCreate() - 注册页面监听

```typescript
static onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage): void
```

**示例：**
```typescript
onWindowStageCreate(windowStage: window.WindowStage): void {
    GrowingAnalytics.onWindowStageCreate(this, windowStage)
}
```

---

### 13. URL Scheme

#### handleOpenURL() - 处理 URL Scheme

```typescript
static handleOpenURL(uri: string): boolean
```

**用途：**
- 处理圈选、调试器的 URL Scheme 唤起
- 返回是否成功处理

---

## GrowingAnalyticsInterface

`tracker()` 方法返回的接口，用于子 Tracker 操作：

```typescript
export interface GrowingAnalyticsInterface {
    isInitializedSuccessfully(): boolean
    setDataCollectionEnabled(enabled: boolean): void
    setLoginUserId(userId: string, userKey?: string): void
    cleanLoginUserId(): void
    setLoginUserAttributes(attributes: GrowingAttrType): void
    track(eventName: string, attributes?: GrowingAttrType, sendTo?: string[]): void
    trackTimerStart(eventName: string): string
    trackTimerPause(timerId: string): void
    trackTimerResume(timerId: string): void
    trackTimerEnd(timerId: string, attributes?: GrowingAttrType, sendTo?: string[]): void
    removeTimer(timerId: string): void
    clearTrackTimer(): void
    createHybridProxy(controller: WebviewController, webviewId?: string): GrowingJSProxyType | undefined
    setPeopleVariable(attributes: GrowingAttrType): void
    setEvar(attributes: GrowingAttrType): void
    setVisitor(attributes: GrowingAttrType): void
}
```

**注意：**
- 与 `GrowingAnalytics` 静态方法类似，但只操作当前 Tracker 实例
- 不支持的静态方法：`start()`, `configure()`, `tracker()`, `startSubTracker()` 等全局操作

---

## 参见

- [AnalyticsCore](../core/analytics_core.md) - SDK 核心实现
- [GrowingConfig](../core/config.md) - 配置管理
- [Context](../core/context.md) - 上下文管理
