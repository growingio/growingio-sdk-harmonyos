# AnalyticsCore 逻辑详解

> **模块归属**: 核心模块 (core)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/core/AnalyticsCore.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 中 `AnalyticsCore` 模块的逻辑实现。该模块是 SDK 的核心控制器，负责初始化、生命周期管理、事件处理和子 Tracker 管理。

## 目录

- [概述](#概述)
- [核心架构](#核心架构)
- [SDK 初始化流程](#sdk-初始化流程)
- [生命周期管理](#生命周期管理)
- [事件写入与存储](#事件写入与存储)
- [子 Tracker 机制](#子-tracker-机制)
- [定时任务管理](#定时任务管理)
- [位置信息管理](#位置信息管理)
- [SaaS 模式特殊方法](#saas-模式特殊方法)

---

## 概述

`AnalyticsCore` 是 GrowingIO HarmonyOS SDK 的核心类，实现了 `GrowingAnalyticsInterface` 接口，提供以下核心功能：

1. **SDK 初始化管理**：主 Tracker 和子 Tracker 的启动流程
2. **生命周期管理**：监听应用前后台切换、Ability 生命周期
3. **事件处理**：自定义事件、登录用户属性、计时器事件
4. **数据存储**：事件持久化到数据库
5. **插件系统**：MobileDebugger、Circle 等插件的注册和管理

### 架构位置

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           SDK 架构层次                                   │
├─────────────────────────────────────────────────────────────────────────┤
│  应用层 (Application)                                                    │
│  └── GrowingAnalytics.start()                                          │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│  接口层 (Interface)                                                      │
│  └── GrowingAnalyticsInterface                                         │
│      ├── track()                                                       │
│      ├── setLoginUserId()                                              │
│      └── ...                                                           │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│  核心层 (Core) ◄── AnalyticsCore 所在位置                               │
│  ├── AnalyticsCore (主控制器)                                           │
│  ├── Session (会话管理)                                                 │
│  ├── DeviceInfo (设备信息)                                              │
│  ├── UserIdentifier (用户标识)                                          │
│  └── ...                                                               │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│  事件层 (Event)                                                          │
│  ├── EventBuilder                                                      │
│  ├── EventPersistence                                                  │
│  └── EventSender                                                       │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│  存储层 (Storage)                                                        │
│  └── EventDatabase                                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 核心架构

### 类关系图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         AnalyticsCore                                   │
│                    (实现 GrowingAnalyticsInterface)                      │
├─────────────────────────────────────────────────────────────────────────┤
│  静态属性                                                               │
│  ├── uiContent: UIContext              // 全局 UI 上下文                │
│  ├── mainWindow: Window                // 主窗口实例                    │
│  ├── core: AnalyticsCore | DummyTracker // 核心实例（单例）              │
│  ├── trackers: AnalyticsCore[]         // 子 Tracker 列表               │
│  ├── dummyTracker: DummyTracker        // 空实现 Tracker                │
│  └── location: Location                // 位置信息                      │
├─────────────────────────────────────────────────────────────────────────┤
│  实例属性                                                               │
│  ├── context: GrowingContext           // 上下文配置                    │
│  └── _isInitializedSuccessfully        // 初始化状态                    │
├─────────────────────────────────────────────────────────────────────────┤
│  初始化方法                                                             │
│  ├── startCore()                       // 启动主 Tracker                │
│  ├── startSubTracker()                 // 启动子 Tracker                │
│  └── tracker()                         // 获取 Tracker 实例             │
├─────────────────────────────────────────────────────────────────────────┤
│  生命周期方法                                                           │
│  ├── setLifecycleCallback()            // Ability 生命周期监听          │
│  └── setAppStateChangeCallback()       // 应用状态变化监听              │
├─────────────────────────────────────────────────────────────────────────┤
│  事件方法                                                               │
│  ├── track()                           // 追踪自定义事件                │
│  ├── setLoginUserAttributes()          // 设置登录用户属性              │
│  ├── writeEventToDisk()                // 写入事件到磁盘                │
│  └── ...                                                               │
└─────────────────────────────────────────────────────────────────────────┘
```

### 核心数据结构

```typescript
// 位置信息
class Location {
  latitude: number = 0    // 纬度
  longitude: number = 0   // 经度
}

// SDK 版本号
export const SDK_VERSION: string = HAR_VERSION
```

---

## SDK 初始化流程

### 主 Tracker 初始化

```
应用调用 GrowingAnalytics.start()
        │
        ▼
┌─────────────────────┐
│  startCore()        │
│  主 Tracker 初始化  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 1. 注册插件         │
│ • MobileDebugger    │
│ • Circle (条件)     │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 2. 通知插件预初始化 │
│ onSDKWillInitialize │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 3. 设置默认上下文   │
│ GrowingContext      │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 4. 创建核心实例     │
│ new AnalyticsCore() │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 5. 初始化各模块     │
│ • Autotrack         │
│ • SharedPreferences │
│ • AppInfo           │
│ • DeviceInfo        │
│ • UserIdentifier    │
│ • EventDatabase     │
│ • Network           │
│ • Session           │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 6. 启动定时发送任务 │
│ EventSender.send    │
│ Event()             │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 7. 通知初始化完成   │
│ EMIT_EVENT_MAIN_    │
│ TRACKER_INITIALIZE  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 8. 通知插件已完成   │
│ onSDKDidInitialize  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 9. 标记初始化成功   │
│ _isInitialized      │
│ Successfully = true │
└─────────────────────┘
```

### 代码实现

```typescript
static startCore(context: Context, config: GrowingConfig) {
  // 1. 准备插件列表
  let plugins = [...config.plugins]
  if (config.mode != ConfigMode.SaaS) {
    plugins.push(new MobileDebugger())  // 仅 NewSaaS 和 CDP
  }
  if (config.mode == ConfigMode.NewSaaS && config.autotrackEnabled) {
    plugins.push(new Circle())  // NewSaaS 且开启无埋点
  }

  // 2. 注册插件
  Plugins.registerPlugins(plugins)
  Plugins.onSDKWillInitialize()

  // 3. 设置默认上下文
  GrowingContext.setDefaultContext(config)
  let gContext = GrowingContext.getDefaultContext() as GrowingContext

  // 4. 创建核心实例
  let core = new AnalyticsCore(gContext)
  AnalyticsCore.core = core
  AnalyticsCore.trackers.push(core)

  // 5. 设置调试模式
  LogUtil.debugEnabled = config.debugEnabled

  // 6. 初始化各模块
  Autotrack.initAutotrack(gContext)
  AnalyticsCore.setLifecycleCallback(context)
  AnalyticsCore.setAppStateChangeCallback(context)
  SharedPreferences.initWithContext(context)
  AppInfo.initAppInfo(context)
  DeviceInfo.initDeviceInfo(gContext)
  UserIdentifier.initUser(gContext)
  EventDatabase.initDatabase(context)
  Network.initNetwork(gContext)
  Session.refreshSession(gContext)

  // 7. 启动定时发送任务
  let delay = config.debugEnabled && AppInfo.debug ? 1000 : config._dataUploadInterval
  setInterval(() => {
    EventSender.sendEvent(gContext)
  }, delay)

  // 8. 通知初始化完成
  emitter.emit(EMIT_EVENT_MAIN_TRACKER_INITIALIZE)
  LogUtil.info(() => 'Thank you very much for using GrowingIO...')
  Plugins.onSDKDidInitialize(config, SDK_VERSION)

  // 9. 标记初始化成功
  core._isInitializedSuccessfully = true
}
```

### 插件注册策略

| 模式 | MobileDebugger | Circle | 说明 |
|------|---------------|--------|------|
| NewSaaS | ✅ | ✅ (条件) | 支持圈选和调试器 |
| CDP | ✅ | ❌ | 仅支持调试器 |
| SaaS | ❌ | ❌ | 插件不支持 |

### 初始化时序图

```
Application          GrowingAnalytics    AnalyticsCore       Plugins         Modules
     │                     │                   │                │               │
     │ start(context,      │                   │                │               │
     │      config)        │                   │                │               │
     │────────────────────▶│                   │                │               │
     │                     │ startCore()       │                │               │
     │                     │──────────────────▶│                │               │
     │                     │                   │ registerPlugins│               │
     │                     │                   │───────────────▶│               │
     │                     │                   │                │               │
     │                     │                   │ onSDKWillInitialize()          │
     │                     │                   │───────────────▶│               │
     │                     │                   │                │               │
     │                     │                   │ init modules   │               │
     │                     │                   │────────────────────────────────▶
     │                     │                   │                │               │
     │                     │                   │ ◀──────────────│               │
     │                     │                   │                │               │
     │                     │                   │ setInterval    │               │
     │                     │                   │ (sendEvent)    │               │
     │                     │                   │                │               │
     │                     │                   │ emit(MAIN_    │               │
     │                     │                   │ TRACKER_INIT)  │               │
     │                     │                   │                │               │
     │                     │                   │ onSDKDidInit   │               │
     │                     │                   │───────────────▶│               │
     │                     │◀─────────────────│                │               │
     │◀────────────────────│                   │                │               │
     │                     │                   │                │               │
```

---

## 生命周期管理

### Ability 生命周期监听

```typescript
static setLifecycleCallback(context: Context) {
  // 避免重复注册
  if (AnalyticsCore._mainWindowStage != undefined) {
    return
  }

  let callback = (abilityContext: common.UIAbilityContext, windowStage: window.WindowStage) => {
    AnalyticsCore._mainWindowStage = windowStage
    windowStage.getMainWindow().then(mainWindow => {
      let context = mainWindow.getUIContext()
      AnalyticsCore.mainWindow = mainWindow
      AnalyticsCore.uiContent = context
    })

    // 设置无埋点状态获取器
    Plugins.setAutotrackStatusFetcher(() => {
      return Autotrack.uiContent != undefined && Autotrack.uiContent != null
    })
    Plugins.afterWindowStageCreate(abilityContext, windowStage)
  }

  // 延迟初始化场景处理
  if (Util.isUIAbilityContext(context)) {
    let abilityContext = context as common.UIAbilityContext
    let windowStage = abilityContext.windowStage
    if (windowStage) {
      Plugins.onDeferStart()
      callback(abilityContext, windowStage)
      return
    }
  }

  // 注册 Ability 生命周期监听
  let abilityLifecycleCallback: AbilityLifecycleCallback = {
    onAbilityCreate(ability: UIAbility) {},
    onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage) {
      callback(ability.context, windowStage)
    },
    onWindowStageActive(ability: UIAbility, windowStage: window.WindowStage) {},
    onWindowStageInactive(ability: UIAbility, windowStage: window.WindowStage) {},
    onWindowStageDestroy(ability: UIAbility, windowStage: window.WindowStage) {},
    onAbilityDestroy(ability: UIAbility) {},
    onAbilityForeground(ability: UIAbility) {},
    onAbilityBackground(ability: UIAbility) {},
    onAbilityContinue(ability: UIAbility) {}
  }
  context.getApplicationContext().on('abilityLifecycle', abilityLifecycleCallback)
}
```

### 应用状态变化监听

```typescript
static setAppStateChangeCallback(context: Context) {
  let applicationStateChangeCallback: ApplicationStateChangeCallback = {
    onApplicationForeground() {
      Session.onForeground()          // 通知会话：进入前台
      EventTimer.handleAllTimersResume()  // 恢复所有计时器
    },
    onApplicationBackground() {
      Session.onBackground()          // 通知会话：进入后台
      EventTimer.handleAllTimersPause()   // 暂停所有计时器
    }
  }

  context.getApplicationContext().on('applicationStateChange', applicationStateChangeCallback)
}
```

### 延迟初始化支持

SDK 支持两种初始化时机：

| 场景 | 特点 | 处理方式 |
|------|------|----------|
| **正常初始化** | 在 `onWindowStageCreate` 之前调用 `start()` | 注册生命周期监听，等待窗口创建 |
| **延迟初始化** | 在 `onWindowStageCreate` 之后调用 `start()` | 直接获取 windowStage，调用 `onDeferStart()` |

---

## 事件写入与存储

### 事件写入流程

```typescript
static async writeEventToDisk<T extends Event>(
  event: T,
  context: GrowingContext,
  eventScene: EventScene = EventScene.Native
) {
  // 防呆：再次检查数据采集开关
  if (!context.config.dataCollectionEnabled) {
    return
  }

  // 1. 转换为持久化事件
  let pst = EventPersistence.fromEvent(event, context)
  
  // 2. 写入数据库
  await EventDatabase.writeEvent(pst)
  
  // 3. 通知插件事件已写入
  Plugins.onEventWroteToDisk(pst, eventScene)
  
  // 4. VISIT 事件立即触发发送
  if (pst.eventType == EventType.Visit) {
    EventSender.sendEvent(context)
  }
}
```

### 写入流程图

```
事件生成 (EventBuilder.build)
        │
        ▼
┌─────────────────────┐
│ writeEventToDisk()  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 检查 dataCollection │
│ Enabled             │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ EventPersistence    │
│ .fromEvent()        │
│ 转换为持久化格式    │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ EventDatabase       │
│ .writeEvent()       │
│ 写入 SQLite         │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Plugins             │
│ .onEventWroteToDisk │
│ 通知插件            │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ VISIT 事件?         │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【是】    【否】
    │         │
    ▼         ▼
 立即发送   等待定时
    │      发送任务
    ▼
EventSender
.sendEvent()
```

---

## 子 Tracker 机制

### 子 Tracker 启动

支持多 Tracker 实例，用于向不同的项目上报数据：

```typescript
static startSubTracker(trackerId: string, config: GrowingConfig): boolean {
  // 1. 检查是否已存在相同配置
  if (GrowingContext.hasSimilarContext(trackerId, config)) {
    return false
  }

  // 2. 创建上下文
  GrowingContext.setContext(trackerId, config)
  let context = GrowingContext.getContext(trackerId) as GrowingContext

  // 3. 创建子 Tracker
  let subTracker = new AnalyticsCore(context)
  AnalyticsCore.trackers.push(subTracker)

  // 4. 初始化用户和会话
  UserIdentifier.initMultiUser(context)
  Session.refreshSession(context)

  // 5. 启动定时发送任务
  let delay = config.debugEnabled && AppInfo.debug ? 1000 : config._dataUploadInterval
  setInterval(() => {
    EventSender.sendEvent(context)
  }, delay)

  // 6. 通知插件
  Plugins.onStartSubTracker(trackerId, config)

  // 7. 标记初始化成功
  subTracker._isInitializedSuccessfully = true
  return true
}
```

### 获取 Tracker 实例

```typescript
static tracker(trackerId: string): AnalyticsCore | DummyTracker {
  // 查找指定 ID 的 Tracker
  for (let tracker of AnalyticsCore.trackers) {
    if (tracker.context.trackerId == trackerId) {
      return tracker
    }
  }
  // 未找到返回空实现
  return AnalyticsCore.dummyTracker
}
```

### 事件跨 Tracker 发送

```typescript
static sendTo(
  curTrackerId: string,
  trackers: string[],
  eventName: string,
  attributes: AttributesType = {}
) {
  // 过滤当前 Tracker
  trackers = trackers.filter(trackerId => trackerId != curTrackerId)
  // 去重
  trackers = Array.from(new Set(trackers))
  
  // 向每个目标 Tracker 发送事件
  trackers.forEach(trackerId => {
    let tracker = AnalyticsCore.tracker(trackerId)
    if (!tracker.isInitializedSuccessfully()) {
      return
    }
    if (!(tracker as AnalyticsCore).context.config.dataCollectionEnabled) {
      return
    }
    let e = CustomEvent.create(eventName, Util.cloneObject(attributes), (tracker as AnalyticsCore).context)
    AnalyticsCore.writeEventToDisk(e, (tracker as AnalyticsCore).context)
  })
}
```

---

## 定时任务管理

### 事件发送定时任务

```typescript
// 启动时设置定时任务
let delay = config.debugEnabled && AppInfo.debug ? 1000 : config._dataUploadInterval
setInterval(() => {
  EventSender.sendEvent(gContext)
}, delay)
```

| 场景 | 间隔时间 | 说明 |
|------|---------|------|
| 调试模式 | 1000ms (1秒) | 快速发送，便于调试 |
| 正常模式 | 15000ms (15秒，默认) | 可配置，节省电量和流量 |

---

## 位置信息管理

### 设置位置信息

CDP 模式下，首次设置有效位置时会触发 VISIT 事件：

```typescript
static setLocation(latitude: number, longitude: number) {
  let needSendVisit: boolean = false
  let context = GrowingContext.getDefaultContext() as GrowingContext
  
  if (context) {
    if (context.config.mode == ConfigMode.CDP) {
      // 首次设置有效位置时标记需要发送 VISIT
      if ((AnalyticsCore.location.latitude == 0 && Math.abs(latitude) > 0)
        || (AnalyticsCore.location.longitude == 0 && Math.abs(longitude) > 0)) {
        needSendVisit = true
      }
    }
  }

  // 保存位置信息
  AnalyticsCore.location.latitude = latitude
  AnalyticsCore.location.longitude = longitude

  // CDP 模式：首次设置位置时发送 VISIT
  if (needSendVisit) {
    Session.generateVisit(context)
  }
}
```

---

## SaaS 模式特殊方法

### onPageEnd() - WebView 圈选脚本注入

```typescript
onPageEnd(controller: webview.WebviewController, webviewId?: string): Promise<void>
```

**作用：** 委托给 `Hybrid.onPageEnd()`。仅当 SaaS 模式 + `hybridAutotrackEnabled=true` + `Hybrid.saasCircleEnabled=true` 时执行，在 WebView `onPageEnd` 时机向 H5 页面注入圈选插件脚本，并将 WebView 的 Native xpath 同步到 `window._vds_hybrid_native_info.x`。

---

### 设置 People Variable

```typescript
setPeopleVariable(attributes: AttributesType) {
  // 仅 SaaS 模式支持
  if (this.context.config.mode != ConfigMode.SaaS) {
    LogUtil.info(() => 'Failed to set people variable, only support on SaaS mode')
    return
  }
  if (!this.context.config.dataCollectionEnabled) {
    LogUtil.info(() => 'Failed to set people variable, dataCollectionEnabled is false')
    return
  }
  // 实际调用登录用户属性
  this.setLoginUserAttributes(attributes)
}
```

### 设置 Evar（转化变量）

```typescript
setEvar(attributes: AttributesType) {
  if (this.context.config.mode != ConfigMode.SaaS) {
    LogUtil.info(() => 'Failed to set evar, only support on SaaS mode')
    return
  }
  if (!this.context.config.dataCollectionEnabled) {
    LogUtil.info(() => 'Failed to set evar, dataCollectionEnabled is false')
    return
  }

  let e = SaaSEvarEvent.create(Util.cloneObject(attributes), this.context)
  AnalyticsCore.writeEventToDisk(e, this.context)
  LogUtil.info(() => 'Set evar: ' + JSON.stringify(attributes))
}
```

### 设置 Visitor（访问者变量）

```typescript
setVisitor(attributes: AttributesType) {
  if (this.context.config.mode != ConfigMode.SaaS) {
    LogUtil.info(() => 'Failed to set visitor, only support on SaaS mode')
    return
  }
  if (!this.context.config.dataCollectionEnabled) {
    LogUtil.info(() => 'Failed to set visitor, dataCollectionEnabled is false')
    return
  }

  let e = SaaSVisitorEvent.create(Util.cloneObject(attributes), this.context)
  AnalyticsCore.writeEventToDisk(e, this.context)
  LogUtil.info(() => 'Set visitor: ' + JSON.stringify(attributes))
}
```

---

## 总结

AnalyticsCore 是 GrowingIO HarmonyOS SDK 的核心控制器，负责：

1. **初始化管理**：主 Tracker 和子 Tracker 的启动流程
2. **生命周期监听**：Ability 和应用状态变化的处理
3. **事件存储**：事件持久化到数据库的统一入口
4. **插件管理**：MobileDebugger、Circle 等插件的注册和协调
5. **多 Tracker 支持**：向多个项目上报数据的能力
6. **模式适配**：针对不同模式（NewSaaS/CDP/SaaS）的特殊处理

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
