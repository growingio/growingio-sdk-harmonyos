# GrowingIO HarmonyOS SDK 工程指南

本文档是 GrowingIO HarmonyOS SDK 的领域知识和工程规范总览。适用于所有参与 SDK 开发的工程师与自动化 agent。

## 产品与使命

GrowingIO HarmonyOS SDK 是一个面向 HarmonyOS Next 的数据分析 SDK。通过无埋点（Auto Track）和埋点（Manual Track）两种模式，让业务方以最小接入成本获得完整的用户行为数据。目标是接入方只需几行初始化代码就能获得可靠、准确、合规的行为数据上报能力。

## 核心职责

### 构建 GrowingIO 数据采集 SDK

- 实现 SDK 初始化入口（`GrowingAnalytics.start()`），支持三种模式：NewSaaS、SaaS、CDP，通过 `GrowingConfig` 工厂方法配置
- 提供标准埋点 API：`track(eventName, attributes)`、`setLoginUserId(id)`、`setLoginUserAttributes(attrs)`
- 实现无埋点自动采集：页面浏览（PAGE）、元素点击（VIEW_CLICK）；VIEW_CHANGE 仅在 Hybrid/Flutter 场景下产生，原生无埋点暂不支持；SaaS 模式不支持无埋点采集
- 维护事件数据协议与 GrowingIO 平台 schema 严格对齐，保障多端数据一致性

### 数据管道与可靠上报

- 设计本地事件队列（基于 HarmonyOS RDB 加密数据库），保障离线场景下事件不丢失
- 实现批量上报（batch upload）策略：单批最多 500 条（2MB 上限）+ 定时触发（默认 15 秒）
- 处理网络异常的指数退避重试，避免在弱网环境下轰炸服务器
- 支持 Protobuf（NewSaaS/CDP）和 JSON（SaaS Measurement Protocol v2）双格式序列化，通过 `useProtobuf` 配置
- 支持 Snappy 压缩（`compressEnabled`）和 XOR 混淆加密（`encryptEnabled`）

### HarmonyOS 平台适配

- 挂载 UIAbility 生命周期（`onForeground`/`onBackground`）实现 App 级 session 管理
- 通过 `UIObserver.on('willClick')` + `FrameNode`（`@ohos.arkui.node`）实现无埋点组件识别，支持 Button、Text、Input、ListItem 等组件自动点击采集
- 采集设备上下文：deviceId、bundleName、versionName、networkType、screenSize 等（支持 `ignoreField` 位掩码按需忽略）
- 适配 HarmonyOS API 12（Compatible 5.0.0）~ API 20（Target 6.0.0），使用 `canIUse()` 做能力降级保护

### 隐私合规与数据安全

- 严格遵循《个人信息保护法》（PIPL）和 GrowingIO 隐私政策：初始化前不采集任何数据
- 提供 `dataCollectionEnabled`（全局开关）、`setDataCollectionEnabled(false)` 动态关闭接口
- 支持数据字段脱敏：通过 `ignoreField`（`GrowingIgnoreFields` / `GrowingIgnoreFieldsAll`）枚举位掩码忽略指定设备字段
- 无埋点元素标识：通过 `GrowingAutotrackElementID`（常量字符串 `'GROWING_AUTOTRACK_ELEMENT'`）作为组件自定义属性键，为组件指定稳定业务 ID，供圈选/热图工具识别

## 🚨 Critical Rules

### SDK 设计红线

- **初始化前零采集**：`GrowingAnalytics.start()` 调用前，任何采集、存储、网络行为都不允许发生
- **主线程零阻塞**：所有 IO（数据库读写、网络请求）必须在 `TaskPool` 或 `Worker` 中执行，绝不阻塞 UI 线程
- **不重复上报**：事件上报成功（2xx/3xx）后从数据库物理删除，失败时保留等待重试；`isUploading` 标志防止并发发送；`eventSequenceId`（递增序号）仅用于服务端排序
- **最小权限原则**：SDK 只申请 `ohos.permission.INTERNET` 和 `ohos.permission.GET_NETWORK_INFO`

### ArkTS 开发规范

- **ArkTS 严格模式**：不使用 `any`，不做动态属性访问，所有数据结构有明确接口定义
- **Stage 模型**：AbilityStage + UIAbility 生命周期钩子，不使用已废弃的 FA 模型
- **HAR 打包**：SDK 以 HAR 形式交付（`byteCodeHar: true`），公开 API 仅通过 `index.ets` 导出，内部实现不暴露

详细 ArkTS 编码规范见 `growingio-arkts-coding-style` skill。

---

## 📚 项目文档路由

> `docs/` 目录下有各模块的详细设计文档。**修改代码前请按场景读取对应文档**，避免破坏已有的数据协议和模块边界。

### 核心架构（改动 SDK 主流程时必读）

- `docs/GrowingAnalytics/interfaces/GrowingConfig.md` — 三种模式（NewSaaS/SaaS/CDP）的参数差异、配置项默认值、`copy()` 验证逻辑
- `docs/GrowingAnalytics/interfaces/GrowingAnalytics.md` — 所有公开 API 的签名、行为约束、`GrowingAnalyticsInterface` 接口定义
- `docs/GrowingAnalytics/core/AnalyticsCore.md` — SDK 初始化全流程（模块初始化顺序、插件注册策略、子 Tracker 机制、定时任务）
- `docs/GrowingAnalytics/event/Event.md` — 事件模型全链路（Event → EventBuilder → EventPersistence → EventSender）、字段定义、批量上报限制（500条/2MB）、序列号管理

### 按场景读取

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

### 构建命令

```bash
# 构建 GrowingAnalytics（HAR）
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p product=default -p module=GrowingAnalytics@default \
  assembleHar --analyze=normal --parallel --incremental --daemon

# 构建 GrowingToolsKit（HAR）
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p product=default -p module=GrowingToolsKit@default \
  assembleHar --analyze=normal --parallel --incremental --daemon

# 构建 entry（HAP）
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p module=entry@default -p product=default \
  -p requiredDeviceType=phone assembleHap \
  --analyze=normal --parallel --incremental --daemon

# 清理构建产物
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  -p product=default clean --analyze=normal --parallel --incremental --daemon
```

---

## 💭 沟通风格（面向开发者）

- **数据精准第一**："这里的 `sessionId` 需要在 App 回到前台超过 30 秒（`sessionInterval` 默认值）后重新生成，否则服务端的访问次数指标会偏低"
- **对接入方友好**："初始化推荐用 `new GrowingConfig().NewSaaS()`/`CDP()`/`SaaS()` 实例方法，三种模式的字段要求不同，工厂方法帮接入方做了参数校验；调试工具 `GrowingToolsKit` 是插件，通过 `config.plugins` 注入，不要单独 start"
- **性能意识**："数据库写入必须异步，把它丢到 TaskPool 里，别在 onClick 回调里直接写 RDB"
- **隐私合规敬畏**："数据采集总开关 `setDataCollectionEnabled(false)` 必须在用户拒绝隐私协议后立即调用，SDK 收到 false 后需同时停止上报调度"
- **多端一致性**："这个字段命名在 Android SDK 里叫 `appVersion`，HarmonyOS 这边也必须保持一致，不然数据仓库会出现重复字段"

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

### 无埋点技术深度

- **UIObserver 点击监听**：通过 `UIObserver.on('willClick')` 在事件分发链路上拦截全局点击，结合 `FrameNode`（`@ohos.arkui.node`）遍历组件树，支持 Button、Toggle、Checkbox、Text、Input、ListItem、GridItem 等类型组件的自动点击采集
- **GrowingAutotrackElementID 属性**：值为常量 `'GROWING_AUTOTRACK_ELEMENT'`，作为 ArkUI 组件自定义属性键，供圈选/热图工具稳定识别元素业务 ID
- **元素路径稳定性**：跨版本、跨屏幕尺寸的元素 xpath 路径设计（节点类型 + 同类兄弟节点索引拼接）

### SDK 工程化

- **多版本兼容矩阵**：维护 HarmonyOS API 12（Compatible 5.0.0）~ API 20（Target 6.0.0）的兼容性测试矩阵
- **代码混淆保护**：配置 `obfuscation-rules.txt` 保护 SDK 核心实现，保留公开 API 符号名；`byteCodeHar: true` 编译为字节码 HAR
- **OHPM 发布流程**：`oh-package.json5` 规范配置（当前版本 `@growingio/analytics@2.8.0`）、版本号管理（semver）、OHPM Registry 发布自动化
- **插件架构**：通过 `config.plugins` 数组扩展 SDK 能力（如 GrowingToolsKit 调试插件）
- **调试工具**：`@growingio/tools`（`GrowingToolsKit`）提供 SDK信息、事件库、网络记录、FPS监控等调试 UI

### 数据质量保障

- **事件序号设计**：`eventSequenceId`（递增整数）作为服务端排序键，配合 `sessionId` 保障事件时序
- **加密传输**：`encryptEnabled`（默认 true）XOR 混淆加密事件 payload，`compressEnabled` Snappy 压缩，双重保护

---

**技术决策优先级**：在面对具体技术决策时，以「数据准确性 > 接入成本 > 性能开销 > 包体积」的优先级进行权衡。
