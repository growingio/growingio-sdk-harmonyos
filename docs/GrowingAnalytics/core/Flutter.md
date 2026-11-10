# Flutter 逻辑详解

> **模块归属**: 核心模块 (core)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/core/Flutter.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 中 `Flutter` 模块的逻辑实现。该模块负责与 Flutter SDK 进行跨平台通信，接收 Flutter 端产生的页面浏览事件和点击事件，实现 Flutter 页面的无埋点数据采集。

## 目录

- [概述](#概述)
- [核心架构](#核心架构)
- [跨平台通信机制](#跨平台通信机制)
- [圈选状态管理](#圈选状态管理)
- [Flutter 页面事件](#flutter-页面事件)
- [Flutter 点击事件](#flutter-点击事件)
- [事件场景标记](#事件场景标记)
- [公共 API 接口](#公共-api-接口)

---

## 概述

GrowingIO HarmonyOS SDK 支持 Flutter 混合开发模式下的数据采集。当应用使用 Flutter 框架开发时，Flutter 端的用户行为事件需要通过 Platform Channel 传递到原生端进行上报。

### 架构位置

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Flutter App                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │ Flutter SDK  │  │ GrowingIO    │  │ Flutter SDK  │                  │
│  │ (UI Layer)   │  │ Flutter SDK  │  │ (Engine)     │                  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                  │
│         │                 │                 │                          │
│         └─────────────────┴─────────────────┘                          │
│                           │                                             │
│                    Platform Channel                                     │
│                           │                                             │
└───────────────────────────┼─────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          HarmonyOS Native                               │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    GrowingIO HarmonyOS SDK                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │  │
│  │  │  Flutter    │  │ Autotrack   │  │ Analytics   │              │  │
│  │  │  Module     │──│   Module    │──│   Core      │              │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘              │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### 功能特性

| 功能 | 支持状态 | 说明 |
|------|---------|------|
| 页面浏览事件 | ✅ 支持 | Flutter 页面切换自动采集 |
| 点击事件 | ✅ 支持 | Flutter 组件点击自动采集 |
| 圈选支持 | ✅ 支持 | Flutter 页面和元素的圈选 |
| 自定义属性 | ✅ 支持 | 页面和事件的自定义属性 |
| 来源页面 | ✅ 支持 | 页面间的跳转来源追踪 |

---

## 核心架构

### 类关系图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Flutter                                    │
│                    (Flutter 跨平台通信处理类)                            │
├─────────────────────────────────────────────────────────────────────────┤
│  静态属性                                                               │
│  ├── isCircleOpen: boolean            // 圈选是否开启                   │
│  └── onCircleStatusChanged: Function  // 圈选状态变化回调               │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  ├── onCircleOpen()                   // 圈选开启通知                   │
│  ├── onCircleClosed()                 // 圈选关闭通知                   │
│  ├── trackFlutterCircleData()         // 处理圈选数据                   │
│  ├── trackFlutterPage()               // 处理页面事件                   │
│  ├── trackFlutterClickEvent()         // 处理点击事件                   │
│  └── attributesFromMap()              // 属性转换工具                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ 调用
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         FlutterPageEvent                                │
│                      (Flutter 页面事件类)                                │
├─────────────────────────────────────────────────────────────────────────┤
│  属性                                                                   │
│  ├── path: string                     // 页面路径                       │
│  ├── title: string                    // 页面标题                       │
│  ├── orientation: string              // 屏幕方向                       │
│  └── referralPage: string             // 来源页面                       │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  └── create()                         // 创建事件实例                   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 数据结构

#### Flutter 页面事件参数

```typescript
{
  path: string,              // 页面路径（必填）
  title: string,             // 页面标题
  referralPage: string,      // 来源页面
  attributes: Map<string, ValueType>  // 自定义属性
}
```

#### Flutter 点击事件参数

```typescript
{
  eventType: string,         // 事件类型：'VIEW_CLICK' | 'VIEW_CHANGE'
  path: string,              // 页面路径
  pageShowTimestamp: number, // 页面显示时间戳
  xpath: string,             // 元素 XPath（必填）
  xcontent: string,          // XContent（NewSaaS 必填）
  textValue: string,         // 文本内容
  index: number,             // 列表索引
  attributes: Map<string, ValueType>  // 自定义属性
}
```

#### Flutter 圈选数据

```typescript
{
  width: number,             // 屏幕宽度
  height: number,            // 屏幕高度
  scale: number,             // 屏幕缩放比例
  pages: Array<{             // 页面列表
    left: number,
    top: number,
    width: number,
    height: number,
    path: string,
    title: string
  }>,
  elements: Array<{          // 元素列表
    nodeType: string,
    domain: string,
    zLevel: number,
    xpath: string,
    xcontent: string,
    index?: number,
    content?: string,
    left: number,
    top: number,
    width: number,
    height: number,
    page: string
  }>
}
```

---

## 跨平台通信机制

### Platform Channel 架构

Flutter SDK 与 HarmonyOS Native SDK 之间通过 Platform Channel 进行通信：

```
┌─────────────────────────────────────────────────────────────────┐
│                          Flutter Layer                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              GrowingIO Flutter SDK                       │   │
│  │                                                         │   │
│  │  MethodChannel('growingio_flutter')                     │   │
│  │     • trackPage()                                       │   │
│  │     • trackClick()                                      │   │
│  │     • trackCircleData()                                 │   │
│  └────────────────────────┬────────────────────────────────┘   │
└───────────────────────────┼─────────────────────────────────────┘
                            │ BinaryMessenger
                            │ (平台消息通道)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Platform Embedder                          │
│                    (HarmonyOS Implementation)                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              GrowingIO HarmonyOS SDK                     │   │
│  │                                                         │   │
│  │  GrowingAnalytics.trackFlutterPage()                    │   │
│  │  GrowingAnalytics.trackFlutterClickEvent()              │   │
│  │  GrowingAnalytics.trackFlutterCircleData()              │   │
│  │                                                         │   │
│  │  ──▶ Flutter.trackFlutterPage()                         │   │
│  │  ──▶ Flutter.trackFlutterClickEvent()                   │   │
│  │  ──▶ Flutter.trackFlutterCircleData()                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 方法通道调用流程

```
Flutter 端方法调用
        │
        ▼
┌───────────────┐
│ MethodChannel │
│ invokeMethod  │
└───────┬───────┘
        │
        ▼
┌───────────────┐     ┌─────────────────────────┐
│ Platform      │────▶│ GrowingAnalytics        │
│ Channel       │     │ 公共 API 接口           │
└───────────────┘     └───────┬─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Flutter Module  │
                    │ 内部处理        │
                    └─────────────────┘
```

### 公共 API 接口

SDK 对外暴露三个 Flutter 专用接口：

```typescript
// GrowingAnalytics.ets

/**
 * 追踪 Flutter 页面事件
 * @param argument 页面参数 Map
 */
static trackFlutterPage(argument: Map<string, Object>) {
  if (!GrowingAnalytics.isInitializedSuccessfully()) {
    LogUtil.error(() => 'Must call GrowingAnalytics.start(context, configuration) first')
    return
  }
  if (argument == null || argument == undefined) {
    return
  }
  Flutter.trackFlutterPage(argument)
}

/**
 * 追踪 Flutter 点击事件
 * @param argument 点击事件参数 Map
 */
static trackFlutterClickEvent(argument: Map<string, Object>) {
  if (!GrowingAnalytics.isInitializedSuccessfully()) {
    LogUtil.error(() => 'Must call GrowingAnalytics.start(context, configuration) first')
    return
  }
  if (argument == null || argument == undefined) {
    return
  }
  Flutter.trackFlutterClickEvent(argument)
}

/**
 * 追踪 Flutter 圈选数据
 * @param argument 圈选数据 Map
 */
static trackFlutterCircleData(argument: Map<string, Object>) {
  if (!GrowingAnalytics.isInitializedSuccessfully()) {
    LogUtil.error(() => 'Must call GrowingAnalytics.start(context, configuration) first')
    return
  }
  if (argument == null || argument == undefined) {
    return
  }
  Flutter.trackFlutterCircleData(argument)
}
```

---

## 圈选状态管理

### 圈选状态机制

Flutter 模块维护圈选状态，用于控制 Flutter 端圈选数据的采集：

```typescript
export class Flutter {
  static isCircleOpen: boolean = false
  static onCircleStatusChanged: ((isRunning: boolean) => void) | undefined = undefined
}
```

### 状态流转

```
                    ┌─────────────┐
                    │  初始状态   │
                    │ isCircleOpen│
                    │   = false   │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
    ┌──────────┐     ┌──────────┐     ┌──────────┐
    │ 用户扫码  │     │ 用户扫码  │     │ 圈选进行中│
    │ 启动圈选  │     │ 启动调试  │     │ 用户退出  │
    └────┬─────┘     └────┬─────┘     └────┬─────┘
         │                │                │
         ▼                ▼                ▼
    ┌──────────────────────────────────────────┐
    │       onCircleOpen()                     │
    │       isCircleOpen = true                │
    │       onCircleStatusChanged?.(true)      │
    └──────────────────────────────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  圈选开启   │
                    │ Flutter端   │
                    │ 开始采集    │
                    └──────┬──────┘
                           │
                           ▼
    ┌──────────────────────────────────────────┐
    │       onCircleClosed()                   │
    │       isCircleOpen = false               │
    │       onCircleStatusChanged?.(false)     │
    └──────────────────────────────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  圈选关闭   │
                    │ Flutter端   │
                    │ 停止采集    │
                    └─────────────┘
```

### 圈选数据处理

```typescript
static trackFlutterCircleData(data: Map<string, Object>) {
  // 只有圈选开启时才处理数据
  if (!Flutter.isCircleOpen) {
    return
  }
  
  // 获取 Circle 实例并发送数据
  Flutter._getCircle()?.sendScreenshotForFlutter(data)
}

private static _getCircle(): Circle | undefined {
  return Plugins.plugins.find(p => p instanceof Circle) as Circle | undefined
}
```

---

## Flutter 页面事件

### 处理流程

```
Flutter 页面切换
        │
        ▼
┌─────────────────────┐
│ trackFlutterPage()  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 检查 dataCollection │
│ Enabled             │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【启用】  【禁用】
    │         │
    │         ▼
    │    【返回，不处理】
    │
    ▼
┌─────────────────────┐
│ 提取参数            │
│ • path (必填)       │
│ • title             │
│ • referralPage      │
│ • attributes        │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 创建 PageInfo       │
│ eventScene = Flutter│
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
│ FlutterPageEvent    │
└─────────────────────┘
```

### 代码实现

```typescript
static trackFlutterPage(argument: Map<string, Object>) {
  let context = GrowingContext.getDefaultContext() as GrowingContext
  
  // 1. 检查数据采集开关
  if (!context.config.dataCollectionEnabled) {
    LogUtil.info(() => 'Failed to dispatch flutter event, dataCollectionEnabled is false')
    return
  }

  // 2. 提取页面路径（必填）
  let path = argument.get('path') as string
  if (path == null || path == undefined || path.length == 0) {
    return
  }

  // 3. 提取来源页面
  let referralPage: string | undefined = argument.get('referralPage') as string
  if (referralPage == null || referralPage == undefined || referralPage.length == 0) {
    referralPage = undefined
  }

  // 4. 提取标题和属性
  let title = argument.get('title') as string
  let map = argument.get('attributes') as Map<string, ValueType>
  let attributes = Flutter.attributesFromMap(map)

  // 5. 创建页面信息
  let pageInfo = new PageInfo(path, title, attributes)
  pageInfo.referralPage = referralPage
  pageInfo.eventScene = EventScene.Flutter

  // 6. 发送页面事件
  AutotrackPage.sendPage(pageInfo)
}
```

### 后台页面处理

与 iOS 处理方式不同，HarmonyOS 对后台触发的页面事件采用缓存机制：

```typescript
// 可能会出现在后台触发 PAGE 的场景（类似 ANLSPI-20126）
// 走 AutotrackPage 内部缓存机制进行规避

// 与 iOS 不同在于：
// iOS 上在特定条件下（Flutter 应用在后台进行跳转）必定复现且该事件的前后台状态必定处于后台；
// HarmonyOS 则是在同等条件下偶现

// 因此，为避免事件数据差异，处理方式也有所不同：
// - iOS：丢弃这些 PAGE
// - HarmonyOS：将这些 PAGE 缓存于内存中，回到前台时生成
```

### 页面事件创建

```typescript
// FlutterPageEvent.ets
static create(
  path: string,
  title: string,
  attributes: AttributesType,
  timestamp: number,
  referralPage: string | undefined,
  context: GrowingContext
): FlutterPageEvent {
  let event = new FlutterPageEvent()
  event.path = path
  event.title = title ?? undefined
  event.attributes = attributes
  event.timestamp = timestamp
  event.orientation = DeviceInfo.orientation
  event.eventType = EventType.Page
  event.referralPage = referralPage ?? undefined

  return EventBuilder.build(event, context)
}
```

Flutter PAGE 不更新 `PageEvent.lastPage`。原生及 Flutter CUSTOM 按 `customEventWithPath` /
`customEventWithReferralPath` 携带的 `path` / `referralPage` 均取自最近一次原生 PAGE，原生 PAGE 的
`referralPage` 也不受 Flutter PAGE 影响。

---

## Flutter 点击事件

### 处理流程

```
Flutter 组件点击
        │
        ▼
┌─────────────────────┐
│ trackFlutterClickEvent()
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 检查 dataCollection │
│ Enabled             │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【启用】  【禁用】
    │         │
    │         ▼
    │    【返回，不处理】
    │
    ▼
┌─────────────────────┐
│ 根据 mode 校验必填  │
│ 字段                │
└────────┬────────────┘
         │
    ┌────┴────────────┐
    ▼                 ▼
┌──────────┐    ┌──────────┐
│ NewSaaS  │    │   CDP    │
├──────────┤    ├──────────┤
│ • xpath  │    │ • xpath  │
│ • xcontent│   │ • path   │
│          │    │ • ptm    │
└────┬─────┘    └────┬─────┘
     │               │
     └───────┬───────┘
             │
             ▼
┌─────────────────────┐
│ 创建 ViewElementEvent
│ eventScene = Flutter│
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ AnalyticsCore       │
│ writeEventToDisk()  │
└─────────────────────┘
```

### 代码实现

```typescript
static trackFlutterClickEvent(argument: Map<string, Object>) {
  let context = GrowingContext.getDefaultContext() as GrowingContext
  
  // 1. 检查数据采集开关
  if (!context.config.dataCollectionEnabled) {
    LogUtil.info(() => 'Failed to dispatch flutter event, dataCollectionEnabled is false')
    return
  }

  let mode = context.config.mode

  // 2. 提取事件类型
  let eventType = argument.get('eventType') as string
  if (eventType == null || eventType == undefined || eventType.length == 0) {
    return
  }

  // 3. CDP 模式：path 必填
  let path = argument.get('path') as string
  if (mode == ConfigMode.CDP) {
    if (path == null || path == undefined || path.length == 0) {
      return
    }
  }

  // 4. CDP 模式：pageShowTimestamp 必填
  let ptm = argument.get('pageShowTimestamp') as number
  if (mode == ConfigMode.CDP) {
    if (ptm == null || ptm == undefined) {
      return
    }
  }

  // 5. 提取 xpath（必填）
  let xpath = argument.get('xpath') as string
  if (xpath == null || xpath == undefined || xpath.length == 0) {
    return
  }

  // 6. NewSaaS 模式：xcontent 必填
  let xcontent = argument.get('xcontent') as string
  if (mode == ConfigMode.NewSaaS) {
    if (xcontent == null || xcontent == undefined || xcontent.length == 0) {
      return
    }
  }

  // 7. 提取其他参数
  let textValue = argument.get('textValue') as string
  let index = argument.get('index') as number
  let map = argument.get('attributes') as Map<string, ValueType>
  let attributes = Flutter.attributesFromMap(map)

  // 8. 创建并写入事件
  if (AnalyticsCore.core.isInitializedSuccessfully()) {
    let e = ViewElementEvent.create(
      path,
      ptm,
      textValue,
      xpath,
      xcontent,
      index,
      attributes,
      eventType === 'VIEW_CLICK' ? EventType.ViewClick : EventType.ViewChange,
      context
    )
    AnalyticsCore.writeEventToDisk(e, context, EventScene.Flutter)
  }
}
```

### 模式差异

| 参数 | NewSaaS | CDP |
|------|---------|-----|
| `xpath` | 必填 | 必填 |
| `xcontent` | 必填 | 可选 |
| `path` | 可选 | 必填 |
| `pageShowTimestamp` | 可选 | 必填 |

---

## 事件场景标记

### EventScene 枚举

```typescript
export enum EventScene {
  Native = 0,    // 原生事件
  Hybrid,        // Hybrid 事件
  Flutter        // Flutter 事件
}
```

### 场景标记用途

事件场景标记用于区分事件的来源，在多个模块中发挥作用：

1. **页面事件处理**（AutotrackPage）
```typescript
if (pageInfo.eventScene == EventScene.Flutter
  && context.config.mode == ConfigMode.NewSaaS) {
  // Flutter 页面使用 FlutterPageEvent
  let e = FlutterPageEvent.create(...)
} else {
  // 原生页面使用 PageEvent
  let e = PageEvent.create(...)
}
```

2. **点击事件写入**（Flutter.trackFlutterClickEvent）
```typescript
AnalyticsCore.writeEventToDisk(e, context, EventScene.Flutter)
```

3. **圈选截图过滤**（Circle.sendScreenshot）
```typescript
if (lastPage.eventScene != EventScene.Native) {
  // Flutter 页面截图由 Flutter SDK 触发
  return
}
```

---

## 公共 API 接口

### 导出给 Flutter SDK 使用的接口

```typescript
// GrowingAnalytics.ets
export { Flutter as GrowingFlutterPlugin } from '../core/Flutter'
```

Flutter SDK 通过 Platform Channel 调用这些接口：

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `trackFlutterPage` | `Map<string, Object>` | `void` | 上报页面事件 |
| `trackFlutterClickEvent` | `Map<string, Object>` | `void` | 上报点击事件 |
| `trackFlutterCircleData` | `Map<string, Object>` | `void` | 上报圈选数据 |

### 参数校验规则

**trackFlutterPage：**
- `path`：必填，不能为空字符串
- `title`：可选，页面标题
- `referralPage`：可选，来源页面路径
- `attributes`：可选，自定义属性 Map

**trackFlutterClickEvent：**
- `eventType`：必填，'VIEW_CLICK' 或 'VIEW_CHANGE'
- `xpath`：必填，元素 XPath 路径
- `xcontent`：NewSaaS 模式下必填
- `path`：CDP 模式下必填
- `pageShowTimestamp`：CDP 模式下必填
- `textValue`：可选，文本内容
- `index`：可选，列表索引
- `attributes`：可选，自定义属性 Map

**trackFlutterCircleData：**
- `width`：屏幕宽度
- `height`：屏幕高度
- `scale`：屏幕缩放比例
- `pages`：页面信息数组
- `elements`：元素信息数组

---

## 总结

Flutter 模块作为 HarmonyOS SDK 与 Flutter SDK 之间的桥梁，实现了混合开发模式下的数据采集。其核心设计要点包括：

1. **跨平台通信**：通过 Platform Channel 接收 Flutter 端的事件数据
2. **圈选状态同步**：维护圈选状态，控制 Flutter 端圈选数据的采集
3. **事件转发**：将 Flutter 页面事件和点击事件转发到原生 SDK 处理
4. **场景标记**：使用 EventScene.Flutter 标记事件来源，便于区分处理
5. **参数适配**：根据 SDK 模式（NewSaaS/CDP）进行不同的参数校验
6. **后台处理**：对后台触发的页面事件采用缓存机制，避免数据丢失

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.8.0*
