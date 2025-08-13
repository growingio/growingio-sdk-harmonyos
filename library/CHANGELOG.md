# [1.3.0](https://github.com/growingio/growingio-sdk-harmonyos/tree/1.3.0) (2025-08-13)

### Refactor (BREAKING CHANGE)

* SDK 初始化接口从异步调用方式改为同步，需要更换集成方式 (在数据库创建或连接成功之前产生的事件将先在内存中缓存)
* 事件计时器相关外部接口从异步调用方式改为同步，需要更换集成方式 (内部接口更换已废弃的 API systemDatetime.getRealTime 为 systemDatetime.getUptime)

### Bug Fixes

* 使用 applicationStateChange 监听应用前后台变化，兼容子窗口存在的场景
* 修复多实例下，事件的 eventSequenceId 字段未进行区分，现在各个实例单独计数
* start、track、trackTimerEnd 方法签名修正
* 内部 emit 机制中，eventId 使用 string 类型替代原先的 number 类型，避免误触发

> 以上改动皆取自 2.3.0 最新版本

### 数据影响

* 由于使用了新的键值，所有 1.3.0 生成的新事件event.eventSequenceId 将从 0 开始

### 附：HarmonyOS SDK 1.3.0 升级说明

> 以 CDP 项目举例

#### 初始化

调整 SDK 初始化代码从异步改为同步：

```typescript
startAnalytics() {
  let config = new GrowingConfig().CDP(
    'Your AccountId',
    'Your DataSourceId',
    'Your UrlScheme',
    'Your DataCollectionServerHost'
  )
  GrowingAnalytics.start(this.context, config)
}
```

#### 事件计时器

若您的应用中使用了事件计时器相关接口，将调用方式从异步修改为同步：

```typescript
let timerId = GrowingAnalytics.trackTimerStart('eventName')
GrowingAnalytics.trackTimerPause(timerId)
GrowingAnalytics.trackTimerResume(timerId)
GrowingAnalytics.trackTimerEnd(timerId)
GrowingAnalytics.trackTimerEnd(timerId, {
  'property': 'value',
  'property2': 100
})
GrowingAnalytics.removeTimer(timerId)
GrowingAnalytics.clearTrackTimer()
```

# [1.2.0](https://github.com/growingio/growingio-sdk-harmonyos/tree/1.2.0) (2024-07-26)

### Features

* 适配 Flutter on HarmonyOS (3.7.12-ohos)

# [1.1.0](https://github.com/growingio/growingio-sdk-harmonyos/tree/1.1.0) (2024-06-21)

### Features

* 适配 HarmonyOS NEXT
* 支持从 OpenHarmony API 10 到 API 12
* 支持 New SaaS/SaaS/CDP 平台集成
* 支持多实例采集
* 支持通用属性
* 支持 hybrid 打通
* 支持事件数据加密压缩上报
* 新增初始化配置项，如：网络请求超时时长、数据有效时长、加密、压缩等等

### Bug Fixes

* 优化 SDK 初始化方式，见 README
* 其他稳定性优化

# [1.0.0](https://github.com/growingio/growingio-sdk-harmonyos/tree/1.0.0) (2023-12-14)

### Features

* 适配 ArkTS 语法
* 支持 OpenHarmony API 10

# [0.0.1](https://github.com/growingio/growingio-sdk-harmonyos/tree/0.0.1) (2023-12-08)

### Features

* 支持埋点事件上报
* 支持访问事件自动上报
* 支持用户属性上报
* 支持事件计时器
* 支持用户 ID 配置，包括 ID Mapping
* 支持数据采集开关配置
* 支持静态公共属性配置
* 支持 HarmonyOS 3.1.0 (OpenHarmony API 9)

