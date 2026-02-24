---
name: ohpm-publish
description: GrowingIO HarmonyOS SDK 的 OHPM 包发布流程。当用户需要发布 @growingio/analytics 或 @growingio/tools 到 OHPM 中心仓时使用。
---

# OHPM 包发布指南

本 skill 用于指导 GrowingIO HarmonyOS SDK 模块发布到 OHPM（OpenHarmony Package Manager）中心仓。

## 发布模块

本项目包含两个可发布模块：

| 模块 | 包名 | 配置文件路径 |
|------|------|-------------|
| GrowingAnalytics | `@growingio/analytics` | `GrowingAnalytics/oh-package.json5` |
| GrowingToolsKit | `@growingio/tools` | `GrowingToolsKit/oh-package.json5` |

## 发布流程

### 1. 准备工作

#### 1.1 确认版本号

检查对应模块的 `oh-package.json5` 中的 `version` 字段：

```bash
# GrowingAnalytics
grep '"version"' GrowingAnalytics/oh-package.json5

# GrowingToolsKit
grep '"version"' GrowingToolsKit/oh-package.json5
```

版本号规范遵循 **SemVer**：`主版本号.次版本号.修订号`

#### 1.2 检查依赖版本一致性

确保两个模块的公共依赖版本一致：
- `snappyjs`
- `@ohos/protobufjs`
- `long`

#### 1.3 更新版本号（如需）

如需更新版本，编辑对应模块的 `oh-package.json5`：

```json5
{
  "version": "x.y.z"
}
```

#### 1.4 提交版本更新

```bash
git add GrowingAnalytics/oh-package.json5 GrowingToolsKit/oh-package.json5
git commit -m "chore: release x.y.z"
```

### 2. 构建 HAR 包

使用 hvigor 构建 HAR（HarmonyOS Archive）：

```bash
# 构建 GrowingAnalytics
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p product=default -p module=GrowingAnalytics@default \
  assembleHar --analyze=normal --parallel --incremental --daemon

# 构建 GrowingToolsKit
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p product=default -p module=GrowingToolsKit@default \
  assembleHar --analyze=normal --parallel --incremental --daemon
```

构建产物位于：`build/default/outputs/default/<模块名>.har`

### 3. 登录 OHPM

如未登录，先执行登录：

```bash
/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm login
```

按提示输入用户名和密码。

### 4. 发布包

进入模块目录执行发布：

```bash
# 发布 GrowingAnalytics
cd GrowingAnalytics
/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm publish

# 发布 GrowingToolsKit
cd GrowingToolsKit
/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm publish
```

> **注意**：确保在模块根目录（包含 oh-package.json5 的目录）执行 publish 命令。

### 5. 验证发布

发布后可在 OHPM 中心仓搜索验证：
- https://ohpm.openharmony.cn/#/cn/detail/@growingio%2Fanalytics
- https://ohpm.openharmony.cn/#/cn/detail/@growingio%2Ftools

或使用命令验证：

```bash
/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm view @growingio/analytics versions
/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm view @growingio/tools versions
```

## 常见问题

### 版本已存在

如果提示版本已存在，需要：
1. 确认是否重复发布
2. 如需更新，先提升版本号
3. 重新构建并发布

### 未登录错误

```
error: you are not logged in
```

解决：执行 `ohpm login` 登录。

### 包名冲突

确保 oh-package.json5 中的 `name` 字段正确：
- `@growingio/analytics`
- `@growingio/tools`

## 发布检查清单

- [ ] 版本号已正确更新
- [ ] 公共依赖版本一致性已检查
- [ ] 代码已提交到 git
- [ ] HAR 构建成功
- [ ] 已登录 OHPM
- [ ] 发布命令在正确的模块目录执行
- [ ] 发布后已在中心仓验证
