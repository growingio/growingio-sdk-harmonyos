---
name: writing-plans
description: Use when a request has unclear scope, affects multiple modules or public APIs, or needs an implementation plan before coding
---

# 按需澄清与实施计划

计划的目的是暴露决策和遗漏，不是为每个改动增加文档和审批。能够从代码、规格或用户指令中得到答案时，直接继续；只有答案会改变实现方向时才询问用户。

## 先判断所需粒度

- 范围清楚的小改动：直接实施，完成后验证。
- 用户已经确认方案或明确要求直接实施、提交 PR：不重复要求审批，不强制新增规格或计划文件。
- 跨模块、修改公开 API 或数据协议、存在多种实现方向：先给出简短计划和主要取舍。
- 复杂且需要留存决策的变更：可写入 `docs/plans/YYYY-MM-DD-<topic>.md`；不要把计划文档数量当作完成度。

计划至少说明：目标、受影响行为、关键实现路径和验证方式。任务拆分按依赖顺序组织，测试与被测代码放在同一实施单元。

## 开始前的项目上下文

按需读取：

1. `docs/sdk-engineering-guide.md` 的项目索引。
2. `docs/sdk-doc-routing.md` 中与改动场景对应的模块文档。
3. 核心模块改动前读取 `docs/sdk-critical-rules.md`。
4. 相关源码、测试和近期相关变更，不凭名称猜行为。

## 影响面检查

只列实际适用的项目：

| 改动 | 必查内容 |
|------|----------|
| 公开 API | 模块入口、声明、混淆规则、公开文档、调用方和测试 |
| GrowingConfig | NewSaaS / SaaS / CDP 的适用性、默认值和 `copy()` |
| 事件字段或上报 | 各受影响产品线、Protobuf / JSON、压缩 / 加密、事件序号 |
| 核心模块 | 实现、单元测试、对应模块文档、隐私与线程约束 |
| Autotrack / Hybrid / Flutter | 各入口的支持范围和明确的跳过行为 |
| Session / 生命周期 | 前后台、超时、重复初始化和状态清理 |

逐项确认 NewSaaS / SaaS / CDP 是受影响还是明确不变，避免把单产品线需求扩展到全部模式。

## 需要用户决策的情况

- 产品语义、公开 API 或线上协议存在无法从现有证据确定的歧义。
- 多个方案的兼容性、性能或接入成本取舍需要需求方选择。
- 请求涉及发布、合并、删除远程数据等高风险操作。

用户作出决定后继续执行，不反复重开已确认的问题。

核心路径实施使用 `test-driven-development`，交付前使用 `verification-before-completion`，提交规范见 `git-conventions`。
