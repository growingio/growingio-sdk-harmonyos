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
2. **数据加密**: 支持 AES 加密保护数据安全
3. **数据压缩**: 支持 Gzip 压缩减少传输大小
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
│ • Gzip 压缩         │
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

  // 发送事件请求
  static async request(
    events: EventPersistence[], 
    urlPath: string, 
    context: GrowingContext
  ): Promise<rcp.Response>

  // 生成 HTTP 请求
  static async generateRequest(
    time: number, 
    url: string, 
    events: EventPersistence[], 
    context: GrowingContext
  ): Promise<rcp.Request>

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
  context: GrowingContext
): Promise<rcp.Response> {
  
  // 1. 检查会话是否初始化
  if (!Network.session) {
    return Promise.reject(new Error('Network session not initialized'))
  }

  // 2. 生成时间戳
  let curTime = Date.now()
  
  // 3. 生成 URL
  let url = Network.generateUrl(curTime, urlPath, context)

  try {
    // 4. 生成请求对象
    let request = await Network.generateRequest(curTime, url, events, context)
    
    // 5. 发送请求
    return Network.session.fetch(request)
  } catch (error) {
    LogUtil.error(() => 'Failed to generate request: ' + error)
    return Promise.reject(error)
  }
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
  mergeSaaSClick: boolean = false   // SaaS 无埋点点击合并上报开关
): Promise<rcp.Request> {

  // 1. 判断是否使用 Protobuf
  let useProtobuf = context.config.useProtobuf
  if (context.config.mode == ConfigMode.SaaS) {
    useProtobuf = false  // SaaS 模式不支持 Protobuf
  }

  // 2. 在子线程处理事件序列化
  let processTask = new taskpool.Task(
    processEvents, 
    events, 
    useProtobuf, 
    context.config.compressEnabled,
    mergeSaaSClick                   // 传入合并标志
  )
  
  let serialize: ArrayBuffer
  try {
    serialize = await taskpool.execute(processTask) as ArrayBuffer
  } catch (error) {
    LogUtil.error(() => 'Failed to execute taskpool task: ' + error)
    return Promise.reject(error)
  }

  // 3. 加密（如果启用）
  if (context.config.encryptEnabled) {
    serialize = Util.encrypt(serialize, time)
  }

  // 4. 生成请求头
  let headers = Network.generateHeaders(time, useProtobuf, context)

  // 5. 创建请求对象
  let request = new rcp.Request(url, "POST", headers, serialize)

  // 6. 配置请求参数
  const requestConfig: rcp.Configuration = {
    transfer: {
      timeout: {
        connectMs: context.config.requestOptions._connectTimeout,
        transferMs: context.config.requestOptions._transferTimeout,
      }
    },
    tracing: {
      collectTimeInfo: true
    }
  }
  request.configuration = requestConfig

  return request
}
```

### processEvents 并发任务

数据序列化在子线程中执行，避免阻塞主线程：

```typescript
// utils/Concurrent.ets
@Concurrent
export function processEvents(
  events: EventPersistence[], 
  useProtobuf: boolean, 
  compressEnabled: boolean,
  mergeSaaSClick: boolean = false   // true 时按 SaaS 合并格式序列化 clck/chng 事件
): ArrayBuffer {
  
  // 1. 转换为 JSON 数组
  let eventArray = events.map(event => event.data)
  let jsonString = '[' + eventArray.join(',') + ']'

  // 2. 转换为 ArrayBuffer
  let buffer = new util.TextEncoder().encode(jsonString)

  // 3. Protobuf 编码（如果启用）
  if (useProtobuf) {
    // Protobuf 编码逻辑
    buffer = protobufEncode(buffer)
  }

  // 4. Gzip 压缩（如果启用）
  if (compressEnabled) {
    buffer = gzipCompress(buffer)
  }

  return buffer
}
```

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
│ TextEncoder         │
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
│ Gzip   │    │
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

- **算法**: AES 加密
- **密钥**: 基于时间戳生成
- **作用**: 保护数据在传输过程中的安全性
- **开关**: 通过 `config.encryptEnabled` 控制（默认开启）

---

## 数据压缩

### 压缩逻辑

```typescript
// 在子线程中进行 Gzip 压缩
if (compressEnabled) {
  buffer = gzipCompress(buffer)
}
```

### 压缩特点

- **算法**: Gzip
- **作用**: 减少数据传输大小，节省流量
- **开关**: 通过 `config.compressEnabled` 控制（默认开启）
- **标识**: 请求头 `X-Compress-Codec: 2` 表示使用 Gzip

---

## 请求头生成

### generateHeaders() 方法

```typescript
static generateHeaders(
  time: number, 
  useProtobuf: boolean, 
  context: GrowingContext
): Record<string, string> {
  
  let headers: Record<string, string> = {
    "Content-Type": useProtobuf ? "application/protobuf" : "application/json",
    "Accept": "application/json",
    "X-Timestamp": time + ''
  }

  // 压缩标识
  if (context.config.compressEnabled) {
    headers['X-Compress-Codec'] = '2'  // 2 = Gzip
  }

  // 加密标识
  if (context.config.encryptEnabled) {
    headers['X-Crypt-Codec'] = '1'  // 1 = AES
  }

  return headers
}
```

### 请求头列表

| Header | 值 | 说明 |
|--------|-----|------|
| `Content-Type` | `application/protobuf` 或 `application/json` | 内容类型 |
| `Accept` | `application/json` | 接受响应类型 |
| `X-Timestamp` | 时间戳 | 请求时间 |
| `X-Compress-Codec` | `2` | 压缩算法（Gzip）|
| `X-Crypt-Codec` | `1` | 加密算法（AES）|

---

## URL 生成

### generateUrl() 方法

```typescript
static generateUrl(time: number, urlPath: string, context: GrowingContext): string {
  let config = context.config
  let serverHost = config.dataCollectionServerHost
  
  // 去除末尾斜杠
  if (serverHost.endsWith('/')) {
    serverHost = serverHost.substring(0, serverHost.length - 2)
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
*基于 GrowingIO HarmonyOS SDK v2.7.1*
