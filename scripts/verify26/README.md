# HarmonyOS 26.0.0 适配验证工具

目标：**不用肉眼看数据**。在两台设备上各跑一次采集，得到两个 JSON，再用 `compare.py` 出结论表。

## 0. 准备

- 两台设备：一台 HarmonyOS **26.0.0**，一台低版本作基线（6.1.0(24) / 6.0.0(20) / 5.x 都行）
- `hdc` 可用（DevEco Studio 自带；或设置环境变量 `HDC=/path/to/hdc`）
- 真机打开 USB 调试，`hdc list targets` 能看到

### 没有 26.0.0 真机：用模拟器

26 那一侧可以用模拟器，基线侧用手头任意低版本真机即可。

- 需要 **DevEco Studio 26.0.0 Release（26.0.0.821）**，它配套 Emulator 26.0.0.400 与 26.0.0 镜像
- macOS 上模拟器**只支持 Apple Silicon**（Intel Mac 不行），macOS ≥ 12.5，内存建议 16GB
- 建法：`Tools > Device Manager > New Emulator` → 选 Phone → 下载 26.0.0 镜像 → Finish → 启动；
  Phone/Tablet/2in1 镜像仅支持在中国境内使用
- 模拟器推包一般免签名，DevEco 里直接 Run `entry` 即可
- 模拟器同样支持 `uitest` 命令行，所以 `--auto` 能跑；它会像真机一样出现在 `hdc list targets` 里

模拟器对本验证的可信度：

| 检查 | 模拟器是否可信 |
|------|---------------|
| 主页 NavDestination path 归属 / 弹窗 xpath / 列表 index | 可信，纯 ArkUI 框架行为 |
| Hybrid / ArkWeb | 可信，官方说明 ArkWeb Kit 支持模拟器 |
| 圈选 UX（阴影、触摸热区） | 仅供参考，模拟器用电脑显示器，存在锯齿与色域差异 |

升级 DevEco 到 26 后，本工程 `targetSdkVersion` 仍是显式配置的 `6.0.0(20)` 不会被动改，
未显式配置的 `compileSdkVersion` 会变成 26.0.0 —— 正好对应第一轮"用 26 SDK 编译、target 仍在 20"。

## 1. 装包

两台设备装**同一个** debug 包（entry 模块，带 `Verify26Recorder` 插件）。
工程没有配 `signingConfigs`，命令行产物未签名，直接用 DevEco Studio 把 `entry` Run 到设备上最省事。

装好后确认插件生效：

```bash
hdc shell hilog -T GIOV26      # 启动 app 后应能看到 GIOV26 开头的日志
```

## 2. 采集（两台设备各跑一次）

> 所有命令都在**电脑上**跑（仓库根目录），手机只负责被 hdc 连着。
> 两条命令是同一条跑两遍，`--label` 只决定产出文件叫什么名字，不负责选设备。

```bash
# 只插 26.0.0 那台：自动模式，脚本用 uitest 自己点，全程无人值守
python3 scripts/verify26/collect.py --label api26 --auto

# 换成基线设备（6.0.0(20)/5.x）再跑一遍
python3 scripts/verify26/collect.py --label api20 --auto
```

两台想同时连着也行，用 `--device` 指名道姓（不指定且连了多台时脚本会直接报错，不会蒙一台）：

```bash
hdc list targets                                   # 先看 connectKey
python3 scripts/verify26/collect.py --label api26 --auto --device <26.0.0 的 connectKey>
python3 scripts/verify26/collect.py --label api20 --auto --device <基线机的 connectKey>
```

如果设备不支持 `uitest` 命令行（脚本会报 `dumpLayout 失败`），去掉 `--auto` 用手动模式：
脚本会打印一份带序号的操作清单，照着点，点完回车即可，数据仍然是脚本抓的。

产物：`verify26-api26.json`、`verify26-api20.json`。

## 3. 比对

```bash
python3 scripts/verify26/compare.py verify26-api20.json verify26-api26.json
```

输出 `verify26-compare.md` + `verify26-compare.json`，退出码 0 = 全 PASS，1 = 有问题。

结论表包含三类判定：

| 检查 | PASS 的含义 | FAIL / CHANGED 说明什么 |
|------|------------|------------------------|
| 弹窗 xpath 前缀 | `xpath` 命中 `DIALOG_PATH_PREFIXES`，且 `path` 回退到宿主页面 | 26.0.0 的弹窗节点树变了，要更新 `Constants.ts` 的 `DIALOG_PATH_PREFIXES` |
| 列表 index | `index` == 按钮序号 + 1，且 xpath 里有 `ListItem`/`GridItem`/`FlowItem`/`GridCol` | 列表层级或 index 口径变了，要更新 `LIST_COMPONENTS` |
| NavDestination path 归属 | 点击事件有非空 `path` | 结合跨版本对照看 `path` 是否从 router 路径变成 `/Verify26NavHome` |
| 跨版本 PAGE 序列 | 两侧页面事件 path 序列一致 | 主页 NavDestination 行为变更影响了页面归属，要评估历史数据口径 |

## 4. 交付

把这三个文件发出来就够了，不需要自己解读：

- `verify26-api20.json`
- `verify26-api26.json`
- `verify26-compare.md`

## 5. 脚本覆盖不到的两项

- **Hybrid / ArkWeb 144**：首页 → `verify26` → `[4. Hybrid]`，在 H5 里点几下。事件同样会被 `Verify26Recorder` 抓到，出现在报告里（`scene` 字段为 1）。
- **圈选 UX**：需要连圈选服务，只能人工看高亮框是否贴合 `verify26` 入口页底部的表单组件/阴影卡片。

## 6. 抓不到数据的排查顺序

1. `hdc shell hilog -T GIOV26` 有没有输出 —— 没有说明装的包不带 `Verify26Recorder`，或 SDK 没初始化
2. 报告里 `brokenRecords` 不为空 —— 日志分片丢了，重跑；或把 `--auto` 换成手动模式放慢节奏
3. 报告里 `stepProblems` 不为空 —— 自动模式没找到对应控件（界面没跳过去/控件文案对不上），照着 `desc` 手动补
4. 兜底：设备沙箱里还有一份完整记录 `files/verify26-events.jsonl`，
   debug 包可用 DevEco 的 Device File Browser 或 `hdc file recv` 取
