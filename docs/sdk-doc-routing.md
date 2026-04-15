# SDK 文档路由

> `docs/` 目录下有各模块的详细设计文档。**修改代码前请按场景读取对应文档**，避免破坏已有的数据协议和模块边界。

## 核心架构（改动 SDK 主流程时必读）

- `docs/GrowingAnalytics/interfaces/GrowingConfig.md` — 三种模式（NewSaaS/SaaS/CDP）的参数差异、配置项默认值、`copy()` 验证逻辑
- `docs/GrowingAnalytics/interfaces/GrowingAnalytics.md` — 所有公开 API 的签名、行为约束、`GrowingAnalyticsInterface` 接口定义
- `docs/GrowingAnalytics/core/AnalyticsCore.md` — SDK 初始化全流程（模块初始化顺序、插件注册策略、子 Tracker 机制、定时任务）
- `docs/GrowingAnalytics/event/Event.md` — 事件模型全链路（Event → EventBuilder → EventPersistence → EventSender）、字段定义、批量上报限制（500条/2MB）、序列号管理

## 按场景读取

| 场景 | 文档 |
|------|------|
| 修改会话管理（VISIT/APP_CLOSED 触发时机、session 超时） | `core/Session.md` |
| 修改网络层（RCP、加密压缩、URL 格式、请求头） | `core/Network.md` |
| 修改设备/应用信息采集（ignoreField、网络状态监听） | `core/DeviceInfo.md` |
| 修改用户标识（userId/userKey、ID Mapping、多 Tracker 隔离） | `core/UserIdentifier.md` |
| 修改多 Tracker / GrowingContext 上下文管理 | `core/Context.md` |
| 修改计时事件（EventTimer 状态机、前后台处理） | `core/EventTimer.md` |
| 修改无埋点页面采集（Navigation/Router 监听、双队列、NavBar 栈） | `autotrack/AutotrackPage.md` |
| 修改无埋点点击采集（willClick、XPath 生成算法、弹窗处理） | `autotrack/AutotrackClick.md` |
| 修改 Hybrid/WebView 集成（JSBridge、SaaS 脚本注入、onPageEnd） | `core/Hybrid.md` |
| 修改 Flutter 桥接（Platform Channel、圈选状态、后台 PAGE 缓存） | `core/Flutter.md` |
| 修改插件系统（PluginsInterface 生命周期、DeepLink 处理） | `plugins/Plugins.md` |
| 修改圈选功能（WebSocket 协议、截图机制、XPath 生成、WebView 圈选） | `circle/Circle.md` |
| 修改 MobileDebugger（事件/日志队列、实时发送） | `mobileDebugger/MobileDebugger.md` |
| 工具函数（niceTry、XOR 加密、序列化协议映射、日志系统） | `utils/Utils.md` |
| 遇到 ArkTS 语法限制需要迁移 TypeScript 写法 | `docs/typescript-to-arkts-migration-guide.md` |
