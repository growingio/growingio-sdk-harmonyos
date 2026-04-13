---
name: jira-ticket
description: Use when user asks to create a version release ticket, says "帮我建个发版任务", "建个 Jira", "创建发版单", or needs to track an SDK release in Jira
---

# Jira Ticket

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
