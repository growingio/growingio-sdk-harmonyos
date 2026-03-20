# Entry 模块 - 智能体指南

本模块是 GrowingIO HarmonyOS SDK 的**示例应用**，展示 SDK 的集成方式和各项功能的使用方法。

## 模块概述

entry 模块作为综合示例，演示以下内容：
- SDK 在 AbilityStage 中的初始化
- URL Scheme 处理（用于 Mobile Debugger）
- 各种追踪 API 的使用
- 多实例（子追踪器）配置
- Hybrid WebView 集成
- 通用属性管理

## 模块结构

```
entry/
├── src/main/ets/
│   ├── entryability/           # 主 UIAbility
│   │   └── EntryAbility.ets    # 处理 URL Scheme 和窗口生命周期
│   ├── entryabilitystage/      # AbilityStage
│   │   └── EntryAbilityStage.ets  # SDK 初始化
│   ├── pages/                  # 示例页面
│   │   ├── Index.ets          # 主示例页面
│   │   ├── Track.ets          # 自定义事件追踪示例
│   │   ├── TrackTimer.ets     # 事件计时器示例
│   │   ├── SubTracker.ets     # 多实例示例
│   │   ├── Hybrid.ets         # WebView 集成示例
│   │   └── GeneralProps.ets   # 通用属性示例
│   ├── trackability/          # Track 页面 Ability
│   ├── tracktimerability/     # TrackTimer 页面 Ability
│   ├── subtrackerability/     # SubTracker 页面 Ability
│   ├── hybridability/         # Hybrid 页面 Ability
│   ├── generalpropsability/   # GeneralProps 页面 Ability
│   ├── Util.ets               # 工具函数
│   └── Util_TS.ts             # TypeScript 工具
├── src/main/resources/        # 资源文件
├── src/test/                  # 单元测试
├── src/ohosTest/              # 集成测试
├── oh-package.json5           # 模块依赖
└── build-profile.json5        # 构建配置
```

## 关键文件说明

### EntryAbilityStage.ets
SDK 初始化使用两阶段模式：

```typescript
// 阶段 1：配置 SDK
setupAnalytics() {
  let config = new GrowingConfig().NewSaaS(
    'AccountId',
    'DataSourceId',
    'UrlScheme'
  )
  config.debugEnabled = true
  config.idMappingEnabled = true
  config.autotrackEnabled = true
  config.plugins = [new GrowingToolsKit()]
  GrowingAnalytics.configure(config)
}

// 阶段 2：启动分析（获得隐私同意后）
startAnalytics() {
  GrowingAnalytics.startAnalytics(this.context)
}
```

### EntryAbility.ets
主 UIAbility，处理 URL Scheme：

```typescript
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  let uri = want?.uri
  if (uri) {
    GrowingAnalytics.handleOpenURL(uri)
  }
}

onWindowStageCreate(windowStage: window.WindowStage): void {
  windowStage.loadContent('pages/Index', (err) => {
    GrowingAnalytics.onWindowStageCreate(this, windowStage)
  })
}
```

## 示例页面

### Index.ets
主示例页面，展示：
- `getDeviceId()` - 获取匿名设备 ID
- `setDataCollectionEnabled()` - 开关数据采集
- `setLoginUserId()` / `cleanLoginUserId()` - 用户识别
- `setLocation()` / `cleanLocation()` - 地理位置
- `setLoginUserAttributes()` - 用户属性
- `setEvar()` / `setVisitor()` - SaaS 特定 API
- 导航到其他示例页面

### Track.ets
自定义事件追踪示例：
- 简单事件追踪
- 带属性的事件追踪
- 使用 `sendTo` 转发事件

### TrackTimer.ets
事件计时器示例：
- `trackTimerStart()` - 启动计时器
- `trackTimerPause()` / `trackTimerResume()` - 暂停/恢复
- `trackTimerEnd()` - 结束计时器并发送事件

### SubTracker.ets
多实例追踪示例：
- 初始化子追踪器
- 各实例独立追踪
- 实例间事件转发

### Hybrid.ets
WebView 集成示例：
- 注入 JavaScript 桥
- 追踪 H5 页面浏览
- Hybrid 事件采集

### GeneralProps.ets
通用属性示例：
- `setGeneralProps()` - 设置静态属性
- `setDynamicGeneralProps()` - 设置动态属性
- `removeGeneralProps()` / `clearGeneralProps()` - 移除属性

## 依赖关系

```json
{
  "dependencies": {
    "@growingio/analytics": "file:../GrowingAnalytics",
    "@growingio/tools": "file:../GrowingToolsKit"
  }
}
```

## 构建配置

- **API 类型**: stageMode
- **混淆**: 发布构建启用
- **目标**: default, ohosTest

## SDK 配置示例

### NewSaaS 模式（默认）
```typescript
let config = new GrowingConfig().NewSaaS(
  'accountId',
  'dataSourceId',
  'urlScheme',
  'https://napi.growingio.com'  // 可选
)
```

### CDP 模式
```typescript
let config = new GrowingConfig().CDP(
  'accountId',
  'dataSourceId',
  'urlScheme',
  'https://cdp-api.growing.com'
)
```

### SaaS 模式
```typescript
let config = new GrowingConfig().SaaS(
  'accountId',
  'urlScheme',
  'https://api.growingio.com'  // 可选
)
```

## 测试

- 单元测试: `src/test/LocalUnit.test.ets`
- 集成测试: `src/ohosTest/ets/test/Ability.test.ets`
- 测试运行器: `OpenHarmonyTestRunner.ets`
