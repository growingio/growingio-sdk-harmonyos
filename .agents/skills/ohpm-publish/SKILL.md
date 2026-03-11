---
name: ohpm-publish
description: HarmonyOS SDK 发布工具，用于将 @growingio/analytics 和/或 @growingio/tools 打包并发布到 ohpm 仓库。当用户提到"发布 SDK"、"ohpm 发布"、"打包发布"、"上传 har"、"publish"、"发版"、"release"等关键词时触发此 skill。即使用户只说了"发布"或"上传"也应该触发。
---

# ohpm-publish

将 GrowingIO HarmonyOS SDK 打包并发布到 ohpm 仓库。

## 模块信息

| 模块名 | 包名 | oh-package.json5 | HAR 输出路径 |
|--------|------|-------------------|--------------|
| GrowingAnalytics | @growingio/analytics | `GrowingAnalytics/oh-package.json5` | `GrowingAnalytics/build/default/outputs/default/GrowingAnalytics-signed.har` |
| GrowingToolsKit | @growingio/tools | `GrowingToolsKit/oh-package.json5` | `GrowingToolsKit/build/default/outputs/default/GrowingToolsKit-signed.har` |

## 发布流程

按顺序执行以下步骤，每步完成后告知用户进展。

---

### 第一步：确认发布模块

询问用户要发布哪个（或哪些）模块：
- `@growingio/analytics`（GrowingAnalytics）
- `@growingio/tools`（GrowingToolsKit）
- 两个都发布

---

### 第二步：更新版本号

读取每个待发布模块的 `oh-package.json5`，显示当前 `version` 值，询问用户新版本号是多少。

确认后，直接编辑 `oh-package.json5` 将 `version` 字段更新为新版本。

---

### 第三步：检查签名配置

读取仓库根目录的 `build-profile.json5`，检查 `app.signingConfigs` 数组。

**判断条件：** 数组非空，且第一个元素的 `material` 对象包含 `storeFile`、`keyAlias`、`profile`、`certpath` 字段。

如果签名配置缺失或不完整，**停止流程**，提示：

```
⚠️ 缺少发布签名配置，请先在 build-profile.json5 的 app.signingConfigs 中配置以下字段：
  storeFile、storePassword、keyAlias、keyPassword、signAlg、profile、certpath
配置完成后重新运行发布流程。
```

签名配置正常则继续。

---

### 第四步：构建 HAR 包

对每个待发布模块，在**仓库根目录**执行构建命令（告知用户正在构建，可能需要几分钟）：

**GrowingAnalytics：**
```bash
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module \
  -p product=default \
  -p module=GrowingAnalytics@default \
  -p buildMode=release \
  assembleHar \
  --analyze=normal --parallel --incremental --daemon
```

**GrowingToolsKit：**
```bash
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module \
  -p product=default \
  -p module=GrowingToolsKit@default \
  -p buildMode=release \
  assembleHar \
  --analyze=normal --parallel --incremental --daemon
```

构建完成后，确认 HAR 文件存在于对应的输出路径（见上方模块信息表）。
若文件不存在，报告构建失败并展示命令输出供排查，不继续发布。

---

### 第五步：发布到 ohpm

对每个构建好的模块，使用**签名版本**的 HAR 文件执行发布命令：

```bash
ohpm publish <HAR文件路径>
```

例如：
```bash
ohpm publish GrowingAnalytics/build/default/outputs/default/GrowingAnalytics-signed.har
ohpm publish GrowingToolsKit/build/default/outputs/default/GrowingToolsKit-signed.har
```

展示 ohpm 的输出结果，告知用户发布结果。

若提示未登录（`you are not logged in`），提示用户先执行 `ohpm login` 登录后重试。

---

## 注意事项

- 构建命令必须在**仓库根目录**执行
- 构建可能耗时数分钟，耐心等待即可
- 同时发布两个模块时，**逐个处理**：先构建第一个模块并发布，成功后再构建第二个模块并发布
