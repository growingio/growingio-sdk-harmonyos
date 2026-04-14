---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks - dispatches fresh subagent per task with two-stage review (spec compliance then code quality)
---

# Subagent-Driven Development

通过 dispatch 独立 subagent 执行 plan 中的每个任务，每个任务完成后进行两阶段审查（规格合规 → 代码质量）。

**为什么用 subagent：** 你是控制器，负责调度和协调。将实现任务委派给独立 subagent，每个 subagent 有隔离的上下文。你精心构造它们需要的指令和上下文，确保它们专注完成任务。它们不继承你的会话历史——你构造它们需要的一切。这也保护了你自己的上下文窗口用于协调工作。

**核心原则：** 每任务一个新鲜 subagent + 两阶段审查（规格 → 质量）= 高质量、快迭代

## 何时使用

**使用条件（全部满足）：**
- 有实施规划（plan 文件）
- 任务大部分相互独立
- 希望在当前会话中连续执行

**不适用时：**
- 无 plan → 先写 plan 或手动实施
- 任务紧密耦合 → 手动实施
- 只有 1-2 个简单改动 → 直接改，不需要这个流程

## 流程

```
读取 plan，提取所有任务全文
  ↓
[Per Task]
  ↓
记录 BASE_SHA
  ↓
Dispatch 实现者 subagent（./implementer-prompt.md）
  ↓
实现者提问？ ──yes──→ 回答问题 → 重新 dispatch
  │no
  ↓
实现者实现、测试、提交、自审
  ↓
返回状态（见"处理实现者状态"）
  ↓
记录 HEAD_SHA
  ↓
Dispatch 规格审查者 subagent（./spec-reviewer-prompt.md）
  ↓
规格合规？ ──no──→ 实现者修复 → 重新规格审查
  │yes
  ↓
Dispatch 质量审查者 subagent（./code-quality-reviewer-prompt.md）
  ↓
质量通过？ ──no──→ 实现者修复 → 重新质量审查
  │yes
  ↓
标记任务完成
  ↓
[/Per Task]
  ↓
更多任务？ ──yes──→ 下一个任务
  │no
  ↓
Dispatch 全局 code-reviewer（sdk-code-review skill）
  ↓
完成
```

## 模型选择

用能胜任的最轻量模型，节省成本和时间。

**机械实现任务**（独立函数、清晰规格、1-2 文件）：用 `haiku`。规划明确时大多数 SDK 实现任务属于此类。

**集成和判断任务**（多文件协调、模式匹配、调试）：用 `sonnet`。

**架构、设计和审查任务**：用 `opus`。

**判断依据：**
- 改 1-2 个文件 + 完整规格 → `haiku`
- 改多个文件 + 有集成逻辑 → `sonnet`
- 需要设计判断或全局理解 → `opus`

## 处理实现者状态

实现者 subagent 返回四种状态之一：

**DONE：** 进入规格合规审查。

**DONE_WITH_CONCERNS：** 实现者完成了但标记了疑虑。先读疑虑再决定：
- 正确性 / 范围问题 → 解决后再审查
- 观察性备注（如"这个文件越来越大"）→ 记录后继续审查

**NEEDS_CONTEXT：** 实现者缺少必要信息。补充上下文，重新 dispatch。

**BLOCKED：** 实现者无法完成。评估阻塞原因：
1. 上下文不足 → 提供更多上下文，同模型重新 dispatch
2. 任务需要更强推理 → 用更强模型重新 dispatch
3. 任务太大 → 拆成更小的子任务
4. plan 本身有问题 → 升级给用户

**绝不**忽略升级信号或让同一模型无变化地重试。实现者说卡住了，就是有东西需要改变。

## Prompt 模板

- `./implementer-prompt.md` — dispatch 实现者 subagent
- `./spec-reviewer-prompt.md` — dispatch 规格合规审查 subagent
- `./code-quality-reviewer-prompt.md` — dispatch 代码质量审查 subagent

## 上下文构造原则

**粘贴全文，不让 subagent 读文件：**
- 任务描述：从 plan 中提取完整文本，粘贴到 prompt 中
- 规格内容：粘贴 plan 相关章节，不给文件路径让 subagent 自己读
- 减少 subagent 的文件读取开销，保证它拿到的信息是你筛选过的

**提供场景设置：**
- 这个任务在整体 plan 中的位置
- 前序任务已完成了什么
- 本任务与其他任务的依赖关系
- 相关的已有代码文件路径

## 示例

```
我使用 Subagent-Driven Development 执行这个 plan。

[读取 plan: docs/plans/2026-04-13-on-page-end.md]
[提取 3 个任务的完整文本]

Task 1: 新增 onPageEnd 接口定义

BASE_SHA=$(git rev-parse HEAD)  # a7981ec

[Dispatch 实现者 subagent，model: haiku]
  → 任务全文 + GrowingAnalyticsInterface 上下文

实现者："开始前有个问题——onPageEnd 的 attributes 参数是 AttributesType 还是 Record<string, string>？"

我："用 AttributesType，和 track() 保持一致。"

[重新 dispatch 实现者]
实现者：
  - 实现了 onPageEnd(pageName, attributes?) 接口
  - 更新了 obfuscation-rules.txt
  - 自审：无遗漏
  - Status: DONE

HEAD_SHA=$(git rev-parse HEAD)  # 3df7661

[Dispatch 规格审查者]
规格审查者：✅ 合规 — 所有需求已实现，无多余工作

[Dispatch 质量审查者]
质量审查者：通过。Suggestion: 考虑给 pageName 加空字符串校验。

[标记 Task 1 完成]

Task 2: 实现 Hybrid 模块中的 onPageEnd 逻辑
...

[所有任务完成后]
[Dispatch 全局 code-reviewer（通过 sdk-code-review skill）]
全局审查：通过，可合并。

完成！
```

## 红线

**绝不：**
- 跳过审查（规格审查和质量审查都不可跳过）
- 带着未修复的问题进入下一个任务
- 并行 dispatch 多个实现者 subagent（会冲突）
- 让 subagent 自己读 plan 文件（提供全文）
- 省略场景设置上下文
- 忽略实现者的提问（回答后再继续）
- 接受规格审查的"差不多"（有问题 = 没通过）
- 在规格审查通过前开始质量审查（顺序不可颠倒）
- 让实现者的自审替代正式审查（两者都需要）
- 自己手动修复代码（上下文污染）——dispatch 修复 subagent

**如果实现者提问：**
- 清楚完整地回答
- 按需提供额外上下文
- 不要催它赶紧写代码

**如果审查者发现问题：**
- 实现者（同一个 subagent）修复
- 审查者重新审查
- 重复直到通过
- 不跳过重新审查

**如果 subagent 失败：**
- dispatch 新的修复 subagent，给出具体指令
- 不自己手动修（上下文污染）

## 与其他 skill 的集成

- **sdk-code-review** — 全部任务完成后，dispatch 全局审查
- **receiving-code-review** — 处理审查反馈的规范
- **growingio-arkts-coding-style** — 实现者和审查者都应遵循的编码规范
- **git-conventions** — 提交信息规范
