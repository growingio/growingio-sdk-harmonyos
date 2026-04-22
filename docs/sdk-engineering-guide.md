# GrowingIO HarmonyOS SDK 工程指南

本文档是 GrowingIO HarmonyOS SDK 的领域知识**索引**。适用于所有参与 SDK 开发的工程师与自动化 agent。

## 核心职责（概要）

- **数据采集**：三种模式（NewSaaS/SaaS/CDP）初始化入口；标准埋点 API；无埋点自动采集（PAGE / VIEW_CLICK）
- **数据管道**：本地 RDB 加密队列 + 批量上报（500条/2MB） + 指数退避重试 + Protobuf/JSON 双格式 + Snappy 压缩 + XOR 混淆
- **平台适配**：UIAbility 生命周期 + `UIObserver.on('willClick')` + `FrameNode` 无埋点识别 + API 12~20 降级兼容
- **隐私合规**：PIPL 合规、初始化前零采集、`setDataCollectionEnabled` 动态开关、`ignoreField` 位掩码脱敏

详细行为见 `docs/GrowingAnalytics/` 下各模块文档。

## 🚨 Critical Rules

**修改核心模块代码前 → 必读 [`docs/sdk-critical-rules.md`](./sdk-critical-rules.md)**

## 📚 文档路由

**按场景读取模块文档 → [`docs/sdk-doc-routing.md`](./sdk-doc-routing.md)**

## 🔨 构建命令

**hvigor 构建命令 → [`docs/sdk-build-commands.md`](./sdk-build-commands.md)**

---

## 🎯 SDK 健康指标

- SDK 初始化耗时（主线程）< 5ms，对宿主 App 冷启动影响 < 50ms
- 事件采集准确率 > 99.9%（无重复、无丢失）
- 弱网（3G/4G 抖动）场景下事件 0 丢失，离线缓存事件在网络恢复后 30 秒内全量上报
- SDK HAR 包体积 < 300KB（压缩前）
- 崩溃率 < 0.01%（SDK 内部不向宿主 App 抛出未捕获异常）
- 单元测试覆盖率 > 80%（核心路径 100% 覆盖）
- AppGallery 隐私合规审核一次通过率 > 95%
