# AutotrackPage 逻辑详解

> **模块归属**: 无埋点模块 (autotrack)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/autotrack/AutotrackPage.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 中 `AutotrackPage` 模块的逻辑实现，该模块负责自动采集页面浏览事件（PAGE 事件）。

## 目录

- [概述](#概述)
- [核心架构](#核心架构)
- [数据结构与状态管理](#数据结构与状态管理)
- [页面监听机制](#页面监听机制)
- [页面切换处理流程](#页面切换处理流程)
- [事件生成与发送](#事件生成与发送)
- [特殊场景处理](#特殊场景处理)
- [配置与开关](#配置与开关)

---

## 概述

`AutotrackPage` 是 HarmonyOS SDK 无埋点功能的核心模块之一，主要功能包括：

1. **自动监听页面切换**：通过 ArkUI 的 UIObserver 监听 Navigation 和 Router 的页面变化
2. **生成页面浏览事件**：在页面切换时自动生成 PAGE 事件
3. **支持混合导航架构**：同时支持 Navigation 组件导航和 @ohos.router 路由
4. **页面属性扩展**：支持通过参数设置页面别名、自定义标题和属性

---

## 核心架构

### 类关系图

```
┌─────────────────────────────────────────────────────────────┐
│                      AutotrackPage                          │
├─────────────────────────────────────────────────────────────┤
│  静态属性                                                    │
│  ├── pagesCacheOnBackground: PageInfo[]    // 后台缓存        │
│  ├── navBarStack: _NavBarInfo[]            // NavBar 栈       │
│  ├── deferNavDestinationPages: PageInfo[]  // 延迟页面队列    │
│  ├── lastNativePage: PageInfo              // 最后原生页      │
│  └── lastPage: PageInfo                    // 最后页面        │
├─────────────────────────────────────────────────────────────┤
│  核心方法                                                    │
│  ├── startObserver()          // 启动页面监听                │
│  ├── onPageUpdate()           // 页面变化回调                │
│  ├── sendNativePage()         // 发送原生页面事件            │
│  └── generatePage()           // 生成页面事件                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        PageInfo                             │
├─────────────────────────────────────────────────────────────┤
│  path: string              // 页面路径 (如 "/pages/Index")   │
│  title: string             // 页面标题                       │
│  attributes: AttributesType // 自定义属性                    │
│  alias?: string            // 页面别名                       │
│  dstId?: string            // NavDestination ID              │
│  timestamp: number         // 时间戳                         │
│  referralPage?: string     // 来源页面                       │
│  eventScene: EventScene    // 事件场景 (Native/Flutter)      │
└─────────────────────────────────────────────────────────────┘
```

### 与系统的交互

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  ArkUI 系统   │────▶│ UIObserver   │────▶│onPageUpdate()│
│              │     │              │     │              │
│ • Navigation │     │ • navDestinationUpdate             │
│ • Router     │     │ • navDestinationSwitch             │
└──────────────┘     │ • routerPageUpdate │               │
                     └──────────────┘     └──────────────┘
                                                    │
                                                    ▼
                                          ┌──────────────┐
                                          │  事件分发处理 │
                                          │              │
                                          │ • Navigation │
                                          │ • Router     │
                                          │ • 后台恢复   │
                                          └──────────────┘
```

---

## 数据结构与状态管理

### 1. pagesCacheOnBackground

**用途**: 存储在 SDK 未初始化完成或应用处于后台时触发的页面浏览事件

```typescript
static pagesCacheOnBackground: Array<PageInfo> = []
```

**触发时机**:
- 应用启动时，SDK 尚未初始化完成，用户已切换页面
- 应用从后台返回前台时产生的页面事件

**处理逻辑**:
1. 当 `generatePage()` 检测到 SDK 未初始化或应用在后台时，将 PageInfo 加入缓存
2. 当 SDK 初始化完成或应用切换到前台时，通过 `resendPageFromCacheOnBackground()` 发送缓存事件

### 2. navBarStack

**用途**: 存储 Navigation 的 NavBar（首页）信息，用于处理返回首页的场景

```typescript
static navBarStack: Array<_NavBarInfo> = []

class _NavBarInfo {
  navBar: PageInfo      // NavBar 页面信息
  dstId: string         // 关联的 NavDestination ID
}
```

**工作原理**:
- 当从 NavBar 跳转到 NavDestination 时，将 NavBar 页面信息入栈
- 当从 NavDestination 返回到 NavBar 时，从栈中查找对应的 NavBar 并发送页面事件
- 支持多层嵌套 Navigation 场景

### 3. deferNavDestinationPages

**用途**: 解决 `navDestinationUpdate` 和 `navDestinationSwitch` 触发顺序不确定的问题

```typescript
static deferNavDestinationPages: Array<PageInfo> = []
```

**问题背景**:
- HarmonyOS 中两个监听的触发顺序不确定
- 需要确保同一页面只发送一次页面浏览事件
- 需要确保先发送 Router 页面事件，再发送 Navigation 页面事件（后台回前台场景）

**解决方案**:
1. `navDestinationUpdate` 触发时，将页面信息存入 `deferNavDestinationPages`
2. `navDestinationSwitch` 触发时，检查队列中是否存在相同页面：
   - 存在：发送页面事件并从队列移除
   - 不存在：等待后续处理

### 4. lastNativePage / lastPage

**用途**: 记录最后访问的页面信息

| 属性 | 用途 |
|------|------|
| `lastNativePage` | 记录最后访问的原生页面（用于 NavBar 入栈） |
| `lastPage` | 记录最后访问的所有页面（包括 Flutter） |

---

## 页面监听机制

### 监听器注册

```typescript
static startObserver(context: UIContext) {
  context.getUIObserver().on('navDestinationUpdate', AutotrackPage.onPageUpdate)
  context.getUIObserver().on('navDestinationSwitch', AutotrackPage.onPageUpdate)
  context.getUIObserver().on('routerPageUpdate', AutotrackPage.onPageUpdate)
}
```

### 三种页面事件类型

| 事件类型 | 触发场景 | HarmonyOS 版本 |
|---------|---------|---------------|
| `navDestinationUpdate` | Navigation 页面显示/隐藏状态变化 | 5.0.0(12)+ |
| `navDestinationSwitch` | Navigation 页面切换完成 | 5.0.0(12)+ |
| `routerPageUpdate` | Router 页面生命周期变化 | 5.0.0(12)+ |

### 事件触发顺序（重要）

根据代码注释和实际测试，不同场景的触发顺序如下：

#### 1. Navigation 页面切换
```
navDestinationUpdate ──┐
                       ├──► 几乎同时触发，顺序不确定
navDestinationSwitch ──┘
```

#### 2. Router 页面切换
```
routerPageUpdate (ON_PAGE_SHOW)
```

#### 3. 返回 Navigation 首页 (NavBar)
```
navDestinationSwitch (to = "navBar")
```
注意：`navDestinationUpdate` 不会触发

#### 4. 后台回前台
```
navDestinationUpdate ──┐
                       ├──► 两者都触发
routerPageUpdate ──────┘
```
注意：`navDestinationSwitch` 不会触发

#### 5. 触发时机关系
```
navDestinationUpdate 和 navDestinationSwitch: 顺序不确定
navDestinationUpdate 早于 routerPageUpdate
```

---

## 页面切换处理流程

### 入口方法: `onPageUpdate()`

```typescript
static onPageUpdate(info: NavDestinationInfo | uiObserver.NavDestinationSwitchInfo | RouterPageInfo) {
  // 1. 判空检查
  if (!info) return

  // 2. 根据信息类型分发处理
  if (Util.isNavDestinationSwitchInfo(info)) {
    // 处理 navDestinationSwitch
  } else if (Util.isNavDestinationInfo(info)) {
    // 处理 navDestinationUpdate
  } else {
    // 处理 routerPageUpdate
  }
}
```

### 场景一: Navigation 页面切换 (navDestinationSwitch)

```
┌─────────────────────────────────────────────────────────────┐
│                 NavDestinationSwitch 处理流程                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ to 是否为 NavBar │
                    │ (typeof to ===   │
                    │    'string')     │
                    └────────┬─────────┘
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
        【是：返回首页】                   【否：页面切换】
            │                                 │
            ▼                                 ▼
    ┌───────────────┐               ┌───────────────────┐
    │ 从 navBarStack │               │ from 是否为 NavBar │
    │ 中查找匹配项   │               │ (首页跳转)        │
    └───────┬───────┘               └─────────┬─────────┘
            │                                 │
            ▼                                 ▼
    ┌───────────────┐               ┌───────────────────┐
    │ 找到匹配项？   │               │ 【是】将当前首页   │
    └───────┬───────┘               │ 入栈 navBarStack  │
            │                       └─────────┬─────────┘
    ┌───────┴───────┐                       │
    ▼               ▼                       ▼
【找到】        【未找到】         ┌───────────────────┐
    │               │              │ 【否】刷新当前    │
    ▼               ▼              │ NavDestination    │
发送 NavBar      继续遍历         │ 关联的 dstId      │
页面事件          栈              └───────────────────┘
            │                                 │
            │                                 ▼
            │                     ┌───────────────────┐
            │                     │ 发送 Navigation   │
            │                     │ 页面事件          │
            │                     │ (调用 sendNav     │
            │                     │  DestinationPage  │
            │                     │  IfNeeded)        │
            │                     └───────────────────┘
            │                                 │
            └────────────────┬────────────────┘
                             ▼
                    ┌──────────────────┐
                    │ 清理对应 defer   │
                    │ NavDestination   │
                    │ Pages 减少内存   │
                    └──────────────────┘
```

**关键代码**:
```typescript
// 返回首页场景
if (typeof to == 'string' && to != null && to != undefined) {
  // LIFO 方式查找匹配的 NavBar
  while (!isFind && AutotrackPage.navBarStack.length > 0) {
    let k = AutotrackPage.navBarStack.pop()!
    if (k.isEqual(fromInfo)) {
      AutotrackPage.sendNativePage(k.navBar)
      // 清理对应的 deferNavDestinationPages
      ...
      isFind = true
    }
  }
}
```

### 场景二: Navigation 页面更新 (navDestinationUpdate)

```
┌─────────────────────────────────────────────────────────────┐
│                 NavDestinationUpdate 处理流程                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ 获取页面信息      │
                    │ 检查状态是否为   │
                    │ ON_SHOWN         │
                    └────────┬─────────┘
                             │
                    ┌────────┴────────┐
                    ▼                 ▼
                【状态合法】       【状态非法】
                    │                 │
                    ▼                 ▼
            ┌───────────────┐    【返回】
            │ 检查是否为     │
            │ GTK_ 前缀页面  │
            │ (内部页面过滤) │
            └───────┬───────┘
                    │
           ┌────────┴────────┐
           ▼                 ▼
       【非内部页面】     【内部页面】
           │                 │
           ▼                 ▼
   ┌───────────────┐    【返回】
   │ 调用 sendNav  │
   │ Destination  │
   │ PageIfNeeded │
   └───────────────┘
```

### 场景三: Router 页面更新 (routerPageUpdate)

```
┌─────────────────────────────────────────────────────────────┐
│                   RouterPageUpdate 处理流程                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ 检查状态是否为   │
                    │ ON_PAGE_SHOW     │
                    └────────┬─────────┘
                             │
                    ┌────────┴────────┐
                    ▼                 ▼
                【ON_SHOW】       【其他状态】
                    │                 │
                    ▼                 ▼
            ┌───────────────┐    【返回】
            │ 提取页面名称   │
            │ 构建 path      │
            │ (/{pageName})  │
            └───────┬───────┘
                    │
                    ▼
            ┌───────────────┐
            │ 从 Router     │
            │ 获取参数       │
            │ • growing_alias
            │ • growing_title
            │ • growing_attributes
            └───────┬───────┘
                    │
                    ▼
            ┌───────────────┐
            │ 创建 PageInfo │
            │ 发送页面事件   │
            │ sendNativePage│
            └───────┬───────┘
                    │
                    ▼
            ┌───────────────┐
            │ 处理延迟队列   │
            │ deferNav      │
            │ Destination   │
            │ Pages         │
            └───────────────┘
```

### 页面信息提取方法: `getPageInfoFromNavDestinationInfo()`

```typescript
static getPageInfoFromNavDestinationInfo(navInfo: NavDestinationInfo): PageInfo | undefined {
  // 1. 状态检查
  if (navInfo.state != uiObserver.NavDestinationState.ON_SHOWN) {
    return undefined
  }

  let name = navInfo.name.toString()
  
  // 2. 过滤 GrowingToolsKit 内部页面
  const GTK_NAV_PATH_PREFIX = '__GTK_'
  if (name.startsWith(GTK_NAV_PATH_PREFIX)) {
    return undefined
  }

  // 3. 构建基础信息
  let path = PATH_SEPARATOR + name
  let title = name
  
  // 4. 处理路径分隔符（取最后一部分作为标题）
  if (title.includes(PATH_SEPARATOR)) {
    title = title.substring(title.lastIndexOf(PATH_SEPARATOR) + 1)
  }

  // 5. 提取参数中的扩展信息
  let attributes = Util.getAttributesFromNavInfoParameter(navInfo.param)
  let alias = Util.getAliasFromNavInfoParameter(navInfo.param)
  let customTitle = Util.getTitleFromNavInfoParameter(navInfo.param)

  // 6. 应用别名和自定义标题
  if (alias.length > 0) {
    path = PATH_SEPARATOR + alias
  }
  if (customTitle.length > 0) {
    title = customTitle
  }

  // 7. 创建 PageInfo（包含 dstId 用于唯一标识）
  return new PageInfo(path, title, attributes, alias, navInfo.navDestinationId)
}
```

---

## 事件生成与发送

### 发送流程: `sendNativePage()` → `sendPage()` → `generatePage()`

```
sendNativePage(pageInfo)
        │
        ├── 1. 设置时间戳
        ├── 2. 更新 lastNativePage
        ├── 3. 检查 autotrackEnabled
        ├── 4. 检查 autotrackAllPages
        │       └── 如果为 false，检查是否有 alias
        │           └── 有 alias 则继续发送
        │
        ▼
   sendPage(pageInfo)
        │
        ├── 1. 更新 lastPage
        ├── 2. 触发 resendPageFromCacheOnBackground()
        │       └── 发送之前缓存的后台页面事件
        │
        ▼
   generatePage(pageInfo)
        │
        ├── 检查 SDK 初始化状态
        ├── 检查 Session 状态（Foreground）
        ├── 检查 dataCollectionEnabled
        │
        ├── 【条件满足】
        │       ├── Flutter 页面 → 创建 FlutterPageEvent
        │       └── 原生页面   → 创建 PageEvent
        │       └── 写入磁盘 AnalyticsCore.writeEventToDisk()
        │
        └── 【条件不满足】
                └── 缓存到 pagesCacheOnBackground
```

### 配置检查逻辑

```typescript
static sendNativePage(pageInfo: PageInfo) {
  // 1. 基础信息设置
  pageInfo.timestamp = Date.now()
  AutotrackPage.lastNativePage = pageInfo

  let context = GrowingContext.getDefaultContext() as GrowingContext
  if (context == undefined) {
    return
  }

  // 2. 无埋点总开关检查
  if (!context.config.autotrackEnabled) {
    return
  }

  // 3. 全页面采集开关检查
  // 注意：该配置仅影响 NativePage，不影响 FlutterPage
  if (!context.config.autotrackAllPages) {
    // 若设置了页面别名，将继续发送该页面浏览事件
    if (!pageInfo.alias || (pageInfo.alias && pageInfo.alias.length == 0)) {
      return
    }
  }

  AutotrackPage.sendPage(pageInfo)
}
```

### 事件创建

#### 原生页面事件 (PageEvent)

```typescript
static create(path: string, title: string, attributes: AttributesType, 
              timestamp: number, context: GrowingContext): PageEvent {
  let event = new PageEvent()
  event.path = path
  event.title = title ?? undefined
  event.attributes = attributes
  event.timestamp = timestamp
  event.orientation = DeviceInfo.orientation
  event.eventType = EventType.Page

  // SaaS/NewSaaS 模式下记录来源页面
  if (context.config.mode == ConfigMode.SaaS || context.config.mode == ConfigMode.NewSaaS) {
    let lastPage = PageEvent.getLastPage(context)
    if (lastPage) {
      event.referralPage = lastPage.path
    }
    PageEvent.setLastPage(event, context)
  }

  return EventBuilder.build(event, context)
}
```

#### Flutter 页面事件 (FlutterPageEvent)

仅在 `mode == ConfigMode.NewSaaS` 且 `eventScene == EventScene.Flutter` 时创建，用于区分 Flutter 页面和原生页面的数据上报。

---

## 特殊场景处理

### 场景一: 后台回前台

**问题**: 应用从后台返回前台时，系统会触发页面事件，但此时 Session 可能处于后台状态

**解决方案**:

```
后台回前台
    │
    ├── 系统触发 navDestinationUpdate
    │       └── 生成 PageInfo 存入 deferNavDestinationPages
    │
    ├── 系统触发 routerPageUpdate
    │       ├── 发送 Router 页面事件
    │       └── 遍历 deferNavDestinationPages
    │           └── 依次发送 Navigation 页面事件
    │
    └── Session 切换到 Foreground
            └── 触发 EMIT_EVENT_SESSION_STATE_FOREGROUND
                └── resendPageFromCacheOnBackground()
                    └── 发送 pagesCacheOnBackground 中的事件
```

**代码注释**:
```typescript
// 注意：这里假设应用导航架构是 router 嵌套 Navigation(推荐)
// 因此在后台回前台时先发送 routerPage，再发送 deferNavDestinationPage
// 如果应用导航架构是纯 Navigation(推荐)，后台回前台时不会发送当前正在显示的 NavDestinationPage
```

### 场景二: SDK 延迟初始化

**问题**: 应用启动后用户立即切换页面，但 SDK 尚未初始化完成

**解决方案**:

```typescript
static generatePage(pageInfo: PageInfo) {
  if (AnalyticsCore.core.isInitializedSuccessfully()
    && Session.sessionState === SessionState.Foreground) {
    // SDK 已初始化且在前台，直接生成事件
    ...
  } else {
    // SDK 未初始化或在后台，缓存事件
    // https://github.com/growingio/growingio-sdk-harmonyos/pull/6#issuecomment-2232880146
    AutotrackPage.cachePageOnBackground(pageInfo)
  }
}
```

**事件重发机制**:
```typescript
static startSubscribeToEvent() {
  // SDK 初始化完成时重发缓存事件
  emitter.once(EMIT_EVENT_MAIN_TRACKER_INITIALIZE, 
               AutotrackPage.resendPageFromCacheOnBackground)
  // 应用切换到前台时重发缓存事件
  emitter.on(EMIT_EVENT_SESSION_STATE_FOREGROUND, 
             AutotrackPage.resendPageFromCacheOnBackground)
}
```

### 场景三: Navigation 返回首页

**问题**: 从 NavDestination 返回到 NavBar（首页）时，需要正确识别并发送 NavBar 的页面事件

**解决方案**:

```
首页 (NavBar)
    │
    ├── 跳转到 PageA
    │       ├── 触发 navDestinationSwitch
    │       │       ├── from: NavBar
    │       │       └── to: PageA
    │       │
    │       └── 将 NavBar 页面信息入栈 navBarStack
    │               └── _NavBarInfo(NavBarPageInfo, PageA_dstId)
    │
    └── 从 PageA 返回
            └── 触发 navDestinationSwitch
                    ├── from: PageA
                    └── to: "navBar" (字符串类型)
                    │
                    └── 从 navBarStack 中查找
                            └── 发送匹配的 NavBar 页面事件
```

### 场景四: 嵌套 Navigation

**问题**: 应用可能使用多层嵌套的 Navigation 结构

**解决方案**:

```typescript
// 从后往前遍历，子 NavBar 跳转更常见
for (let i = AutotrackPage.navBarStack.length - 1; i >= 0; i--) {
  let k = AutotrackPage.navBarStack[i]
  if (k.isEqual(fromInfo)) {
    k.refreshNavDestination(toInfo)
    break
  }
}
```

使用 `dstId`（NavDestinationId）来唯一标识和匹配页面，系统保证该 ID 全局唯一。

### 场景五: 全模态返回

**问题**: 使用全模态（Full Screen Modal）返回时，可能产生多余的 deferNavDestinationPages

**处理**:
```typescript
// 返回到首页时，清理当前 navBar 对应的 deferNavDestinationPage
for (let i = 0; i < AutotrackPage.deferNavDestinationPages.length; i++) {
  let p = AutotrackPage.deferNavDestinationPages[i]
  if (k.dstId == p.dstId) {
    AutotrackPage.deferNavDestinationPages.splice(i, 1)
    break
  }
}
```

---

## 配置与开关

### 相关配置项

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `autotrackEnabled` | boolean | false | 无埋点总开关 |
| `autotrackAllPages` | boolean | false | 自动采集所有页面开关 |

### 配置影响范围

```
autotrackEnabled = false
    └── 不发送任何无埋点页面事件

autotrackEnabled = true
    └── autotrackAllPages = true
            └── 发送所有页面事件
    └── autotrackAllPages = false
            └── 仅发送设置了别名的页面事件
```

### 页面参数配置

通过 Navigation 或 Router 的参数传递页面配置：

```typescript
// Navigation 方式
let destination = new NavPathInfo(name, {
  "growing_alias": "homePage",        // 页面别名
  "growing_title": "首页",            // 自定义标题
  "growing_attributes": {             // 页面属性
    "key1": "value1",
    "key2": 100
  }
})
this.pageStack.pushDestination(destination)

// Router 方式
router.pushUrl({
  url: path,
  params: {
    "growing_alias": "homePage",
    "growing_title": "首页",
    "growing_attributes": {
      "key1": "value1"
    }
  }
})
```

### 参数提取方法

```typescript
// 提取页面属性
static getAttributesFromNavInfoParameter(param: any): AttributesType {
  return niceTry(() => {
    if (param) {
      return param['growing_attributes'] || {}
    } else {
      return {}
    }
  }, {})
}

// 提取页面别名
static getAliasFromNavInfoParameter(param: any): string {
  return niceTry(() => {
    if (param) {
      return param['growing_alias'] || ''
    } else {
      return ''
    }
  }, '')
}

// 提取页面标题
static getTitleFromNavInfoParameter(param: any): string {
  return niceTry(() => {
    if (param) {
      return param['growing_title'] || ''
    } else {
      return ''
    }
  }, '')
}
```

---

## 总结

`AutotrackPage` 模块通过监听 HarmonyOS 的页面生命周期事件，实现了对 Navigation 和 Router 两种导航方式的统一页面浏览事件采集。其核心设计要点包括：

1. **双队列机制**: `deferNavDestinationPages` 解决事件顺序问题，`pagesCacheOnBackground` 解决初始化时机问题
2. **NavBar 栈管理**: `_NavBarInfo` 结构支持返回首页的正确事件发送
3. **灵活的页面配置**: 通过参数支持别名、标题、属性的自定义
4. **场景适配**: 针对后台回前台、延迟初始化、嵌套导航等特殊场景做了专门处理

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
