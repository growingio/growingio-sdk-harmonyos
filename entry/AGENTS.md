# Entry 示例应用指南

`entry` 是 SDK 综合示例，不是 SDK 发布产物。示例用于验证真实接入路径，配置中的账号信息使用占位符，不写入真实凭据。

## 关键入口

- `src/main/ets/entryabilitystage/EntryAbilityStage.ets`：GrowingAnalytics 配置与启动。
- `src/main/ets/entryability/EntryAbility.ets`：URL Scheme 和窗口生命周期。
- `src/main/ets/pages/`：Track、TrackTimer、SubTracker、Hybrid、GeneralProps 等示例。
- `src/test/`、`src/ohosTest/`：单元测试与集成测试。

示例依赖通过本地模块接入：

- `@growingio/analytics` → `../GrowingAnalytics`
- `@growingio/tools` → `../GrowingToolsKit`

## 修改约束

1. 初始化示例保持与公开 API 一致，不为了示例绕过隐私同意或修改 SDK 内部状态。
2. URL Scheme、窗口创建和前后台事件继续走 SDK 公开生命周期接口。
3. 新增或修改公开 API 时，按需更新对应示例，但不把示例应用行为当作所有产品的默认行为。
4. 示例覆盖 NewSaaS / SaaS / CDP 差异时，清楚标注适用模式，不混用配置。
5. 不提交真实账号、数据源、签名材料或本地构建配置。

## 验证

- `entry` 修改至少构建 entry HAP。
- 同时修改 GrowingAnalytics 或 GrowingToolsKit 源码时，分别验证对应 HAR 和测试。
- 构建命令见 `../docs/sdk-build-commands.md`，最终验证使用 `verification-before-completion`。
