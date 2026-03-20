# Event 系统逻辑详解

> **模块归属**: 核心模块 (event)  
> **源文件**: 
> - `GrowingAnalytics/src/main/ets/components/event/Event.ets`
> - `GrowingAnalytics/src/main/ets/components/event/EventBuilder.ets`
> - `GrowingAnalytics/src/main/ets/components/event/EventPersistence.ets`
> - `GrowingAnalytics/src/main/ets/components/event/EventSender.ets`

本文档详细描述 GrowingIO HarmonyOS SDK 中 **Event 系统** 的逻辑实现，包括事件定义、构建、持久化和发送的完整流程。

## 目录

- [概述](#概述)
- [事件定义](#事件定义)
- [事件构建流程](#事件构建流程)
- [事件持久化](#事件持久化)
- [事件发送机制](#事件发送机制)
- [事件序列号管理](#事件序列号管理)
- [事件大小限制](#事件大小限制)

---

## 概述

Event 系统是 GrowingIO SDK 的核心数据处理模块，负责：

1. **事件定义**：定义各类事件的数据结构和类型
2. **事件构建**：填充事件的通用字段（设备信息、用户信息等）
3. **事件持久化**：将事件保存到本地数据库
4. **事件发送**：批量发送事件到服务器

### 事件生命周期

```
事件创建 (CustomEvent.create/PageEvent.create)
        │
        ▼
┌─────────────────────┐
│ EventBuilder.build()│  填充通用字段
│ • 设备信息          │
│ • 应用信息          │
│ • 用户信息          │
│ • 会话信息          │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ EventPersistence    │
│ .fromEvent()        │  转换为持久化格式
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ EventDatabase       │
│ .writeEvent()       │  写入 SQLite
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ EventSender         │
│ .sendEvent()        │  批量发送
│ (定时/即时触发)     │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Network.request()   │  HTTP 请求
└─────────────────────┘
```

---

## 事件定义

### Event 基类

所有事件都继承自 `Event` 抽象基类，包含以下字段：

```typescript
abstract class Event {
  // 基础字段
  userId: string | undefined              // 登录用户 ID
  userKey: string | undefined             // 用户 Key（ID Mapping）
  sessionId: string = ''                  // 会话 ID
  eventSequenceId: number = 0             // 事件序列号
  timestamp: number = 0                   // 时间戳
  sdkVersion: string = ''                 // SDK 版本
  dataSourceId: string = ''               // 数据源 ID
  urlScheme: string = ''                  // URL Scheme
  attributes: AttributesType | undefined  // 自定义属性
  eventType: EventType = EventType.Visit  // 事件类型

  // 位置信息
  latitude: number | undefined            // 纬度
  longitude: number | undefined           // 经度

  // 设备信息
  deviceId: string = ''                   // 设备 ID
  platform: string = ''                   // 平台
  platformVersion: string | undefined     // 平台版本
  screenHeight: number | undefined        // 屏幕高度
  screenWidth: number | undefined         // 屏幕宽度
  deviceBrand: string | undefined         // 设备品牌
  deviceModel: string | undefined         // 设备型号
  deviceType: string | undefined          // 设备类型
  language: string | undefined            // 语言
  timezoneOffset: string | undefined      // 时区偏移
  networkState: string | undefined        // 网络状态

  // 应用信息
  domain: string = ''                     // 应用包名
  appState: string = ''                   // 应用状态（FOREGROUND/BACKGROUND）
  appName: string = ''                    // 应用名称
  appVersion: string = ''                 // 应用版本
  appChannel: string | undefined          // 应用渠道

  // 序列化方法
  toSerialize(context: GrowingContext): string
}
```

### 事件类型枚举

```typescript
enum EventType {
  Visit = 'VISIT',                        // 访问事件
  Custom = 'CUSTOM',                      // 自定义事件
  LoginUserAttributes = 'LOGIN_USER_ATTRIBUTES',  // 登录用户属性
  Page = 'PAGE',                          // 页面浏览事件
  ViewClick = 'VIEW_CLICK',               // 点击事件
  ViewChange = 'VIEW_CHANGE',             // 元素变化事件
  AppClosed = 'APP_CLOSED',               // 应用关闭事件

  // SaaS 模式专用
  SaaS_Evar = 'evar',                     // 转化变量
  SaaS_Vstr = 'vstr',                     // 访问者变量
  SaaS_Pvar = 'pvar',                     // 页面变量
}
```

### 事件场景枚举

```typescript
enum EventScene {
  Native = 0,    // 原生事件
  Hybrid,        // H5/Hybrid 事件
  Flutter        // Flutter 事件
}
```

### 具体事件类型

| 事件类 | 说明 | 特有字段 |
|--------|------|----------|
| `CustomEvent` | 自定义事件 | `eventName: string` |
| `PageEvent` | 页面浏览事件 | `path`, `title`, `orientation`, `referralPage` |
| `HybridPageEvent` | H5 页面事件 | `title`, `referralPage`, `protocolType`, `path`, `query` |
| `FlutterPageEvent` | Flutter 页面事件 | `path`, `title`, `orientation`, `referralPage` |
| `ViewElementEvent` | 点击/变化事件 | `textValue`, `xpath`, `xcontent`, `index` |
| `HybridViewElementEvent` | H5 点击事件 | `textValue`, `xpath`, `xcontent`, `index`, `hyperlink` |
| `HybridCustomEvent` | H5 自定义事件 | `eventName`, `pageShowTimestamp` |
| `LoginUserAttributesEvent` | 登录用户属性 | 无 |
| `AppClosedEvent` | 应用关闭 | `eventDuration` |

---

## 事件构建流程

### EventBuilder.build()

事件构建器负责为事件填充通用字段：

```typescript
class EventBuilder {
  static build<T extends Event>(event: T, context: GrowingContext): T {
    // 1. 会话和应用状态
    event.sessionId = Session.getSessionId(context)!
    event.appState = Session.sessionState === SessionState.Foreground ? 'FOREGROUND' : 'BACKGROUND'
    
    // 2. 时间和版本
    event.timestamp = event.timestamp > 0 ? event.timestamp : Date.now()
    event.sdkVersion = SDK_VERSION

    // 3. 设备信息
    event.deviceId = DeviceInfo.deviceId
    event.platform = DeviceInfo.platform
    event.platformVersion = DeviceInfo.platformVersion
    event.screenHeight = DeviceInfo.screenHeight
    event.screenWidth = DeviceInfo.screenWidth
    event.deviceBrand = DeviceInfo.deviceBrand
    event.deviceModel = DeviceInfo.deviceModel
    event.deviceType = DeviceInfo.deviceType
    event.language = DeviceInfo.language
    event.timezoneOffset = DeviceInfo.timezoneOffset
    event.networkState = DeviceInfo.networkState

    // 4. 应用信息
    event.domain = event.domain || AppInfo.domain
    event.appChannel = AppInfo.appChannel
    event.appName = AppInfo.appName
    event.appVersion = AppInfo.appVersion

    // 5. 配置信息
    event.dataSourceId = context.config.dataSourceId
    event.urlScheme = context.config.urlScheme

    // 6. 位置信息
    event.latitude = Math.abs(AnalyticsCore.location.latitude) > 0 
      ? AnalyticsCore.location.latitude 
      : undefined
    event.longitude = Math.abs(AnalyticsCore.location.longitude) > 0 
      ? AnalyticsCore.location.longitude 
      : undefined

    // 7. 用户信息
    let user = UserIdentifier.getUser(context)!
    event.userId = user.userId.length > 0 ? user.userId : undefined
    if (context.config.idMappingEnabled) {
      event.userKey = user.userKey.length > 0 ? user.userKey : undefined
    }

    // 8. 通用属性合并
    let attributes = GrowingGeneralProps.getGeneralProps()
    if (event.attributes) {
      attributes = Util.concatObject(attributes, event.attributes)
    }
    event.attributes = Util.serializableAttributes(attributes)

    // 9. 事件序列号
    event.eventSequenceId = EventBuilder.updateEventSequenceId(context)

    return event
  }
}
```

### 构建流程图

```
事件子类创建
(CustomEvent.create)
        │
        ▼
┌─────────────────────┐
│ 设置事件特有字段    │
│ • eventName         │
│ • attributes        │
│ • timestamp         │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ EventBuilder.build()│
└────────┬────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 1. 基础信息                             │
│    • sessionId (从 Session 获取)        │
│    • appState (FOREGROUND/BACKGROUND)   │
│    • timestamp (使用传入值或当前时间)   │
│    • sdkVersion                         │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 2. 设备信息 (从 DeviceInfo 获取)        │
│    • deviceId, platform                 │
│    • platformVersion                    │
│    • screenWidth, screenHeight          │
│    • deviceBrand, deviceModel           │
│    • deviceType, language               │
│    • timezoneOffset, networkState       │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 3. 应用信息 (从 AppInfo 获取)           │
│    • domain, appName                    │
│    • appVersion, appChannel             │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 4. 用户信息 (从 UserIdentifier 获取)    │
│    • userId                             │
│    • userKey (ID Mapping 启用时)        │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 5. 位置信息 (从 AnalyticsCore 获取)     │
│    • latitude, longitude                │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 6. 通用属性合并                         │
│    • 获取 GeneralProps                  │
│    • 合并事件自定义属性                 │
│    • 序列化处理                         │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 7. 更新事件序列号                       │
│    • 从 SharedPreferences 读取          │
│    • 自增并保存                         │
└─────────────────────────────────────────┘
         │
         ▼
    事件构建完成
```

---

## 事件持久化

### EventPersistence 类

用于事件的本地持久化存储，标记为 `@Sendable` 支持跨线程传递：

```typescript
@Sendable
class EventPersistence {
  uuid: string           // 事件唯一标识
  data: string           // 事件序列化后的 JSON 字符串
  eventType: string      // 事件类型
  sdkVersion: string     // SDK 版本
  accountId: string      // 项目 ID
  dataSourceId: string   // 数据源 ID

  static fromEvent<T extends Event>(event: T, context: GrowingContext): EventPersistence {
    // 1. 验证事件大小
    let validation = Util.validateEventSize(event)
    if (!validation.isValid) {
      LogUtil.warn(() => `Event size exceeds limit`)
      event.attributes = validation.attributes
    }

    // 2. 生成 UUID
    let uuid = util.generateRandomUUID(false)

    // 3. 序列化事件
    let data = event.toSerialize(context)

    // 4. 创建持久化对象
    let e = new EventPersistence(
      uuid,
      data,
      event.eventType,
      event.sdkVersion,
      context.config.accountId,
      context.config.dataSourceId
    )
    return e
  }
}
```

### 持久化流程

```
EventBuilder.build() 返回事件
        │
        ▼
┌─────────────────────┐
│ AnalyticsCore       │
│ .writeEventToDisk() │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ EventPersistence    │
│ .fromEvent()        │
│ • 验证大小          │
│ • 生成 UUID         │
│ • 序列化            │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ EventDatabase       │
│ .writeEvent()       │
│ 插入 SQLite         │
└─────────────────────┘
```

---

## 事件发送机制

### EventSender 类型

```typescript
enum EventSenderType {
  NewSaaS = 0,     // NewSaaS 模式
  SaaS_PV,         // SaaS 页面事件
  SaaS_CSTM        // SaaS 自定义事件
}
```

### URL 路径配置

| 类型 | URL 路径 | 说明 |
|------|---------|------|
| NewSaaS | `/v3/projects/accountId/collect` | 统一上报接口 |
| SaaS_PV | `/v3/accountId/harmonyos/pv` | 页面/访问事件 |
| SaaS_CSTM | `/v3/accountId/harmonyos/cstm` | 自定义事件 |

### 发送流程

```typescript
class EventSender {
  async sendEvent(gContext?: GrowingContext) {
    // 1. 防止并发发送
    if (this.isUploading) {
      return
    }
    this.isUploading = true

    // 2. 获取上下文
    let context = gContext ?? GrowingContext.getContext(this.trackerId)

    // 3. 从数据库获取事件
    let events = await EventDatabase.getEventsByCount(
      REQUEST_MAX_EVENT_COUNT,    // 最大 500 条
      REQUEST_MAX_EVENT_SIZE,     // 最大 2MB
      context,
      this.eventTypes             // 过滤事件类型
    )
    if (events.length == 0) {
      this.isUploading = false
      return
    }

    // 4. 发送请求
    try {
      let response = await Network.request(events, this.urlPath, context)
      Plugins.onResponseReceive(response)

      if (response.statusCode >= 200 && response.statusCode < 400) {
        // 5. 发送成功，删除已发送事件
        await EventDatabase.removeEvents([...events])
        Plugins.onEventsDidSend(events, response.request)
        Plugins.onEventsRemoveFromDisk(events.map(e => e.uuid))
        this.isUploading = false

        // 6. 检查是否还有更多事件
        let count = await EventDatabase.countOfEvents(context, this.eventTypes)
        if (count > REQUEST_MAX_EVENT_COUNT) {
          this.sendEvent(context)  // 递归继续发送
        }
      } else {
        this.isUploading = false
      }
    } catch (e) {
      this.isUploading = false
    }
  }
}
```

### 发送流程图

```
定时器触发 / VISIT 事件触发
        │
        ▼
┌─────────────────────┐
│ EventSender         │
│ .sendEvent()        │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 检查 isUploading    │
│ 防止并发            │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ EventDatabase       │
│ .getEventsByCount() │
│ 读取最多 500 条     │
│ 或 2MB 数据         │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 无事件？            │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【有】    【无】
    │         │
    │         ▼
    │    结束
    ▼
┌─────────────────────┐
│ Network.request()   │
│ HTTP POST 请求      │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 响应状态码          │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【2xx】   【其他】
    │         │
    ▼         ▼
 成功      失败
    │         │
    ▼         ▼
┌─────────┐ ┌─────────┐
│删除已发送│ │保留事件  │
│检查更多  │ │等待下次  │
└────┬────┘ └─────────┘
     │
     ▼
┌─────────────┐
│ 还有更多？  │
└──────┬──────┘
       │
  ┌────┴────┐
  ▼         ▼
【有】    【无】
  │         │
  ▼         ▼
递归发送   结束
```

---

## 事件序列号管理

### 序列号生成机制

事件序列号用于保证事件顺序，按项目+数据源维度独立计数：

```typescript
class EventBuilder {
  private static _eventSequenceIds: Record<string, number>

  private static updateEventSequenceId(context: GrowingContext): number {
    // 1. 获取当前序列号
    let sequenceId = EventBuilder.getEventSequenceId(context) + 1
    
    // 2. 更新内存缓存
    let key = context.config.accountId + '_' + context.config.dataSourceId
    EventBuilder._eventSequenceIds[key] = sequenceId
    
    // 3. 持久化到 SharedPreferences
    SharedPreferences.put(
      PREFERENCE_EVENT_SEQUENCE_ID, 
      JSON.stringify(EventBuilder._eventSequenceIds)
    )
    
    return sequenceId
  }

  private static getEventSequenceId(context: GrowingContext): number {
    // 首次加载从持久化存储读取
    if (!EventBuilder._eventSequenceIds) {
      let sequenceIdsString = SharedPreferences.getValue(
        PREFERENCE_EVENT_SEQUENCE_ID, 
        '{}'
      ) as string
      EventBuilder._eventSequenceIds = JSON.parse(sequenceIdsString)
    }

    let key = context.config.accountId + '_' + context.config.dataSourceId
    return EventBuilder._eventSequenceIds[key] ?? 0
  }
}
```

### 序列号 Key 规则

```
Key = {accountId}_{dataSourceId}

示例:
- projectA_ds1: 1, 2, 3, 4, 5...
- projectA_ds2: 1, 2, 3...
- projectB_ds1: 1, 2, 3, 4...
```

---

## 事件大小限制

### 限制策略

```typescript
static validateEventSize(event: any): { isValid: boolean, attributes: AttributesType } {
  let eventString = JSON.stringify(event)
  let eventSize = new util.TextEncoder().encode(eventString).length

  if (eventSize > MAX_EVENT_SIZE) {
    // 超出限制，截断 attributes
    let newAttributes: AttributesType = {
      'growing_error': true,
      'growing_error_msg': `Event size(${eventSize}) exceeds limit(${MAX_EVENT_SIZE})`
    }
    return { isValid: false, attributes: newAttributes }
  }

  return { isValid: true, attributes: event.attributes }
}
```

### 限制参数

| 参数 | 值 | 说明 |
|------|-----|------|
| `MAX_EVENT_SIZE` | 8KB | 单条事件最大大小 |
| `REQUEST_MAX_EVENT_COUNT` | 500 | 单次请求最大事件数 |
| `REQUEST_MAX_EVENT_SIZE` | 2MB | 单次请求最大数据量 |

---

## 总结

Event 系统是 GrowingIO SDK 的数据处理核心，其设计特点包括：

1. **分层架构**：Event → EventBuilder → EventPersistence → EventSender
2. **自动填充**：EventBuilder 自动填充设备、应用、用户等通用信息
3. **本地持久化**：事件先写入 SQLite，再批量发送，保证可靠性
4. **批量发送**：支持 500 条/2MB 批量发送，减少网络请求
5. **序列号管理**：保证事件顺序，支持多项目独立计数
6. **大小限制**：单条事件 8KB 限制，超限时自动截断

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
