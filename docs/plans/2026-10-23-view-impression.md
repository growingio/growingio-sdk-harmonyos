# 元素曝光采集（ViewImpression）

> **触发规划的原因**：新增公开 API（`GrowingAnalytics` 2 个静态方法、`GrowingConfig` 3 个配置项、新导出 `GrowingImpressionConfig`），改动文件 ≥ 3。
>
> **修订记录**：
>
> **v2（2026-10-23）** 同步 iOS SDK 收窄 ViewImpression 公开接口的改动：对外只保留 `trackViewImpression(componentId, eventName, attributes?)`、`stopTrackViewImpression(componentId)`、`GrowingImpressionConfig.create(impressionScale, stayDuration)` 与 3 个全局配置项，默认支持重复曝光。identifier 多槽位、不可重复曝光（`repeatable`）、单元素配置、属性更新、按 identifier 移除、曝光回调、状态重置转为内部预留能力：实现与单元测试保留，不经 `GrowingAnalytics` / `index.ets` 暴露，待后续迭代再公开。
>
> **v3（2026-10-23）** 依据需求追加：
> 1. 元素曝光仅支持 NewSaaS 模式，CDP / SaaS 模式下不可用；不可用原因（未初始化 / 非 NewSaaS / 开关关闭 / 未开启无埋点监听）分别输出，配置相关判定抽为 `unavailableReasonOfConfig` 并补充单测
> 2. 组件重建（uniqueId 变化）时曝光状态改为重置：新节点视为新元素（与 iOS 新视图实例一致），不再依赖旧节点回调 0 或 onDisappear
> 3. 示例应用改为逐场景验证页（基础标记/停止、带属性/重复标记、组件移除/重新出现、页面跳转/前后台、列表滚动），并在 EntryAbilityStage 设置全局曝光条件

## 1. Context（背景）

iOS SDK 已通过 `Modules/ViewImpression` 提供元素曝光采集：业务方为视图打上曝光标记，视图满足可见面积占比与停留时长条件时发送一个自定义事件（cstm），并支持不可重复曝光、动态属性、发送前拦截等能力。HarmonyOS SDK 目前缺少对应能力，业务方只能自行监听 `onVisibleAreaChange` 再调用 `track`，难以统一处理停留时长、列表复用、页面切换与前后台等场景。

本计划在 HarmonyOS 端实现与 iOS 接口、配置项、状态语义一致的元素曝光采集。

## 2. 方案

### 2.1 曝光目标的标识

ArkUI 声明式组件没有可持有的视图对象，以组件 `.id()` 作为 componentId 标识曝光目标，通过 `UIContext.getAttachedFrameNodeById` 获取 FrameNode。

### 2.2 可见性检测

使用 `FrameNode.commonEvent.setOnVisibleAreaApproximateChange`（API 12）：
- 由系统按 `expectedUpdateInterval` 节流计算可见比例，对应 iOS `viewImpressionCheckInterval`（runloop 节流检测）
- 通过 `commonEvent` 设置，与业务侧声明式事件并存，SDK 侧无需业务改动组件属性
- 阈值为 `[0, ...各标记 impressionScale]`，0 用于感知完全离开可视区

备选方案及放弃原因：
- 声明式 `onVisibleAreaApproximateChange`：API 17 起才支持，且需要业务方在组件上书写，无法由 SDK 统一管理
- `UIObserver.on('nodeRenderState')`：API 20 起支持，只反映是否渲染，不等价于可见，且官方不建议用于节点复用的列表场景
- 定时遍历组件树计算可见区域：计算量大，官方不建议

### 2.3 状态语义（对齐 iOS）

| 场景 | 行为 |
|------|------|
| 离开可视区后再进入 | 重新曝光（内部预留的 `repeatable = false` 按 identifier 全局只曝光一次） |
| 页面跳转后返回 | 重新曝光（iOS 中页面被覆盖时视图离开 window） |
| 退后台再回前台 | 不重新曝光，仅中断停留计时 |
| 内容不变的重复标记 | 保留曝光状态（列表刷新不重复曝光） |
| 同事件名换 identifier | 清除旧槽位（复用场景） |
| `resetState`（内部预留） | 清除记录，仍可见的元素立即重新曝光 |

页面隐藏/显示通过 `UIObserver` 的 `navDestinationUpdate` 与 `routerPageUpdate` 感知；页面隐藏与退后台回调先后不确定，页面隐藏时只中断计时，显示时再根据期间是否经历退后台决定是否重置。

### 2.4 开关

- **仅支持 NewSaaS 产品线**：CDP、SaaS 模式下 `trackViewImpression` 告警并忽略
- 与 iOS 一致，曝光属于无埋点能力：需 `autotrackEnabled = true`，`viewImpressionEnabled`（默认 true）用于单独关闭曝光

## 3. 公开 API 变更

```typescript
// GrowingAnalytics
static trackViewImpression(componentId: string, eventName: string, attributes?: GrowingAttrType)
static stopTrackViewImpression(componentId: string)

// GrowingConfig
viewImpressionEnabled: boolean = true
viewImpressionConfig: GrowingImpressionConfig
viewImpressionCheckInterval: number = 0.5   // 秒

// 新导出
class GrowingImpressionConfig { impressionScale; stayDuration; static create(impressionScale, stayDuration) }
```

内部预留（不导出）：`ViewImpression.mark` 的 identifier / config 参数、`updateAttributes`、`unmark(componentId, identifier)`、`addDelegate` / `removeDelegate`、`resetState`、`GrowingImpressionConfig._repeatable`、`GrowingImpressionDelegate`。

数据协议：无变更，曝光事件为 CUSTOM 事件，经 `AnalyticsCore.core.track` 发送。

## 4. 影响文件

| 文件 | 变更 |
|------|------|
| `components/autotrack/ViewImpression.ets` | 新增：曝光状态机、节点绑定、页面与前后台处理 |
| `components/interfaces/GrowingImpression.ets` | 新增：`GrowingImpressionConfig`、`GrowingImpressionDelegate`（内部预留） |
| `components/interfaces/GrowingAnalytics.ets` | 新增 2 个静态方法、导出 `GrowingImpressionConfig` |
| `components/interfaces/GrowingConfig.ets` | 新增 3 个配置项及 `copy()` |
| `components/autotrack/Autotrack.ets` | `startObserver` 中注册曝光页面监听 |
| `components/core/AnalyticsCore.ets` | 前后台回调中通知曝光模块 |
| `components/utils/Util.ts` | 新增 `isAttributesEqual` |
| `index.ets` | 导出新类型 |
| `src/test/autotrack/ViewImpression.test.ets`、`src/test/utils/Util.test.ets`、`src/test/List.test.ets` | 单元测试 |
| `docs/GrowingAnalytics/autotrack/ViewImpression.md` 等文档 | 模块文档、接入文档、文档路由 |
| `entry/.../pages/ViewImpression.ets`、`ViewImpressionDetail.ets`、`EntryAbilityStage.ets` | 示例验证页、跳转目标页、全局曝光条件 |

## 5. 测试

`ViewImpressionHost` 抽象外部依赖（可用性、节点查找、定时器、事件发送），单元测试以 FakeHost 驱动可见比例回调与定时器，覆盖：配置截断与拷贝、阈值与容差、重复标记、多槽位、复用、组件重建、挂载重试、不可重复曝光与 reset、停留时长、前后台、页面跳转/隐藏/销毁、delegate 拦截/动态属性/异常隔离。

真机验收：示例应用 `viewImpression` 页面逐场景验证：基础标记/停止、带属性/重复标记、组件移除/重新出现、页面跳转返回、前后台切换、列表滚动；切换到 CDP / SaaS 配置后确认不上报。

## 6. 已知限制

- 系统可见面积计算不考虑兄弟节点遮挡、窗口遮挡、旋转
- 页面跳转离开后、返回前恰好经历一次前后台切换，返回时不重新曝光
- 内部预留的 delegate 为强引用
- 仅主 Tracker
