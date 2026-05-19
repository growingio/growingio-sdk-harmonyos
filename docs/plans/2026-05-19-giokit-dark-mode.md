# GrowingToolsKit 深色模式适配

> **触发 Planning Gate 的原因**：影响文件 ≥ 3（资源新增 2 份 + `Constants.ets` 重构 + 多个 UI 文件 verify），且 `GTKColor` 作为模块内公开符号其类型从 `string enum` 变为 `Resource | string`，属于内部 API 行为变更。
>
> **修订记录**：
>
> **v2（2026-05-19，规划期）** 依据 plan-document-review 反馈修订：
> 1. C1 — 增加 Spike Step 0；`GTKColor` 设计从 "class + static getter" 改为 **`const` 对象字面量**（避免未验证模式），并显式给出 fallback 方案
> 2. C2 — 影响清单补上 `EntryIcon.ets`
> 3. I1 — `blackAlpha` → `transparentBackground` 改名（语义清晰）
> 4. I3 — 自查清单补上 `Color.Green` 系统枚举
> 5. I5 — `primaryWhite` 等历史命名加 JSDoc 注释
> 6. S1 — 任务拆分理由更正：资源新增可先于 Constants 重构（无副作用）
> 7. 新增"公开 API 变更（空）"显式声明节
>
> **v3（2026-05-19，规划期）** 依据 v2 reviewer 二轮反馈再修订：
> 1. I-new-1 — Spike Fallback 从单纯"A 或 B"扩展为决策矩阵（0a/0b 两个 sub-step + 三种路径）
> 2. I-new-2 — Spike Step 0 代码去掉显式 `Resource` 类型注解，依赖类型推断避免编译期假阴性
> 3. I-new-3 — 4.4 Step 7 显式标注"本步实改 2 处"消除字段数歧义
> 4. S-new-1 — T0/T1 任务依赖关系修正（T0 依赖 T1 最小子集）
> 5. S-new-2 — 5 节验收用"按下/抬起态"替代"hover"移动端词汇
>
> **v5（2026-05-19，code-review 期）** 依据 code-reviewer 反馈修订：
> 1. **Important 修复** — `PullToRefreshConfigurator` 文字色 token 从 `gtk_tertiaryBlack`（浅 `#DDDDDD` / 深 `#666666`）改为 `gtk_secondaryBlack`（浅 `#666666` / 深 `#AAAAAA`）。v3 plan 4.4 写"对齐 iOS `black_3`"是误判——iOS `black_3` 的浅色值 `#999999` 在 HM 端没有直接对应 token，而 `gtk_tertiaryBlack` 浅色值 `#DDDDDD` 实际是分隔线色（contrast 1.37:1 不满足 WCAG AA）。修订后对齐 iOS `black_2`，浅色 5.7:1 / 深色 3.4:1 均通过 WCAG AA。
> 2. **Suggestion S1** — 资源 JSON 统一为 8 位 ARGB 格式（base 中 6 个 6 位 RGB token 补 `FF` alpha 前缀；dark 中已是 8 位的保留）。不影响渲染，仅消除维护期歧义。
> 3. **Suggestion S3 衍生** — `Constants.ets` 中 `primaryWhite` JSDoc 补充使用规范："仅用于 `.backgroundColor()`；品牌色背景上的白字请用 `Color.White`，不要用 `primaryWhite` 作 `fontColor`"。
>
> **v4（2026-05-19，实施期）** 依据用户真机目检后两轮反馈追加的范围扩展（实施完成后回填规格）：
> 1. **HOTFIX A** — `ModuleButton.ets` 第 45 行 `.backgroundColor(Color.White)` → `.backgroundColor(GTKColor.transparentBackground)`。**理由**：v3 plan 2.2 节将 ModuleButton 整体标注"不适配"，但该决策仅针对**品牌橙圆形图标的颜色不变**；外层 `Button` 容器硬编码的 `Color.White` 在浅色模式下与白页融合无感知（隐性 bug），切到深色模式后凸显成白色方块——属于"规格遗漏的隐性 bug"而非"违反不适配决策"。**修订后语义**：ModuleButton 的品牌橙不变；外层容器透明化以适配两种模式的页面背景。
> 2. **HOTFIX B** — 8 处 `.fontColor(GTKColor.primaryWhite)` → `.fontColor(Color.White)`（涉及 TrackerTabBar.ets:42,73、EventsList.ets:117,136,146、NetFlow.ets:127,291、SdkInfo.ets:78）。**理由**：v3 plan 4.3 Step 6 预判这些站点"仅需 import 验证、无需修改"，但实际上 `GTKColor.primaryWhite` 同时被用作两种语义：**(a) `.backgroundColor()` 卡片/列表表面**（应随深浅切换：浅=#FFF / 深=#232323）和 **(b) `.fontColor()` 品牌色背景上的白字**（应永远白色）。深色模式下用例 (b) 会变成"橙底深字"对比度差。规格未做语义拆分。**修订后语义**：`GTKColor.primaryWhite` 仅代表"表面色"，所有"品牌色背景上的白字"统一使用 ArkUI 内置 `Color.White`，与 iOS 端 `UIColor whiteColor` 处理范式一致。**保留** 3 处 `.backgroundColor(GTKColor.primaryWhite)` 不变（EventsList.ets:189、NetFlow.ets:155、SdkInfo.ets:69）。
> 3. **影响文件清单更正**（同步第 7 节）：实际 touched 文件中 `ModuleButton.ets`、`TrackerTabBar.ets`、`EventsList.ets`、`SdkInfo.ets` 从"仅 import 验证"升级为"实改"；新增 `AGENTS.md`（同步示例代码 `blackAlpha` → `transparentBackground` 改名）。
> 4. **验收表 5 节更正**：ModuleButton 行的"橙色按钮（不变）"补注：外层容器背景已从 `Color.White` 改为 `transparentBackground`，品牌橙圆形图标颜色不变。

---

## 1. Context（背景）

iOS 版本 `growingio-sdk-ios-toolskit` 已通过 `UIColor (GrowingTK)` 类目 + `colorWithDynamicProvider` 适配 iOS 13+ 深色模式（参考 `Sources/Core/Categories/UIKit/UIColor+GrowingTK.{h,m}`）。HarmonyOS 端 `GrowingToolsKit` 目前 `GTKColor` 是字符串 enum 硬编码，仅按浅色模式呈现，在 HarmonyOS 系统深色模式下 UI 反差强烈、可读性差。

本计划将 HarmonyOS giokit 在深色模式下的色彩与 iOS 对齐，沿用 HarmonyOS 官方推荐的**资源限定符**（`resources/dark/element/color.json`）+ `$r('app.color.xxx')` 自动切换机制，无需运行时手动监听系统模式变化。

### iOS 端色彩 token 与映射（事实源）

> 来源：`Sources/Core/Categories/UIKit/UIColor+GrowingTK.m`

| Token | Light | Dark |
|---|---|---|
| primaryBackgroundColor | `#FC5F3A` | `#FC5F3A` |
| secondaryBackgroundColor | `#FF9167` | `#FF9167` |
| tertiaryBackgroundColor | `#C22A0D` | `#C22A0D` |
| black_alpha | `#000000` α 0.9 | `#FFFFFF` α 0.9 |
| black_1（主要文字） | `#333333` | `#DDDDDD` |
| black_2（次要文字） | `#666666` | `#AAAAAA` |
| black_3（占位/分隔） | `#999999` | `#666666` |
| labelColor | `UIColor.labelColor`（≈`#000000`） | `UIColor.labelColor`（≈`#FFFFFF`） |
| secondaryLabelColor | `#3C3C43` α 0.6 | `#EBEBF5` α 0.6 |
| white_1（主背景） | `#FFFFFF` | `#232323` |
| white_2（次背景） | `#F2F2F7` | `#181818` |
| bg_1（Base VC 背景） | `tertiarySystemBackgroundColor`（`#FFFFFF`） | `tertiarySystemBackgroundColor`（`#2C2C2E`） |
| bg_2（分组背景） | `#F4F5F6` | `#353537` |

### 用户确认的范围决策

| 决策点 | 选择 |
|---|---|
| 技术方案 | 资源限定符 + `$r()` Resource 引用（HarmonyOS 官方推荐，ArkUI 自动随系统模式切换并重绘） |
| **不适配** | FPSCanvas（黑底悬浮 HUD，iOS 无对应实现）、ModuleButton（品牌橙）、EntryIcon（悬浮入口品牌色）、Tag 标签色（hybrid `#FF5733`、flutter `#027DFD`） |

> 备注：EntryIcon 的内层 token `GTKColor.primaryTheme/secondaryTheme` 仍然要参与 `GTKColor` 重构（types 改成 Resource），但**色值在浅深两份资源里同值**，因此呈现效果"不变"——所谓"不适配"是指色值不切换，不代表不重构。

### 三产品线影响标注（数据协议变更覆盖）

本任务**不涉及事件字段、Protobuf/JSON 协议、上报管道、Session、autotrack、`GrowingConfig`**——仅触及 GrowingToolsKit（开发者工具模块）的 UI 呈现层。

- SaaS：✗ 不影响（giokit 不参与事件协议）
- NewSaaS：✗ 不影响
- CDP：✗ 不影响

### 公开 API 变更（显式声明：无）

- `GrowingAnalytics/Index.ets`：**无变更**（已核对：未导出 `GTKColor`）
- `GrowingAnalytics/obfuscation-rules.txt`：**无变更**
- `GrowingToolsKit/Index.ets`：**无变更**（`GTKColor` 属于模块内部，未对外导出）

### 文档同步（显式声明：无）

- `docs/GrowingAnalytics/`：**无变更**（与色彩无关）
- `docs/GrowingToolsKit/`：**不存在该目录**（已 `ls` 核对），无需同步

---

## 2. 当前用法影响面（自查清单）

### 2.1 `GTKColor` 调用站点（直接消费方）

通过 `grep -rn "GTKColor\." GrowingToolsKit/src/main/ets` 全量列出：

| 文件 | token 引用次数 | 备注 |
|---|---|---|
| `components/utils/Constants.ets` | 定义文件（enum） | **改造为 `const` 对象字面量** |
| `components/views/Common.ets` | 2（`primaryLabel`） | NavTitle 文字色 |
| `components/views/TrackerTabBar.ets` | 6（`primaryTheme`/`secondaryTheme`/`primaryWhite`） | 主题色 + 按钮文字，主题色不变 |
| `components/pages/Home.ets` | 1（`tertiaryBlack`） | 底部版本号背景分隔条 |
| `components/pages/SdkInfo.ets` | 4（`primaryWhite`/`tertiaryBlack`/`secondaryTheme`） | 列表背景 + 分隔线 + Header |
| `components/pages/EventsList.ets` | 12（多 token） | 列表背景、Tag、文字、分隔 |
| `components/pages/NetFlow.ets` | 25（多 token，含 `blackAlpha`） | 列表、详情、Header、按钮（含透明背景按钮） |
| `components/pages/EntryIcon.ets` | 2（`primaryTheme`/`secondaryTheme`） | **【v2 补】** 悬浮入口圆球按钮品牌色 |
| `components/interfaces/GrowingToolsKit.ets` | 1（`blackAlpha` → 传给 `setWindowBackgroundColor(string)`） | **保持 string 类型，特殊处理** |

### 2.2 其他散落的硬编码色彩

| 文件 | 现状 | 处理 |
|---|---|---|
| `components/views/ModuleButton.ets` | `'#E5732C'` / `'#FF9167'` / `Color.White` | **不适配**（品牌橙，跟随用户确认） |
| `components/views/PullToRefreshConfigurator.ets` | 默认 `#999999` 3 处 | 适配（详见 4.4） |
| `components/pages/FPSCanvas.ets` | `#1a1a1a` / `#444444` / `#888888` / `#000000AA` 等 | **不适配**（黑底悬浮 HUD，跟随用户确认） |
| `components/pages/NetFlow.ets:106` | `Color.Green` | **【v2 补】不适配**（HarmonyOS 系统色枚举，"请求成功"语义在深浅模式都用绿，符合无障碍习惯） |

### 2.3 `transparentBackground`（原 `blackAlpha`）的特殊语义

> ⚠️ **重要：HarmonyOS 端原 `blackAlpha = '#00000000'` 是"完全透明"语义，而非 iOS 的 `#000000 α 0.9`（近似全黑）。两者同名但用途完全不同。**

**【v2 改名】** 把该字段从 `blackAlpha` 改名为 `transparentBackground`，消除语义错位带来的误导风险。改名只影响 3 个调用点：
- `GrowingToolsKit.ets:159`: `subWindow.setWindowBackgroundColor(GTKColor.transparentBackground)` — 子窗口透明背景
- `NetFlow.ets:190`: `.backgroundColor(GTKColor.transparentBackground)` — 请求详情 Sheet 顶部"请求"按钮透明背景
- `NetFlow.ets:203`: `.backgroundColor(GTKColor.transparentBackground)` — 同上"响应"按钮

两处都依赖"完全透明"语义，不参与深浅模式切换。`setWindowBackgroundColor` API 签名只接受 `string`，必须保持字符串字面量。

**决策**：`transparentBackground` 在新 `GTKColor` 中保持 **`string` 类型**（带 JSDoc 注释说明"完全透明，非深浅色 token"），不进入 Resource。

---

## 3. Goal / Non-Goals

### Goal

1. 在 HarmonyOS 系统切换深色模式时，giokit 主面板（Home/SdkInfo/EventsList/NetFlow/详情 Sheet）**ArkUI 自动重绘**，背景与文字色对齐 iOS 深色模式映射表。
2. `GTKColor` 重构为 `const` 对象字面量，对外暴露的成员名保持不变（`GTKColor.primaryBlack` 等），调用站点 **依赖 `ResourceColor` 联合类型直接兼容 Resource，零修改**。
3. `PullToRefreshConfigurator` 默认下拉/上拉文字色随系统模式切换。
4. 新增的两份 `color.json`（base / dark）通过 hvigor 资源校验，hap 包能正常构建。

### Non-Goals

- 不引入运行时 `mediaquery` 监听（资源限定符已覆盖 99% 场景）。
- 不改动主 SDK `GrowingAnalytics`（与色彩无关）。
- 不适配 FPSCanvas / ModuleButton 的品牌橙圆形图标 / EntryIcon 的色值切换 / Hybrid+Flutter Tag（已明确）。注：ModuleButton **外层容器**已由 v4 HOTFIX A 由 `Color.White` 改为 `transparentBackground`，仅"品牌橙色值"维持不切换。
- 不修改 `entry/` 示例 App（虽然有未提交改动，与本任务无关）。
- 不在 `Index.ets` 公开 `GTKColor`（它本就是模块内部使用，未暴露给宿主 App）。
- 不处理 `PullToRefreshConfigurator.refreshColor`（string，给 Canvas 用，需要 UI context 才能查询资源，本期 Out-of-Scope，保持 `#999999` 浅色默认值）。

---

## 4. 实施步骤

### 4.0 【新增】Spike：验证 `$r()` 在 `const` 对象字面量中的可用性

> **C1 风险化解**：仓库现有 `$r()` 调用 5 处全部位于 `build()` / `@Builder` 上下文中，**无任何先例**在模块顶层 const 初始化器中调用 `$r()`。虽然 HarmonyOS 官方文档将 `$r()` 描述为"返回 `Resource` 字面量"的普通函数（不依赖 UI 上下文），但本项目需要预先在最小用例验证可行性，避免重构到一半发现编译失败。

#### Step 0 - 最小 Spike（**前置条件**：4.1 Step 1 的 base/color.json 至少含 `gtk_primaryTheme` 条目）

> **前置依赖修正**：Spike 实际依赖 T1 的最小子集——`resources/base/element/color.json` 中至少存在 `gtk_primaryTheme` 一条记录，否则 `$r()` 会因资源未注册而求值失败。**Spike 不是 T1 之前，而是 T1 最小子集就绪之后**。

为了分离两类不同失败原因（"`$r()` 不能在模块顶层"和"`$r()` 必须在 ArkUI build 字面量内由编译器解析"），Spike 拆为 **2 个 sub-step**：

##### Sub-step 0a：验证 `$r()` 在模块顶层 const 初始化器中可用

在 `Constants.ets` 顶部新增临时常量。**【v3 修复编译性】** 注意 ArkTS 中 `Resource` 类型默认可用（隐式从 `@ohos.arkui.component` 全局暴露），但为避免编译期 "Cannot find name 'Resource'" 假阴性，去掉显式类型注解、依赖类型推断：

```ts
// 临时 Spike 常量，验证完移除
export const __SPIKE_DARK_MODE_TEST = $r('app.color.gtk_primaryTheme')
```

在 `Home.ets` 临时把版本号 `Row()` 的 `backgroundColor` 改成 `__SPIKE_DARK_MODE_TEST`。

执行：
```bash
hvigorw assembleHar --mode module -p product=default -p module=GrowingToolsKit@default --no-daemon --no-parallel
```

真机/模拟器 run，确认页面渲染正确（橙色）。

**通过判据**：编译 0 error / 0 warning，运行时显示橙色。

##### Sub-step 0b：验证 `$r()` 在普通函数体内可用（仅当 0a 失败时执行）

在 `Constants.ets` 顶部新增：
```ts
export function __spikeGetColor(): Resource | undefined {
  return $r('app.color.gtk_primaryTheme')
}
```
（这里允许写显式返回类型，因为函数签名声明 `Resource` 时 ArkTS 编译器会主动加载该类型。如仍报错，去掉返回类型用类型推断。）

在 `Home.ets` 把版本号 `backgroundColor` 改为 `__spikeGetColor()`。同样 hvigorw + 真机验证。

##### 决策矩阵

| 0a | 0b | 进入路径 |
|---|---|---|
| ✓ 通过 | — | **主方案**：4.2 Step 4 `const` 对象字面量（最优雅） |
| ✗ 失败 | ✓ 通过 | **Fallback A**：`GTKColor` 改为含静态方法的 class（`static get(token: TokenName): Resource { return $r('app.color.gtk_' + token) }`），调用站点 `GTKColor.primaryBlack` → `GTKColor.get('primaryBlack')`，全仓库约 50 处机械替换 |
| ✗ 失败 | ✗ 失败 | **Fallback B**：放弃 `GTKColor` 抽象层，调用站点直接写 inline `$r('app.color.gtk_primaryBlack')`，约 50 处全文件替换（最稳健，但 import 不再统一） |

**Spike 完成清理**：移除 `__SPIKE_DARK_MODE_TEST` / `__spikeGetColor` 临时代码；Home.ets 版本号 backgroundColor 还原为 `GTKColor.tertiaryBlack`。

**Spike 失败时不另行向用户求确认——决策矩阵已穷举**，按上表直接落地对应 fallback。

### 4.1 新增资源文件（无副作用，可独立 commit）

> **【v2 任务拆分修订】** 资源新增是纯增文件，不影响任何现有代码（color.json 是 ArkUI 编译期资源扫描的输入，未被 import 的资源不会触发编译错误）。可独立先行。

#### Step 1 - 创建 `resources/base/element/color.json`（浅色，权威源）

路径：`GrowingToolsKit/src/main/resources/base/element/color.json`

字段命名约定：所有 token 加 `gtk_` 前缀，避免与宿主 App 资源冲突（HarmonyOS Resource 命名空间是 module 级，宿主与 har 之间会合并）。

```json
{
  "color": [
    { "name": "gtk_primaryTheme",       "value": "#FC5F3A" },
    { "name": "gtk_secondaryTheme",     "value": "#FF9167" },
    { "name": "gtk_tertiaryTheme",      "value": "#C22A0D" },
    { "name": "gtk_primaryBlack",       "value": "#333333" },
    { "name": "gtk_secondaryBlack",     "value": "#666666" },
    { "name": "gtk_tertiaryBlack",      "value": "#DDDDDD" },
    { "name": "gtk_primaryWhite",       "value": "#FFFFFFFF" },
    { "name": "gtk_secondaryWhite",     "value": "#FFF2F2F7" },
    { "name": "gtk_primaryLabel",       "value": "#FF000000" },
    { "name": "gtk_secondaryLabel",     "value": "#993C3C43" },
    { "name": "gtk_primaryBackground",  "value": "#FFFFFFFF" },
    { "name": "gtk_secondaryBackground","value": "#FFF4F5F6" },
    { "name": "gtk_hybridTagLabel",     "value": "#FFFF5733" },
    { "name": "gtk_flutterTagLabel",    "value": "#FF027DFD" }
  ]
}
```

#### Step 2 - 创建 `resources/dark/element/color.json`（深色覆盖）

路径：`GrowingToolsKit/src/main/resources/dark/element/color.json`

> **路径正确性核对（v2）**：`resources/dark/element/color.json` 是 HarmonyOS Next API 12+ 的官方资源限定符约定。`dark` 是 ColorMode qualifier 的合法目录名，与 `base` 同级（不是 `resources/base/dark/` 嵌套形式）。

```json
{
  "color": [
    { "name": "gtk_primaryTheme",       "value": "#FC5F3A" },
    { "name": "gtk_secondaryTheme",     "value": "#FF9167" },
    { "name": "gtk_tertiaryTheme",      "value": "#C22A0D" },
    { "name": "gtk_primaryBlack",       "value": "#DDDDDD" },
    { "name": "gtk_secondaryBlack",     "value": "#AAAAAA" },
    { "name": "gtk_tertiaryBlack",      "value": "#666666" },
    { "name": "gtk_primaryWhite",       "value": "#FF232323" },
    { "name": "gtk_secondaryWhite",     "value": "#FF181818" },
    { "name": "gtk_primaryLabel",       "value": "#FFFFFFFF" },
    { "name": "gtk_secondaryLabel",     "value": "#99EBEBF5" },
    { "name": "gtk_primaryBackground",  "value": "#FF2C2C2E" },
    { "name": "gtk_secondaryBackground","value": "#FF353537" },
    { "name": "gtk_hybridTagLabel",     "value": "#FFFF5733" },
    { "name": "gtk_flutterTagLabel",    "value": "#FF027DFD" }
  ]
}
```

> 注 1：`hybridTagLabel` / `flutterTagLabel` 在浅深两份配置中**故意取同值**，符合用户决策"标签色不切换"。  
> 注 2：`primaryTheme` / `secondaryTheme` / `tertiaryTheme` 同上，品牌色不切换。  
> 注 3：**【v2 删除原"覆盖式语义"误导性说明】** 这里两份配置均冗余列出所有 key，确保资源解析器在任意模式下都能命中（HarmonyOS 不同版本对"缺失 key 回退到 base"的行为不一致，全量声明最稳）。

#### Step 3 - hvigor 资源声明（核对结果：无需修改）

**【v2 简化】** 已核对 `GrowingToolsKit/src/main/module.json5`：内容极简，仅含 `name/type/deviceTypes/metadata`，无 `pages` / `qualifiers` 字段。HarmonyOS API 12+ 默认即按 `resources/<qualifier>/` 目录约定加载资源——**无需任何 module.json5 修改**。

### 4.2 `Constants.ets` 重构（依赖 Spike 通过）

#### Step 4 - 把 `GTKColor` 从 enum 改为 `const` 对象字面量

```ts
/**
 * GrowingToolsKit 色彩 token。深浅模式适配通过资源限定符
 * （resources/base/element/color.json + resources/dark/element/color.json）实现。
 *
 * 命名约定（历史保留，请按"语义/用途"而非"字面颜色"理解）：
 * - primaryBlack / secondaryBlack / tertiaryBlack：文字层级（主/次/占位与分隔），
 *   深色模式下值为浅色——名称仅源自浅色模式
 * - primaryWhite / secondaryWhite：表面层（卡片/列表）背景，
 *   深色模式下值为深色（#232323 / #181818）——名称仅源自浅色模式
 * - primaryBackground / secondaryBackground：页面级背景
 * - primaryLabel / secondaryLabel：iOS labelColor / secondaryLabelColor 系统色对齐
 * - primaryTheme / secondaryTheme / tertiaryTheme：品牌橙色（深浅模式相同）
 * - hybridTagLabel / flutterTagLabel：事件类型标记色（深浅模式相同）
 * - transparentBackground：完全透明（#00000000），非深浅色 token，
 *   用于 setWindowBackgroundColor 等只接受 string 的 API
 */
interface GTKColorTokens {
  readonly primaryTheme: Resource
  readonly secondaryTheme: Resource
  readonly tertiaryTheme: Resource
  readonly primaryBlack: Resource
  readonly secondaryBlack: Resource
  readonly tertiaryBlack: Resource
  readonly primaryWhite: Resource
  readonly secondaryWhite: Resource
  readonly primaryLabel: Resource
  readonly secondaryLabel: Resource
  readonly primaryBackground: Resource
  readonly secondaryBackground: Resource
  readonly hybridTagLabel: Resource
  readonly flutterTagLabel: Resource
  readonly transparentBackground: string
}

export const GTKColor: GTKColorTokens = {
  primaryTheme:         $r('app.color.gtk_primaryTheme'),
  secondaryTheme:       $r('app.color.gtk_secondaryTheme'),
  tertiaryTheme:        $r('app.color.gtk_tertiaryTheme'),
  primaryBlack:         $r('app.color.gtk_primaryBlack'),
  secondaryBlack:       $r('app.color.gtk_secondaryBlack'),
  tertiaryBlack:        $r('app.color.gtk_tertiaryBlack'),
  primaryWhite:         $r('app.color.gtk_primaryWhite'),
  secondaryWhite:       $r('app.color.gtk_secondaryWhite'),
  primaryLabel:         $r('app.color.gtk_primaryLabel'),
  secondaryLabel:       $r('app.color.gtk_secondaryLabel'),
  primaryBackground:    $r('app.color.gtk_primaryBackground'),
  secondaryBackground:  $r('app.color.gtk_secondaryBackground'),
  hybridTagLabel:       $r('app.color.gtk_hybridTagLabel'),
  flutterTagLabel:      $r('app.color.gtk_flutterTagLabel'),
  transparentBackground: '#00000000',
}
```

**为何 `const` 对象字面量 vs class + static getter（v2 决策）**：
- `const` 对象字面量是 ArkTS 100% 标准 TS 语法，`$r()` 求值时机明确（模块加载时一次性求值，返回 `Resource` 字面量），完全无类静态字段 / getter 的不确定性。
- ArkUI 解析 `Resource` 字面量发生在每次重绘时——`$r()` 返回的是描述符（含 `params: ['app.color.xxx']`），ArkUI 持有描述符并在重绘时查表，因此**自动随系统模式切换**。

**为何保留 `transparentBackground` 为 string**：
- `setWindowBackgroundColor(color: string)` 是 `@ohos.window` 的 API，签名只接受 string。
- `.backgroundColor()` 接受 `ResourceColor = Color | string | number | Resource`——string 也兼容。
- 维持 string 同时满足两个调用点，避免引入额外间接层（如 `getColorStringSync` 包装器）。

### 4.3 调用站点替换 + 验证

#### Step 5 - `GTKColor.blackAlpha` → `GTKColor.transparentBackground` 改名（3 处）

精确替换：
- `components/pages/NetFlow.ets:190`
- `components/pages/NetFlow.ets:203`
- `components/interfaces/GrowingToolsKit.ets:159`

#### Step 6 - 其余调用站点编译验证（不修改源码）

由于 ArkUI 的 `.backgroundColor()` / `.fontColor()` / `.divider({color})` 都接受 `ResourceColor` 联合类型，且 `Resource` ∈ `ResourceColor`，**这些站点不需要任何修改**。

需逐一打开**编译验证**（hvigorw assembleHar）：
- `components/views/Common.ets`
- `components/views/TrackerTabBar.ets`（注意：`button` builder 形参 `color: () => ResourceColor`，传入 Resource OK）
- `components/pages/Home.ets`
- `components/pages/SdkInfo.ets`
- `components/pages/EventsList.ets`
- `components/pages/NetFlow.ets`
- `components/pages/EntryIcon.ets` **【v2 补】**

如果有任何 `.fontColor(GTKColor.xxx)` 在编译时报"类型不兼容"，说明个别 ArkUI 属性的形参类型不是 `ResourceColor`——届时改为 inline `$r('app.color.gtk_xxx')` 表达。

### 4.4 PullToRefreshConfigurator 适配

**核对结果（v2）**：`PullToRefresh` 组件在 `EventsList.ets:18,75` 和 `NetFlow.ets:18,53` 实际有使用，**非僵尸代码**。本节保留。

#### Step 7 - 默认色字段改为 Resource

**本步实改 2 处**（`refreshTextColor` / `loadTextColor`），第 3 处 `refreshColor` 仅说明 Out-of-Scope 理由。`PullToRefreshConfigurator.ets` 三处默认值的归属：

- `refreshColor: string = '#999999'`（**Out-of-Scope**）— Canvas 动画用，`getRefreshColor(): string` 必须返回 string。保持 `#999999` 浅色默认值不变，作为已知 limitation（深色模式下下拉箭头颜色不变，UX 可接受）。
- `refreshTextColor: ResourceColor = '#999999'` → 改为 `$r('app.color.gtk_tertiaryBlack')`（对齐 iOS `black_3`）。
- `loadTextColor: ResourceColor = '#999999'` → 改为 `$r('app.color.gtk_tertiaryBlack')`。

### 4.5 构建与回归验证

#### Step 8 - 构建产物

```bash
hvigorw clean --no-daemon --no-parallel
hvigorw assembleHar --mode module -p product=default -p module=GrowingToolsKit@default --no-daemon --no-parallel
hvigorw assembleHap --mode module -p product=default -p module=entry@default --no-daemon --no-parallel
```

预期：HAR 与 HAP 均构建通过，无 `Resource not found` / `Unresolved color` 警告。

构建后用 `unzip -l build/.../growing-tools-*.har | grep dark` 检查 HAR 中是否含 `resources/dark/element/color.json`。

#### Step 9 - 真机/模拟器目检

- 启动示例 App，触发 giokit 悬浮入口 → 打开主面板。
- 系统设置 → 显示和亮度 → 深色模式 → 切换 ON。
- 目检对照表（见 5 节）。

---

## 5. Acceptance Criteria（验收）

| 页面 | 浅色模式 | 深色模式 |
|---|---|---|
| Home | 白底、深字、版本号底色 `#DDDDDD` 浅灰 | 深色底（`#2C2C2E` 或继承系统）、浅字、版本号底色 `#666666` 深灰 |
| SdkInfo | 白底列表、橙 Header、`#DDDDDD` 分隔 | `#232323` 底、橙 Header（不变）、`#666666` 分隔 |
| EventsList | 白底、橙 TabBar、Tag 色不变 | `#232323` 底、橙 TabBar（不变）、Tag 色不变 |
| NetFlow 列表 | `#F2F2F7` 底、白卡片、`#666666` 次要文字、`Color.Green` 200 状态码 | `#181818` 底、`#232323` 卡片、`#AAAAAA` 次要文字、`Color.Green`（不变） |
| NetFlow 详情 Sheet | 白底 + 橙 Header、请求/响应按钮区域透明 | `#232323` + 橙 Header、按钮文字浅色、按钮背景透明（依然透）**【v2 新增按下/抬起态切换验证：点按"请求"/"响应"两按钮时，无背景遮挡，橙色下划线 Line 切换正确】** |
| EntryIcon | 橙色悬浮球（不变） | 橙色悬浮球（不变） |
| ModuleButton | 橙色圆形图标（不变），外层容器透明融入白页面 | 橙色圆形图标（不变），外层容器透明融入深色页面 **【v4：外层从 Color.White 改为 transparentBackground】** |
| FPSCanvas | 黑色 HUD（不变） | 黑色 HUD（不变） |

**功能性验收**：
- 切换系统深色模式时 UI **自动重绘**，无需重启 App / 重新打开 giokit 面板。
- 子窗口（giokit 悬浮入口及主面板）背景透明语义保持（`transparentBackground` 透明依然生效）。
- NetFlow 详情 Sheet 顶部双按钮（请求/响应）：浅深模式下按钮区域均为透明叠加，点按时无背景遮挡、橙色下划线 Line 切换正确。
- `hvigorw assembleHar` 0 warning / 0 error。
- HAR 包内 `resources/dark/element/color.json` 存在（`unzip -l` 验证）。

---

## 6. Risks & Open Questions

| 风险 | 等级 | 缓解 |
|---|---|---|
| **`$r()` 在 `const` 对象字面量中编译/运行时不可用** | **中（概率未知，依赖 Spike 收敛）** | 4.0 Spike Step 0 拆 2 sub-step 预先验证；失败时按决策矩阵切 Fallback A（含静态方法的 class）或 Fallback B（inline `$r()`） |
| ArkUI `ResourceColor` 联合在 API 12 早期机型上不覆盖 Resource | 低 | 4.3 Step 6 全文件 hvigorw 编译验证；个案改为 inline `$r()` |
| `module.json5` 资源限定符配置异常导致 dark 资源不被打包 | 低 | Step 8 构建后 `unzip -l` 校验 HAR 内含 `resources/dark/` |
| `transparentBackground` 改名遗漏（仍残留 `GTKColor.blackAlpha` 引用） | 低 | Step 5 精确路径 + `grep -rn "blackAlpha"` 收尾扫描 |
| 宿主 App 资源 namespace 与 har 冲突 | 低 | `gtk_` 前缀已防御 |
| Sheet/Dialog 子树是否继承当前系统模式 | 低 | HarmonyOS Sheet 共享主 UIContext，遵循同一模式；目检即可验证 |
| `primaryWhite` 等命名在深色模式下语义反直觉 | 低 | Step 4 JSDoc 注释明确说明"名称仅源自浅色模式"，引导后续开发者按用途选择 |

**Open Question**：是否需要在示例 App `entry/` 增加一个"显示语言/主题切换"按钮便于测试？  
→ 建议：**不**。系统设置即可触发，避免污染示例 App。

---

## 7. 影响文件清单（完整）

| 类型 | 路径 | 改动 |
|---|---|---|
| 新增 | `GrowingToolsKit/src/main/resources/base/element/color.json` | 14 个 light token |
| 新增 | `GrowingToolsKit/src/main/resources/dark/element/color.json` | 14 个 dark token |
| 重构 | `GrowingToolsKit/src/main/ets/components/utils/Constants.ets` | `GTKColor` enum → `const` 对象（14 个 Resource + 1 个 string） |
| 改动 | `GrowingToolsKit/src/main/ets/components/views/PullToRefreshConfigurator.ets` | 2 个默认值改为 `$r()` |
| 改名 | `GrowingToolsKit/src/main/ets/components/pages/NetFlow.ets` | `GTKColor.blackAlpha` → `GTKColor.transparentBackground`（2 处）+ **【v4】** `.fontColor(GTKColor.primaryWhite)` → `.fontColor(Color.White)`（2 处：耗时徽标、详情 Header） |
| 改名 | `GrowingToolsKit/src/main/ets/components/interfaces/GrowingToolsKit.ets` | `GTKColor.blackAlpha` → `GTKColor.transparentBackground`（1 处） |
| 验证 | `components/views/Common.ets` | 仅 import 验证 |
| **改动** **【v4】** | `components/views/TrackerTabBar.ets` | `.fontColor(GTKColor.primaryWhite)` → `.fontColor(Color.White)`（2 处） |
| 验证 | `components/pages/Home.ets` | 仅 import 验证 |
| **改动** **【v4】** | `components/pages/SdkInfo.ets` | `.fontColor(GTKColor.primaryWhite)` → `.fontColor(Color.White)`（1 处 Header） |
| **改动** **【v4】** | `components/pages/EventsList.ets` | `.fontColor(GTKColor.primaryWhite)` → `.fontColor(Color.White)`（3 处：分组 Header、Hybrid Tag、Flutter Tag） |
| 验证 | `components/pages/EntryIcon.ets` **【v2 补】** | 仅 import 验证（2 处 `primaryTheme`/`secondaryTheme`） |
| **改动** **【v4】** | `components/views/ModuleButton.ets` | 外层 Button `.backgroundColor(Color.White)` → `.backgroundColor(GTKColor.transparentBackground)`；新增 `import { GTKColor }` |
| **改动** **【v4】** | `GrowingToolsKit/AGENTS.md` | 同步示例代码 `blackAlpha` → `transparentBackground` 改名（2 处） |
| 文档 | `docs/plans/2026-05-19-giokit-dark-mode.md` | 本规划文档（v1 → v4） |

**合计**：2 新增 + 9 改动（含 v4 范围扩展）+ 3 仅验证 + 1 plan = **15 个 touched file**。

---

## 8. 任务拆分（v2 修订）

按照 `writing-plans` 的拆分原则：

| Task | 内容 | 依赖 | 可否独立 commit |
|---|---|---|---|
| **T1 - 资源新增** | Step 1 + Step 2：新增两份 color.json | 无（纯新增文件，无消费方时不影响编译） | ✓ 可独立 commit |
| **T0 - Spike** | Step 0 (0a/0b) 验证 `$r()` 在 const 字面量 / 函数体中可用 | T1 的最小子集（base/color.json 至少含 `gtk_primaryTheme`） | 不 commit（用完恢复） |
| **T2 - Constants 重构 + 改名** | Step 4（新 GTKColor 定义）+ Step 5（`blackAlpha` → `transparentBackground` 3 处） | T1（资源必须先存在） | ✓ 可独立 commit |
| **T3 - 调用站点验证** | Step 6 编译验证 7 个文件 | T2 | 不 commit（仅验证） |
| **T4 - PullToRefreshConfigurator 适配** | Step 7 | T1 | ✓ 可独立 commit |
| **T5 - 构建 + 目检** | Step 8 + Step 9 | T2 + T4 | 不 commit（`verification-before-completion`） |

实施建议：
- **commit 1**：T1（仅资源）。
- **执行 T0**（不 commit）确认 Spike 路径——决策矩阵已穷举，无需中途求确认。
- **commit 2**：T2 + T3 + T4（Constants + PullToRefresh 一并）——T3 不产生改动但确认无类型不兼容。
- **commit 3**：若 T5 发现问题，hot fix。

**任务数 < 3 个开发任务**（T1 / T2+T3+T4 / T0 是验证），**不走 `subagent-driven-development`**，由主控制器顺序执行。
