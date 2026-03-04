# UniApp（跨平台应用）逻辑详解

> **模块归属**: 核心模块 (core)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/core/UniApp.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 中 `UniApp` 模块的逻辑实现。该模块负责与 UniApp 框架进行跨平台通信，接收 UniApp 端产生的页面浏览事件，实现 UniApp 页面的无埋点数据采集。

## 目录

- [概述](#概述)
- [核心架构](#核心架构)
- [工作原理](#工作原理)
- [页面事件处理](#页面事件处理)
- [事件场景标记](#事件场景标记)
- [公共 API 接口](#公共-api-接口)
- [使用示例](#使用示例)

---

## 概述

GrowingIO HarmonyOS SDK 支持 UniApp 混合开发模式下的数据采集。当应用使用 UniApp 框架开发并运行于 HarmonyOS 平台时，UniApp 端的页面浏览事件需要通过特定接口传递到原生端进行上报。

### 架构位置

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              UniApp App                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │  UniApp SDK  │  │  UniApp SDK  │  │  UniApp SDK  │                  │
│  │    (Vue)     │  │   (Logic)    │  │  (Runtime)   │                  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                  │
│         │                 │                 │                          │
│         └─────────────────┴─────────────────┘                          │
│                           │                                             │
│                    Native Channel                                       │
│                           │                                             │
└───────────────────────────┼─────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          HarmonyOS Native                               │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    GrowingIO HarmonyOS SDK                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │  │
│  │  │   UniApp    │  │ Autotrack   │  │  Analytics  │              │  │
│  │  │   Module    │──│   Module    │──│   Core      │              │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘              │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### 功能特性

| 功能 | 支持状态 | 说明 |
|------|---------|------|
| 页面浏览事件 | ✅ 支持 | UniApp 页面切换自动采集 |
| 自定义属性 | ✅ 支持 | 页面的自定义属性 |
| NewSaaS 模式 | ✅ 支持 | 仅支持 NewSaaS 模式 |

---

## 核心架构

### 类关系图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              UniApp                                     │
│                    (UniApp 跨平台通信处理类)                              │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  ├── trackUniAppPage()                // 处理页面事件                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ 调用
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         UniAppPageEvent                                 │
│                      (UniApp 页面事件类)                                 │
├─────────────────────────────────────────────────────────────────────────┤
│  属性                                                                   │
│  ├── path: string                     // 页面路径                       │
│  ├── title: string                    // 页面标题（固定为空）            │
│  ├── orientation: string              // 屏幕方向                       │
│  └── referralPage: string             // 来源页面（固定为空）            │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  └── create()                         // 创建事件实例                   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 数据结构

#### UniApp 页面事件参数

```typescript
{
  path: string,              // 页面路径（必填）
  attributes: AttributesType  // 自定义属性
}
```

#### UniApp 页面事件类

```typescript
class UniAppPageEvent extends Event implements Page {
  path: string | undefined = undefined
  title: string | undefined = undefined           // 固定为 undefined
  orientation: string | undefined = undefined     // 当前屏幕方向
  referralPage: string | undefined = undefined    // 固定为 undefined
}
```

---

## 工作原理

### 通信流程

```
UniApp 页面切换
        │
        ▼
┌─────────────────────┐
│ 调用原生桥接方法     │
│ trackUniAppPage()   │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ UniApp.trackUniApp  │
│ Page()              │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 检查 SDK 状态       │
│ • 初始化状态        │
│ • 模式检查          │
│ • 数据采集开关      │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【通过】   【失败】
    │         │
    │         ▼
    │    【返回，不处理】
    │
    ▼
┌─────────────────────┐
│ 创建 PageInfo       │
│ eventScene = UniApp │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ AutotrackPage       │
│ sendPage()          │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 生成 PAGE 事件      │
│ UniAppPageEvent     │
└─────────────────────┘
```

### 前置检查

`trackUniAppPage` 方法在执行时会进行以下检查：

1. **SDK 初始化检查**：确保 `GrowingAnalytics.start()` 已被调用
2. **模式检查**：确保当前为 `NewSaaS` 模式（UniApp 仅支持 NewSaaS 模式）
3. **数据采集开关**：确保 `dataCollectionEnabled` 为 `true`
4. **路径校验**：确保 `path` 参数不为空

```typescript
static trackUniAppPage(path: string, attributes: AttributesType = {}) {
  // 1. 检查 SDK 初始化
  let context = GrowingContext.getDefaultContext() as GrowingContext
  if (!context) {
    LogUtil.info(() => 'Failed to dispatch UniApp event, must call GrowingAnalytics.start() first')
    return
  }
  
  // 2. 检查 SDK 模式
  if (context.config.mode != ConfigMode.NewSaaS) {
    LogUtil.info(() => 'Failed to dispatch UniApp event, must be New SaaS mode')
    return
  }
  
  // 3. 检查数据采集开关
  if (!context.config.dataCollectionEnabled) {
    LogUtil.info(() => 'Failed to dispatch UniApp event, dataCollectionEnabled is false')
    return
  }
  
  // 4. 检查路径
  if (path == null || path == undefined || path.length == 0) {
    LogUtil.warn(() => 'Failed to dispatch UniApp event, path is undefined')
    return
  }
  
  // ... 处理逻辑
}
```

---

## 页面事件处理

### 处理流程

```
UniApp 页面切换
        │
        ▼
┌─────────────────────┐
│ trackUniAppPage()   │
│ path, attributes    │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 前置检查            │
│ (初始化/模式/开关)  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 创建 PageInfo       │
│ • path              │
│ • title = ''        │
│ • attributes        │
│ • eventScene        │
│   = EventScene.     │
│   UniApp            │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ AutotrackPage.      │
│ sendPage()          │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 判断 eventScene     │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ UniAppPageEvent.    │
│ create()            │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ AnalyticsCore.      │
│ writeEventToDisk()  │
│ EventScene.UniApp   │
└─────────────────────┘
```

### 代码实现

```typescript
static trackUniAppPage(path: string, attributes: AttributesType = {}) {
  // ... 前置检查 ...
  
  // 创建页面信息
  let pageInfo = new PageInfo(path, '', attributes)
  pageInfo.eventScene = EventScene.UniApp
  
  // 发送页面事件
  AutotrackPage.sendPage(pageInfo)
}
```

### 页面事件创建

```typescript
// UniAppPageEvent.ets
static create(
  path: string,
  attributes: AttributesType,
  context: GrowingContext
): UniAppPageEvent {
  let event = new UniAppPageEvent()
  event.path = path
  event.attributes = attributes
  event.orientation = DeviceInfo.orientation
  event.eventType = EventType.Page

  return EventBuilder.build(event, context)
}
```

### 与 Flutter/Hybrid 的区别

| 特性 | UniApp | Flutter | Hybrid |
|------|--------|---------|--------|
| 支持模式 | 仅 NewSaaS | NewSaaS/CDP | NewSaaS/CDP/SaaS |
| 页面事件 | ✅ | ✅ | ✅ |
| 点击事件 | ❌ | ✅ | ✅ |
| 圈选支持 | ❌ | ✅ | ✅ |
| 标题传递 | ❌ | ✅ | ✅ |
| 来源页面 | ❌ | ✅ | ✅ |

UniApp 模块设计较为精简，仅处理页面浏览事件，标题和来源页面信息不传递。

---

## 事件场景标记

### EventScene 枚举

```typescript
export enum EventScene {
  Native = 0,    // 原生事件
  Hybrid,        // Hybrid 事件
  Flutter,       // Flutter 事件
  UniApp         // UniApp 事件
}
```

### 场景标记用途

事件场景标记用于区分事件的来源，在页面事件处理模块中发挥作用：

```typescript
// AutotrackPage.ets
if (pageInfo.eventScene == EventScene.Flutter
  && context.config.mode == ConfigMode.NewSaaS) {
  // Flutter 页面使用 FlutterPageEvent
  let e = FlutterPageEvent.create(...)
} else if (pageInfo.eventScene == EventScene.UniApp) {
  // UniApp 页面使用 UniAppPageEvent
  let e = UniAppPageEvent.create(
    pageInfo.path,
    pageInfo.attributes,
    context
  )
} else {
  // 原生页面使用 PageEvent
  let e = PageEvent.create(...)
}
```

---

## 公共 API 接口

### 导出给 UniApp SDK 使用的接口

```typescript
// GrowingAnalytics.ets
export { UniApp as GrowingUniAppPlugin } from '../core/UniApp'
```

UniApp SDK 通过 Native Channel 调用这些接口：

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `trackUniAppPage` | `path: string, attributes?: AttributesType` | `void` | 上报页面事件 |

### 参数说明

**trackUniAppPage：**
- `path`：必填，页面路径，不能为空字符串
- `attributes`：可选，自定义属性对象

### 参数校验规则

```typescript
// path 校验
if (path == null || path == undefined || path.length == 0) {
  LogUtil.warn(() => 'Failed to dispatch UniApp event, path is undefined')
  return
}
```

---

## 使用示例

### 在 UniApp 中调用

```typescript
// UniApp 页面生命周期中调用
// 通过 nativejs 桥接调用 HarmonyOS 原生方法

// 页面显示时上报
onShow() {
  const path = '/pages/index/index'
  const attributes = {
    'custom_key': 'custom_value'
  }
  
  // 调用原生 SDK 的 trackUniAppPage 方法
  uni.requireNativePlugin('GrowingAnalytics').trackUniAppPage(path, attributes)
}
```

### HarmonyOS 原生端配置

```typescript
// 在 EntryAbility 中初始化 SDK
import { GrowingAnalytics } from '@growingio/analytics'

onCreate() {
  // 初始化配置
  const config = new GrowingConfig()
  config.accountId = '您的项目ID'
  config.dataSourceId = '您的数据源ID'
  config.urlScheme = '您的URL Scheme'
  config.mode = ConfigMode.NewSaaS  // UniApp 仅支持 NewSaaS 模式
  
  // 启动 SDK
  GrowingAnalytics.start(this.context, config)
}
```

### 注意事项

1. **模式限制**：UniApp 模块仅在 `NewSaaS` 模式下工作，其他模式将忽略 UniApp 事件
2. **初始化顺序**：必须先调用 `GrowingAnalytics.start()` 初始化 SDK，才能接收 UniApp 事件
3. **路径必填**：`path` 参数不能为空，否则事件将被丢弃
4. **事件类型**：UniApp 仅支持页面浏览事件（PAGE），不支持点击事件

---

## 总结

UniApp 模块作为 HarmonyOS SDK 与 UniApp 框架之间的桥梁，实现了混合开发模式下的页面数据采集。其核心设计要点包括：

1. **精简设计**：仅处理页面浏览事件，不涉及点击事件和圈选功能
2. **模式限定**：仅支持 NewSaaS 模式，确保与新版本分析平台的兼容性
3. **事件转发**：将 UniApp 页面事件转发到原生 SDK 处理流程
4. **场景标记**：使用 `EventScene.UniApp` 标记事件来源，便于区分处理
5. **前置校验**：严格的初始化、模式和参数校验，确保数据质量

---

*文档生成时间: 2026-03-04*
*基于 GrowingIO HarmonyOS SDK*
