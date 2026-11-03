---
name: release
description: Use when the user asks to create a Jira release ticket, tag a version, build and publish an OHPM HAR, or mentions 发版, release, or ohpm publish for this SDK
---

# SDK 发版

只在用户明确要求发版时使用。普通功能提交或 PR 不自动升级版本、创建 Jira、打 tag 或发布 OHPM。

## 模块与产物

| 模块 | 包名 | 版本文件 | 签名 HAR |
|------|------|----------|----------|
| GrowingAnalytics | `@growingio/analytics` | `GrowingAnalytics/oh-package.json5` | `GrowingAnalytics/build/default/outputs/default/GrowingAnalytics-signed.har` |
| GrowingToolsKit | `@growingio/tools` | `GrowingToolsKit/oh-package.json5` | `GrowingToolsKit/build/default/outputs/default/GrowingToolsKit-signed.har` |

## 1. 确认范围与版本

- 确认发布模块和目标版本，当前版本以模块 `oh-package.json5` 为准。
- 按 SemVer 和用户决定更新版本，同步对应 CHANGELOG 与公开文档。
- 检查分支、工作区和待发布 diff，不混入无关本地修改。
- 完成 `verification-before-completion` 要求的测试和构建；存在失败时明确阻塞，不发布了再验证。

## 2. Jira 发版单

团队需要 Jira 跟踪时，在发布前创建：

```bash
jira-ticket release detect
jira-ticket release create --dry-run
jira-ticket release create
```

`JIRA_TOKEN` 必须已配置，`JIRA_URL` 和 `DEFAULT_PROJECT_KEY` 可选。不要输出或复制 token。工具不可用、鉴权失败或 dry-run 内容不正确时停止并报告；不绕过校验，不默认使用 `--yes`。

已有发版单时复用，不重复创建；需要更新已有 Ticket 但工具不支持时，明确交由用户处理。

## 3. 签名与 release 构建

检查根 `build-profile.json5` 的 `app.signingConfigs`，确认 `storeFile`、`keyAlias`、`profile`、`certpath` 等签名材料已配置。不要读取或打印密码。签名缺失时停止，不用未签名 HAR 代替。

在仓库根目录逐个构建：

```bash
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p product=default -p module=GrowingAnalytics@default \
  -p buildMode=release assembleHar --analyze=normal --parallel --incremental --daemon

/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p product=default -p module=GrowingToolsKit@default \
  -p buildMode=release assembleHar --analyze=normal --parallel --incremental --daemon
```

确认目标签名 HAR 存在后再继续；文件不存在或输出路径不一致时停止排查，不直接 publish。

## 4. 发布与 tag

OHPM 同版本不能覆盖发布。执行前再次向用户确认模块、版本和 HAR 路径，然后逐模块执行：

```bash
ohpm publish <签名HAR路径>
```

未登录时提示用户完成 `ohpm login`，不代替用户交互登录。一个模块发布成功后再处理下一个，任一失败都停止后续发布并报告实际结果。

tag 在发版提交合并到 master 后、用户明确要求时创建：

- GrowingAnalytics：`v<version>`。
- GrowingToolsKit：`toolskit-v<version>`。

最终报告版本、Jira、构建产物、OHPM 结果、tag 和 PR / 合并状态；未执行的步骤单独列出。
