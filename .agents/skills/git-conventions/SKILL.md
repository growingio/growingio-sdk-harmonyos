---
name: git-conventions
description: GrowingIO HarmonyOS SDK 项目的 Git 规范约束。用于规范分支命名、Commit message 格式和 PR 流程。当用户需要执行 git commit、创建分支、或询问 Git 提交规范时使用。
---

# GrowingIO HarmonyOS SDK Git 规范

本项目遵循 Angular Commit 规范进行版本控制和变更追踪。

## Commit Message 规范

### 格式

```
<type>(<scope>): <subject>
```

### Type（必填）

| 类型 | 说明 |
|------|------|
| `feat` | 新功能（feature） |
| `fix` | 修复 bug |
| `docs` | 文档（documentation） |
| `style` | 格式（不影响代码运行的变动） |
| `refactor` | 重构（即不是新增功能，也不是修改 bug 的代码变动） |
| `perf` | 性能优化 |
| `test` | 增加测试 |
| `chore` | 构建过程或辅助工具的变动 |
| `ci` | 持续集成相关配置修改 |
| `revert` | 回滚到上一个版本 |

### Scope（可选）

用于区分代码变更所属的产品线：

| Scope | 说明 |
|-------|------|
| `saas` | 仅 **SaaS** 产品线相关修改 |
| `cdp` | 仅 **CDP** 产品线相关修改 |
| *(空)* | **New SaaS** 产品线修改（默认）<br>**或** SaaS/CDP/New SaaS **三个产品线通用**的修改 |

**使用规则**：
- 仅涉及单一产品线（SaaS 或 CDP）时，填写对应 scope
- 涉及 New SaaS 时，省略 scope（默认）
- 涉及三个产品线通用的修改，省略 scope

### Subject（必填）

- 使用祈使句，描述本次修改的目的
- 不超过 50 个字符
- 首字母小写
- 结尾不加句号

### 示例

```bash
# SaaS 产品线相关（仅 SaaS）
feat(saas): add custom event tracking API
fix(saas): resolve login user ID validation issue

# CDP 产品线相关（仅 CDP）
feat(cdp): add user profile synchronization
fix(cdp): fix data export timeout handling

# New SaaS（默认，省略 scope）
feat: add referralPage for page event
fix: update obfuscation rules

# 三个产品线通用（省略 scope）
feat: add gzip compression for network requests
fix: fix concurrent database access issue
refactor: simplify event processing logic

# 通用功能（省略 scope）
docs: update integration guide
chore: release 2.7.1
perf: optimize EventDatabase with concurrent task processing
```

## 分支命名规范

### 主分支

- `master` - 主分支，用于发布

### 功能分支

```
<type>/<short-description>
```

示例：
- `feat/analytics-v3`
- `fix/memory-leak`
- `docs/api-reference`
- `refactor/database-optimization`

### 版本发布分支

```
release/v<version>
```

示例：
- `release/v2.8.0`

### 热修复分支

```
hotfix/<description>
```

## 提交前检查清单

- [ ] Commit message 符合上述规范
- [ ] 代码通过编译检查
- [ ] 相关测试通过（如有）
- [ ] 文档已更新（如涉及文档变更）

## 版本号规范

本项目采用语义化版本（SemVer）：`主版本号.次版本号.修订号`

- 主版本号：做了不兼容的 API 修改
- 次版本号：做了向下兼容的功能性新增
- 修订号：做了向下兼容的问题修正

当前版本可参考 `GrowingAnalytics/oh-package.json5` 中的 `version` 字段。

## 常用命令示例

```bash
# SaaS 产品线 - 提交新功能
git commit -m "feat(saas): add custom event tracking API"

# SaaS 产品线 - 提交 bug 修复
git commit -m "fix(saas): resolve login user ID validation issue"

# CDP 产品线 - 提交新功能
git commit -m "feat(cdp): add user profile synchronization"

# CDP 产品线 - 提交 bug 修复
git commit -m "fix(cdp): fix data export timeout handling"

# New SaaS（默认，省略 scope）- 提交新功能
git commit -m "feat: add referralPage for page event"

# New SaaS（默认，省略 scope）- 提交 bug 修复
git commit -m "fix: update obfuscation rules"

# 文档更新（通用，可省略 scope）
git commit -m "docs: update integration guide"

# 性能优化
git commit -m "perf: optimize EventDatabase with concurrent task processing"

# 重构
git commit -m "refactor: simplify event processing logic"

# 构建/工具相关
git commit -m "chore: upgrade build dependencies"
```

## PR 规范

1. PR 标题应清晰描述变更内容
2. PR 描述中应说明变更原因和影响范围
3. 关联相关 Issue（如有）
4. 确保 CI 检查通过
