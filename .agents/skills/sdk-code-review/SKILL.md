---
name: sdk-code-review
description: Use when a feature, bugfix, or refactoring step is completed and needs review, or before merging to main, or when user says "review", "审查", "帮我看看代码"
---

# SDK 代码审查

> **Type:** Technique | **Discipline:** Rigid

dispatch 审查 subagent 对已完成的工作进行独立审查。审查者不继承当前会话历史——你负责构造它需要的全部上下文。

## 何时触发

**强制：**
- 触发了 Planning Gate 的改动完成后
- 涉及公开 API 变更的改动完成后
- 合并到 master 之前
- subagent-driven-development 全部任务完成后的全局审查

**可选但推荐：**
- 修复复杂 bug 后
- 重构后
- 卡住时（换个独立视角）

## 审查模式选择

### 决策图

```
工作完成，需要审查?
  │
  ▼
有 plan 文件对应本次改动?
  ├─ YES → 模式 A：完整审查（spec-reviewer → code-reviewer）
  │
  └─ NO  → 变更文件 ≤ 5 且不涉及公开 API?
            ├─ YES → 模式 B：独立审查（仅 code-reviewer）
            └─ NO  → 回退去补 plan（writing-plans），再走模式 A

审查者返回结果
  ├─ 通过        → verification-before-completion
  ├─ 需要修改    → 修复 → 重新 dispatch 同审查者（不可自行判断"已修好"）
  └─ 需要讨论    → receiving-code-review skill 处理 push back
```

### 模式 A：完整审查（有 plan 的改动）

dispatch 两个独立审查者，**顺序执行**：

1. **规格合规审查**：dispatch `spec-reviewer` subagent
   - 通过 → 进入步骤 2
   - 不通过 → 修复后重新 dispatch spec-reviewer
   - 需要讨论 → 与用户讨论后决定

2. **代码质量审查**：dispatch `code-reviewer` subagent
   - 通过 → 审查完成
   - 需要修改 → 修复后重新 dispatch code-reviewer
   - 需要讨论 → 与用户讨论后决定

### 模式 B：独立审查（无 plan 的改动）

满足以下**全部**条件时，只 dispatch `code-reviewer` 一次：
- 无对应 plan 文件
- 变更文件 ≤ 5 个
- 不涉及公开 API 变更

## 调度步骤

### 1. 确定变更范围

根据触发场景选择正确的 BASE_SHA：

**场景 A：合并到 master 之前（review 整个功能分支）**

```bash
# 用 merge-base 找到分支与 master 的分叉点
BASE_SHA=$(git merge-base HEAD master)
HEAD_SHA=$(git rev-parse HEAD)
```

**场景 B：单个任务完成后（subagent-driven-development 中的任务级审查）**

```bash
# BASE_SHA 在 dispatch 实现者 subagent 前记录，HEAD_SHA 在实现者提交后记录
# 具体做法见 subagent-driven-development skill
```

**场景 C：当前工作区未提交的改动**

```bash
BASE_SHA=$(git rev-parse HEAD)
# HEAD_SHA 不适用；让审查者用 git diff HEAD 查看未暂存 + 已暂存的改动
```

```bash
# 查看变更文件列表
git diff --name-only $BASE_SHA..$HEAD_SHA

# 查看完整 diff
git diff $BASE_SHA..$HEAD_SHA
```

### 2. Dispatch 审查者

**dispatch spec-reviewer 时，必须提供：**

| 字段 | 说明 | 示例 |
|------|------|------|
| **变更内容** | 本次完成了什么 | "新增 onPageEnd API" |
| **规格/规划** | plan 全文或任务描述全文 | 粘贴 plan 内容 |
| **实现者报告** | 实现者的完成报告（如有） | 粘贴报告 |
| **BASE_SHA** | 变更起始 commit | `a7981ec` |
| **HEAD_SHA** | 变更结束 commit | `3df7661` |
| **变更文件列表** | `git diff --name-only` 的输出 | 文件列表 |

**dispatch code-reviewer 时，必须提供：**

| 字段 | 说明 | 示例 |
|------|------|------|
| **变更内容** | 本次完成了什么 | "新增 onPageEnd API" |
| **对应规划** | plan 文件路径（供参考） | `docs/plans/2026-04-10-on-page-end.md` |
| **BASE_SHA** | 变更起始 commit | `a7981ec` |
| **HEAD_SHA** | 变更结束 commit | `3df7661` |
| **变更文件列表** | `git diff --name-only` 的输出 | 文件列表 |

### 3. 处理审查结果

按 `receiving-code-review` skill 的规范处理反馈。核心流程：

```
审查者返回结果
  ↓
判断结论
  ├── "通过" / "合规" → 继续后续工作
  ├── "需要修改" / "不合规"
  │     ├── Critical → 立即修复，修完后重新 dispatch 同审查者
  │     ├── Important → 合并前修复
  │     └── Suggestion → 记录，可后续处理
  └── "需要讨论" → 与用户讨论后决定
```

**处理原则：**
- Critical 和 Important 修复后，**必须重新 dispatch review**，不可自行判断已修好
- 如果认为审查者判断有误，用技术理由 push back（参见 `receiving-code-review` skill）
- 不做表演式认同，直接修复或给出技术反驳

## Rationalizations

| Excuse | Reality |
|---|---|
| "改动小，跳过审查吧" | 模式 B 已经是最轻量路径，再跳就是裸奔 |
| "我自己看过一遍没问题" | 自审替代不了独立审查，上下文污染 |
| "先做质量审查，规格审查之后补" | 顺序不可颠倒——实现不合规时做质量审查是浪费 |
| "reviewer 说 Important，我觉得是 Suggestion" | 可以 push back，但要有技术理由，不是感觉 |
| "改完了，直接声明通过" | Critical/Important 修复后必须重新 dispatch，不可自判 |

## Red Flags — STOP if you catch yourself thinking these

- "这个改动太小了不需要审查" → 模式 B 就是为小改动设计的，再跳 = 裸奔
- "我自己检查过了，没问题" → 自审替代不了独立审查，你有上下文盲区
- "先跑质量审查，spec review 后面补" → 顺序不可颠倒，规格不合规时质量审查是浪费
- "修完 Critical 了，不用重新 dispatch reviewer" → 必须重新 dispatch，自判 = 赌博

## 关联 skill

- **上游触发：**
  - `subagent-driven-development` 每任务完成后 + 全部完成后的全局审查
  - 手动实施完成后，触发 Planning Gate 的改动必须走模式 A
  - 准备合并到 master 前强制触发
- **调度 subagent：**
  - `spec-reviewer` agent（`.claude/agents/spec-reviewer.md`）— 模式 A 第一阶段
  - `code-reviewer` agent（`.claude/agents/code-reviewer.md`）— 模式 A 第二阶段 / 模式 B 唯一审查者
- **完成后交接：** 通过 → `verification-before-completion` → `finishing-a-development-branch`
- **处理反馈：** `receiving-code-review` 的 STOP-ASK / YAGNI / push back 规范
- **替代路径：** 仅修改文档/配置且无 SDK 行为影响 → 跳过本 skill
