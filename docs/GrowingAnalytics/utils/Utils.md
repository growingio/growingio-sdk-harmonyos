# Utils - 工具类模块

Utils 模块提供 GrowingIO HarmonyOS SDK 的基础工具能力，包括并发处理、本地存储、日志系统、数据序列化、加解密等。

## 1. Concurrent - 并发处理

### 功能说明

基于 HarmonyOS TaskPool 实现的事件序列化并发处理，避免在主线程执行耗时操作。

### processEvents() - 事件批量处理

```typescript
@Concurrent
export function processEvents(
    events: EventPersistence[],
    useProtobuf: boolean,
    compressEnabled: boolean
): ArrayBuffer
```

**参数：**
| 参数 | 类型 | 说明 |
|------|------|------|
| `events` | `EventPersistence[]` | 待处理的事件数组 |
| `useProtobuf` | `boolean` | 是否使用 Protobuf 序列化 |
| `compressEnabled` | `boolean` | 是否启用 Snappy 压缩 |

**处理流程：**

```
输入: EventPersistence[]
    │
    ├─ useProtobuf = true ─┐
    │                      ▼
    │              Protobuf 序列化
    │              (EventV3List.encode)
    │                      │
    │ useProtobuf = false ─┤
    │                      ▼
    │              JSON 序列化
    │              (JSON.stringify)
    │                      │
    ▼                      ▼
        ArrayBuffer
            │
    compressEnabled = true ▼
        Snappy 压缩
            │
            ▼
    输出: ArrayBuffer
```

**实现细节：**

```typescript
// Protobuf 序列化流程
if (useProtobuf) {
    let values: event_pb.EventV3Dto[] = []
    events.forEach(e => {
        let event = JSON.parse(e.data) as object
        let dto = event_pb.EventV3Dto.fromObject(event)
        values.push(dto)
    })
    let list = event_pb.EventV3List.create({values: values})
    let arrayBuffer: Uint8Array = event_pb.EventV3List.encode(list).finish()
    serialize = buffer.from(arrayBuffer).buffer
} else {
    // JSON 序列化
    let json = '[' + events.map(event => String(event.data)).join(',') + ']'
    serialize = buffer.from(json, 'utf-8').buffer
}

// Snappy 压缩
if (compressEnabled) {
    serialize = snappy.compress(serialize) as ArrayBuffer
}
```

**调用位置：**
- `EventSender.sendEventsConcurrently()` - 事件发送前的批量处理

---

## 2. SharedPreferences - 本地存储

### 功能说明

基于 HarmonyOS `preferences` 模块的键值对存储，用于持久化 SDK 配置和用户标识。

### 核心方法

#### initWithContext() - 初始化

```typescript
static initWithContext(context: Context): void
```

**说明：**
- 使用应用级 Context 获取 Preferences 实例
- 存储文件名由 `PREFERENCE_NAME` 常量定义（`growing_analytics_preferences`）
- 在 `AnalyticsCore.startCore()` 中初始化

#### put() / getValue() - 存取数据

```typescript
// 存储数据
static async put(key: string, value: preferences.ValueType): Promise<void>

// 读取数据
static getValue(
    key: string,
    defValue: preferences.ValueType = ''
): preferences.ValueType
```

**支持的 ValueType：**
- `string`
- `number`
- `boolean`
- `Array<string | number | boolean>`

**使用示例：**

```typescript
// 存储设备 ID
await SharedPreferences.put('device_id', 'abc123')

// 读取设备 ID
let deviceId = SharedPreferences.getValue('device_id', '') as string
```

**存储的 Key：**

| Key | 用途 | 模块 |
|-----|------|------|
| `device_id` | 设备唯一标识 | UserIdentifier |
| `user_id` | 登录用户 ID | UserIdentifier |
| `user_key` | ID Mapping Key | UserIdentifier |
| `session_id` | 当前会话 ID | Session |
| `latest_visit_time` | 上次访问时间 | Session |
| `general_props` | 通用属性 | GeneralProps |

---

## 3. LogUtil - 日志工具

### 功能说明

统一的日志输出管理，支持控制台输出和调试器转发。

### 静态属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `debugEnabled` | `boolean` | 是否启用 DEBUG 日志（由 `GrowingConfig.debugEnabled` 控制）|
| `logDebugger` | `function \| undefined` | MobileDebugger 日志回调函数 |

### 日志级别

#### info() - 信息日志

```typescript
static info(message: () => string): void
```

**特点：**
- 仅在 `debugEnabled = true` 时输出到控制台
- 总是转发到 MobileDebugger（如果已连接）

#### error() - 错误日志

```typescript
static error(message: () => string): void
```

**特点：**
- 总是输出到控制台（`console.error`）
- 总是转发到 MobileDebugger

#### warn() - 警告日志

```typescript
static warn(message: () => string): void
```

**特点：**
- 总是输出到控制台（`console.warn`）
- 总是转发到 MobileDebugger

**使用示例：**

```typescript
// 使用 Lambda 延迟计算，避免不必要的字符串拼接
LogUtil.info(() => `Event sent: ${eventName}`)
LogUtil.error(() => `Failed to send: ${error.message}`)
LogUtil.warn(() => `Configuration missing: ${key}`)
```

**日志前缀：**
所有日志自动添加 `[GrowingAnalytics]` 前缀，便于过滤。

---

## 4. Util - 通用工具函数

### 4.1 数据转换

#### mapToObject() - Map 转 Object

```typescript
static mapToObject(map: Map<string, ValueType>): AttributesType
```

用途：将 ES Map 转换为普通对象，便于 JSON 序列化。

#### concatObject() - 合并对象

```typescript
static concatObject(objA: AttributesType, objB: AttributesType): AttributesType
```

**注意：** objB 的属性会覆盖 objA 的同名属性。

#### removeKeysForObject() - 删除指定 Key

```typescript
static removeKeysForObject(keys: string[], obj: AttributesType): void
```

#### cloneObject() - 浅拷贝对象

```typescript
static cloneObject(obj: AttributesType): AttributesType
```

#### serializableAttributes() - 属性序列化

```typescript
static serializableAttributes(attr: AttributesType): AttributesType | undefined
```

**转换规则：**
| 原始类型 | 转换后 |
|----------|--------|
| `Array` | 用 `\|\|` 连接为字符串 |
| 其他 | `String()` 转换 |

```typescript
// 示例
{ tags: ['a', 'b', 'c'], count: 123 }
// 转换后
{ tags: 'a||b||c', count: '123' }
```

### 4.2 数据加密

#### getHintFromTime() - 生成加密密钥

```typescript
static getHintFromTime(time: number): Uint8Array
```

**算法：**
```
time (ms) → 16进制字符串 → 取最后2位 → 转为 Uint8Array
```

#### encrypt() - XOR 加密

```typescript
static encrypt(serialize: ArrayBuffer, time: number): ArrayBuffer
```

**算法：**
- 使用 `time` 生成的 hint 作为密钥
- 对每个字节执行 XOR 运算：`encrypted[i] = original[i] ^ hint[i % hint.length]`
- 基于时间的简单加密，用于数据传输混淆

### 4.3 协议序列化

#### toSerializeByMeasurementProtocolV2() - SaaS 协议

```typescript
static toSerializeByMeasurementProtocolV2(
    event: any,
    networkState: string
): string
```

**字段映射（按事件类型分支）：**

*公共基础字段（所有类型共享）：*
| 输出字段 | 源字段 | 说明 |
|----------|--------|------|
| `esid`/`gesid` | eventSequenceId | 事件序列号 |
| `u` | deviceId | 设备 ID |
| `s` | sessionId | 会话 ID |
| `d` | domain | 包名/域名 |
| `tm` | timestamp | 事件时间戳 |
| `cs1` | userId | 登录用户 ID（有值时写入） |

*CUSTOM (`t: cstm`)*：`n`(eventName), `var`(attributes), `p`(path), `ptm`(pageShowTimestamp)

*PAGE (`t: page`)*：`var`(attributes), `p`(path), `q`(query), `tl`(title), `rp`(referralPage), `r`(networkState→WIFI/CELL/UNKNOWN/NONE)

*VIEW_CLICK (`t: clck`) / VIEW_CHANGE (`t: chng`)（SaaS 无埋点）：*
| 输出字段 | 源字段 | 说明 |
|----------|--------|------|
| `t` | eventType | `clck`（VIEW_CLICK）或 `chng`（VIEW_CHANGE） |
| `p` | path | 页面路径 |
| `ptm` | pageShowTimestamp | 页面显示时间戳 |
| `x` | xpath | 元素 xpath |
| `v` | textValue | 元素文本（undefined 时不写入） |
| `q` | query | 页面查询参数（undefined 时不写入） |
| `h` | hyperlink | 超链接地址（undefined 时不写入） |
| `idx` | index | 列表索引，以字符串写入（undefined 时不写入） |
| `r` | networkState | 网络状态（WIFI/CELL/UNKNOWN/NONE） |
| `lat`/`lng` | latitude/longitude | 地理位置（undefined 时不写入） |

*VISIT (`t: vst`)*：设备信息字段（`db`, `dm`, `sh`, `sw`, `os`, `cv` 等）

*APP_CLOSED (`t: cls`)*：`p`(path)

#### toSerializeByMeasurementProtocolV3() - CDP 协议

```typescript
static toSerializeByMeasurementProtocolV3(event: any): string
```

**特点：**
- 直接 JSON 序列化
- 删除 `timezoneOffset` 和 `xcontent` 字段

### 4.4 HarmonyOS 上下文判断

#### isUIAbilityContext() - 判断 UIAbilityContext

```typescript
static isUIAbilityContext(context: any): boolean
```

**判断逻辑：**
- 检查 `context.abilityInfo.name` 是否存在
- 用于延迟启动时确保传入正确的 Context 类型

#### isNavDestinationSwitchInfo() / isNavDestinationInfo()

```typescript
static isNavDestinationSwitchInfo(info: any): boolean
static isNavDestinationInfo(info: any): boolean
```

用途：判断 Navigation 相关信息类型，用于页面自动采集。

### 4.5 页面属性提取

#### getComponentLabel() - 获取组件标签

```typescript
static getComponentLabel(inspectorInfo: any): string
```

**提取顺序：**
1. `inspectorInfo['$attrs']['label']`
2. `inspectorInfo['$attrs']['content']`
3. 空字符串

#### getAliasFromNavInfoParameter() - 获取页面别名

```typescript
static getAliasFromNavInfoParameter(param: any): string
```

从 Navigation 参数中提取 `growing_alias`。

#### getAttributesFromNavInfoParameter() - 获取页面属性

```typescript
static getAttributesFromNavInfoParameter(param: any): AttributesType
```

从 Navigation 参数中提取 `growing_attributes`。

#### getTitleFromNavInfoParameter() - 获取页面标题

```typescript
static getTitleFromNavInfoParameter(param: any): string
```

从 Navigation 参数中提取 `growing_title`。

### 4.6 事件大小验证

#### validateEventSize() - 验证事件大小

```typescript
static validateEventSize(event: any): {
    isValid: boolean,
    attributes: AttributesType
}
```

**限制：**
- 最大 1.8 MB
- 超过限制时添加 `growing_error_msg` 属性标记

### 4.7 安全执行

#### niceTry() / niceTryAsync() - 安全执行函数

```typescript
// 同步版本
export function niceTry<T>(fn: () => T): T | undefined
export function niceTry<T>(fn: () => T, fallback: T): T

// 异步版本
export function niceTryAsync<T>(fn: () => Promise<T>): Promise<T | undefined>
export function niceTryAsync<T>(fn: () => Promise<T>, fallback: T): Promise<T>
```

**用途：**
- 包装可能抛出异常的函数
- 异常时返回默认值（如果有）或 undefined
- 避免异常中断程序执行

**使用示例：**

```typescript
// 有默认值
let value = niceTry(() => JSON.parse(jsonString), {})

// 无默认值
let result = niceTry(() => riskyOperation())

// 异步版本
await niceTryAsync(() => asyncOperation())
```

---

## 5. Protobuf - 协议缓冲区

### 功能说明

使用 protobuf.js 定义的事件数据结构，用于 CDP/NewSaaS 模式的高效序列化。

### 文件位置

```
utils/protobuf/event_pb.d.ts
```

### 核心类型

| 类型 | 说明 |
|------|------|
| `event_pb.EventV3Dto` | 单个事件 DTO |
| `event_pb.EventV3List` | 事件列表容器 |

### 使用方法

```typescript
import { event_pb } from './protobuf/event_pb'

// 创建 DTO
let dto = event_pb.EventV3Dto.fromObject(eventData)

// 创建列表
let list = event_pb.EventV3List.create({values: [dto]})

// 编码
let buffer = event_pb.EventV3List.encode(list).finish()
```

---

## 模块关系

```
┌─────────────────────────────────────────────────────────────┐
│                         Utils 模块                           │
├─────────────────────────────────────────────────────────────┤
│  Concurrent.ets                                              │
│     │                                                        │
│     ▼                                                        │
│  TaskPool ────────▶ EventSender ──────▶ 批量事件序列化       │
│     │                                                        │
│  SharedPreferences.ets                                        │
│     │                                                        │
│     ▼                                                        │
│  preferences ────▶ UserIdentifier/Session/GeneralProps       │
│     │                                                        │
│  LogUtil.ts                                                  │
│     │                                                        │
│     ▼                                                        │
│  console ────────▶ 全模块日志输出                            │
│     │                                                        │
│  Util.ts                                                     │
│     │                                                        │
│     ├────────────▶ EventBuilder (协议序列化)                 │
│     ├────────────▶ Autotrack (组件信息提取)                  │
│     ├────────────▶ EventPersistence (大小验证)               │
│     └────────────▶ 全模块 (niceTry 保护)                     │
│     │                                                        │
│  protobuf/event_pb.d.ts                                      │
│     │                                                        │
│     ▼                                                        │
│  protobuf.js ────▶ Concurrent (事件编码)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 参见

- [EventSender](../event/event_system.md) - 事件发送器
- [EventBuilder](../event/event_system.md) - 事件构建
- [Network](../core/network.md) - 网络请求（加密压缩相关）
