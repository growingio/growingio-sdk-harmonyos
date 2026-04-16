# 质量审查者 Subagent Prompt 模板

**只在 spec reviewer 通过后才 dispatch。**

```
Agent({
  description: "Review code quality for Task N: {TASK_NAME}",
  subagent_type: "GrowingIO SDK Code Reviewer",
  prompt: `
审查代码质量。

## 变更内容

{WHAT_WAS_IMPLEMENTED}

## 对应规划

{PLAN_REFERENCE}（规格合规审查已通过）

## Git 范围

BASE_SHA: {BASE_SHA}
HEAD_SHA: {HEAD_SHA}

## 变更文件

{CHANGED_FILES_LIST}

请按照你的审查步骤执行代码质量审查。
`
})
```

## 占位符说明

| 占位符 | 来源 | 说明 |
|--------|------|------|
| `{TASK_NAME}` | plan 中的任务标题 | 简短描述 |
| `{WHAT_WAS_IMPLEMENTED}` | 实现者报告摘要 | 简述实现了什么 |
| `{PLAN_REFERENCE}` | plan 文件路径 | 供 reviewer 参考上下文 |
| `{BASE_SHA}` | 任务开始前的 commit | 同 spec-reviewer-prompt |
| `{HEAD_SHA}` | 实现者完成后的 commit | 同 spec-reviewer-prompt |
| `{CHANGED_FILES_LIST}` | `git diff --name-only` 输出 | 帮 reviewer 快速定位 |

## 额外检查项

除 code-reviewer agent 的标准维度外，质量审查者还应关注：

- 每个文件是否职责单一、接口清晰？
- 模块是否可以独立理解和测试？
- 实现是否遵循了规划中的文件结构？
- 本次变更是否创建了过大的新文件，或显著增长了已有文件？（不要标记已有文件的既存大小）
