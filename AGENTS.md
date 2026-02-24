# GrowingIO HarmonyOS SDK - 智能体指南

本文档为在 GrowingIO HarmonyOS SDK 项目上工作的 AI 编码智能体提供基本信息。

## 项目概述

**GrowingIO HarmonyOS SDK** 是一个面向 HarmonyOS 应用的数据分析 SDK，提供自动事件采集和手动埋点 API。本项目由北京易数科技有限公司（GrowingIO）开发。

- **GrowingAnalytics**: 核心分析 SDK 模块 (`@growingio/analytics` v2.7.1)
- **GrowingToolsKit**: 开发者工具模块 (`@growingio/tools` v1.4.0)
- **entry**: 展示 SDK 用法的示例应用

## 技术栈

- **目标操作系统**: HarmonyOS
- **兼容 SDK 版本**: 5.0.0(12) (OpenHarmony API 12)
- **目标 SDK 版本**: 6.0.0(20)
- **主要语言**: ArkTS（HarmonyOS TypeScript 变体）
- **构建工具**: hvigor
- **包管理器**: OHPM

## 构建命令

```bash
# 构建 entry 模块（HAP）
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p module=entry@default -p product=default \
  -p requiredDeviceType=phone assembleHap \
  --analyze=normal --parallel --incremental --daemon

# 构建 GrowingAnalytics（HAR）
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p product=default -p module=GrowingAnalytics@default \
  assembleHar --analyze=normal --parallel --incremental --daemon

# 构建 GrowingToolsKit
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  --mode module -p product=default -p module=GrowingToolsKit@default \
  assembleHar --analyze=normal --parallel --incremental --daemon

# 清理构建产物
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  -p product=default clean --analyze=normal --parallel --incremental --daemon
```

## 各模块文档

- [entry/AGENTS.md](./entry/AGENTS.md) - 示例应用模块
- [GrowingAnalytics/AGENTS.md](./GrowingAnalytics/AGENTS.md) - 核心 SDK 模块
- [GrowingToolsKit/AGENTS.md](./GrowingToolsKit/AGENTS.md) - 开发者工具模块

## ArkTS 语言约束

本项目使用 **ArkTS**，而非标准 TypeScript。关键约束：

| 禁止 | 允许 |
|------|------|
| `any`, `unknown` 类型 | 显式类型 |
| `let { x, y } = point` 解构 | `let x = point.x` |
| `obj['key']` 索引访问 | `obj.key` |
| `var` 关键字 | `let` / `const` |
| `#foo` 私有字段 | `private foo` |

更多约束详见各模块文档。

## 代码风格

- **缩进**: 4 个空格（禁用 tab）
- **行宽限制**: 120 字符
- **命名**: 类/接口使用 PascalCase，方法/字段使用 camelCase
- **文件头**: 必须包含 Apache 2.0 许可证

## 许可证

Apache License 2.0 - 详见 [LICENSE](./LICENSE) 文件。

Copyright (C) 2024 Beijing Yishu Technology Co., Ltd.
