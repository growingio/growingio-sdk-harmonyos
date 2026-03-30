# Hybrid（混合应用）逻辑详解

> **模块归属**: 核心模块 (core)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/core/Hybrid.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 中 `Hybrid` 模块的逻辑实现。该模块负责实现原生应用与 H5 页面的数据打通，支持 WebView 中的无埋点数据采集和圈选功能。

## 目录

- [概述](#概述)
- [核心架构](#核心架构)
- [JSBridge 通信机制](#jsbridge-通信机制)
- [Hybrid 代理创建](#hybrid-代理创建)
- [事件分发处理](#事件分发处理)
- [SaaS 模式支持](#saas-模式支持)
- [WebView 圈选支持](#webview-圈选支持)
- [脚本注入机制](#脚本注入机制)
  - [onPageEnd API](#公共-api-接口)

---

## 概述

Hybrid 模块是 GrowingIO SDK 实现原生应用与 H5 页面数据打通的核心组件。通过 JavaScript Bridge（JSBridge）技术，实现：

1. **H5 无埋点采集**：WebView 中的页面浏览、点击事件自动采集
2. **数据一致性**：H5 页面使用原生 SDK 的设备和用户标识
3. **圈选支持**：H5 页面支持无埋点圈选功能
4. **用户状态同步**：登录状态在原生与 H5 之间双向同步

### 架构位置

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              H5 WebView                                  │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     GrowingIO H5 SDK                             │   │
│  │                                                                  │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                      │   │
│  │  │  PAGE    │  │  CLICK   │  │  CUSTOM  │                      │   │
│  │  │  EVENT   │  │  EVENT   │  │  EVENT   │                      │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘                      │   │
│  │       │             │             │                            │   │
│  │       └─────────────┴─────────────┘                            │   │
│  │                     │                                            │   │
│  │         JSBridge.postMessage()                                  │   │
│  │                     │                                            │   │
│  └─────────────────────┼────────────────────────────────────────────┘   │
└────────────────────────┼────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        HarmonyOS Native                                 │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    GrowingIO HarmonyOS SDK                       │   │
│  │                                                                  │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │   │
│  │  │   Hybrid    │  │  WebView    │  │  Analytics  │             │   │
│  │  │   Module    │◀─│  Controller │──│   Core      │             │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘             │   │
│  │         │                                                       │   │
│  │         ▼                                                       │   │
│  │  EventBuilder.build()                                           │   │
│  │         │                                                       │   │
│  │         ▼                                                       │   │
│  │  AnalyticsCore.writeEventToDisk()                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 核心架构

### 类关系图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Hybrid                                     │
│                   (NewSaaS/CDP 模式 Hybrid 处理类)                       │
├─────────────────────────────────────────────────────────────────────────┤
│  属性                                                                   │
│  ├── name: string = 'GrowingWebViewJavascriptBridge'                   │
│  ├── methodList: string[]              // JSBridge 方法列表             │
│  ├── controller: WebviewController     // WebView 控制器                │
│  ├── context: GrowingContext           // SDK 上下文                    │
│  └── configuration: string             // 配置信息 JSON                 │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  ├── getConfiguration()                // 获取配置信息                  │
│  ├── dispatchEvent()                   // 分发事件                      │
│  ├── onDomChanged()                    // DOM 变化通知                  │
│  ├── setNativeUserId()                 // 设置用户 ID                   │
│  ├── setNativeUserIdAndUserKey()       // 设置用户 ID 和 Key            │
│  ├── clearNativeUserId()               // 清除用户 ID                   │
│  └── clearNativeUserIdAndUserKey()     // 清除用户 ID 和 Key            │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ 继承/区分
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            SaaSHybrid                                   │
│                      (SaaS 模式 Hybrid 处理类)                           │
├─────────────────────────────────────────────────────────────────────────┤
│  属性                                                                   │
│  ├── name: string = '_vds_bridge'                                       │
│  ├── methodList: string[]              // SaaS 专用方法列表             │
│  ├── webviewId?: string                // WebView 唯一标识              │
│  └── static _saasHybrids: SaaSHybrid[] // 所有 SaaS Hybrid 实例列表   │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  ├── saveEvent()                       // 保存事件                      │
│  ├── setUserId()                       // 设置用户 ID                   │
│  ├── clearUserId()                     // 清除用户 ID                   │
│  ├── setVisitor()                      // 设置访客属性                  │
│  ├── hoverNodes()                      // 圈选悬停节点                  │
│  ├── webCircleHybridEvent()            // 圈选事件                      │
│  └── onDOMChanged()                    // DOM 变化通知                  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ 使用
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      SaaSHybridEventHandler                             │
│                     (SaaS 事件处理器)                                    │
├─────────────────────────────────────────────────────────────────────────┤
│  方法                                                                   │
│  └── eventHandler()                    // 处理 SaaS 类型事件            │
└─────────────────────────────────────────────────────────────────────────┘
```

### Hybrid 事件类

```
┌─────────────────────────────────────────────────────────┐
│                      HybridEvent                        │
│                       (接口)                             │
├─────────────────────────────────────────────────────────┤
│  path: string | undefined                               │
│  query: string | undefined                              │
└─────────────────────────────────────────────────────────┘
                             △
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ HybridPageEvent │  │ HybridCustomEvent│  │HybridViewElement│
├─────────────────┤  ├─────────────────┤  │    Event        │
├─────────────────┤  ├─────────────────┤  ├─────────────────┤
│ title           │  │ eventName       │  │ textValue       │
│ referralPage    │  │ pageShowTimestamp│  │ xpath          │
│ protocolType    │  │                 │  │ xcontent        │
│ orientation     │  │                 │  │ index           │
└─────────────────┘  └─────────────────┘  │ hyperlink       │
                                          └─────────────────┘
```

---

## JSBridge 通信机制

### 通信原理

```
┌─────────────────────┐                  ┌─────────────────────┐
│      H5 Page        │                  │   HarmonyOS Native  │
│                     │                  │                     │
│  ┌───────────────┐  │                  │  ┌───────────────┐  │
│  │    H5 SDK     │  │                  │  │  Hybrid Class │  │
│  │               │  │   JSBridge       │  │               │  │
│  │ window.Growing│──┼─────────────────▶│  │ @JavaScript    │  │
│  │ WebViewJS     │  │  MethodChannel   │  │ Proxy          │  │
│  │ Bridge        │  │                  │  │               │  │
│  │               │◀─┼──────────────────│  │               │  │
│  │  postMessage()│  │   Return Value   │  │  getConfig()   │  │
│  └───────────────┘  │                  │  └───────────────┘  │
└─────────────────────┘                  └─────────────────────┘
```

### JSBridge 方法列表

#### NewSaaS/CDP 模式

| 方法名 | 方向 | 说明 |
|--------|------|------|
| `getConfiguration` | Native → H5 | 获取 SDK 配置信息 |
| `dispatchEvent` | H5 → Native | 分发事件数据 |
| `onDomChanged` | H5 → Native | DOM 结构变化通知 |
| `setNativeUserId` | H5 → Native | 设置登录用户 ID |
| `setNativeUserIdAndUserKey` | H5 → Native | 设置用户 ID 和 Key |
| `clearNativeUserId` | H5 → Native | 清除登录用户 |
| `clearNativeUserIdAndUserKey` | H5 → Native | 清除用户和 Key |

#### SaaS 模式

| 方法名 | 方向 | 说明 |
|--------|------|------|
| `saveEvent` | H5 → Native | 保存事件数据 |
| `setUserId` | H5 → Native | 设置用户 ID |
| `clearUserId` | H5 → Native | 清除用户 ID |
| `setVisitor` | H5 → Native | 设置访客属性 |
| `hoverNodes` | H5 → Native | 圈选悬停节点 |
| `webCircleHybridEvent` | H5 → Native | 圈选事件 |
| `onDOMChanged` | H5 → Native | DOM 变化通知 |

---

## Hybrid 代理创建

### 创建流程

```
应用创建 WebView
        │
        ▼
┌─────────────────────┐
│ createHybridProxy() │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 检查 SDK Mode       │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌────────┐
│NewSaaS │ │  SaaS  │
└───┬────┘ └───┬────┘
    │          │
    ▼          ▼
┌────────┐ ┌────────┐
│ Hybrid │ │SaaSHybrid
│实例    │ │实例    │
└───┬────┘ └───┬────┘
    │          │
    └────┬─────┘
         │
         ▼
┌─────────────────────┐
│ JavaScriptProxyType │
│ 返回给应用注册      │
└─────────────────────┘
```

### 代码实现

```typescript
static createHybridProxy(
  controller: webview.WebviewController, 
  webviewId: string | undefined, 
  context: GrowingContext
): JavaScriptProxyType {
  
  if (context.config.mode == ConfigMode.NewSaaS) {
    // NewSaaS 模式
    let hybrid = new Hybrid(controller, context)
    if (webviewId && webviewId.length > 0) {
      Hybrid._hybrids[webviewId] = hybrid  // 注册到全局管理
    }
    return {
      object: hybrid,
      name: hybrid.name,
      methodList: hybrid.methodList,
      controller: controller
    }
    
  } else if (context.config.mode == ConfigMode.SaaS && context.config.hybridAutotrackEnabled) {
    // SaaS 模式且开启 Hybrid 无埋点
    let hybrid = new SaaSHybrid(controller, context, webviewId)
    return {
      object: hybrid,
      name: hybrid.name,
      methodList: hybrid.methodList,
      controller: controller
    }
    
  } else {
    // CDP 模式 或 SaaS 非无埋点模式
    let hybrid = new Hybrid(controller, context)
    return {
      object: hybrid,
      name: hybrid.name,
      methodList: hybrid.methodList,
      controller: controller
    }
  }
}
```

### 配置信息

```typescript
constructor(controller: webview.WebviewController, context: GrowingContext) {
  this.controller = controller
  this.context = context
  this.configuration = JSON.stringify({
    "projectId": context.config.accountId,           // 项目 ID
    "dataSourceId": context.config.dataSourceId,     // 数据源 ID
    "appPackage": AppInfo.domain,                    // 应用包名
    "appId": context.config.urlScheme,               // URL Scheme
    "nativeSdkVersion": SDK_VERSION,                 // SDK 版本
    "nativeSdkVersionCode": 1                        // 版本号
  })
}
```

---

## 事件分发处理

### 事件处理流程

```
H5 触发事件
        │
        ▼
┌─────────────────────┐
│ window.Growing      │
│ WebViewJSBridge     │
│ .postMessage()      │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ dispatchEvent()     │
│ (Hybrid Class)      │
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
  【启用】   【禁用】
    │         │
    │         ▼
    │    【返回，不处理】
    │
    ▼
┌─────────────────────┐
│ 解析 eventString    │
│ JSON.parse()        │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 根据 eventType      │
│ 分发处理            │
└────────┬────────────┘
         │
    ┌────┼────┬────────┬──────────┐
    ▼    ▼    ▼        ▼          ▼
┌─────┐┌─────┐┌─────┐┌─────────┐┌──────────┐
│PAGE ││CLICK││CUSTOM││LOGIN_USER││  SaaS    │
│     ││     ││     ││ATTRIBUTES││  EVENT   │
└──┬──┘└──┬──┘└──┬──┘└────┬────┘└────┬─────┘
   │      │      │        │          │
   └──────┴──────┴────────┴──────────┘
                  │
                  ▼
         ┌────────────────┐
         │ writeEventToDisk│
         │ EventScene.Hybrid
         └────────────────┘
```

### 事件类型处理

```typescript
dispatchEvent = (eventString: string): void => {
  try {
    LogUtil.info(() => "[Hybrid] dispatchEvent: " + eventString)

    // 1. 检查数据采集开关
    if (!this.context.config.dataCollectionEnabled) {
      LogUtil.info(() => 'Failed to dispatch hybrid event, dataCollectionEnabled is false')
      return
    }

    // 2. 解析事件
    let event: Record<string, Object> = JSON.parse(eventString)
    let eventType: string = event.eventType as string

    // 3. 根据类型分发
    if (eventType == EventType.Custom) {
      // 自定义事件
      let e = HybridCustomEvent.create(
        event.eventName as string,
        event.attributes as AttributesType,
        event.path as string,
        event.query as string,
        event.timestamp as number,
        event.domain as string,
        this.context
      )
      AnalyticsCore.writeEventToDisk(e, this.context, EventScene.Hybrid)
      
    } else if (eventType == EventType.Page) {
      // 页面事件
      let e = HybridPageEvent.create(
        event.title as string,
        event.referralPage as string,
        event.protocolType as string,
        event.attributes as AttributesType,
        event.path as string,
        event.query as string,
        event.timestamp as number,
        event.domain as string,
        this.context
      )
      AnalyticsCore.writeEventToDisk(e, this.context, EventScene.Hybrid)
      
    } else if (eventType == EventType.ViewClick || eventType == EventType.ViewChange) {
      // 点击/变化事件
      let e = HybridViewElementEvent.create(
        event.textValue as string,
        event.xpath as string,
        event.xcontent as string,
        event.index as number,
        event.hyperlink as string,
        event.attributes as AttributesType,
        event.path as string,
        event.query as string,
        event.timestamp as number,
        event.domain as string,
        eventType,
        this.context
      )
      AnalyticsCore.writeEventToDisk(e, this.context, EventScene.Hybrid)
      
    } else if (eventType == EventType.LoginUserAttributes) {
      // 用户属性事件
      let e = LoginUserAttributesEvent.create(
        event.attributes as AttributesType, 
        this.context
      )
      AnalyticsCore.writeEventToDisk(e, this.context, EventScene.Hybrid)
      
    } else if (this.context.config.mode == ConfigMode.SaaS) {
      // SaaS 模式其他事件
      SaaSHybridEventHandler.eventHandler(event, this.context)
    }
    
  } catch (e) {
    LogUtil.error(() => "Failed to dispatch event: " + e.message)
  }
}
```

---

## SaaS 模式支持

### SaaS Hybrid 实现

SaaS 模式使用独立的 `SaaSHybrid` 类，提供更精简的 JSBridge 接口：

```typescript
class SaaSHybrid {
  name: string = '_vds_bridge'
  methodList: string[] = [
    'saveEvent',           // 保存事件
    'setUserId',           // 设置用户 ID
    'clearUserId',         // 清除用户 ID
    'setVisitor',          // 设置访客属性
    'hoverNodes',          // 圈选悬停节点
    'webCircleHybridEvent',// 圈选事件
    'onDOMChanged',        // DOM 变化通知
  ]
  
  // ... 方法实现
}
```

### SaaS 事件处理

```typescript
class SaaSHybridEventHandler {
  static eventHandler(event: Record<string, Object>, context: GrowingContext) {
    let t: string = String(event.t ?? '')           // 事件类型标识
    let attributes: AttributesType = event.var ?? {} // 事件属性
    let d = AppInfo.domain + '::' + String(event.d ?? '')  // 域名
    
    if (t == 'clck' || t == 'chng') {
      // 点击/变更无埋点事件，由 AutotrackClick 模块处理
    } else if (t == 'cstm' || t == 'pvar' || t == 'page') {
      let p = String(event.p ?? '')  // 页面路径
      let lastPage = PageEvent.getLastPage(context)
      if (lastPage) {
        // 组合原生页面和 H5 页面路径
        p = (lastPage.path ?? '') + '::' + p
      }
      
      if (t == 'page') {
        // 页面事件
        let rp = String(event.rp ?? '')
        let tl = String(event.tl ?? '')
        if (lastPage) {
          rp = (lastPage.path ?? '') + '::' + rp
          tl = (lastPage.title ?? '') + '::' + tl
        }
        let e = HybridPageEvent.create(tl, rp, '', event.var, p, event.q, event.tm, d, context)
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
        
      } else if (t == 'cstm') {
        // 自定义事件
        let eventName: string = event.n as string
        if (eventName.length > 0) {
          let e = HybridCustomEvent.create(eventName, attributes, p, event.q, event.tm, d, context)
          e.pageShowTimestamp = event.ptm as number
          AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
        }
        
      } else if (t == 'pvar') {
        // 页面变量
        let e = SaaSPageVarEvent.create(attributes, p, event.ptm, context)
        e.domain = d
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      }
      
    } else if (Object.keys(attributes).length > 0) {
      // 用户属性类事件
      if (t == 'ppl') {
        let e = LoginUserAttributesEvent.create(attributes, context)
        e.domain = d
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
        
      } else if (t == 'evar') {
        let e = SaaSEvarEvent.create(attributes, context)
        e.domain = d
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
        
      } else if (t == 'vstr') {
        let e = SaaSVisitorEvent.create(attributes, context)
        e.domain = d
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      }
    }
  }
}
```

### 页面路径组合规则

SaaS 模式下，H5 页面路径会与原生页面路径组合：

```
原生页面路径: /pages/Index
H5 页面路径: /home.html

组合后: /pages/Index::/home.html
```

---

## WebView 圈选支持

### DOM 树获取

Hybrid 模块支持获取 H5 页面的 DOM 树，用于圈选功能：

```typescript
static async getDomTreeById(
  webviewId: string,           // WebView 唯一标识
  left: number,                // 区域左坐标
  top: number,                 // 区域上坐标
  width: number,               // 区域宽度
  height: number,              // 区域高度
): Promise<string> {
  
  // 1. 获取 Hybrid 实例
  let hybrid = Hybrid._hybrids[webviewId]
  if (hybrid == null || hybrid == undefined) {
    return ''
  }
  
  // 2. 检查是否为主实例（子实例不支持圈选）
  if (!GrowingContext.isDefaultContext(hybrid.context)) {
    return ''
  }
  
  // 3. 执行 JavaScript 获取 DOM 树
  let controller = hybrid.controller
  let zLevel = 100
  let js = `window.GrowingWebViewJavascriptBridge.getDomTree(${left}, ${top}, ${width}, ${height}, ${zLevel})`
  let elements = await niceTryAsync(() => controller.runJavaScript(js))
  
  return elements ?? ''
}
```

### DOM 变化通知

当 H5 页面 DOM 结构变化时，通知圈选模块刷新：

```typescript
onDomChanged = (): void => {
  Plugins.onWebViewDomTreeChanged()
}
```

### 使用场景

在 `CircleElement` 中遍历到 WebView 元素时：

```typescript
if (nodeType == CIRCLE_NODE_WEBVIEW) {
  let webviewId = ''
  if (e.attrs.id && e.attrs.id.length > 0) {
    webviewId = e.attrs.id
    
    // 获取 H5 DOM 树
    let domTree = await Hybrid.getDomTreeById(
      webviewId, 
      element.left, 
      element.top, 
      element.width, 
      element.height
    )
    
    try {
      element.webView = JSON.parse(domTree) ?? undefined
    } catch {
      element.webView = undefined
    }
  }
}
```

---

## 脚本注入机制

### SaaS 模式脚本注入

SaaS 模式支持在 WebView 加载时自动注入 Hybrid JS SDK：

#### Document Start 脚本

```typescript
static javaScriptOnDocumentStart(
  context: GrowingContext,
  scriptRules: Array<string> = ['*'],
  saasJavaScriptConfig: SaaSJavaScriptConfigType = {
    hashTagEnabled: false,
    impEnabled: false
  }
): Array<ScriptItem> {
  
  let scripts: Array<ScriptItem> = []
  
  if (context.config.mode == ConfigMode.SaaS && context.config.hybridAutotrackEnabled) {
    // 1. 注入配置
    let config: AttributesType = {
      enableHT: saasJavaScriptConfig.hashTagEnabled,
      disableImp: !saasJavaScriptConfig.impEnabled,
      phoneWidth: DeviceInfo.screenWidth ?? DeviceInfo.defaultScreenWidth,
      phoneHeight: DeviceInfo.screenHeight ?? DeviceInfo.defaultScreenHeight,
      protocolVersion: 1
    }
    scripts.push({
      script: 'window._vds_hybrid_config = ' + JSON.stringify(config),
      scriptRules: scriptRules
    })

    // 2. 注入原生信息
    let nativeInfo: AttributesType = {
      ai: context.config.accountId,
      d: AppInfo.domain,
      u: DeviceInfo.deviceId,
      s: Session.getSessionId(context) ?? '',
      cs1: UserIdentifier.getUser(context)?.userId ?? '',
      p: PageEvent.getLastPage(context)?.path ?? ''   // 当前页面路径
    }
    scripts.push({
      script: 'window._vds_hybrid_native_info = ' + JSON.stringify(nativeInfo),
      scriptRules: scriptRules
    })
  }
  
  return scripts
}
```

#### Document End 脚本

```typescript
static javaScriptOnDocumentEnd(
  context: GrowingContext,
  scriptRules: Array<string> = ['*']
): Array<ScriptItem> {
  
  let scripts: Array<ScriptItem> = []
  
  if (context.config.mode == ConfigMode.SaaS && context.config.hybridAutotrackEnabled) {
    let sdkVersion = SDK_VERSION
    let sdkPlatform = SDK_PLATFORM
    
    // Hybrid JS SDK 地址
    let hybridSrc = 'https://assets.giocdn.com/sdk/hybrid/2.0/gio_hybrid.min.js?sdkVer=' 
      + sdkVersion + '&platform=' + sdkPlatform
    
    // 包装脚本：确保在页面加载完成后注入
    let wrapper = 'javascript:(function(){try{' 
      + 'if(window.self==window.top||document.head.childElementCount||'
      + 'document.body.childElementCount){'
      + 'var p=document.createElement(\'script\');p.src=\'gio_hybrid_src\';'
      + 'document.head.appendChild(p);'
      + '}}catch(e){}})()'
    
    let hybridJavaScript = wrapper.replace('gio_hybrid_src', hybridSrc)
    
    scripts.push({
      script: hybridJavaScript,
      scriptRules: scriptRules
    })
  }
  
  return scripts
}
```

### 公共 API 接口

SDK 对外暴露 Hybrid 脚本注入接口：

```typescript
// GrowingAnalytics.ets

/**
 * 获取 Document Start 时注入的脚本
 * @param scriptRules 脚本规则数组
 * @param saasJavaScriptConfig SaaS 配置
 */
static javaScriptOnDocumentStart(
  scriptRules?: Array<string>,
  saasJavaScriptConfig?: SaaSJavaScriptConfigType
): Array<ScriptItem> {
  return AnalyticsCore.core.javaScriptOnDocumentStart(scriptRules, saasJavaScriptConfig)
}

/**
 * 获取 Document End 时注入的脚本
 * @param scriptRules 脚本规则数组
 */
static javaScriptOnDocumentEnd(scriptRules?: Array<string>): Array<ScriptItem> {
  return AnalyticsCore.core.javaScriptOnDocumentEnd(scriptRules)
}

/**
 * 创建 Hybrid 代理
 * @param controller WebView 控制器
 * @param webviewId WebView 唯一标识
 */
static createHybridProxy(
  controller: webview.WebviewController,
  webviewId?: string
): JavaScriptProxyType | undefined {
  return AnalyticsCore.core.createHybridProxy(controller, webviewId)
}

/**
 * WebView 页面加载完成时调用，注入圈选插件
 * @param controller WebView 控制器
 * @param webviewId WebView 唯一标识
 */
static onPageEnd(
  controller: webview.WebviewController,
  webviewId?: string
): Promise<void> {
  return AnalyticsCore.core.onPageEnd(controller, webviewId)
}
```

### 使用示例

```typescript
// 在 WebView 组件中使用
Web({ src: 'https://example.com', controller: this.controller })
  .javaScriptProxy(GrowingAnalytics.createHybridProxy(this.controller, 'webview_1'))
  .javaScriptOnDocumentStart(
    GrowingAnalytics.javaScriptOnDocumentStart(),
    GrowingAnalytics.javaScriptOnDocumentEnd()
  )
```

---

## 用户状态同步

### 登录状态同步

H5 页面可以通过 JSBridge 同步登录状态到原生端：

```typescript
// 设置用户 ID
setNativeUserId = (userId: string): void => {
  LogUtil.info(() => "[Hybrid] setNativeUserId: " + userId)
  UserIdentifier.setLoginUserId(userId, '', this.context)
}

// 设置用户 ID 和 Key
setNativeUserIdAndUserKey = (userId: string, userKey: string): void => {
  LogUtil.info(() => "[Hybrid] setNativeUserId: " + userId + " and userKey: " + userKey)
  UserIdentifier.setLoginUserId(userId, userKey, this.context)
}

// 清除用户 ID
clearNativeUserId = (): void => {
  LogUtil.info(() => "[Hybrid] clearNativeUserId")
  UserIdentifier.setLoginUserId('', '', this.context)
}

// 清除用户 ID 和 Key
clearNativeUserIdAndUserKey = (): void => {
  LogUtil.info(() => "[Hybrid] clearNativeUserIdAndUserKey")
  UserIdentifier.setLoginUserId('', '', this.context)
}
```

---

## 总结

Hybrid 模块实现了原生应用与 H5 页面的数据打通，是 GrowingIO SDK 混合开发支持的核心组件。其主要特点包括：

1. **双模式支持**：NewSaaS/CDP 模式和 SaaS 模式有不同的实现策略
2. **JSBridge 通信**：通过 JavaScript Proxy 实现原生与 H5 的双向通信
3. **事件统一处理**：H5 事件使用与原生相同的事件构建和存储流程
4. **圈选支持**：支持获取 H5 DOM 树，实现 H5 页面的无埋点圈选
5. **脚本注入**：SaaS 模式支持自动注入 Hybrid JS SDK
6. **状态同步**：登录状态可以在原生和 H5 之间双向同步

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
