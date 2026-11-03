# GrowingAnalytics 模块指南

核心分析 SDK，包名 `@growingio/analytics`，公开入口为 `index.ets`。本文件只记录长期约束；版本、完整 API 和参数说明不复制到这里。

## 代码入口

- `src/main/ets/components/interfaces/`：公开 API 与配置。
- `src/main/ets/components/core/`：初始化、上下文、用户标识、Session、网络和平台适配。
- `src/main/ets/components/event/`：事件构建、持久化与发送。
- `src/main/ets/components/autotrack/`：页面和点击自动采集。
- `src/main/ets/components/hybrid/`，以及 core 中的 Hybrid / Flutter：外部入口适配。
- `src/test/`：Hypium 单元测试，新增测试文件在 `List.test.ets` 注册。

## 修改约束

1. 修改核心模块前阅读 `../docs/sdk-critical-rules.md`，按 `../docs/sdk-doc-routing.md` 定位对应模块文档。
2. 初始化前不得采集、存储或发起网络请求；数据库和网络 IO 不阻塞主线程。
3. 新事件路径遵循 `dataCollectionEnabled`，新增采集字段检查 `ignoreField` 和权限影响。
4. 明确 NewSaaS / SaaS / CDP 各自是否受影响，不默认把单产品线需求扩展到全部模式。
5. 事件成功上报后删除，失败保留重试；注意并发发送和事件顺序，避免重复上报。
6. 公开 API 仅通过 `index.ets` 导出，并同步声明、`obfuscation-rules.txt`、公开文档和测试。
7. 行为变化时同步 `../docs/GrowingAnalytics/` 中对应文档，不在本文件重复维护 API 清单。

API 与行为以源码及以下文档为准：

- `../docs/GrowingAnalytics/interfaces/GrowingAnalytics.md`
- `../docs/GrowingAnalytics/interfaces/GrowingConfig.md`
- `../docs/GrowingAnalytics/core/AnalyticsCore.md`
- `../docs/GrowingAnalytics/event/Event.md`

## 验证

- 源码修改至少构建 GrowingAnalytics HAR。
- 事件、存储、网络、Session 和用户标识修改还需运行 GrowingAnalytics Hypium 测试。
- 构建命令见 `../docs/sdk-build-commands.md`；交付验证与审查分别使用 `verification-before-completion` 和 `../docs/sdk-review-checklist.md`。
