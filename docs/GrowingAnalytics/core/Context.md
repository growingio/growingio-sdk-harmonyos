# GrowingContext - 上下文管理

`GrowingContext` 是 GrowingIO HarmonyOS SDK 的上下文管理类，负责管理多 Tracker 实例的生命周期和上下文隔离。

## 核心职责

1. **Tracker 实例管理**: 维护 `trackerId` 到 `GrowingContext` 的映射
2. **配置隔离**: 每个 Context 拥有独立的 `GrowingConfig` 配置
3. **事件发送器管理**: 根据配置模式创建对应的事件发送器
4. **默认上下文**: 支持主 Tracker（defaultContext）和子 Tracker（subTracker）

## 类定义

```typescript
export default class GrowingContext {
    trackerId: string
    config: GrowingConfig
    eventSender: EventSender[] = []
    static contexts: Map<string, GrowingContext> = new Map()
    static defaultContext: GrowingContext | undefined = undefined
}
```

## 静态属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `contexts` | `Map<string, GrowingContext>` | 所有 Tracker 实例的上下文映射表 |
| `defaultContext` | `GrowingContext \| undefined` | 主 Tracker（默认实例）的上下文 |

## 实例属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `trackerId` | `string` | Tracker 实例唯一标识 |
| `config` | `GrowingConfig` | 该实例的配置对象 |
| `eventSender` | `EventSender[]` | 事件发送器数组（SaaS 模式下有多个） |

## 核心方法

### 1. 构造函数

```typescript
constructor(trackerId: string, config: GrowingConfig)
```

**逻辑说明：**

创建新的上下文实例时，根据配置模式初始化对应的事件发送器：

```typescript
if (config.mode == ConfigMode.SaaS) {
    // SaaS 模式：分离 PV 事件和自定义事件的发送
    this.eventSender.push(new EventSender(EventSenderType.SaaS_PV, this.trackerId))
    this.eventSender.push(new EventSender(EventSenderType.SaaS_CSTM, this.trackerId))
} else {
    // NewSaaS/CDP 模式：统一发送
    this.eventSender.push(new EventSender(EventSenderType.NewSaaS, this.trackerId))
}
```

### 2. setDefaultContext() - 设置默认上下文

```typescript
static setDefaultContext(configuration: GrowingConfig)
```

**用途：**
- 创建主 Tracker 的上下文
- 使用固定的 `MAIN_TRACKER_ID` 作为 trackerId
- 同时设置 `defaultContext` 并加入 `contexts` 映射表

**调用时机：**
- `AnalyticsCore.startCore()` 中调用
- SDK 初始化时创建主 Tracker

### 3. setContext() - 设置子 Tracker 上下文

```typescript
static setContext(trackerId: string, configuration: GrowingConfig)
```

**用途：**
- 创建子 Tracker 的上下文
- 用户自定义的 trackerId

**调用时机：**
- `AnalyticsCore.startSubTracker()` 中调用
- 用户调用 `GrowingAnalytics.startSubTracker()` 时

### 4. getContext() - 获取指定上下文

```typescript
static getContext(trackerId: string): GrowingContext | undefined
```

**用途：**
- 根据 trackerId 获取对应的上下文
- 用于子 Tracker 的事件发送等操作

### 5. getDefaultContext() - 获取默认上下文

```typescript
static getDefaultContext(): GrowingContext | undefined
```

**用途：**
- 获取主 Tracker 的上下文
- 大部分 SDK 操作默认使用此上下文

### 6. isDefaultContext() - 判断是否默认上下文

```typescript
static isDefaultContext(context: GrowingContext): boolean
```

**用途：**
- 判断指定上下文是否为主 Tracker 的上下文
- 用于区分主/子 Tracker 的特殊处理逻辑

### 7. hasSimilarContext() - 检查重复配置

```typescript
static hasSimilarContext(trackerId: string, configuration: GrowingConfig): boolean
```

**检查逻辑：**

```typescript
// 1. 检查 trackerId 是否已存在
if (context.trackerId == trackerId) {
    return true  // 相同的 trackerId
}

// 2. 检查 accountId + dataSourceId 是否已存在
if (config.accountId == configuration.accountId &&
    config.dataSourceId == configuration.dataSourceId) {
    return true  // 相同的项目和数据源
}
```

**用途：**
- 防止创建重复的 Tracker 实例
- 在 `startSubTracker()` 前进行预检查

## 多实例架构

### 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    GrowingContext                           │
├─────────────────────────────────────────────────────────────┤
│  static contexts: Map<string, GrowingContext>               │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │  MAIN_TRACKER   │  │  "subTracker1"  │  ...             │
│  │  (defaultContext)│  │                 │                  │
│  └────────┬────────┘  └────────┬────────┘                  │
│           │                    │                            │
│  ┌────────▼────────┐  ┌────────▼────────┐                  │
│  │ GrowingContext  │  │ GrowingContext  │                  │
│  │  - trackerId    │  │  - trackerId    │                  │
│  │  - config       │  │  - config       │                  │
│  │  - eventSender  │  │  - eventSender  │                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### 上下文隔离机制

每个 `GrowingContext` 实例拥有独立的：

1. **配置对象 (`config`)**
   - 独立的数据源配置
   - 独立的采集开关
   - 独立的无埋点配置

2. **事件发送器 (`eventSender`)**
   - 独立的发送队列
   - 独立的发送间隔
   - 独立的数据库（通过 trackerId 区分）

3. **用户标识**
   - 独立的设备 ID
   - 独立的登录用户
   - 独立的会话 ID

## 使用场景

### 场景 1: 主 Tracker（默认实例）

```typescript
// 初始化默认实例
const config = new GrowingConfig()
    .NewSaaS('accountId', 'dataSourceId', 'urlScheme')

GrowingAnalytics.start(context, config)
// 内部调用: GrowingContext.setDefaultContext(config)
```

### 场景 2: 子 Tracker（多实例）

```typescript
// 主实例已初始化后，创建子实例
const subConfig = new GrowingConfig()
    .NewSaaS('otherAccount', 'otherDataSource', 'urlScheme')

GrowingAnalytics.startSubTracker('tracker2', subConfig)
// 内部调用: GrowingContext.setContext('tracker2', subConfig)
```

### 场景 3: 获取特定 Tracker 实例

```typescript
// 获取子 Tracker 实例进行操作
const subTracker = GrowingAnalytics.tracker('tracker2')
subTracker.track('custom_event')

// 内部流程:
// 1. AnalyticsCore.tracker('tracker2') 获取 Tracker
// 2. Tracker 内部持有对应的 GrowingContext
// 3. 事件发送到该 Context 对应的数据库和服务器
```

## 与 AnalyticsCore 的关系

```
AnalyticsCore
    │
    ├─ core: Tracker (主实例)
    │   └─ context: GrowingContext (MAIN_TRACKER_ID)
    │
    └─ trackers: Map<string, Tracker> (子实例)
        ├─ "tracker2" → Tracker
        │               └─ context: GrowingContext ("tracker2")
        └─ "tracker3" → Tracker
                        └─ context: GrowingContext ("tracker3")
```

**关键流程：**

1. **初始化时**
   ```
   AnalyticsCore.startCore()
       → GrowingContext.setDefaultContext(config)
       → 创建主 Tracker，绑定 defaultContext
   ```

2. **创建子 Tracker 时**
   ```
   GrowingAnalytics.startSubTracker(id, config)
       → AnalyticsCore.startSubTracker()
           → GrowingContext.hasSimilarContext()  // 检查重复
           → GrowingContext.setContext(id, config)  // 创建上下文
           → 创建子 Tracker，绑定新 Context
   ```

3. **发送事件时**
   ```
   tracker.track()
       → 获取 tracker.context
       → 使用 context.eventSender 发送
       → 数据存储到 trackerId 对应的数据库表
   ```

## 数据库隔离

通过 `trackerId` 实现数据库表隔离：

```typescript
// EventDatabase.getTableName()
private getTableName(): string {
    if (GrowingContext.isDefaultContext(this.context)) {
        return EventDatabase.TABLE_NAME  // "growingio_events"
    } else {
        return EventDatabase.TABLE_NAME + "_" + this.context.trackerId  // "growingio_events_tracker2"
    }
}
```

## 注意事项

1. **trackerId 唯一性**
   - 主 Tracker 使用固定的 `MAIN_TRACKER_ID`
   - 子 Tracker 的 trackerId 由用户指定，必须唯一

2. **accountId + dataSourceId 唯一性**
   - 不允许创建指向相同项目和数据源的多个 Tracker
   - 通过 `hasSimilarContext()` 进行检查

3. **默认上下文生命周期**
   - `defaultContext` 在 SDK 初始化时创建
   - 除非应用重启，否则一直存在

4. **子 Tracker 生命周期**
   - 创建后一直存在，目前不支持动态移除
   - 重启应用后需要重新调用 `startSubTracker()`

## 参见

- [AnalyticsCore](./analytics_core.md) - SDK 核心，Tracker 管理
- [GrowingConfig](./config.md) - 配置管理
- [EventSender](../event/event_system.md) - 事件发送器
