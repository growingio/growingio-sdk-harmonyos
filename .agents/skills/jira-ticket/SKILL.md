---
name: jira-ticket
description: Use when user asks to create a version release ticket, says "帮我建个发版任务", "建个 Jira", "创建发版单", or needs to track an SDK release in Jira
---

# Jira Ticket

> **Type:** Reference | **Discipline:** Flexible

创建 SDK 版本发布的 Jira Ticket。

## 使用场景

**适用：**
- "帮我创建发版 Ticket"
- "准备发布 v1.2.0"
- "检测当前版本信息"

**不适用：**
- 查询已有 Ticket 状态
- 修改或更新现有 Ticket
- 非 SDK 项目的 Jira 操作

## 命令

```bash
jira-ticket release detect   # 检测版本
jira-ticket release create   # 创建 Ticket
jira-ticket release create --dry-run  # 预览
jira-ticket release create --yes      # 跳过确认
```

## 环境变量

需设置 `JIRA_TOKEN`，可选 `JIRA_URL` 和 `DEFAULT_PROJECT_KEY`。

## 避免这么想

| 想法 | 现实 |
|---|---|
| "等发完版再建 ticket" | 先建 ticket 再发版，版本号和 ticket ID 关联性才清晰 |
| "dry-run 跑过就等于建成了" | `--dry-run` 不落盘，必须去掉才实际创建 |
| "`--yes` 跳过确认省事" | 生产流程建议先交互确认，自动化脚本才用 `--yes` |
| "`JIRA_TOKEN` 过期就注释掉校验" | 过期一定要重新生成 token，不可绕过鉴权 |

## 关联 skill

- **上游触发：** 准备发版（版本号确定后、`ohpm-publish` 之前）
- **调度 subagent：** 无（命令行工具，直接执行）
- **完成后交接：** `ohpm-publish` 发布 HAR → 发版完成后回到 ticket 更新状态
- **替代路径：** 已有发版 ticket → 跳过本 skill，直接进入 ohpm-publish
