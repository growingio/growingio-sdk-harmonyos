# GrowingAnalytics 模块 - 智能体指南

本模块是 GrowingIO HarmonyOS SDK 的**核心分析 SDK**（`@growingio/analytics`），提供事件追踪和数据采集功能。

## 模块概述

GrowingAnalytics 模块是主 SDK 包，提供：
- 事件追踪 API（自定义事件、计时器）
- 自动 UI 事件采集（页面浏览、点击）
- 用户识别和属性
- 会话管理
- 数据持久化和传输
- Hybrid WebView 集成
- 多实例支持
- Flutter 平台通道支持

## 模块结构

```
GrowingAnalytics/
├── src/main/ets/
│   ├── components/
│   │   ├── interfaces/           # 公共 API 导出
│   │   │   ├── GrowingAnalytics.ets   # 主 SDK API 类
│   │   │   └── GrowingConfig.ets      # 配置类
│   │   ├── core/                 # 核心 SDK 功能
│   │   │   ├── AnalyticsCore.ets      # 核心 SDK 引擎
│   │   │   ├── Context.ets            # SDK 上下文管理
│   │   │   ├── AppInfo.ets            # 应用信息
│   │   │   ├── DeviceInfo.ets         # 设备信息
│   │   │   ├── Session.ets            # 会话管理
│   │   │   ├── Network.ets            # 网络工具
│   │   │   ├── EventTimer.ets         # 事件计时逻辑
│   │   │   ├── Hybrid.ets             # WebView 桥接
│   │   │   ├── Flutter.ets            # Flutter 支持
│   │   │   ├── UserIdentifier.ets     # 用户 ID 管理
│   │   │   ├── GeneralProps.ets       # 通用属性
│   │   │   └── DummyTracker.ets       # 空操作追踪器
│   │   ├── event/                # 事件系统
│   │   │   ├── Event.ets              # 基础事件类
│   │   │   ├── EventBuilder.ets       # 事件构建器
│   │   │   ├── EventDatabase.ets      # SQLite 数据库
│   │   │   ├── EventPersistence.ets   # 事件持久化
│   │   │   ├── EventSender.ets        # 网络发送
│   │   │   ├── CustomEvent.ets        # 自定义事件
│   │   │   ├── PageEvent.ets          # 页面浏览事件
│   │   │   ├── VisitEvent.ets         # 访问/会话事件
│   │   │   ├── ViewElementEvent.ets   # 元素点击事件
│   │   │   ├── AppClosedEvent.ets     # 应用关闭事件
│   │   │   ├── LoginUserAttributesEvent.ets
│   │   │   ├── flutter/               # Flutter 事件
│   │   │   ├── hybrid/                # Hybrid 事件
│   │   │   └── saas/                  # SaaS 特定事件
│   │   ├── autotrack/            # 自动事件追踪
│   │   │   ├── Autotrack.ets
│   │   │   ├── AutotrackPage.ets
│   │   │   └── AutotrackClick.ets
│   │   ├── circle/               # 可视化圈选
│   │   │   ├── Circle.ets
│   │   │   └── CircleElement.ets
│   │   ├── mobileDebugger/       # 实时调试
│   │   │   ├── MobileDebugger.ets
│   │   │   ├── WebSocket.ets
│   │   │   ├── Snapshot.ets
│   │   │   ├── StatusView.ets
│   │   │   ├── Queue.ets
│   │   │   └── Model.ets
│   │   ├── plugins/              # 插件系统
│   │   │   └── Plugins.ets
│   │   └── utils/                # 工具类
│   │       ├── Constants.ts
│   │       ├── Util.ts
│   │       ├── LogUtil.ts
│   │       ├── SharedPreferences.ets
│   │       └── Concurrent.ets
│   └── test/, ohosTest/          # 测试
├── oh-package.json5              # 包: @growingio/analytics v2.7.1
└── BuildProfile.ets              # 构建版本信息
```

## 核心 API

### GrowingAnalytics（主入口）

```typescript
// 两阶段初始化
static configure(configuration: GrowingConfig)  // 阶段 1
static startAnalytics(context: Context)         // 阶段 2
static start(context: Context, configuration: GrowingConfig)  // 直接启动
static deferStart(context: UIAbilityContext, configuration?: GrowingConfig)   // 延迟启动

// 追踪 API
static track(eventName: string, attributes?: GrowingAttrType, sendTo?: string[])
static trackTimerStart(eventName: string): string
static trackTimerPause(timerId: string): void
static trackTimerResume(timerId: string): void
static trackTimerEnd(timerId: string, attributes?: GrowingAttrType, sendTo?: string[])
static removeTimer(timerId: string): void
static clearTrackTimer(): void

// 用户 API
static setLoginUserId(userId: string, userKey?: string)
static cleanLoginUserId()
static setLoginUserAttributes(attributes: GrowingAttrType)
static getDeviceId(): string

// 通用属性
static setGeneralProps(props: GrowingAttrType)
static removeGeneralProps(keys: string[])
static clearGeneralProps()
static setDynamicGeneralProps(generator: () => GrowingAttrType)

// 地理位置
static setLocation(latitude: number, longitude: number)
static cleanLocation()

// 数据采集
static setDataCollectionEnabled(enabled: boolean)
static isInitializedSuccessfully(trackerId?: string): boolean

// Hybrid
static createHybridProxy(controller: WebviewController, webviewId?: string): GrowingJSProxyType
static javaScriptOnDocumentStart(scriptRules?: Array<string>, saasJavaScriptConfig?: SaaSJavaScriptConfigType): Array<ScriptItem>
static javaScriptOnDocumentEnd(scriptRules?: Array<string>): Array<ScriptItem>

// 多实例
static startSubTracker(trackerId: string, configuration: GrowingConfig)
static tracker(trackerId: string): GrowingAnalyticsInterface

// URL Scheme
static handleOpenURL(uri: string): boolean

// Flutter
static trackFlutterPage(argument: Map<string, Object>)
static trackFlutterClickEvent(argument: Map<string, Object>)
static trackFlutterCircleData(argument: Map<string, Object>)

// 窗口生命周期（自动追踪）
static onWindowStageCreate(ability: UIAbility, windowStage: WindowStage)

// SaaS 特定
static setPeopleVariable(attributes: GrowingAttrType)
static setEvar(attributes: GrowingAttrType)
static setVisitor(attributes: GrowingAttrType)
```

### GrowingConfig

```typescript
class GrowingConfig {
  // 初始化方法
  NewSaaS(accountId, dataSourceId, urlScheme, dataCollectionServerHost?): GrowingConfig
  CDP(accountId, dataSourceId, urlScheme, dataCollectionServerHost): GrowingConfig
  SaaS(accountId, urlScheme, dataCollectionServerHost?): GrowingConfig
  
  // 配置选项
  debugEnabled: boolean          // 默认: false
  sessionInterval: number        // 默认: 30（秒）
  dataUploadInterval: number     // 默认: 15（秒）
  dataCollectionEnabled: boolean // 默认: true
  idMappingEnabled: boolean      // 默认: false
  encryptEnabled: boolean        // 默认: true
  compressEnabled: boolean       // 默认: true
  useProtobuf: boolean           // 默认: true
  mode: ConfigMode               // 默认: ConfigMode.NewSaaS
  trackerId: string              // 默认: ''
  autotrackEnabled: boolean      // 默认: false
  autotrackAllPages: boolean     // 默认: false
  hybridAutotrackEnabled: boolean // 默认: true
  plugins: Array<PluginsInterface>
  ignoreField: number            // 忽略字段的位掩码
  requestOptions: RequestOptions
  dataValidityPeriod: number      // 默认: 7（天）
}

// 配置模式
enum ConfigMode {
  NewSaaS = 0,
  SaaS,
  CDP
}

// 隐私字段忽略
enum IgnoreFields {
  NetworkState = (1 << 0)
  ScreenSize = (1 << 1)
  DeviceBrand = (1 << 2)
  DeviceModel = (1 << 3)
  DeviceType = (1 << 4)
  SystemLanguage = (1 << 5)
  TimezoneOffset = (1 << 6)
  PlatformVersion = (1 << 7)
}
const IgnoreFieldsAll = ... // 所有字段
```

## 事件类型

| 事件类型 | 类 | 描述 |
|----------|-----|------|
| VISIT | VisitEvent | 会话开始 |
| CUSTOM | CustomEvent | 用户定义事件 |
| PAGE | PageEvent | 页面浏览 |
| VIEW_CLICK | ViewElementEvent | 元素点击 |
| VIEW_CHANGE | ViewElementEvent | 元素变更 |
| APP_CLOSED | AppClosedEvent | 应用关闭 |
| LOGIN_USER_ATTRIBUTES | LoginUserAttributesEvent | 用户属性 |
| evar (SaaS) | SaaSEvarEvent | 转化变量 |
| vstr (SaaS) | SaaSVisitorEvent | 访客变量 |
| pvar (SaaS) | SaaSPageVarEvent | 页面变量 |

## 事件处理流水线

```
1. 事件创建（API/自动追踪/Hybrid）
   ↓
2. 事件持久化（EventPersistence）
   ↓
3. 数据库写入（EventDatabase - SQLite）
   ↓
4. 定时发送（EventSender）
   ↓
5. 网络传输（Protobuf + Snappy + 加密）
```

## 自动追踪

### 配置
```typescript
config.autotrackEnabled = true      // 启用自动追踪
config.autotrackAllPages = true     // 追踪所有页面
```

### 追踪的事件
- **页面事件**: 页面导航（通过 NavPathStack）
- **点击事件**: 组件点击（带 `growing_attributes`）

### 自定义属性
```typescript
// 为任何组件添加自定义属性
Button('点击我')
  .customProperty("growing_attributes", {
    "action": "buy",
    "product_id": "12345"
  })
```

## 多实例支持

```typescript
// 初始化主追踪器
GrowingAnalytics.configure(mainConfig)
GrowingAnalytics.startAnalytics(context)

// 初始化子追踪器
GrowingAnalytics.startSubTracker('subTrackerId', subConfig)

// 使用子追踪器
let subTracker = GrowingAnalytics.tracker('subTrackerId')
subTracker.track('event', { key: 'value' })

// 事件转发
GrowingAnalytics.track('event', { key: 'value' }, ['subTrackerId'])
```

## Hybrid 集成

```typescript
// 方式 1：直接注入
Web({ src: url, controller: this.controller })
  .javaScriptAccess(true)
  .domStorageAccess(true)
  .javaScriptProxy(
    GrowingAnalytics.createHybridProxy(this.controller, webviewId)
  )

// 方式 2：带权限
.onControllerAttached(() => {
  let proxy = GrowingAnalytics.createHybridProxy(this.controller, webviewId)
  this.controller.registerJavaScriptProxy(
    proxy.object, proxy.name, proxy.methodList, [], permission
  )
})
```

## 依赖项

```json
{
  "dependencies": {
    "snappyjs": "0.7.0",
    "@ohos/protobufjs": "2.1.0",
    "long": "5.2.1"
  }
}
```

## 构建信息

- **包**: `@growingio/analytics`
- **许可证**: Apache License 2.0
- **主入口**: `index.ets`
