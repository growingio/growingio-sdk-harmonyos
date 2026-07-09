# GrowingIO HarmonyOS SDK

**GrowingIO HarmonyOS SDK** 是一个面向 HarmonyOS 应用的数据分析 SDK，提供自动事件采集和手动埋点 API。

- **GrowingAnalytics** (`@growingio/analytics`): 核心分析 SDK 模块
- **GrowingToolsKit** (`@growingio/tools`): 开发者工具模块
- **entry**: 示例应用

## 技术栈

- HarmonyOS，兼容 API 12 (5.0.0) ~ 目标 API 20 (6.0.0)
- 主要语言：ArkTS | 构建工具：hvigor | 包管理器：OHPM

## 工程指南

@docs/sdk-engineering-guide.md 提供产品使命 + 文档索引 + 健康指标。

> **注意**：以下文档为 lazy-load（不自动注入），按需读取：
>
> - `docs/sdk-critical-rules.md` — 修改核心模块 **必读**（SDK 设计红线 + ArkTS 开发规范）
> - `docs/sdk-doc-routing.md` — 按场景读取的模块文档索引表
> - `docs/sdk-build-commands.md` — hvigor 构建命令速查

## 注释纪律

- **不写解释性注释**：协议依据、设计动机、"对齐 iOS xxx"等背景信息一律放 commit message，不放代码
- 该规则**同样适用于 `docs/` 模块文档中的伪代码块**——文档会被读入上下文，冗余注释同样浪费 token
- 允许保留的仅限：承载协议语义的短字段注释（如 `// 仅 NewSaaS`），且需遵循所在文件既有风格
- 清理注释时核查范围 = 全分支 diff（源码 + 文档）：`git diff master...HEAD | grep -E '^\+.*//'`
