# entry_wearable — 手表端示例应用

面向 HarmonyOS 智能手表（`deviceTypes: ["wearable"]`）的 GrowingAnalytics 接入示例。

手机端示例见 `entry` 模块。两者刻意拆开：按官方多设备工程结构，"一次开发多端部署"只在业务逻辑层与数据层复用，UI 与交互层仍需按设备分别开发。

## 与手机端 demo 的关键差异

| 维度 | entry（手机） | entry_wearable（手表） |
|---|---|---|
| 无埋点 | 开启 | **不开启** |
| `GrowingAnalytics.onWindowStageCreate` | 调用 | **不调用** |
| `autotrackEnabled` | `true` | `false` |
| `hybridAutotrackEnabled` | 默认 `true` | `false`（无 WebView 场景） |
| GrowingToolsKit 插件 | 挂载 | 不挂载（悬浮窗形态，手表放不下） |
| `dataUploadInterval` | 15s | 60s（减少网络唤醒，照顾续航） |
| PAGE 事件 | 无埋点自动产生 | **不产生**，且不新增手动接口（见下） |

`dataUploadInterval` 敢调到 60s，是因为 SDK 侧对手表做了特殊处理：**进入后台生成 `APP_CLOSED` 后会立即冲刷一次上报**（`AnalyticsCore.writeEventToDisk`，仅 `deviceType == 'wearable'` 生效）。手表落腕后会被系统快速冻结，只靠定时器大概率等不到下一次触发，事件会积压到下次冷启动。两者互补：平时低频省电，退出时保证送达。

## 如何关掉无埋点

SDK 有两道独立开关，本 demo 两道都关：

1. **`config.autotrackEnabled = false`** —— 默认值即为 `false`。它控制回调内部是否继续处理，但**不阻止监听注册**。
2. **不调用 `GrowingAnalytics.onWindowStageCreate(this, windowStage)`** —— 这才是决定性的一步。

第 2 点是关键。该方法是无埋点 UI 监听的唯一注册入口，内部会挂上 4 个 `UIObserver` 回调：

```
willClick               → AutotrackClick.onWillClick
navDestinationUpdate    → AutotrackPage.onPageUpdate
navDestinationSwitch    → AutotrackPage.onPageUpdate
routerPageUpdate        → AutotrackPage.onPageUpdate
```

只设 `autotrackEnabled = false` 而仍然调用它，这 4 个回调依然会注册，每次点击和路由跳转都会进入 SDK 回调再被开关拦下 —— 白白付出唤醒成本。手表 CPU 与续航都更紧张，不调用即零注册，是更干净的做法。

不调用不影响其余功能：手动埋点、会话管理、设备信息、事件入库与上报走的是另一条链路（`AnalyticsCore.setLifecycleCallback` 内部注册，与 `Autotrack` 无关）。

## 没有 PAGE 事件

不调用 `onWindowStageCreate` 就没有无埋点，SDK 也不再产生 PAGE 事件；公开 API 中没有手动上报页面浏览的接口（`trackFlutterPage` 仅供 Flutter 桥接使用）。手表端不打算为此新增 PAGE 接口——页面层级浅、停留短，分析价值不足以支撑一个新的公开 API。

确需页面维度可以自己发自定义事件，但要清楚它**不是 PAGE 事件**：`eventType` 为 `Custom`，进不了页面分析，属性也不会映射到 `PageEvent` 的 `path` / `title` / `timestamp` 等顶层字段。本 demo 不演示这种写法，以免被当成推荐 schema。

## 构建

```bash
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p module=entry_wearable@default -p product=default \
  -p requiredDeviceType=wearable assembleHap \
  --analyze=normal --parallel --incremental --daemon
```

产物：`entry_wearable/build/default/outputs/default/entry_wearable-default-signed.hap`

## 尚未验证

以下需要手表模拟器或真机确认，编译期查不到：

- `deviceInfo.deviceType` 实际返回值是否为 `wearable`，以及后端埋点协议是否接受该枚举
- 圆形屏幕下 `display.getDefaultDisplaySync()` 的返回值
- 弱网/息屏场景下事件入库与补发行为

demo 首页已把 `deviceType` 和 `deviceId` 直接显示在界面上，便于真机核对第一项。
