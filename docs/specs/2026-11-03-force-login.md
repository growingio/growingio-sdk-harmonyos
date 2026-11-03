# NewSaaS 强制登录模式规格

- 日期：2026-11-03
- 状态：已确认
- 参考实现：[GrowingIO Web JS SDK](https://assets.giocdn.com/sdk/webjs/gdp-full.js)

## 1. 问题定义

GrowingAnalytics 当前自动持久化设备 ID，并立即按既有调度上报事件。接入方需要一种仅用于 NewSaaS 的强制登录模式：先继续采集并持久化事件，但暂停网络上报；动态设置访问用户 ID 后，再以新 ID 上报此前及此后生成的事件。

访问用户 ID 对应事件的 `deviceId`，与 `setLoginUserId` 设置的登录用户 ID（`userId`）相互独立。

## 2. 已确认的范围

- 仅支持 `ConfigMode.NewSaaS`。
- 新增公开配置 `GrowingConfig.forceLogin: boolean`，默认 `false`。
- 新增公开静态接口 `GrowingAnalytics.identify(userId: string): void`。
- 不将 `identify` 加入 `GrowingAnalyticsInterface`，子 Tracker 不提供独立入口。
- 主入口首次有效 `identify` 统一设置全部 NewSaaS 实例的访问用户 ID，并释放所有 NewSaaS 强制登录实例的发送阻塞。
- 每次进程启动都重新等待 `identify`；解锁状态不跨启动保留。
- 待上报事件和访问用户 ID 跨启动持久化。
- 每次启动只接受首次有效 `identify`，后续调用忽略。

## 3. 公开接口行为

### 3.1 配置

```typescript
let config = new GrowingConfig().NewSaaS(accountId, dataSourceId, urlScheme)
config.forceLogin = true
GrowingAnalytics.start(context, config)
```

- 默认值为 `false`，现有接入行为不变。
- `copy()` 必须保留该配置。
- SaaS/CDP 中即使设置为 `true` 也不阻塞、不替换 ID。
- 仅主 Tracker 为 NewSaaS 且启用 `forceLogin` 时，主入口 `identify` 才可生效；因此不支持仅在子 Tracker 开启强制登录的接入方式。

### 3.2 动态设置访问用户 ID

```typescript
GrowingAnalytics.identify('访问用户ID')
```

处理规则：

1. SDK 未初始化、主 Tracker 非 NewSaaS、主 Tracker 未启用 `forceLogin` 或本次启动已解锁：记录日志并忽略。
2. 对输入去除首尾空白；空字符串或处理后长度超过 1000 字符时，记录日志并忽略，发送保持阻塞。
3. 首次有效调用保存访问用户 ID、将本次启动标记为已解锁，并立即尝试发送所有被阻塞的 NewSaaS 实例。
4. 后续 NewSaaS 事件使用新的访问用户 ID；SaaS/CDP 事件不受影响。
5. 本次启动内再次调用不修改 ID，也不再次触发解锁流程。

`identify` 是身份设置接口，不是事件采集接口。`dataCollectionEnabled=false` 时仍可设置身份；既有事件继续遵循当前“已入库数据可发送”的规则，新事件仍按总开关禁止采集。

### 3.3 持久化与读取

- 访问用户 ID 使用独立偏好设置 key，不覆盖自动生成的 `growing_device_id`。
- 初始化时恢复访问用户 ID，但将解锁状态重置为 `false`。
- 下次以 `forceLogin=true` 启动时，事件可先用已恢复的访问用户 ID 构建，但在本次有效 `identify` 前不得上报；若本次传入新 ID，发送副本统一使用新 ID。
- 后续以 `forceLogin=false` 使用 NewSaaS 时，仍沿用已持久化的访问用户 ID。
- `getDeviceId()` 在 NewSaaS 主 Tracker 返回当前有效访问用户 ID；没有动态设置过时返回自动生成的设备 ID。SaaS/CDP 保持原行为。

## 4. 状态转换

| 场景 | 采集/入库 | 网络上报 | 事件 deviceId |
|------|-----------|----------|---------------|
| NewSaaS，`forceLogin=false`，从未 identify | 不变 | 不变 | 自动设备 ID |
| NewSaaS，`forceLogin=true`，本次未 identify | 继续 | 暂停 | 当前已恢复或自动生成的 ID |
| 无效 identify | 继续 | 继续暂停 | 不变 |
| 首次有效 identify 后 | 继续 | 立即尝试补发并恢复定时调度 | 全部 NewSaaS 发送副本使用新 ID |
| 本次启动再次 identify | 继续 | 不重复触发解锁流程 | 保持首次有效 ID |
| 下一次以 `forceLogin=true` 启动 | 继续 | 重新暂停，等待 identify | 恢复上次 ID，identify 后可更新 |
| SaaS/CDP，任意 forceLogin 值 | 不变 | 不变 | 不变 |

## 5. 实现设计

采用“发送闸门 + 上报前替换”。

### 5.1 状态管理

新增内部 `ForceLogin` 管理模块，负责：

- 每次启动的解锁状态；
- 持久化访问用户 ID 的恢复与更新；
- 输入校验、主 Tracker 生效条件和一次性调用限制；
- NewSaaS 事件构建与发送时的有效访问用户 ID 解析。

主 Tracker 初始化时重置运行态。子 Tracker 初始化不得重置主入口已完成的解锁状态。初始化前调用不得产生采集、存储或网络副作用。

### 5.2 发送闸门

- `EventSender` 在读取待发送批次前检查当前上下文。
- NewSaaS 且 `forceLogin=true`、本次未解锁时，不读取发送批次、不构造请求、不访问网络。
- `identify` 成功后，对所有被阻塞的 NewSaaS 上下文触发既有 `EventSender.sendEvent`。
- 既有 `isUploading`、2xx/3xx 成功后删除、失败保留、500 条/2MB 分批和递归补发机制保持不变。
- 首次解锁后 ID 固定，因此并发批次不会使用不同身份。

### 5.3 上报前替换

- 数据库存储内容保持不变，不做 schema 迁移或批量回写。
- 每个 NewSaaS 发送批次在现有 TaskPool `processEvents` 后台任务中，将事件 JSON 的 `deviceId` 设置为当前有效访问用户 ID，再进入 Protobuf 或 JSON 序列化。
- 替换仅生成实际请求数据，不修改原事件的 UUID、事件类型、时间戳、`eventSequenceId`、`userId/userKey` 或其他字段。
- 覆盖当前进程及此前启动遗留的待上报事件；已经成功上传的事件不追改。
- 网络失败的数据库原文继续保留，重试时再次以当前访问用户 ID 构造请求。
- JSON 转换在后台任务执行，不在 UI 线程增加整批解析开销。

## 6. 数据协议与隐私

- 不新增事件字段，不修改 Protobuf schema、SaaS JSON 协议、请求路径或请求头。
- NewSaaS Protobuf 与 JSON 共用替换后的中间事件 JSON。
- `compressEnabled`、`encryptEnabled` 仍在现有网络层处理，组合行为不变。
- 不新增设备信息采集，不新增权限，不扩展 `ignoreField`。
- 不修改 `dataCollectionEnabled`、事件有效期、本地加密数据库和事件序列号语义。

## 7. 产品线影响

| 产品线 | 影响 |
|--------|------|
| NewSaaS | 新增 forceLogin/identify；覆盖 Native、Hybrid、Flutter、UniApp 等所有经统一事件管道生成的待上报事件 |
| SaaS | 无行为变化，forceLogin 不生效 |
| CDP | 无行为变化，forceLogin 不生效 |

不修改线上数据协议，不需要服务端配合。

## 8. 验收标准

1. 默认配置及 `copy()` 后 `forceLogin=false`，既有行为不变。
2. NewSaaS 强制登录模式下，未有效 identify 时事件可入库，但发送批次读取和网络请求均为零。
3. 空白、空字符串、超长 ID、未初始化、非 NewSaaS、未开启 forceLogin 和重复 identify 均不错误解锁。
4. 首次有效 identify 后，主 Tracker 与已启动的强制登录子 Tracker 均立即尝试补发；此后新增的强制登录子 Tracker 使用本次已设置的 ID 和解锁状态。
5. 当前启动和跨启动遗留事件的实际上报 `deviceId` 均为首次有效 identify 的 trimmed ID，其他字段保持不变。
6. NewSaaS Protobuf 与 JSON 请求均正确替换；压缩/加密开启和关闭时均保持现有格式。
7. 上传失败保留事件，后续重试仍使用同一访问用户 ID；成功事件只删除一次，不重复上报。
8. SaaS/CDP 的阻塞、事件 ID 和公开用户 API 行为不变；`setLoginUserId` 不触发挥强制登录解锁。
9. 初始化前 identify 不产生存储或网络行为；批量 JSON 转换在 TaskPool 中执行。
10. GrowingAnalytics 单元测试和 HAR 构建通过，公开 API 文档、混淆规则与模块指南同步更新。

## 9. 非目标

- 不支持 SaaS/CDP 强制登录。
- 不提供子 Tracker 独立 identify 或同一启动内反复切换访问用户 ID。
- 不追改已成功上报的历史数据。
- 不修改数据库中的原始事件 JSON。
- 不调整登录用户 ID、ID Mapping、Session 刷新或事件有效期策略。
