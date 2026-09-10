# HarmonyOS 26.0.0 适配验证清单

> 关联 PR：demo 侧新增 `entry/src/main/ets/pages/verify26/`，用于在 26.0.0 与低版本设备上做对照验证。
> 本 PR **不改动 SDK 代码，也不改动工程版本号配置**，只提供可复现的验证场景。

## 一、背景

HarmonyOS 26.0.0（HarmonyOS 7，API 26）于 2026-08-29 Release。API 版本号从 26.0.0 起改为
语义化版本 `X.Y.Z`（不再有 `(N)` 后缀）。配套：DevEco Studio 26.0.0 Release(26.0.0.821)、
Hvigor 6.26.4、ohpm 26.0.0.630、Node.js 24.14.1；compatibleSdkVersion 最低仍支持 4.0.0(10)。

与本 SDK 相关的行为变更共 4 类，全部集中在无埋点采集链路上，需要真机对照验证：

| # | 变更 | 生效规则 | 影响面 |
|---|------|----------|--------|
| 1 | 主页 NavDestination 的 `queryNavDestinationInfo` 可取到信息 | **全部生效**（不受 targetSdkVersion 隔离） | PAGE / VIEW_CLICK 的 `path` 归属 |
| 2 | Dialog、Toast、AlphabetIndexer、文本选择菜单默认开启沉浸式系统材质 | targetSdkVersion ≥ 26 | 弹窗节点树 → `xpath` 前缀（`DIALOG_PATH_PREFIXES`） |
| 3 | ArkWeb Chromium 内核 132 → 144 | 全部生效 | Hybrid 打通、圈选 |
| 4 | 表单类组件触摸热区最小高度、组件阴影模糊半径规格 | targetSdkVersion ≥ 26 | 圈选高亮框与元素 bounds |

此外 26.0.0 新增了 ChipV2/CounterV2/PopupV2/SwipeRefresherV2/TreeViewV2、
LazyColumnLayout/LazyVWaterFlowLayout/LazyDynamicLayout、ContainerReader、SelectionContainer
等组件。它们需要 compileSdkVersion 升到 26 才能写进 demo，本 PR 暂未覆盖，等工具链升级后再补。

## 二、验证方法

1. 用**同一个 HAP**（当前 targetSdkVersion 6.0.0(20)）分别安装到 HarmonyOS 26.0.0 设备和
   6.0.0(20)/5.x 设备上，得到"基线 vs 26"的对照组。
2. 工程升到 targetSdkVersion 26.0.0 后再跑一遍，覆盖 targetSdkVersion ≥ 26 才生效的第 2、4 项。
3. 事件通过 `config.debugEnabled = true` 的日志或 GrowingToolsKit 悬浮窗查看。
4. 入口：demo 首页 → `verify26` 按钮。

## 三、逐项检查

### 1. 主页 NavDestination（`Verify26NavHome`）

页面用 `Navigation(stack, { name: 'Verify26NavHome' })`（HomePathInfo，API 20 起）把一个
NavDestination 指定为主页。

- [ ] 进入页面时 PAGE 事件的 `path`：基线 vs 26 是否一致（`/pages/verify26/Verify26NavHome` 还是 `/Verify26NavHome`）
- [ ] 点击 `click-in-home-navdestination`，VIEW_CLICK 的 `path` 两侧是否一致
- [ ] push 到 Detail 再 pop 回主页，PAGE 事件的条数与顺序两侧是否一致（无重复、无丢失）

**判定**：两侧 `path` 不一致 → `AutotrackClick.getPageInfo()` / `AutotrackPage` 需要按主页
NavDestination 场景补适配，且要评估历史数据口径的兼容处理。

### 2. 弹窗族 xpath（`Verify26Dialogs`）

覆盖 AlertDialog、CustomDialog、Popup、Menu、Sheet、ContentCover、Select、文本选择菜单、键盘。

- [ ] 每类弹窗内按钮的 VIEW_CLICK，`xpath` 前缀是否仍命中 `DIALOG_PATH_PREFIXES`：
      `/root/AlertDialog`、`/root/Dialog`、`/root/Popup`、`/root/MenuWrapper`、
      `/root/SheetWrapper`、`/root/ModalPage`、`/root/SelectOverlay`、`/root/Keyboard`
- [ ] 前缀命中后，`path` 是否正确回退到宿主页面 `/pages/verify26/Verify26Dialogs`

**判定**：任一前缀不再命中 → 需要更新 `Constants.ts` 的 `DIALOG_PATH_PREFIXES`，
否则弹窗内点击的 `path` 会为空。

### 3. 列表 index（`Verify26Lists`）

覆盖 List/ListItem、Grid/GridItem、WaterFlow/FlowItem、GridRow/GridCol。

- [ ] 点击每个 item 上的按钮，事件 `index` 与按钮上显示的序号是否对得上（NewSaaS 模式下列表内 `index` 会 +1）
- [ ] `xpath` 对应层级是否仍为 `ListItem`/`GridItem`/`FlowItem`/`GridCol`，该层 `xcontent` 是否为 `-`

**判定**：层级名或 index 变化 → 需要更新 `LIST_COMPONENTS` / `CONTAINER_COMPONENTS`。

### 4. Hybrid / ArkWeb 144（复用已有 `pages/Hybrid`）

- [ ] Hybrid 页面内的 H5 埋点事件是否正常上报（`window._vds_hybrid` 注入是否成功）
- [ ] 圈选能否正常识别 Web 内元素
- [ ] Mobile Debugger 的 WebSocket 连接与截图是否正常

### 5. 圈选 UX 对照（`Verify26Index` 底部）

Checkbox / Radio / Toggle / Slider + 带阴影卡片。

- [ ] 开启圈选，元素高亮框的位置与大小是否仍与组件贴合（触摸热区最小高度、阴影模糊半径变更后）

## 四、本 PR 之外仍需处理的事项

- `build-profile.json5`：`targetSdkVersion` → `26.0.0`（新格式无括号）；`compileSdkVersion` 随 IDE 升 26.0.0；
  `compatibleSdkVersion` **保持 5.0.0(12)**（宿主的值必须 ≥ 库的值）。两个 HAR 都是 `byteCodeHar: true`，
  字节码 HAR 对宿主 compileSdkVersion 无要求。
- 工具链：DevEco Studio 26.0.0 + 同版本 Command Line Tools；CI 的 Node 从 18 升到 24。
- 用 DevEco 的 **Tools > API Change Assistant** 扫一遍 6.0.0(20) → 26.0.0 的变更。
- 文档：`docs/sdk-engineering-guide.md` 的「API 12~20 降级兼容」改为 12~26。

## 五、参考

- [OS 平台行为变更总览 26.0.0](https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/changelogs-overview-2600)
- [应用集成三方库（har 包）的兼容性指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/app-compatibility-third-har)
- [版本号格式调整说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/version-number-26)
- [应用升级适配指导——向 26.0.0 升级](https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/upgrade-adaptation)
