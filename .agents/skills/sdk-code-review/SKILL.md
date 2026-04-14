---
name: sdk-code-review
description: Use when a feature, bugfix, or refactoring step is completed and needs review, or before merging to main, or when user says "review", "审查", "帮我看看代码"
---

# SDK 代码审查

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
