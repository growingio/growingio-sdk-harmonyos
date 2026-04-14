---
name: finishing-a-development-branch
description: Use after verification-before-completion passes and code review is clean, to close out the branch — commit loose changes, choose merge/PR/keep/discard, and handle release-specific steps like git tag
---

# Finishing a Development Branch

功能做完、验证通过、审查通过后，进入"收尾阶段"。此 skill 防止两类遗漏：
- **改完就停手**：代码没 commit、分支没合并、PR 没建
- **发版遗漏 tag**：SDK 版本号升了但 git tag 没打，导致历史追溯困难

**核心原则：** 验证通过 ≠ 任务结束。必须走完收尾五步，才算真正完成。

## 何时触发

**强制：**
- `verification-before-completion` skill 通过后
- `sdk-code-review` skill 通过后
- 用户说"这个功能做完了" / "收个尾" / "合并吧"

**不触发：**
- 只是途中提交（Work in Progress），还会继续开发

## 五步收尾流程

### Step 1：盘点当前状态

```bash
git status
git log --oneline $(git merge-base HEAD master)..HEAD
git diff --stat master..HEAD
```

回答三个问题：
1. 工作区有未 commit 的改动吗？
2. 本分支比 master 多了几个 commit？每个 commit 是否都有意义？
3. 有没有中途的 WIP / fixup / 实验代码需要合并或丢弃？

### Step 2：清理未提交改动

如果 `git status` 显示有未提交改动：

- **属于本次功能** → 按 `git-conventions` skill 规范 commit
- **不属于本次功能**（调试遗留、本地配置等） → 询问用户保留/丢弃，不要擅自 commit

**禁止：** 使用 `git add -A` 或 `git add .` 一把梭，可能把 `.env` / 本地配置 / 临时日志一起提交。按文件逐个 `git add`。

### Step 3：判断分支是否属于"发版分支"

检查当前分支是否涉及版本号变更：

```bash
git diff master..HEAD -- GrowingAnalytics/oh-package.json5 GrowingToolsKit/oh-package.json5
```

**如果 `version` 字段有变更：** 这是发版分支，进入 Step 3a。
**否则：** 跳到 Step 4。

#### Step 3a：发版分支附加任务

| 任务 | 如何执行 |
|------|---------|
| 确认 CHANGELOG 已更新 | 检查 `CHANGELOG.md` / `README_*.md` 是否有本版本条目 |
| 确认 obfuscation-rules.txt 已同步 | 公开 API 变更是否已加入 keep 规则 |
| Jira 发版单 | 按 `jira-ticket` skill 创建发版任务（如尚未创建） |
| git tag | 合并到 master 之后再打，不在开发分支上打 |
| OHPM 发布 | 合并后按 `ohpm-publish` skill 执行 |

**tag 命名规范**（与 git-conventions 对齐）：
- GrowingAnalytics：`v<version>`（如 `v2.8.0`）
- GrowingToolsKit：`toolskit-v<version>`（如 `toolskit-v1.2.0`）

### Step 4：选择收尾路径

向用户呈现 4 个选项，不要擅自决定：

```
当前分支 <branch-name> 已准备好收尾，请选择：

A. 合并到 master（直接 merge，无 PR 审查）
B. 创建 PR（走 GitHub/GitLab 审查流程）
C. 暂时保留分支（继续迭代或等待依赖）
D. 废弃分支（改动不再需要）
```

**选项 A（合并）：** 仅当变更很小、已经过本地审查、无需团队 review 时使用。
**选项 B（PR）：** 默认推荐。触发 `git-conventions` skill 的 PR 标题/描述规范。
**选项 C（保留）：** 不做任何动作，但需要说明保留原因（记入 commit message 或本地备注）。
**选项 D（废弃）：** 确认后删除本地和远程分支。

### Step 5：执行选定路径 + 清理

**路径 A（合并到 master）：**
```bash
git checkout master
git pull
git merge --no-ff <branch-name>
git push
# 如果是发版分支，现在打 tag
git tag -a v<version> -m "Release v<version>"
git push --tags
# 清理分支
git branch -d <branch-name>
git push origin --delete <branch-name>
```

**路径 B（创建 PR）：**
- 按 `git-conventions` skill 写 PR title（类型 + scope + 简述）和 description（背景 / 变更 / 测试）
- 使用 `gh pr create` 或对应平台命令
- PR 合并后回到本步骤执行 tag 和清理

**路径 C（保留）：** `git push -u origin <branch-name>`（如尚未推送）

**路径 D（废弃）：**
```bash
# 本地
git checkout master
git branch -D <branch-name>
# 远程（如果已推送）
git push origin --delete <branch-name>
```

## 完成声明格式

收尾完成后，向用户报告：

```
分支 <branch-name> 收尾完成：
- 提交：N 个 commit
- 路径：已合并到 master / PR #123 已创建 / 分支保留 / 分支已删除
- Tag：v2.8.0 已推送 / 无需打 tag
- 后续：需要在 Jira 更新发版单 / 执行 ohpm publish / 无
```

## 禁止行为

| 行为 | 为什么禁止 |
|------|-----------|
| 不问用户直接合并到 master | 合并是不可逆操作，必须用户确认 |
| 发版分支不打 tag 就合并 | 丢失版本追溯能力 |
| `git add -A` 一把梭 | 容易提交敏感文件 |
| 合并后不清理分支 | 仓库分支列表污染 |
| 跳过 Step 1 直接进入合并 | 可能把未提交改动或 WIP commit 带入 master |

## 与其他 skill 的关系

- **前置：** `verification-before-completion`（必须已通过）+ `sdk-code-review`（必须已通过）
- **调用：** `git-conventions`（commit/PR/tag 命名）
- **发版场景下调用：** `jira-ticket`（创建发版单）+ `ohpm-publish`（发布到 OHPM Registry）
- **engineer persona：** 本 skill 应在 Step 5 `verification-before-completion` 通过后被自动触发
