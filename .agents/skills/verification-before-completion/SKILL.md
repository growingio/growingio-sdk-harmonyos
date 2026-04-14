---
name: verification-before-completion
description: Use before claiming work is complete, fixed, or ready to review — run the actual verification command and read the full output before asserting success
---

# Verification Before Completion

在声明工作完成之前，必须运行验证命令并亲眼读完输出。

**核心原则：** 没有运行的验证 = 没有验证。"应该能过"不是证据，`BUILD SUCCESSFUL` 才是。

**绝对禁止：**
- "改好了" / "构建成功" / "应该没问题" —— 在运行验证命令之前
- 看到命令启动就假设它会成功
- 只读前几行输出，跳过后面

## 五步验证门

### Step 1：确定验证命令

根据本次变更范围选择正确的命令：

| 变更范围 | 验证命令 |
|---------|---------|
| 只改 `GrowingAnalytics/` 下的源码 | 构建 GrowingAnalytics HAR |
| 只改 `GrowingToolsKit/` 下的源码 | 构建 GrowingToolsKit HAR |
| 改了两个模块 | 分别构建两个 HAR |
| 改了 `entry/`（示例应用） | 构建 entry HAP |
| 改了核心路径（事件管道/存储/网络层） | 构建 HAR + 运行 hypium 测试 |
| 改了 agent/skill/文档配置文件 | 无需构建，确认文件内容正确即可 |

如果不确定范围，选更宽的命令（多构建一个比漏验证好）。

### Step 2：执行命令

```bash
# 构建 GrowingAnalytics HAR
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p product=default -p module=GrowingAnalytics@default \
  assembleHar --analyze=normal --parallel --incremental --daemon

# 构建 GrowingToolsKit HAR
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p product=default -p module=GrowingToolsKit@default \
  assembleHar --analyze=normal --parallel --incremental --daemon

# 构建 entry HAP
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p module=entry@default -p product=default \
  -p requiredDeviceType=phone assembleHap \
  --analyze=normal --parallel --incremental --daemon
```

等命令执行完毕，不提前下结论。

### Step 3：读完整输出

滚动到底部，找到以下关键字：

**构建成功的标志：**
```
BUILD SUCCESSFUL in Xs
```

**构建失败的标志（任意一条出现 = 失败）：**
```
BUILD FAILED
error:
Error:
FAILED
```

**测试通过的标志（hypium）：**
- 所有 test suite 显示通过
- 无 `FAILED` 行

如果输出中有任何 `error:` 行（即使最终显示 `BUILD SUCCESSFUL`），也需要检查——某些警告级别的错误不阻断构建但会在运行时出问题。

### Step 4：确认输出支持你的结论

对照以下检查项：

- [ ] 看到了 `BUILD SUCCESSFUL`（不是只看到命令启动）
- [ ] 输出中没有 `error:` 行
- [ ] `.har` 文件实际存在于输出路径

```bash
# 验证 HAR 文件实际存在
ls -lh GrowingAnalytics/build/default/outputs/default/*.har
ls -lh GrowingToolsKit/build/default/outputs/default/*.har
```

- [ ] 如果跑了 hypium 测试：所有测试通过，无 FAILED

只有全部打勾，才进入 Step 5。

### Step 5：带证据声明完成

声明完成时，附上验证的简要证据：

✅ **正确做法：**
```
构建通过（BUILD SUCCESSFUL，HAR 文件存在于 outputs/default/）。
测试通过（7 个 test suite，全部 pass）。
```

❌ **错误做法：**
```
改好了。
应该没问题。
构建成功。（没有运行命令）
```

## 快速决策树

```
本次改动是什么？
  │
  ├── agent/skill/docs/配置文件 → 确认文件内容正确 → 完成
  │
  ├── SDK 源码（非核心路径） → 构建对应模块 HAR → 通过 → 完成
  │                                               → 失败 → systematic-debugging
  │
  └── SDK 核心路径（事件/存储/网络）
        │
        ├── 构建 HAR → 失败 → systematic-debugging
        │            → 通过
        │
        └── 运行 hypium 测试 → 失败 → systematic-debugging
                              → 通过 → 完成
```

## 与其他 skill 的关系

- **验证失败**：进入 `systematic-debugging` skill 的四阶段方法
- **验证通过后**：根据场景进入 `sdk-code-review`（审查）或 `finishing-a-development-branch`（分支收尾）
- **engineer persona Step 5**：本 skill 是 Step 5 的可调用形式，实现者 subagent 和直接实施模式都应使用
