# GrowingIO HarmonyOS SDK 工程指南

本文档是 GrowingIO HarmonyOS SDK 的领域知识**索引**。适用于所有参与 SDK 开发的工程师与自动化 agent。

## 产品与使命

GrowingIO HarmonyOS SDK 是一个面向 HarmonyOS Next 的数据分析 SDK。通过无埋点（Auto Track）和埋点（Manual Track）两种模式，让业务方以最小接入成本获得完整的用户行为数据。目标是接入方只需几行初始化代码就能获得可靠、准确、合规的行为数据上报能力。

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

## 🔄 持续积累的知识域

- **GrowingIO 数据协议版本**：SaaS/NewSaaS/CDP 三种模式的字段差异、新增事件类型、废弃字段的处理规则
- **HarmonyOS API 变更**：ArkTS 语言规范更新、系统 API 废弃与替换（尤其是设备信息和网络类 API），当前兼容 API 12 ~ 20
- **无埋点技术演进**：`UIObserver` + `FrameNode` API 的支持组件范围变化、`GrowingAutotrackElementID` 属性的使用规范
- **隐私法规动态**：PIPL 执行细则、AppGallery 隐私标签审核要求变化
- **性能基准**：各主流机型上 SDK 初始化耗时、事件落库延迟、上报网络开销的实测数据

## 🎯 SDK 健康指标

- SDK 初始化耗时（主线程）< 5ms，对宿主 App 冷启动影响 < 50ms
- 事件采集准确率 > 99.9%（无重复、无丢失）
- 弱网（3G/4G 抖动）场景下事件 0 丢失，离线缓存事件在网络恢复后 30 秒内全量上报
- SDK HAR 包体积 < 300KB（压缩前）
- 崩溃率 < 0.01%（SDK 内部不向宿主 App 抛出未捕获异常）
- 单元测试覆盖率 > 80%（核心路径 100% 覆盖）
- AppGallery 隐私合规审核一次通过率 > 95%

## 🚀 进阶能力

- **无埋点技术深度**：`UIObserver.on('willClick')` + `FrameNode` 组件树遍历；`GrowingAutotrackElementID`（值为 `'GROWING_AUTOTRACK_ELEMENT'`）作为稳定业务 ID；跨版本/跨屏幕尺寸的元素 xpath 路径（节点类型 + 同类兄弟节点索引拼接）
- **SDK 工程化**：API 12~20 兼容矩阵；`obfuscation-rules.txt` 保护 + `byteCodeHar: true` 字节码 HAR；OHPM 规范（`@growingio/analytics@2.8.0`）；`config.plugins` 插件架构（如 `GrowingToolsKit`）
- **数据质量保障**：`eventSequenceId` 服务端排序键 + `sessionId` 时序；`encryptEnabled`（默认 true）XOR 加密 + `compressEnabled` Snappy 压缩双重保护

---

> Agent 行为约定（沟通风格、决策权衡优先级等）见 `.claude/agents/engineering-harmonyos-sdk-engineer.md`。
