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

## 二、验证方法（脚本化，不用肉眼比数据）

demo 里注册了 `Verify26Recorder` 插件（`entry/src/main/ets/pages/verify26/Verify26Recorder.ets`），
通过 SDK 的 `onEventWroteToDisk` 回调把每条落库事件以 JSON 写进 hilog（tag `GIOV26`，分片输出）
和沙箱文件，再由 `scripts/verify26/` 下的脚本采集、比对：

```bash
# 两台设备各跑一次（26.0.0 一次，6.0.0(20)/5.x 基线一次）
python3 scripts/verify26/collect.py --label api26 --auto
python3 scripts/verify26/collect.py --label api20 --auto

# 出结论表
python3 scripts/verify26/compare.py verify26-api20.json verify26-api26.json
```

- `--auto` 用 `uitest dumpLayout` + `uitest uiInput click` 按控件文案自动点；设备不支持时去掉 `--auto`
  走手动模式（脚本打印带序号的操作清单，人只负责点，数据仍由脚本抓）。
- 产物 `verify26-compare.md` / `verify26-compare.json` 直接就是结论，退出码 0 = 全 PASS。
- 详细说明见 `scripts/verify26/README.md`。

两轮跑法：
1. 先用当前 `targetSdkVersion 6.0.0(20)` 的同一个包在两台设备上跑 —— 覆盖"全部生效"的第 1、3 项；
2. 工程升到 `targetSdkVersion 26.0.0` 后再跑一轮 —— 覆盖 targetSdkVersion ≥ 26 才生效的第 2、4 项。

## 三、脚本给出的判定

| 检查 | 判定依据 | 不通过时要动的地方 |
|------|----------|-------------------|
| 弹窗 xpath 前缀 | `xpath` 命中 `DIALOG_PATH_PREFIXES`，且 `path` 回退到宿主页面 | `Constants.ts` 的 `DIALOG_PATH_PREFIXES` |
| 列表 index | `index` == 按钮序号 + 1，且 xpath 含 `ListItem`/`GridItem`/`FlowItem`/`GridCol` | `LIST_COMPONENTS` / `CONTAINER_COMPONENTS` |
| NavDestination path 归属 | 点击事件 `path` 非空；跨版本对照看是否从 router 路径变成 `/Verify26NavHome` | `AutotrackClick.getPageInfo()` / `AutotrackPage` |
| PAGE 序列 | 两侧 PAGE 事件的 path 序列一致 | 同上，且需评估历史数据口径兼容 |

脚本覆盖不到、仍需人工的两项：

- **Hybrid / ArkWeb 144**：`verify26` → `[4. Hybrid]`，在 H5 里点几下；事件照样进报告（`scene=1`）
- **圈选 UX**：连上圈选，看 `verify26` 入口页底部表单组件与阴影卡片的高亮框是否贴合

## 三点五、验证结果（2026-09-11，targetSdkVersion = 6.0.0(20)）

采集环境（第二轮已把模拟器分辨率调成与基线机一致，排除屏幕变量）：

| | 基线 | 26 |
|---|---|---|
| 设备 | BRA-AL00 真机 | 模拟器 |
| 系统 | OpenHarmony-6.1.1.120（API 24） | OpenHarmony-7.0.0.105（API 26） |
| 屏幕 | 1216x2688 | 1216x2688 |
| 应用 targetSdkVersion | 6.0.0(20) | 6.0.0(20) |

| 检查 | 结果 | 说明 |
|------|------|------|
| 主页 NavDestination path 归属 | **无影响** | 基线上 `click-in-home-navdestination` 的 path 已经是 `/Verify26NavHome`，PAGE 序列两边逐条一致。SDK 走的 `getPageInfoByUniqueId` 在 6.1.1 上就能拿到主页 NavDestination 信息 |
| 弹窗 xpath 前缀 | **无需改动** | AlertDialog / Dialog / Popup / MenuWrapper / SheetWrapper / ModalPage / SelectOverlay 全部命中 `DIALOG_PATH_PREFIXES`，`path` 均正确回退到宿主页面 |
| 列表 index | **无需改动** | ListItem / GridItem / FlowItem / GridCol 四类的 xpath、xcontent、index 两边完全一致 |
| 文本选择菜单 | **无影响** | xpath、xcontent 完全一致，仅按钮文案随设备语言不同（复制 / Copy） |
| 系统 AlertDialog 内部节点树 | **确认变更**，见下 | SDK 无需改代码，但影响已圈选的元素 |

### 确认变更：系统 AlertDialog 内部节点树

```
基线：/root/AlertDialog/Column/Row/Button                   xcontent=/0/0/0/1/0
26  ：/root/AlertDialog/Column/Scroll/Column/Column/Button   xcontent=/0/0/0/0/0/0/0
```

`Column` 下多了一层 `Scroll`，按钮容器由 `Row` 变 `Column`。两轮采集中第二轮已将模拟器分辨率
调至与基线机一致，差异依旧存在，**排除了屏幕尺寸导致的布局差异**。

- **生效条件**：本轮 `targetSdkVersion` 是 6.0.0(20) 也复现，说明不受 targetSdkVersion 隔离，全部生效
- **官方文档未列出这一条**（26.0.0 变更清单里与弹窗相关的只有"默认开启沉浸式系统材质"，且限定 targetSdkVersion ≥ 26）
- **对 SDK**：xpath 前缀仍是 `/root/AlertDialog`，`DIALOG_PATH_PREFIXES` 命中、`path` 回退正常，**SDK 代码无需改动**
- **对数据**：系统 AlertDialog 内按钮的 xpath / xcontent 变了，已针对这类按钮圈选的元素规则在 26 设备上会失配；
  同一个按钮在 26 与低版本设备上会产生两条不同 xpath 的数据，看板上会分裂
- **建议**：通知业务与数据侧；涉及系统弹窗按钮圈选的应用需在 26 上重新圈选；
  如需跨版本聚合，需要在分析侧做 xpath 归一映射
- **残余变量**：基线是真机、26 是模拟器。节点树由 ArkUI 框架决定，同版本下模拟器与真机应当一致，风险低；
  拿到 26 真机后复测一次，或在同一套模拟器上再建一个 API 24 实例对跑，可彻底钉死

### 仍存在的覆盖缺口

- **`targetSdkVersion` 仍是 20**，第 2、4 项（弹窗默认开启沉浸式系统材质、触摸热区/阴影规格）
  要 target ≥ 26 才生效，本轮**完全未覆盖** —— 升 target 后必须再跑一轮
- 基线是 6.1.1(24)，不是 `compatibleSdkVersion` 所声明的 5.0.0(12)，低版本档位未覆盖
- Hybrid / ArkWeb 144 与圈选 UX 两项本轮未跑

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
