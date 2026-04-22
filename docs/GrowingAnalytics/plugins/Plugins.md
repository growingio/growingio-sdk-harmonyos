# Plugins 插件系统逻辑详解

> **模块归属**: 核心模块 (core)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/plugins/Plugins.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 的插件系统架构，包括插件注册、生命周期管理、事件回调等机制。

## 目录

- [概述](#概述)
- [插件接口定义](#插件接口定义)
- [插件注册与管理](#插件注册与管理)
- [插件生命周期](#插件生命周期)
- [内置插件](#内置插件)
- [事件回调机制](#事件回调机制)
- [延迟初始化支持](#延迟初始化支持)

---

## 概述

Plugins 系统是 GrowingIO SDK 的扩展机制，允许通过插件方式扩展 SDK 功能。目前内置了两个主要插件：

- **MobileDebugger**: 移动调试器，用于实时查看事件和日志
- **Circle**: 无埋点圈选，用于 Web 端可视化圈选元素

### 架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│                        SDK Core                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Plugins 系统                          │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │            PluginsInterface 接口                 │   │   │
│  │  │  • onSDKWillInitialize                           │   │   │
│  │  │  • onSDKDidInitialize                            │   │   │
│  │  │  • onEventWroteToDisk                            │   │   │
│  │  │  • ...                                           │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                           │                            │   │
│  │              ┌────────────┼────────────┐               │   │
│  │              ▼            ▼            ▼               │   │
│  │  ┌───────────────┐ ┌──────────┐ ┌──────────────┐      │   │
│  │  │ MobileDebugger│ │  Circle  │ │ 自定义插件    │      │   │
│  │  │   调试器插件   │ │ 圈选插件  │ │              │      │   │
│  │  └───────────────┘ └──────────┘ └──────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 插件特点

1. **接口化设计**: 通过 `PluginsInterface` 定义标准接口
2. **生命周期管理**: SDK 在关键节点回调插件方法
3. **事件驱动**: 插件可以监听事件写入、发送等操作
4. **灵活扩展**: 支持自定义插件接入

---

## 插件接口定义

### PluginsInterface

```typescript
export interface PluginsInterface {
  // SDK 即将初始化
  onSDKWillInitialize?(): void

  // SDK 初始化完成
  onSDKDidInitialize?(config: GrowingConfig, version: string): void

  // 子 Tracker 启动
  onStartSubTracker?(trackerId: string, config: GrowingConfig): void

  // 设置无埋点状态获取器
  setAutotrackStatusFetcher?(fetcher: () => boolean): void

  // 延迟初始化开始
  onDeferStart?(): void

  // WindowStage 创建后
  afterWindowStageCreate?(
    abilityContext: common.UIAbilityContext, 
    windowStage: window.WindowStage
  ): void

  // 处理 DeepLink URL
  handleOpenURL?(uri: string): boolean

  // 事件写入磁盘
  onEventWroteToDisk?(event: EventPersistence, eventScene: number): void

  // 事件从磁盘移除
  onEventsRemoveFromDisk?(events: string[]): void

  // 收到网络响应
  onResponseReceive?(response: rcp.Response): void

  // 事件发送完成
  onEventsDidSend?(events: EventPersistence[], request: rcp.Request): void

  // WebView DOM 树变化
  onWebViewDomTreeChanged?(): void

  // SaaS 模式 WebView 圈选事件（H5 → Native → 服务端）
  onWebViewSaaSCircleEvent?(message: string, webviewId?: string): void
}
```

### 接口方法分类

| 类别 | 方法 | 触发时机 |
|------|------|---------|
| **生命周期** | `onSDKWillInitialize` | SDK 初始化开始前 |
| | `onSDKDidInitialize` | SDK 初始化完成后 |
| | `onStartSubTracker` | 子 Tracker 启动时 |
| **窗口管理** | `setAutotrackStatusFetcher` | 设置无埋点状态获取器 |
| | `onDeferStart` | 延迟初始化时 |
| | `afterWindowStageCreate` | WindowStage 创建后 |
| **URL 处理** | `handleOpenURL` | 收到 DeepLink URL 时 |
| **事件监听** | `onEventWroteToDisk` | 事件写入磁盘后 |
| | `onEventsRemoveFromDisk` | 事件从磁盘移除后 |
| | `onResponseReceive` | 收到网络响应后 |
| | `onEventsDidSend` | 事件发送完成后 |
| **Hybrid** | `onWebViewDomTreeChanged` | WebView DOM 变化时 |
| | `onWebViewSaaSCircleEvent` | SaaS WebView 圈选事件上报时（H5 → Native 方向） |

---

## 插件注册与管理

### 插件列表

```typescript
export default class Plugins {
  static plugins: Array<PluginsInterface> = []
  static deferDeepLink: string | undefined = undefined  // 延迟处理的 DeepLink
}
```

### 注册插件

```typescript
// 批量注册
static registerPlugins(plugins: PluginsInterface[]) {
  plugins.forEach(plugin => {
    Plugins.registerPlugin(plugin)
  })
}

// 单个注册
static registerPlugin(plugin: PluginsInterface) {
  Plugins.plugins.push(plugin)
}
```

### 注册流程

```
AnalyticsCore.startCore()
        │
        ▼
┌─────────────────────┐
│ 准备插件列表         │
│ • MobileDebugger    │
│ • Circle            │
│ • 自定义插件         │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ registerPlugins()   │
│ 注册到插件列表       │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ onSDKWillInitialize │
│ 通知插件即将初始化   │
└─────────────────────┘
```

---

## 插件生命周期

### 1. SDK 初始化前

```typescript
static onSDKWillInitialize() {
  Plugins.plugins.forEach(plugin => {
    if (plugin.onSDKWillInitialize) {
      plugin.onSDKWillInitialize()
    }
  })
}
```

### 2. SDK 初始化完成

```typescript
static onSDKDidInitialize(config: GrowingConfig, version: string) {
  Plugins.plugins.forEach(plugin => {
    if (plugin.onSDKDidInitialize) {
      plugin.onSDKDidInitialize(config, version)
    }
  })

  // 处理延迟的 DeepLink
  if (Plugins.deferDeepLink) {
    let uri = Plugins.deferDeepLink
    Plugins.deferDeepLink = undefined
    Plugins.handleOpenURL(uri)
  }
}
```

### 3. 子 Tracker 启动

```typescript
static onStartSubTracker(trackerId: string, config: GrowingConfig) {
  Plugins.plugins.forEach(plugin => {
    if (plugin.onStartSubTracker) {
      plugin.onStartSubTracker(trackerId, config)
    }
  })
}
```

### 生命周期流程图

```
SDK 启动
    │
    ▼
┌─────────────────────┐
│ registerPlugins()   │
│ 注册插件             │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ onSDKWillInitialize │
│ 初始化前回调         │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ SDK 初始化各模块     │
│ • DeviceInfo        │
│ • Session           │
│ • ...               │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ onSDKDidInitialize  │
│ 初始化完成回调       │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 检查 deferDeepLink  │
│ 处理延迟的 DeepLink │
└─────────────────────┘

子 Tracker 启动
    │
    ▼
┌─────────────────────┐
│ onStartSubTracker   │
│ 子 Tracker 回调      │
└─────────────────────┘
```

---

## 内置插件

### MobileDebugger 插件

用于实时调试，支持在 Web 端查看事件和日志。

```typescript
class MobileDebugger implements PluginsInterface, WebSocketCallbackInterface {
  // 在 NewSaaS 和 CDP 模式下自动注册
  // SaaS 模式不支持
}
```

**注册条件**:
```typescript
if (config.mode != ConfigMode.SaaS) {
  plugins.push(new MobileDebugger())
}
```

### Circle 插件

用于无埋点圈选，支持在 Web 端可视化圈选元素。

```typescript
class Circle implements PluginsInterface, WebSocketCallbackInterface {
  // 仅在 NewSaaS 模式且开启 autotrack 时注册
}
```

**注册条件**:
```typescript
if (config.mode == ConfigMode.NewSaaS && config.autotrackEnabled) {
  plugins.push(new Circle())
}
```

### 插件注册矩阵

| 插件 | NewSaaS | CDP | SaaS |
|------|---------|-----|------|
| MobileDebugger | ✅ | ✅ | ❌ |
| Circle | ✅ (需 autotrack) | ❌ | ❌ |

---

## 事件回调机制

### 事件写入回调

当事件写入本地数据库后触发：

```typescript
static onEventWroteToDisk(event: EventPersistence, eventScene: number) {
  Plugins.plugins.forEach(plugin => {
    if (plugin.onEventWroteToDisk) {
      plugin.onEventWroteToDisk(event, eventScene)
    }
  })
}
```

**使用场景**:
- MobileDebugger: 实时显示刚写入的事件

### 事件移除回调

当事件从本地数据库移除后触发（发送成功）：

```typescript
static onEventsRemoveFromDisk(events: string[]) {
  Plugins.plugins.forEach(plugin => {
    if (plugin.onEventsRemoveFromDisk) {
      plugin.onEventsRemoveFromDisk(events)
    }
  })
}
```

### 网络响应回调

当收到服务器响应后触发：

```typescript
static onResponseReceive(response: rcp.Response) {
  Plugins.plugins.forEach(plugin => {
    if (plugin.onResponseReceive) {
      plugin.onResponseReceive(response)
    }
  })
}
```

### 事件发送回调

当事件发送完成后触发：

```typescript
static onEventsDidSend(events: EventPersistence[], request: rcp.Request) {
  Plugins.plugins.forEach(plugin => {
    if (plugin.onEventsDidSend) {
      plugin.onEventsDidSend(events, request)
    }
  })
}
```

**使用场景**:
- MobileDebugger: 显示已发送的事件详情

### DOM 变化回调

当 WebView 的 DOM 树发生变化时触发：

```typescript
static onWebViewDomTreeChanged() {
  Plugins.plugins.forEach(plugin => {
    if (plugin.onWebViewDomTreeChanged) {
      plugin.onWebViewDomTreeChanged()
    }
  })
}
```

**使用场景**:
- Circle: 触发截图刷新，更新圈选数据

---

## 延迟初始化支持

### 场景说明

当 SDK 在 `onWindowStageCreate` 之后初始化时，属于延迟初始化场景，需要特殊处理：

```typescript
static onDeferStart() {
  Plugins.plugins.forEach(plugin => {
    if (plugin.onDeferStart) {
      plugin.onDeferStart()
    }
  })
}
```

### WindowStage 创建后

```typescript
static afterWindowStageCreate(
  abilityContext: common.UIAbilityContext, 
  windowStage: window.WindowStage
) {
  Plugins.plugins.forEach(plugin => {
    if (plugin.afterWindowStageCreate) {
      plugin.afterWindowStageCreate(abilityContext, windowStage)
    }
  })
}
```

### 无埋点状态获取器

Circle 和 MobileDebugger 需要获取无埋点状态：

```typescript
static setAutotrackStatusFetcher(fetcher: () => boolean) {
  Plugins.plugins.forEach(plugin => {
    if (plugin.setAutotrackStatusFetcher) {
      plugin.setAutotrackStatusFetcher(fetcher)
    }
  })
}
```

使用示例：
```typescript
Plugins.setAutotrackStatusFetcher(() => {
  return Autotrack.uiContent != undefined && Autotrack.uiContent != null
})
```

---

## DeepLink 处理

### handleOpenURL

插件可以通过 `handleOpenURL` 方法处理 DeepLink URL：

```typescript
static handleOpenURL(uri: string): boolean {
  let isHandle = false
  
  // 遍历所有插件，尝试处理 URL
  for (let plugin of Plugins.plugins) {
    if (plugin.handleOpenURL) {
      isHandle = plugin.handleOpenURL(uri)
      if (isHandle) {
        break  // 已有插件处理，停止遍历
      }
    }
  }

  // 如果未处理且 SDK 未初始化，延迟处理
  if (!isHandle && 
      !AnalyticsCore.core.isInitializedSuccessfully() && 
      uri.startsWith('growing.')) {
    Plugins.deferDeepLink = uri
  }

  return isHandle
}
```

### URL 处理流程

```
收到 DeepLink URL
        │
        ▼
┌─────────────────────┐
│ 遍历插件             │
│ handleOpenURL       │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 有插件处理？         │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【是】    【否】
    │         │
    │         ▼
    │    ┌─────────────────┐
    │    │ SDK 已初始化？   │
    │    └────────┬────────┘
    │             │
    │        ┌────┴────┐
    │        ▼         ▼
    │      【是】    【否】
    │        │         │
    │        │         ▼
    │        │    deferDeepLink
    │        │    延迟处理
    │        │
    └────────┘
              │
              ▼
        返回处理结果
```

### DeepLink 格式

```
growing.{urlScheme}://?
  serviceType={type}&
  wsUrl={websocket_url}

示例:
growing.123456://?serviceType=circle&wsUrl=wss://.../circle
```

| 参数 | 说明 |
|------|------|
| `serviceType` | 服务类型：`circle` 或 `debugger` |
| `wsUrl` | WebSocket 服务器地址 |

---

## 自定义插件示例

### 实现自定义插件

```typescript
import { PluginsInterface } from '@growingio/analytics'

class MyPlugin implements PluginsInterface {
  onSDKDidInitialize(config: GrowingConfig, version: string) {
    console.log('SDK 初始化完成，版本：', version)
  }

  onEventWroteToDisk(event: EventPersistence, eventScene: number) {
    console.log('事件已写入：', event.eventType)
  }
}
```

### 注册自定义插件

```typescript
let config = new GrowingConfig().NewSaaS(...)
config.plugins.push(new MyPlugin())
GrowingAnalytics.start(context, config)
```

---

## 总结

Plugins 系统提供了灵活的扩展机制：

1. **接口化设计**: 通过 `PluginsInterface` 定义标准扩展点
2. **生命周期管理**: 覆盖 SDK 初始化的各个阶段
3. **事件驱动**: 支持监听事件写入、发送等关键操作
4. **内置插件**: MobileDebugger 和 Circle 通过插件方式集成
5. **延迟初始化**: 支持延迟初始化场景的特殊处理

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
