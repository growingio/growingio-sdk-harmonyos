# GrowingIO HarmonyOS SDK - 智能体指南

本文档为在 GrowingIO HarmonyOS SDK 项目上工作的 AI 编码智能体提供基本信息。

## 项目概述

**GrowingIO HarmonyOS SDK** 是一个面向 HarmonyOS 应用的数据分析 SDK，提供自动事件采集和手动埋点 API。

- **GrowingAnalytics**: 核心分析 SDK 模块 (`@growingio/analytics`)
- **GrowingToolsKit**: 开发者工具模块 (`@growingio/tools`)
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