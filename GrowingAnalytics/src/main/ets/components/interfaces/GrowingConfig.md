# GrowingConfig 配置管理逻辑详解

> **模块归属**: 对外接口模块 (interfaces)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/interfaces/GrowingConfig.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 的配置管理系统，包括三种工作模式的配置方式、配置项说明以及配置验证逻辑。

## 目录

- [概述](#概述)
- [三种工作模式](#三种工作模式)
- [配置项详解](#配置项详解)
- [配置验证](#配置验证)
- [使用示例](#使用示例)

---

## 概述

`GrowingConfig` 是 SDK 的配置类，采用 **Builder 模式** 进行配置设置。支持三种工作模式：

- **NewSaaS**: 新 SaaS 平台（推荐）
- **SaaS**: 旧版 SaaS 平台
- **CDP**: 客户数据平台

### 配置流程

```
创建配置对象
    │
    ▼
┌─────────────────┐
│ new GrowingConfig() │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 选择模式配置方法 │
│ • NewSaaS()     │
│ • SaaS()        │
│ • CDP()         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 设置其他配置项   │
│ • autotrackEnabled│
│ • debugEnabled   │
│ • ...           │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ copy() 验证配置 │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 配置验证通过     │
│ 返回可用配置     │
└─────────────────┘
```

---

## 三种工作模式

### 1. NewSaaS 模式（推荐）

适用于 GrowingIO 新 SaaS 平台。

```typescript
let config = new GrowingConfig().NewSaaS(
  'your_accountId',                    // 项目 ID
  'your_dataSourceId',                 // 数据源 ID
  'your_urlScheme',                    // URL Scheme
  'https://napi.growingio.com'         // 数据收集服务器（可选，默认）
)
```

| 参数 | 必填 | 说明 |
|------|------|------|
| accountId | ✅ | 项目 ID |
| dataSourceId | ✅ | 数据源 ID |
| urlScheme | ✅ | URL Scheme |
| dataCollectionServerHost | ❌ | 数据收集服务器地址 |

### 2. SaaS 模式

适用于 GrowingIO 旧版 SaaS 平台。

```typescript
let config = new GrowingConfig().SaaS(
  'your_accountId',                    // 项目 ID
  'your_urlScheme',                    // URL Scheme
  'https://api.growingio.com'          // 数据收集服务器（可选，默认）
)
```

| 参数 | 必填 | 说明 |
|------|------|------|
| accountId | ✅ | 项目 ID |
| urlScheme | ✅ | URL Scheme |
| dataCollectionServerHost | ❌ | 数据收集服务器地址 |

**注意**: SaaS 模式不支持 dataSourceId，且部分功能受限。

### 3. CDP 模式

适用于客户数据平台（CDP）。

```typescript
let config = new GrowingConfig().CDP(
  'your_accountId',                    // 项目 ID
  'your_dataSourceId',                 // 数据源 ID
  'your_urlScheme',                    // URL Scheme
  'https://your-cdp-server.com'        // 数据收集服务器（必填）
)
```

| 参数 | 必填 | 说明 |
|------|------|------|
| accountId | ✅ | 项目 ID |
| dataSourceId | ✅ | 数据源 ID |
| urlScheme | ✅ | URL Scheme |
| dataCollectionServerHost | ✅ | 数据收集服务器地址 |

### 模式对比

| 特性 | NewSaaS | SaaS | CDP |
|------|---------|------|-----|
| accountId | ✅ | ✅ | ✅ |
| dataSourceId | ✅ | ❌ | ✅ |
| urlScheme | ✅ | ✅ | ✅ |
| 默认服务器 | napi.growingio.com | api.growingio.com | 无（必填）|
| MobileDebugger | ✅ | ❌ | ✅ |
| Circle 圈选 | ✅ | ❌ | ✅ |
| Hybrid 无埋点 | ✅ | ✅ (可选) | ✅ |
| ID Mapping | ✅ | ❌ | ✅ |
| Protobuf | ✅ | ❌ | ✅ |

---

## 配置项详解

### 基础配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `mode` | ConfigMode | NewSaaS | 工作模式 |
| `accountId` | string | '' | 项目 ID |
| `dataSourceId` | string | '' | 数据源 ID |
| `dataCollectionServerHost` | string | '' | 数据收集服务器 |
| `urlScheme` | string | '' | URL Scheme |

### 功能开关

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `dataCollectionEnabled` | boolean | true | 数据采集总开关 |
| `autotrackEnabled` | boolean | false | 无埋点功能开关 |
| `autotrackAllPages` | boolean | false | 自动采集所有页面 |
| `hybridAutotrackEnabled` | boolean | true | H5 无埋点开关（仅 SaaS）|
| `idMappingEnabled` | boolean | false | ID Mapping 开关 |
| `debugEnabled` | boolean | false | 调试模式开关 |

### 数据传输配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `encryptEnabled` | boolean | true | 数据加密开关 |
| `compressEnabled` | boolean | true | 数据压缩开关 |
| `useProtobuf` | boolean | true | 使用 Protobuf 格式 |
| `requestOptions` | RequestOptions | - | 网络请求选项 |

### 时间间隔配置

```typescript
// 会话超时时间（秒），默认 30 秒
set sessionInterval(interval: number)  // 范围: 1-∞
get sessionInterval(): number

// 数据上传间隔（秒），默认 15 秒
set dataUploadInterval(interval: number)  // 范围: 1-∞
get dataUploadInterval(): number

// 数据有效期（天），默认 7 天
set dataValidityPeriod(days: number)  // 范围: 3-30
data dataValidityPeriod(): number
```

**内部存储单位转换**:
```typescript
// 外部 API 使用秒，内部存储使用毫秒
_sessionInterval = interval * 1000
_dataUploadInterval = interval * 1000
_dataValidityPeriod = days * 86400000
```

### 网络请求选项

```typescript
class RequestOptions {
  _connectTimeout: number = 30 * 1000   // 连接超时（毫秒）
  _transferTimeout: number = 30 * 1000  // 传输超时（毫秒）
  
  // 设置连接超时（秒），范围 1-60
  set connectTimeout(timeout: number)
  get connectTimeout(): number
  
  // 设置传输超时（秒），范围 1-60
  set transferTimeout(timeout: number)
  get transferTimeout(): number
}
```

### 字段忽略配置

```typescript
export enum IgnoreFields {
  NetworkState = (1 << 0),     // 网络状态
  ScreenSize = (1 << 1),       // 屏幕尺寸
  DeviceBrand = (1 << 2),      // 设备品牌
  DeviceModel = (1 << 3),      // 设备型号
  DeviceType = (1 << 4),       // 设备类型
  SystemLanguage = (1 << 5),   // 系统语言
  TimezoneOffset = (1 << 6),   // 时区偏移
  PlatformVersion = (1 << 7),  // 平台版本
}

// 忽略所有字段
export const IgnoreFieldsAll = 
  IgnoreFields.NetworkState | 
  IgnoreFields.ScreenSize | 
  IgnoreFields.DeviceBrand | 
  IgnoreFields.DeviceModel | 
  IgnoreFields.DeviceType | 
  IgnoreFields.SystemLanguage | 
  IgnoreFields.TimezoneOffset | 
  IgnoreFields.PlatformVersion
```

通过位运算组合忽略的字段：
```typescript
config.ignoreField = IgnoreFields.NetworkState | IgnoreFields.DeviceModel
```

### 插件配置

```typescript
plugins: Array<PluginsInterface> = []  // 自定义插件列表
trackerId: string = ''                  // 子 Tracker ID
```

---

## 配置验证

### copy() 方法验证

配置在使用前必须通过 `copy()` 方法进行验证：

```typescript
copy(): GrowingConfig {
  // 1. 验证 accountId
  if (!(typeof this.accountId === 'string') || this.accountId.trim() === '') {
    throw new Error('[GrowingAnalytics] 请在初始化配置中传入 accountId')
  }

  // 2. 验证 dataSourceId（NewSaaS 和 CDP 模式）
  if (this.mode === ConfigMode.NewSaaS || this.mode === ConfigMode.CDP) {
    if (!(typeof this.dataSourceId === 'string') || this.dataSourceId.trim() === '') {
      throw new Error('[GrowingAnalytics] 请在初始化配置中传入 dataSourceId')
    }
  }

  // 3. 验证 urlScheme
  if (!(typeof this.urlScheme === 'string') || this.urlScheme.trim() === '') {
    throw new Error('[GrowingAnalytics] 请在初始化配置中传入 urlScheme')
  }

  // 4. 验证 dataCollectionServerHost
  if (!(typeof this.dataCollectionServerHost === 'string') || this.dataCollectionServerHost.trim() === '') {
    throw new Error('[GrowingAnalytics] 请在初始化配置中传入 dataCollectionServerHost')
  }

  // 5. 验证 URL 格式
  let pattern = /^(https?:\/\/)((([a-zA-Z0-9\-]+\.)+[a-zA-Z]{2,})|(\d{1,3}\.){3}\d{1,3})(:\d+)?(\/[^\s]*)?$/
  if (!pattern.test(this.dataCollectionServerHost)) {
    throw new Error('[GrowingAnalytics] 请在初始化配置中传入正确的 dataCollectionServerHost')
  }

  // 6. 创建新的配置对象（深拷贝）
  let config = new GrowingConfig()
  config.mode = this.mode
  config.accountId = this.accountId
  // ... 复制所有字段
  
  return config
}
```

### 验证流程图

```
调用 copy()
    │
    ▼
┌─────────────────────┐
│ 验证 accountId      │
│ 非空且为字符串      │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ NewSaaS/CDP 模式？  │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【是】    【否】
    │         │
    ▼         │
┌──────────┐  │
│验证      │  │
│dataSourceId│ │
└────┬─────┘  │
     │        │
     └────────┘
              │
              ▼
┌─────────────────────┐
│ 验证 urlScheme      │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 验证                │
│ dataCollectionServerHost│
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 验证 URL 格式       │
│ 正则表达式匹配      │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 所有验证通过        │
│ 创建并返回配置副本  │
└─────────────────────┘
```

### 验证错误列表

| 错误信息 | 原因 |
|---------|------|
| 请在初始化配置中传入 accountId | accountId 为空或不是字符串 |
| 请在初始化配置中传入 dataSourceId | NewSaaS/CDP 模式下 dataSourceId 为空 |
| 请在初始化配置中传入 urlScheme | urlScheme 为空或不是字符串 |
| 请在初始化配置中传入 dataCollectionServerHost | 服务器地址为空或不是字符串 |
| 请在初始化配置中传入正确的 dataCollectionServerHost | 服务器地址 URL 格式不正确 |

---

## 使用示例

### 完整配置示例

```typescript
import { GrowingConfig } from '@growingio/analytics'

// NewSaaS 模式完整配置
let config = new GrowingConfig()
  .NewSaaS(
    '123456',                          // accountId
    '654321',                          // dataSourceId
    'growing.123456',                  // urlScheme
    'https://napi.growingio.com'       // 服务器地址
  )

// 功能开关配置
config.autotrackEnabled = true          // 开启无埋点
config.autotrackAllPages = true         // 自动采集所有页面
config.debugEnabled = true              // 开启调试模式

// 数据采集配置
config.dataCollectionEnabled = true     // 开启数据采集（默认）
config.idMappingEnabled = true          // 开启 ID Mapping

// 数据传输配置
config.encryptEnabled = true            // 开启加密（默认）
config.compressEnabled = true           // 开启压缩（默认）
config.useProtobuf = true               // 使用 Protobuf（默认）

// 时间间隔配置
config.sessionInterval = 30             // 会话超时 30 秒
config.dataUploadInterval = 15          // 上传间隔 15 秒
config.dataValidityPeriod = 7           // 数据有效期 7 天

// 网络请求配置
config.requestOptions.connectTimeout = 30   // 连接超时 30 秒
config.requestOptions.transferTimeout = 30  // 传输超时 30 秒

// 忽略某些字段（NewSaaS 模式）
config.ignoreField = IgnoreFields.NetworkState | IgnoreFields.DeviceModel

// 验证并复制配置
try {
  let validConfig = config.copy()
  // 使用配置初始化 SDK
  GrowingAnalytics.start(context, validConfig)
} catch (e) {
  console.error('配置错误：', e.message)
}
```

### 最小配置示例

```typescript
// NewSaaS 最小配置
let config = new GrowingConfig()
  .NewSaaS('123456', '654321', 'growing.123456')
GrowingAnalytics.start(context, config.copy())

// SaaS 最小配置
let config = new GrowingConfig()
  .SaaS('123456', 'growing.123456')
GrowingAnalytics.start(context, config.copy())

// CDP 最小配置
let config = new GrowingConfig()
  .CDP('123456', '654321', 'growing.123456', 'https://cdp.example.com')
GrowingAnalytics.start(context, config.copy())
```

---

## 总结

GrowingConfig 提供了灵活的配置系统：

1. **三种工作模式**：NewSaaS（推荐）、SaaS、CDP
2. **链式配置 API**：使用 Builder 模式，支持链式调用
3. **严格的验证机制**：copy() 方法确保配置完整性和正确性
4. **丰富的配置项**：覆盖功能开关、时间间隔、网络选项等
5. **深拷贝保证**：copy() 返回新的配置对象，避免引用问题

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
