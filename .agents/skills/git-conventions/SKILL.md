---
name: git-conventions
description: Use when committing, creating or naming branches, writing PR titles or descriptions, tagging versions, or asking about Git conventions in this project
---

# Git 与 PR 规范

## 提交前

- 先检查 `git status`、目标分支和完整 diff，确认不混入用户已有修改或生成文件。
- 按文件精确暂存，不使用 `git add -A` / `git add .` 一把提交。
- 一次提交聚焦一件事；验证要求见 `verification-before-completion`。
- 只在用户要求时执行 commit、push、合并、删除分支或打 tag，不擅自合并到 master。

## Commit message

格式：`<type>(<scope>): <subject>`

- type：`feat`、`fix`、`docs`、`style`、`refactor`、`perf`、`test`、`chore`、`ci`、`revert`。
- subject 使用祈使句，首字母小写，不超过 50 个字符，结尾不加句号。
- 仅 SaaS 或 CDP 时使用对应 scope；NewSaaS、跨产品线或范围不清时省略 scope。
- 功能模块可使用 `autotrack`、`circle`、`mobiledebugger`、`giokit`、`hybrid`、`flutter`，不与产品线 scope 混用。

示例：

```text
feat: add referralPage for page event
fix(saas): resolve login user ID validation issue
docs: update integration guide
refactor: simplify event processing logic
```

按项目约定，每个 commit 包含：

```text
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

## 分支

- 主分支：`master`。
- 功能分支：`<type>/<short-description>`，例如 `feat/analytics-v3`、`fix/memory-leak`。
- 发版分支：`release/v<version>`。
- 热修复分支：`hotfix/<description>`。

新功能 PR 默认基于最新 `origin/master`，避免无意包含其他未合并功能分支的提交。

## PR

标题清楚描述产品或工程行为，不必机械复制 commit subject。描述包含：

1. 背景和目标。
2. 主要变更及影响范围。
3. 实际执行的构建、测试和配置验证。
4. 未验证场景、既有失败或风险；关联 Issue（如有）。

用户要求提交 PR 时，可以创建分支、提交、推送并创建 PR；不自行合并。PR 创建后核对链接、目标分支和检查结果。

## 版本与收尾

采用 SemVer：不兼容 API 修改升主版本，向下兼容新增功能升次版本，问题修复升修订版本。当前版本以对应模块 `oh-package.json5` 为准。

标签约定：

- GrowingAnalytics：`v<version>`。
- GrowingToolsKit：`toolskit-v<version>`。

只有用户明确要求发版时才修改版本、创建 Jira 发版单、打 tag 或发布 OHPM，流程见 `release`。普通功能 PR 不附带这些操作；分支删除和 master 合并也等待用户明确决定。
