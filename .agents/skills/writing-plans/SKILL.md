---
name: writing-plans
description: Use when drafting an implementation plan in docs/plans/ to guide task decomposition, impact assessment, and common scenario coverage
---

# Writing Plans

指导**如何写好一份实施规划**。Planning Gate（见 `.claude/agents/engineering-harmonyos-sdk-engineer.md`）定义了 plan 的**格式**（四节结构），本 skill 定义**内容质量**——怎样让每一节写得到位、无遗漏。

**核心原则：** plan 是实施的蓝本，写 plan 时多想 10 分钟，实施时少返工 1 小时。审查者（`plan-document-review` skill）查不到的洞，实施阶段会变成 bug。

## 何时触发

Planning Gate 要求输出 plan 时（影响 ≥ 3 文件，或涉及公开 API 变更）。

## 任务拆分策略

### 什么时候该拆成多个任务

- **不同文件的变更逻辑独立**：例如"新增 API"和"更新对应文档"，彼此不依赖运行时共用状态
- **任务可并行执行**：多任务适合 `subagent-driven-development` 模式 A
- **单个任务描述超过 200 字仍讲不清**：信号——在做多件事

### 什么时候该合并

- **共用的接口定义和其使用者**：拆开会导致中间状态编译不过
- **同一模块的内部重构**：强内聚的改动不适合跨任务切分
- **测试与被测代码**：TDD 流程内不应跨任务

### 判断模式

判定"模式 A（subagent-driven）"还是"模式 B（直接实施）"的适用条件，见 `.agents/skills/subagent-driven-development/SKILL.md` 和 engineer persona 的 Step 3。本 skill 不重复定义。

## 影响面评估方法

系统性列全所有受影响的文件，常见三件套/多件套：

### 公开 API 变更 → 三件套

新增 / 修改 / 删除任何 `index.ets` 导出符号，必须同时列出：

1. `GrowingAnalytics/Index.ets`（或对应模块的 index）
2. `GrowingAnalytics/obfuscation-rules.txt`（保护符号名）
3. `docs/GrowingAnalytics/interfaces/*.md`（对应 API 文档）

如涉及 SaaS 模式差异，额外加 `README_SaaS.md`。

### 事件字段变更 → 三产品线

任何事件字段新增 / 修改 / 删除，必须列出对所有相关产品线的影响：

- **SaaS**（JSON，Measurement Protocol v2）
- **NewSaaS**（Protobuf）
- **CDP**（Protobuf）

三者字段要求不同，在"数据协议变更"表的"影响产品线"列明确标注。

### 核心模块变更 → 测试 + 文档

改动 `core/`、`event/`、`autotrack/` 下的任何实现文件，必须同步检查：

- 对应的单元测试文件（`*.test.ets`）
- `docs/GrowingAnalytics/<module>/*.md` 设计文档

### 配置项变更 → 三模式差异

`GrowingConfig` 变更必须考虑 NewSaaS / SaaS / CDP 三种工厂方法的默认值、校验规则是否各自需要更新。

## 常见遗漏场景清单

写 plan 时对照以下清单自查：

### autotrack 改动

- [ ] 是否覆盖 **Native / Hybrid / Flutter** 三种场景？
- [ ] **SaaS 模式不支持无埋点**，是否在 SaaS 路径上显式跳过？
- [ ] 涉及 VIEW_CLICK 变更：`UIObserver.on('willClick')` + `FrameNode` 路径
- [ ] 涉及 PAGE 变更：Navigation / Router / NavBar 栈

### session 改动

- [ ] 前台触发（冷启动 / 超时后回前台）
- [ ] 后台触发（APP_CLOSED）
- [ ] 超时逻辑（默认 30 秒 `sessionInterval`）

### 事件改动

- [ ] Protobuf 路径（NewSaaS / CDP）
- [ ] JSON 路径（SaaS MPv2）
- [ ] `compressEnabled`（Snappy）开关影响
- [ ] `encryptEnabled`（XOR）开关影响
- [ ] `eventSequenceId` 是否受影响

### Config 改动

- [ ] NewSaaS 默认值
- [ ] SaaS 默认值
- [ ] CDP 默认值
- [ ] `copy()` 校验逻辑是否需同步

### 生命周期与线程

- [ ] UIAbility `onForeground` / `onBackground` 钩子
- [ ] IO 操作是否在 `TaskPool` / `Worker`（主线程零阻塞红线）
- [ ] `dataCollectionEnabled` 开关是否在路径上尊重

## 写作节奏

```
1. 粗列任务 → 2. 按清单自查遗漏 → 3. 明确实施模式 → 4. 列全影响文件 → 5. 补变更表 → 6. 保存至 docs/plans/
```

每一步产出都是下一步的输入，不要跳步。

## 交叉引用

- 格式规范：engineer persona 的 `Planning Gate` 节
- 模式判定：`.agents/skills/subagent-driven-development/SKILL.md`
- 写完后审查：`.agents/skills/plan-document-review/SKILL.md`
