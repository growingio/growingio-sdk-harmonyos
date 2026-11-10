# Network 网络请求逻辑详解

> **模块归属**: 核心模块 (core)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/core/Network.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 的网络请求模块，包括事件发送、数据加密压缩、请求头生成等逻辑。

## 目录

- [概述](#概述)
- [Network 模块架构](#network-模块架构)
- [事件发送流程](#事件发送流程)
- [数据序列化](#数据序列化)
- [数据加密](#数据加密)
- [数据压缩](#数据压缩)
- [请求头生成](#请求头生成)
- [URL 生成](#url-生成)

---

## 概述

`Network` 模块负责 SDK 的事件数据网络传输，主要功能包括：

1. **事件发送**: 使用 HarmonyOS RCP (Remote Communication Proxy) 进行 HTTP 请求
2. **数据加密**: 支持基于时间戳的 XOR 混淆保护数据
3. **数据压缩**: 支持 Snappy 压缩减少传输大小
4. **多格式支持**: 支持 JSON 和 Protobuf 两种数据格式
5. **并发处理**: 使用 TaskPool 在子线程处理数据序列化

### 数据流转

```
EventPersistence[]
        │
        ▼
┌─────────────────────┐
│ processEvents()     │  子线程处理
│ • 序列化            │
│ • Protobuf 编码     │
│ • Snappy 压缩       │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 加密 (可选)         │
│ Util.encrypt()      │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 生成 HTTP 请求      │
│ • Headers           │
│ • URL               │
│ • Body              │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ RCP Session.fetch() │
│ 发送 HTTP POST      │
└────────┬────────────┘
         │
         ▼
    HTTP Response
```

---

## Network 模块架构

### 类结构

```typescript
export default class Network {
  static session: rcp.Session  // RCP 会话实例

  // 初始化网络模块
  static initNetwork(context: GrowingContext)

  // 发送事件请求，返回响应和实际发送副本
  static async request(
    events: EventPersistence[],
    urlPath: string,
    context: GrowingContext,
    mergeSaaSClick: boolean = false,
    pendingDeviceIdReplacement: string = ''
  ): Promise<NetworkResponse>

  // 生成 HTTP 请求，同时保留 TaskPool 返回的实际发送副本
  static async generateRequest(
    time: number,
    url: string,
    events: EventPersistence[],
    context: GrowingContext,
    mergeSaaSClick: boolean = false,
    pendingDeviceIdReplacement: string = ''
  ): Promise<GeneratedRequest>

  // 生成请求头
  static generateHeaders(
    time: number,
    useProtobuf: boolean,
    context: GrowingContext
  ): Record<string, string>

  // 生成请求 URL
  static generateUrl(
    time: number,
    urlPath: string,
    context: GrowingContext
  ): string
}
```

### RCP (Remote Communication Proxy)

HarmonyOS 提供的网络通信框架，替代传统的 HTTP 请求方式：

```typescript
// 创建 RCP 会话
Network.session = rcp.createSession()

// 发送请求
let response = await Network.session.fetch(request)
```

---

## 事件发送流程

### request() 方法

```typescript
static async request(
  events: EventPersistence[],
  urlPath: string,
  context: GrowingContext,
  mergeSaaSClick: boolean = false,
  pendingDeviceIdReplacement: string = ''
): Promise<NetworkResponse> {
  if (!Network.session) {
    return Promise.reject(new Error('Network session not initialized'))
  }

  let curTime = Date.now()
  let url = Network.generateUrl(curTime, urlPath, context)
  let generated: GeneratedRequest
  try {
    generated = await Network.generateRequest(
      curTime, url, events, context, mergeSaaSClick, pendingDeviceIdReplacement
    )
  } catch (error) {
    LogUtil.error(() => 'Failed to generate request: ' + error)
    return Promise.reject(error)
  }

  let response = await Network.session.fetch(generated.request)
  let result: NetworkResponse = { response: response, sentEvents: generated.sentEvents }
  return result
}
```

### 完整流程图

```
EventSender.sendEvent()
        │
        ▼
┌─────────────────────┐
│ 从数据库读取事件    │
│ (最多 500 条)       │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Network.request()   │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Session 已初始化？  │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【是】    【否】
    │         │
    │         ▼
    │    返回错误
    ▼
┌─────────────────────┐
│ generateRequest()   │
│ 生成 HTTP 请求      │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Session.fetch()     │
│ 发送 POST 请求      │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 返回 Response       │
│ 包含 statusCode     │
└─────────────────────┘
```

---

## 数据序列化

### generateRequest() 方法

```typescript
static async generateRequest(
  time: number,
  url: string,
  events: EventPersistence[],
  context: GrowingContext,
  mergeSaaSClick: boolean = false,
  pendingDeviceIdReplacement: string = ''
): Promise<GeneratedRequest> {
  let useProtobuf = context.config.useProtobuf
  if (context.config.mode == ConfigMode.SaaS) {
    useProtobuf = false
  }

  let processTask = new taskpool.Task(
    processEvents, events, useProtobuf, context.config.compressEnabled, mergeSaaSClick, pendingDeviceIdReplacement
  )
  let processed: ProcessEventsResult
  try {
    processed = await taskpool.execute(processTask) as ProcessEventsResult
  } catch (error) {
    LogUtil.error(() => 'Failed to execute taskpool task: ' + error)
    return Promise.reject(error)
  }

  let serialize = processed.serialize
  if (context.config.encryptEnabled) {
    serialize = Util.encrypt(serialize, time)
  }

  let headers = Network.generateHeaders(time, useProtobuf, context)
  let request = new rcp.Request(url, "POST", headers, serialize)
  // 省略 request.configuration 的超时与 tracing 配置
  let result: GeneratedRequest = { request: request, sentEvents: processed.sentEvents }
  return result
}
```

`GeneratedRequest` 同时携带请求对象和 `processed.sentEvents`。后者是 TaskPool 中实际用于序列化的事件副本，最终由 `Network.request()` 透传给 `EventSender`，供发送完成回调使用。

### processEvents 并发任务

数据序列化在子线程中执行，避免阻塞主线程：

```typescript
// utils/Concurrent.ets（完整实现见 Utils.md）
@Concurrent
export function processEvents(
  events: EventPersistence[],
  useProtobuf: boolean,
  compressEnabled: boolean,
  mergeSaaSClick: boolean = false,
  pendingDeviceIdReplacement: string = ''
): ProcessEventsResult {
  let serialize: ArrayBuffer = new ArrayBuffer(0)
  if (pendingDeviceIdReplacement.length > 0) {
    // 仅复制 forceLoginPending 为 true 的事件并替换 deviceId，保留 UUID 和数据库原对象
    ...
  }
  if (useProtobuf) {
    // event_pb.EventV3Dto.fromObject → EventV3List.encode().finish()
    ...
  } else if (mergeSaaSClick) {
    // 按 t_u_s_d_p_ptm 分组，公共字段提顶层、专属字段收入 e 数组后 JSON.stringify
    ...
  } else {
    // 普通 JSON： '[' + events.map(e => String(e.data)).join(',') + ']'
    serialize = buffer.from(json, 'utf-8').buffer
  }
  if (compressEnabled) {
    serialize = snappy.compress(serialize) as ArrayBuffer
  }
  let result: ProcessEventsResult = { serialize: serialize, sentEvents: events }
  return result
}
```

> 序列化用 `buffer.from(...)`，Protobuf 走 `event_pb`，压缩用 **snappyjs**。完整逻辑（含 SaaS 合并字段）见 [Utils.md](../utils/Utils.md#processevents---事件批量处理)。

### 序列化流程

```
EventPersistence[]
        │
        ▼
┌─────────────────────┐
│ 提取 data 字段      │
│ (JSON 字符串)       │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 拼接为 JSON 数组    │
│ [event1,event2,...] │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ buffer.from()       │
│ 转为 ArrayBuffer    │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ useProtobuf ?       │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【是】    【否】
    │         │
    ▼         │
┌────────┐    │
│Protobuf│    │
│ 编码   │    │
└────┬───┘    │
     └────────┘
              │
              ▼
┌─────────────────────┐
│ compressEnabled ?   │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【是】    【否】
    │         │
    ▼         │
┌────────┐    │
│ Snappy │    │
│ 压缩   │    │
└────┬───┘    │
     └────────┘
              │
              ▼
         ArrayBuffer
```

---

## 数据加密

### 加密逻辑

```typescript
if (context.config.encryptEnabled) {
  serialize = Util.encrypt(serialize, time)
}
```

### 加密特点

- **算法**: XOR 混淆（逐字节异或，非 AES）
- **密钥**: 由时间戳经 `Util.getHintFromTime(time)` 生成的 hint
- **作用**: 对传输数据做轻量混淆
- **开关**: 通过 `config.encryptEnabled` 控制

---

## 数据压缩

### 压缩逻辑

```typescript
// 在子线程中进行 Snappy 压缩
if (compressEnabled) {
  serialize = snappy.compress(serialize) as ArrayBuffer
}
```

### 压缩特点

- **算法**: Snappy（snappyjs）
- **作用**: 减少数据传输大小，节省流量
- **开关**: 通过 `config.compressEnabled` 控制
- **标识**: 请求头 `X-Compress-Codec: 2` 表示使用 Snappy

---

## 请求头生成

### generateHeaders() 方法

```typescript
static generateHeaders(
  time: number, 
  useProtobuf: boolean, 
  context: GrowingContext
): Record<string, string> {
  let contentType: string
  if (context.config.mode == ConfigMode.SaaS) {
    contentType = "application/octet-stream"
  } else {
    contentType = useProtobuf ? "application/protobuf" : "application/json"
  }

  let headers: Record<string, string> = {
    "Content-Type": contentType,
    "Accept": "application/json",
    "X-Timestamp": time + ''
  }

  // 压缩标识
  if (context.config.compressEnabled) {
    headers['X-Compress-Codec'] = '2'  // 2 = Snappy
  }

  // 加密标识
  if (context.config.encryptEnabled) {
    headers['X-Crypt-Codec'] = '1'  // 1 = XOR 混淆
  }

  return headers
}
```

### 请求头列表

| Header | 值 | 说明 |
|--------|-----|------|
| `Content-Type` | `application/octet-stream` / `application/protobuf` / `application/json` | SaaS 固定为 `application/octet-stream`；NewSaaS/CDP 按 `useProtobuf` 选择 |
| `Accept` | `application/json` | 接受响应类型 |
| `X-Timestamp` | 时间戳 | 请求时间 |
| `X-Compress-Codec` | `2` | 压缩算法（Snappy）|
| `X-Crypt-Codec` | `1` | 加密算法（XOR 混淆）|

SaaS 的请求体使用 JSON 编码，`Content-Type` 固定为 `application/octet-stream`。

---

## URL 生成

### generateUrl() 方法

```typescript
static generateUrl(time: number, urlPath: string, context: GrowingContext): string {
  let config = context.config
  let serverHost = config.dataCollectionServerHost
  
  // 去除末尾斜杠
  if (serverHost.endsWith('/')) {
    serverHost = serverHost.substring(0, serverHost.length - 1)
  }
  
  let accountId = config.accountId
  
  // 替换 URL 路径中的 accountId
  // 添加时间戳参数
  return serverHost + urlPath.replace('accountId', accountId) + '?stm=' + String(time)
}
```

### URL 格式

```
{serverHost}/{urlPath}?stm={timestamp}

示例:
https://napi.growingio.com/v3/projects/123456/collect?stm=1708765432100
```

### URL 路径映射

| 模式 | URL Path | 说明 |
|------|---------|------|
| NewSaaS | `/v3/projects/{accountId}/collect` | 统一收集接口 |
| SaaS PV | `/v3/{accountId}/harmonyos/pv` | 页面/访问事件 |
| SaaS CSTM | `/v3/{accountId}/harmonyos/cstm` | 自定义事件 |
| SaaS OTHER | `/v3/{accountId}/harmonyos/other` | 无埋点点击/变更事件（mergeSaaSClick 合并格式） |

---

## 超时配置

### 请求超时

```typescript
const requestConfig: rcp.Configuration = {
  transfer: {
    timeout: {
      connectMs: context.config.requestOptions._connectTimeout,  // 默认 30s
      transferMs: context.config.requestOptions._transferTimeout, // 默认 30s
    }
  }
}
```

| 超时类型 | 默认 | 说明 |
|---------|------|------|
| 连接超时 (connectTimeout) | 30 秒 | 建立连接的最大等待时间 |
| 传输超时 (transferTimeout) | 30 秒 | 数据传输的最大等待时间 |

---

## 错误处理

### 常见错误

| 错误 | 原因 | 处理 |
|------|------|------|
| Network session not initialized | RCP 会话未创建 | 检查 SDK 初始化顺序 |
| Failed to execute taskpool task | 子线程处理失败 | 检查事件数据格式 |
| Failed to generate request | 请求生成失败 | 检查配置是否正确 |
| HTTP 4xx/5xx | 服务器错误 | 保留事件，下次重试 |

### 重试机制

- 发送失败的事件保留在数据库中
- 下次定时任务会再次尝试发送
- 成功发送后才从数据库删除

---

## 总结

Network 模块提供了完整的网络传输功能：

1. **RCP 通信**: 使用 HarmonyOS RCP 框架进行 HTTP 请求
2. **子线程处理**: 使用 TaskPool 在子线程进行数据序列化
3. **数据安全**: 支持 AES 加密和 Gzip 压缩
4. **多格式支持**: JSON 和 Protobuf 两种数据格式
5. **灵活配置**: 超时、加密、压缩均可配置

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.8.0*
