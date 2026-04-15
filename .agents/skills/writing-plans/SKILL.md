---
name: writing-plans
description: Use when drafting an implementation plan in docs/plans/ to guide task decomposition, impact assessment, and common scenario coverage
---

# Writing Plans

指导如何写好一份实施规划。Planning Gate（见 `using-growingio-sdk-skills` meta-skill）定义 plan 的**格式**（四节结构），本 skill 定义**内容质量**。

**核心原则：** 写 plan 时多想 10 分钟，实施时少返工 1 小时。

## 何时触发

Planning Gate 要求输出 plan 时（影响 ≥ 3 文件，或涉及公开 API 变更）。

## 影响面自查清单

按改动类型对照清单列全受影响的文件/路径，漏一项 = 返工：

| 改动类型 | 必须同时覆盖 |
|---|---|
| **公开 API 新增/改/删** | `Index.ets` + `obfuscation-rules.txt` + `docs/GrowingAnalytics/interfaces/*.md`（涉及 SaaS 差异加 `README_SaaS.md`） |
| **事件字段变更** | SaaS（JSON MPv2）+ NewSaaS（Protobuf）+ CDP（Protobuf）三产品线在"影响产品线"列显式标注 |
| **核心模块** (`core/` `event/` `autotrack/`) | 实现文件 + `*.test.ets` 单测 + `docs/GrowingAnalytics/<module>/*.md` |
| **GrowingConfig 变更** | NewSaaS / SaaS / CDP 三种工厂方法的默认值 + `copy()` 校验逻辑 |
| **autotrack 改动** | Native / Hybrid / Flutter 三场景 + **SaaS 模式不支持无埋点，路径上显式跳过** |
| **session 改动** | 前台触发 + 后台 APP_CLOSED + `sessionInterval`（30s）超时逻辑 |
| **事件上报改动** | Protobuf 路径 + JSON 路径 + `compressEnabled` / `encryptEnabled` 开关 + `eventSequenceId` |
| **生命周期与线程** | UIAbility `onForeground`/`onBackground` + 主线程零阻塞（IO 走 TaskPool） + `dataCollectionEnabled` 开关尊重 |

## 任务拆分

**拆成多任务：** 变更逻辑独立且可并行 / 单任务描述 > 200 字还说不清。
**合并为单任务：** 接口与其使用者（拆开编译不过） / 同模块内部重构 / TDD 内测试与被测代码。

拆分后按 `subagent-driven-development` skill 判定是否走 subagent 模式。

## 避免这么想

| 想法 | 现实 |
|---|---|
| "plan 写得越细越安全" | 过度设计 = 浪费；plan 划边界和决策点，不是代码草稿 |
| "先动手改两个文件再补 plan" | ≥3 文件动手那刻已经违规 |
| "影响文件只列改到的源码" | 文档 / 混淆规则 / 测试都算影响，漏一个就返工 |
| "公开 API 改只动 `Index.ets`" | 三件套缺一即规格不完整 |
| "事件字段只影响当前产品线" | 三产品线字段要求不同，未标注 = 后端仓库出错 |
| "autotrack 不用管 SaaS" | 必须显式声明"SaaS 跳过"，否则会出现错误降级分支 |
| "这次规划口述就行" | 必须落地到 `docs/plans/YYYY-MM-DD-*.md`，reviewer 要读文件 |

## 关联 skill

- **上游触发：** 控制器判定 Planning Gate 触发
- **调度 subagent：** 无（控制器直接执行）
- **完成后交接：** `plan-document-review` → 用户确认 → `subagent-driven-development` 或直接实施
- **替代路径：** 未触发 Planning Gate → 跳过本 skill，直接实施 + `sdk-code-review` 独立审查
