# NewSaaS forceLogin 实施计划

## 输入与目标

依据已确认规格 `docs/specs/2026-11-03-force-login.md`，仅为 NewSaaS 增加 `forceLogin` 和主入口 `identify`。采集与入库不停止，未解锁前不读取发送批次或发起网络请求；首次有效 identify 后，所有 NewSaaS 待上报事件在后台序列化时使用新访问用户 ID。

## 任务 1：以失败测试固定行为

- 在 `GrowingAnalytics/src/test/interfaces/GrowingConfig.test.ets` 增加默认值与 `copy()` 保留测试。
- 新增 `GrowingAnalytics/src/test/core/ForceLogin.test.ets`，覆盖有效/无效 ID、首次解锁、重复调用、主模式与开关条件、跨启动运行态重置、NewSaaS/SaaS/CDP 的有效 ID 解析。
- 在 `EventSendCycle.test.ets` 增加发送闸门测试：禁止发送时不调用 `fetchEvents`、`sendEvents`。
- 在 `EventBuilder.test.ets` 增加动态访问用户 ID 与多模式隔离测试。
- 新增后台序列化测试，验证 NewSaaS JSON/Protobuf 的 `deviceId` 替换、其他字段保留、原数据库对象不变，以及压缩开关；加密继续由 Network 现有路径覆盖。
- 在 `src/test/List.test.ets` 注册新增测试。
- 使用项目 hvigor 测试命令运行，记录因配置、ForceLogin 或序列化参数尚不存在导致的预期失败。

## 任务 2：实现状态与公开 API

- `GrowingConfig.ets`：增加 `forceLogin=false` 并在 `copy()` 中复制。
- `Constants.ts`：增加独立的访问用户 ID 偏好设置 key。
- 新增 `core/ForceLogin.ets`：集中管理持久化 ID、每次启动解锁状态、输入 trim/长度校验、模式判断与发送条件；提供测试重置方法。
- `AnalyticsCore.ets`：主初始化时重置并恢复 ForceLogin；新增静态 identify，首次成功后触发所有 NewSaaS 强制登录上下文补发；`getDeviceId()` 返回当前上下文有效 ID。初始化前调用无副作用。
- `interfaces/GrowingAnalytics.ets`：新增静态 `identify(userId: string)`，不修改 `GrowingAnalyticsInterface`。
- `index.ets` 已导出 GrowingAnalytics，不增加新导出符号。
- `obfuscation-rules.txt`：保留 `forceLogin`、`identify` 公开名称。
- 运行任务 1 相关测试并修正到通过。

## 任务 3：接入事件管道与后台序列化

- `EventBuilder.ets`：NewSaaS 使用 ForceLogin 解析的有效访问用户 ID，其他模式沿用 DeviceInfo。
- `EventSender.ets`：在 `runSendCycle` 取批次前检查闸门；网络调用传入当前 NewSaaS 访问用户 ID。
- `Network.ets`、`utils/Concurrent.ets`：增加内部可选 deviceId 参数，在 TaskPool 中复制事件 JSON、替换字段后进入既有 Protobuf/JSON、压缩与加密流程；不改数据库原文、UUID、序列号或网络协议。
- 运行 ForceLogin、EventBuilder、EventSendCycle、序列化及 Network 测试，确认正常模式无回归。

## 任务 4：同步文档

- 更新 `docs/GrowingAnalytics/interfaces/GrowingConfig.md`、`GrowingAnalytics.md`。
- 更新 `docs/GrowingAnalytics/core/AnalyticsCore.md`、`UserIdentifier.md`、`event/Event.md`、`utils/Utils.md`（后台序列化说明）。
- 更新 `GrowingAnalytics/AGENTS.md` 的公开 API 与配置清单。
- 将规格状态改为已确认，并检查所有新增行为均有对应文档，无旧行为描述残留。

## 任务 5：交付验证

- 执行 GrowingAnalytics 标准单元测试命令和 HAR 构建命令。
- 检查 NewSaaS JSON 与 Protobuf、压缩/加密组合、失败重试、跨启动状态和多 Tracker 测试证据。
- 运行 `git diff --check`、ArkTS 规范自查和 `git status --short`，不覆盖现有 BuildProfile 工作区修改，不保留测试临时产物。
- 若本机无可用测试运行时或设备，明确区分已完成的构建验证与未能执行的设备测试，不以导入/编译代替行为验证。

## 影响产品线

- NewSaaS：实现完整强制登录与补发行为。
- SaaS：仅验证不受 ForceLogin 影响，不改协议和上报路径。
- CDP：仅验证不受 ForceLogin 影响，不改协议和上报路径。
