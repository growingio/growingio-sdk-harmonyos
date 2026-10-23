# ViewImpression 逻辑详解

> **模块归属**: 无埋点模块 (autotrack)
> **源文件**: `GrowingAnalytics/src/main/ets/components/autotrack/ViewImpression.ets`、`GrowingAnalytics/src/main/ets/components/interfaces/GrowingImpression.ets`
> **对齐**: iOS SDK `Modules/ViewImpression`（接口、配置项、状态语义保持一致）

本文档描述元素曝光采集的实现：业务方为组件打上曝光标记，组件满足可见条件时发送一个埋点事件（CUSTOM）。

## 目录

- [对外接口](#对外接口)
- [与 iOS 的接口映射](#与-ios-的接口映射)
- [核心架构](#核心架构)
- [可见性判定](#可见性判定)
- [状态机](#状态机)
- [生命周期处理](#生命周期处理)
- [配置与限制](#配置与限制)

---

## 对外接口

```typescript
// GrowingAnalytics
static trackViewImpression(componentId: string, eventName: string, attributes?: GrowingAttrType,
  identifier?: string, config?: GrowingImpressionConfig)
static updateViewImpressionAttributes(componentId: string, attributes: GrowingAttrType, identifier?: string)
static stopTrackViewImpression(componentId: string, identifier?: string)
static addViewImpressionDelegate(delegate: GrowingImpressionDelegate)
static removeViewImpressionDelegate(delegate: GrowingImpressionDelegate)
static resetViewImpressionState(identifier: string)
static resetAllViewImpressionState()

// GrowingConfig
viewImpressionEnabled: boolean                   // 默认 true
viewImpressionConfig: GrowingImpressionConfig    // 全局默认配置
viewImpressionCheckInterval: number              // 秒，默认 0.5

// GrowingImpressionConfig
impressionScale: number   // 0~1，默认 0（露出即算）
stayDuration: number      // 秒，默认 0
repeatable: boolean       // 默认 true
```

ArkUI 声明式组件没有可直接持有的视图对象，组件通过 `.id()` 设置的 **componentId** 作为曝光目标的句柄，对应 iOS 中 `UIView` 实例。

## 与 iOS 的接口映射

| iOS | HarmonyOS |
|-----|-----------|
| `-[UIView growingTrackViewImpression:attributes:identifier:config:]` | `trackViewImpression(componentId, eventName, attributes?, identifier?, config?)` |
| `-[UIView growingUpdateViewImpressionAttributes:identifier:]` | `updateViewImpressionAttributes(componentId, attributes, identifier?)` |
| `-[UIView growingStopTrackViewImpression]` / `...WithIdentifier:` | `stopTrackViewImpression(componentId, identifier?)` |
| `GrowingImpressionDelegate` 三个可选方法 | `GrowingImpressionDelegate` 三个可选函数属性（参数中 view 换为 componentId） |
| `+resetViewImpressionStateWithIdentifier:` / `+resetAllViewImpressionState` | `resetViewImpressionState(identifier)` / `resetAllViewImpressionState()` |
| `GrowingTrackConfiguration.viewImpressionEnabled / viewImpressionConfig / viewImpressionCheckInterval` | `GrowingConfig` 同名配置项 |

差异：
- iOS delegate 为弱引用；ArkTS 侧为强引用，不再需要时需调用 `removeViewImpressionDelegate`
- iOS 视图释放时标记随之消失；HarmonyOS 组件从组件树移除（`onDisappear`）或所在页面销毁时移除标记，组件再次出现需重新标记（建议在组件 `onAppear` 中调用）

## 核心架构

```
GrowingAnalytics.trackViewImpression
        │
        ▼
ViewImpression.mark ──► ImpressionTarget (componentId)
                          ├── slots: Map<identifier | '@default', ImpressionSlot>
                          └── binding: ImpressionBinding
                                  │  UIContext.getAttachedFrameNodeById(componentId)
                                  ▼
                          FrameNode.commonEvent.setOnVisibleAreaApproximateChange
                          FrameNode.commonEvent.setOnDisappear
                                  │  (isExpanding, currentRatio)
                                  ▼
                          evaluateSlot ──► trackSlot ──► AnalyticsCore.core.track (CUSTOM)
```

- **ImpressionSlot**：一个曝光标记（事件名、属性、identifier、配置、曝光状态）
- **ImpressionTarget**：一个组件及其全部槽位、当前可见比例、节点绑定
- **ViewImpressionHost**：外部依赖（可用性判断、全局配置、节点查找、定时器、事件发送）的抽象，单元测试中替换为 FakeHost

所需系统能力均为 API 12：`getAttachedFrameNodeById`、`getPageInfoByUniqueId`、`FrameNode.commonEvent.setOnVisibleAreaApproximateChange / setOnDisappear`、`UIObserver.on('navDestinationUpdate' | 'routerPageUpdate')`。

`commonEvent` 设置的事件与业务侧声明式事件并存，不会覆盖业务回调。

## 可见性判定

- 监听阈值为 `[0, ...各槽位 impressionScale]`（去重排序），`expectedUpdateInterval = viewImpressionCheckInterval`（系统下限 100ms）
- `impressionScale <= 0`：`currentRatio > 0` 即可见
- `impressionScale > 0`：`currentRatio >= impressionScale - 0.001` 即可见（系统在阈值附近回调，且边界存在 ≤0.001 的舍入误差，容差避免 scale = 1 的元素永远达不到）
- 系统可见面积计算的局限同样适用：不计算兄弟节点遮挡、窗口遮挡、旋转

## 状态机

每个槽位维护 `tracked`（本轮可见期内已曝光）、`visibleStarted`（停留计时已开始）、`stayReached`（停留时长已满足）、`recheckToken`（令已调度的复检失效）：

```
不可见 ──(可见)──► 计时中 ──(停留满足)──► trackSlot ──► 已曝光
  ▲                  │                                   │
  └──────(不可见：重置 tracked / 计时)─────────────────────┘
```

trackSlot 依次检查：
1. `repeatable == false` 且 identifier 已在全局 `trackedIdentifiers` 中 → 不发送
2. 任一 delegate 的 `viewImpressionShouldTrack` 返回 false → 不发送（离开再进入时重新询问）
3. 记录 identifier（上限 10000，超出淘汰最早记录并告警一次）
4. 静态属性 + 各 delegate 的动态属性合并（同名键以动态属性为准），发送 CUSTOM 事件
5. 回调 `viewImpressionDidTrack`

重复标记：内容（事件名、属性、配置）不变时保留原槽位状态，避免列表刷新导致重复曝光；同事件名换了 identifier（复用场景）时清除旧槽位。

## 生命周期处理

| 场景 | 处理 | 与 iOS 一致性 |
|------|------|--------------|
| 退后台 | 中断所有停留计时，不重置已曝光状态；后台期间的可见比例回调被丢弃 | 一致（resign active 只清 visibleSince） |
| 回前台 | 统一复检，可见且未曝光的元素重新开始计时 | 一致 |
| 页面隐藏（Navigation 子页 ON_HIDDEN / router 页 ON_PAGE_HIDE） | 中断停留计时，暂不判定；隐藏期间的可见比例回调被丢弃 | — |
| 页面重新显示 | 若隐藏期间经历过退后台（或隐藏时已在后台）→ 视为退后台，不重新曝光；否则视为页面跳转返回 → 重置曝光状态并复检，仍可见的元素重新曝光 | 一致（iOS 页面被覆盖时视图离开 window，返回后重新曝光） |
| 页面销毁（ON_DISAPPEAR / ABOUT_TO_DISAPPEAR） | 移除该页面内的全部标记 | 一致（视图释放） |
| 组件移除（onDisappear） | 移除该组件的全部标记 | 一致（视图释放） |
| 组件重建（uniqueId 变化，如 LazyForEach） | 下次标记时重新绑定新节点，保留曝光状态 | 一致（cell 复用） |
| 标记时组件未挂载 | 每 50ms 重试查找，最多 5 次，仍找不到则放弃并告警 | — |

> 页面隐藏与退后台两个系统回调的先后顺序不确定，因此页面隐藏时只中断计时，等页面重新显示时再根据期间是否经历过退后台决定是否重置曝光状态。已知边界：页面跳转离开后、返回前恰好经历过一次前后台切换，返回时不会重新曝光。

## 配置与限制

- **前置条件**：SDK 已初始化、已调用 `GrowingAnalytics.onWindowStageCreate`、`autotrackEnabled == true`、`viewImpressionEnabled == true`；不满足时 `trackViewImpression` 告警并忽略
- **数据采集开关**：发送走 `AnalyticsCore.core.track`，`dataCollectionEnabled == false` 时事件被丢弃
- **线程**：全部在 UI 线程执行，无 IO
- **componentId** 需在窗口内唯一；列表项请使用带数据标识的 id（如 `'goods_' + item.id`）
- 不支持子 Tracker；事件仅发送至主 Tracker
