---
name: systematic-debugging
description: Use when facing ArkTS compile errors, hvigor build failures, hypium test failures, event pipeline bugs, network issues, SDK crashes, or any technical problem where a first attempt didn't work or the cause is unclear
---

# Systematic Debugging

遇到技术问题时，用纪律代替直觉。随机猜测让问题变得更复杂；系统性方法让每次尝试都增加信息量。

**核心原则：** 在不理解根本原因之前，不修改代码。每次修改只验证一个假设。

## 何时触发

- 出现编译错误 / 构建失败 / 测试失败
- 一次尝试没有修复问题
- 时间压力下有"随便试试"的冲动（尤其需要此 skill）
- 同一问题反复出现

## 四阶段方法

### Phase 1：调查根因（先读，不动代码）

目标：用一句话准确描述问题。"X 在 Y 处因为 Z 失败。" 填不上这句话 → 继续调查。

**ArkTS 编译错误：**
```bash
# 找到 ERROR 行和规则 ID
# 示例：error: arkts-no-destruct-assignment at Session.ets:42
```
- 找到具体的文件:行号和规则 ID（如 `arkts-no-destruct-assignment`）
- 对照 `growingio-arkts-coding-style` skill 的约束表，确认违规类型
- 不要只看第一个错误——连带错误可能掩盖真正的根因

**hvigor 构建失败：**
```bash
# 在完整输出中找 ERROR:（不是 WARNING:，不是最后的 BUILD FAILED）
# 常见位置：
#   - 依赖解析阶段：oh-package.json5 版本冲突
#   - 编译阶段：ArkTS 语法错误
#   - 打包阶段：签名/资源问题
```

**hypium 测试失败：**
- 读完整的栈追踪，找到失败的 `expect()` 断言
- 确认实际值 vs 期望值
- 检查 `beforeEach` / `afterEach` 是否正确重置了单例状态

**运行时 / 事件管道问题：**
- 事件未入库：检查 `dataCollectionEnabled` 开关，检查 TaskPool 任务是否静默抛出异常
- 事件入库但未上报：检查 `isUploading` 标志，检查网络权限，检查 `dataSourceId` 是否有效
- 字段值错误：在 `EventBuilder` 处打 log，确认构建时的值
- Session 异常：检查 `sessionInterval` 超时逻辑，检查 `onForeground` / `onBackground` 触发时机

### Phase 2：模式识别

在修复之前，回答以下问题：

**范围判断：**
- 问题是孤立的（单个文件 / 单个测试）还是系统性的（多处同时出现）？
- 系统性问题通常有共同根因，不要逐一修复——找到根因一次性解决

**历史查询：**
```bash
git log --oneline --grep="关键词" -10
```
这个错误出现过吗？上次怎么解决的？

**SDK 特有规律速查：**

| 症状 | 常见根因 |
|------|---------|
| debug 模式正常，release 模式失败 | 混淆规则 / ByteCode HAR 导致符号被混淆，检查 `obfuscation-rules.txt` |
| 第一次测试通过，第二次失败 | 单例状态未在 `afterEach` 中重置（AnalyticsCore / GrowingContext） |
| 本地正常，设备上失败 | 权限缺失（`ohos.permission.INTERNET`）/ API level 兼容性（`canIUse()`） |
| 事件入库后消失 | 上报成功删除逻辑误触发 / `isUploading` 并发标志未释放 |
| 首次 VISIT 事件重复 | 多次调用 `start()` / AbilityStage 生命周期钩子重复触发 |
| 构建警告变错误 | 依赖 `oh-package.json5` 版本升级引入 breaking change |
| TaskPool 任务无响应 | 任务函数抛出异常但被 `@Concurrent` 沙箱静默吞掉，加 try-catch 捕获 |
| 无埋点点击不触发 | `UIObserver.on('willClick')` 未在正确的 UIContext 注册 |

### Phase 3：最小假设

用一句话陈述假设：

> "我认为 **[具体的 X]** 导致了 **[具体的 Y]**，因为 **[具体的 Z]**。"

然后：
1. 确定**最小的验证手段**——改一行代码 + 一条命令就能证伪或证实
2. 如果验证需要改动 5 处以上，假设太宽泛，继续细化

**禁止行为：**
- 调试过程中同时重构代码
- 修多处然后"看哪个起效了"
- 改了代码但没有运行验证命令就宣布修好

### Phase 4：单点修复 + 验证

只实施假设对应的最小修复，然后立即用对应命令验证：

**编译/构建验证：**
```bash
# GrowingAnalytics
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p product=default -p module=GrowingAnalytics@default \
  assembleHar --analyze=normal --parallel --incremental --daemon
```

**测试验证（hypium）：**
- 在 DevEco Studio 运行 `GrowingAnalyticsTest` 配置
- 或只跑失败的那个测试文件，不要跑全部

**事件管道验证：**
- 用 GrowingToolsKit 的事件库界面确认事件入库
- 或直接查询 RDB 数据库表

---

如果修复后问题消失 → 完成，记录根因和解法（在 commit message 或注释中）。

如果问题仍然存在 → 带着"已知不是 X"回到 Phase 1，这次你掌握了更多信息。

## 升级条件

**3 次假设验证后问题仍未解决 → 强制停止，不再继续猜测。**

输出升级报告：

```
## 调试报告

问题描述：[一句话]

已尝试：
1. 假设 [X]，修改了 [Y]，结果 [Z]
2. 假设 [X]，修改了 [Y]，结果 [Z]
3. 假设 [X]，修改了 [Y]，结果 [Z]

当前状态：[问题仍然存在 / 部分缓解]

疑似方向（无法自行验证）：[你的猜测和为什么卡住]

需要：[具体需要什么帮助或信息]
```

升级给用户或标记为 BLOCKED。**不要继续随机尝试。**

## 禁止行为

| 行为 | 为什么禁止 |
|------|-----------|
| 边调试边重构 | 引入新变量，无法确定哪个改动起效 |
| "试试看"式修改（无假设） | 随机游走，增加而非减少不确定性 |
| 并行测试多个假设 | 无法分离原因，修好了也不知道为什么 |
| 3 次失败后继续硬撑 | 已进入无效区间，升级比继续试更快 |
| 修复后不运行验证命令 | 最终在 Step 5 发现更早能发现的问题 |

## 避免这么想

| 想法 | 现实 |
|---|---|
| "直接改一下看看行不行" | 无假设的试探 = 随机游走，增加不确定性 |
| "这个错误面熟，大概率是 X" | 面熟是陷阱；Phase 1 要读完整错误+相关代码再判断 |
| "边调试边顺手重构" | 引入新变量，修好了也不知道哪个改动起效 |
| "同时试 3 个可能的修复" | 无法分离原因；一次一个假设 |
| "失败 3 次再试第 4 次说不定就行" | 进入无效区间，升级比继续试更快 |
| "修完了不跑验证命令也能感觉到过了" | 违反 `verification-before-completion`，最终发现问题更贵 |

## 关联 skill

- **上游触发：** 任何编译 / 构建 / 测试 / 运行时失败，且第一次尝试没解决或原因不明
- **调度 subagent：** 无（控制器/实施者自己执行四阶段）
- **完成后交接：** 修复后 → `verification-before-completion` 做完成前验证门
- **替代路径：** ArkTS 语法类编译错误 → Phase 1 后对照 `growingio-arkts-coding-style` 查约束表；subagent 场景下 3 次失败 → 报告 BLOCKED 升级给控制器
