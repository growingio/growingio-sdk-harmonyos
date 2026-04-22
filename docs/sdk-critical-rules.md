# SDK Critical Rules

GrowingIO HarmonyOS SDK 的不可违反红线。**修改核心模块代码前必读**。

## SDK 设计红线

- **初始化前零采集**：`GrowingAnalytics.start()` 调用前，任何采集、存储、网络行为都不允许发生
- **主线程零阻塞**：所有 IO（数据库读写、网络请求）必须在 `TaskPool` 或 `Worker` 中执行，绝不阻塞 UI 线程
- **不重复上报**：事件上报成功（2xx/3xx）后从数据库物理删除，失败时保留等待重试；`isUploading` 标志防止并发发送；`eventSequenceId`（递增序号）仅用于服务端排序
- **最小权限原则**：SDK 只申请 `ohos.permission.INTERNET` 和 `ohos.permission.GET_NETWORK_INFO`

## ArkTS 开发规范

- **ArkTS 严格模式**：不使用 `any`，不做动态属性访问，所有数据结构有明确接口定义
- **Stage 模型**：AbilityStage + UIAbility 生命周期钩子，不使用已废弃的 FA 模型
- **HAR 打包**：SDK 以 HAR 形式交付（`byteCodeHar: true`），公开 API 仅通过 `index.ets` 导出，内部实现不暴露

详细 ArkTS 编码规范见 `growingio-arkts-coding-style` skill。
