# GrowingToolsKit 模块指南

开发者工具模块，包名 `@growingio/tools`，公开入口为 `Index.ets`。本文件只记录长期约束，版本和完整 API 以源码及 `oh-package.json5` 为准。

## 代码入口

- `src/main/ets/components/interfaces/GrowingToolsKit.ets`：插件入口与生命周期。
- `src/main/ets/components/core/`：导航和 Tracker 信息。
- `src/main/ets/components/event/`、`network/`：调试事件与网络请求持久化。
- `src/main/ets/components/pages/`、`views/`：调试面板 UI。
- `src/main/ets/components/utils/`：常量、日志、颜色和偏好存储。

## 修改约束

1. ToolsKit 通过 GrowingAnalytics 的 `config.plugins` 接入，由 SDK 调用生命周期，不增加平行的手动初始化流程。
2. 默认仅用于调试；发布模式启用必须显式经过 `useInRelease`，不能改变默认行为。
3. 调试数据使用独立存储，不直接修改 GrowingAnalytics 的事件数据库或上报队列。
4. 悬浮入口和页面导航遵循现有 UIAbility / WindowStage 生命周期，注意资源释放和深浅色兼容。
5. 公开 API 或插件生命周期变化时，同步导出、声明、混淆规则、调用示例和测试。
6. 与 GrowingAnalytics 共用依赖或模型时，检查两边协议兼容性，不复制出新的隐式数据源。

具体接口、配置字段和依赖版本以源码与 `oh-package.json5` 为准，避免在指南中维护易过期的副本。

## 验证

- 源码修改构建 GrowingToolsKit HAR；影响插件集成时同时验证 GrowingAnalytics 和 entry 示例。
- 构建命令见 `../docs/sdk-build-commands.md`。
- 完成前使用 `verification-before-completion`，并按 `../docs/sdk-review-checklist.md` 审查。
