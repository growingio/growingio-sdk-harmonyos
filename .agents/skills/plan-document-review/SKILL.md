---
name: plan-document-review
description: Use after writing a plan document in docs/plans/ to verify completeness, task decomposition, and coverage before requesting user confirmation
---

# Plan Document Review

在 Planning Gate 输出完规划文档后、请求用户确认前，dispatch 一个 plan reviewer subagent 审查规划本身的质量。这一层审查能堵住"格式正确但内容不到位"的规划漏过 gate 的问题。

**核心原则：** plan 是实施的蓝本，蓝本有洞 = 实施有洞。审查 plan 本身比后期返工便宜得多。

## 何时触发

**强制：** Planning Gate 保存完 plan 到 `docs/plans/` 之后、提示用户确认之前。

**可跳过：** Planning Gate 未触发的小改动（< 3 文件且不涉及公开 API）。

## 调度方式

Plan reviewer 用 `general-purpose` subagent 身份 + prompt 模板实现（不需要专门 agent 定义）。它通过 `AGENTS.md` 的 `@import docs/sdk-engineering-guide.md` 自动继承领域知识。

```
Agent({
  description: "Review plan document",
  subagent_type: "general-purpose",
  prompt: `
你是 GrowingIO HarmonyOS SDK 的规划审查员。验证以下规划是否完备、可实施。

## 待审查规划

文件路径：{PLAN_FILE_PATH}

规划全文（已粘贴，不用再读）：

---
{PLAN_FULL_TEXT}
---

## 原始需求 / 任务描述

{ORIGINAL_TASK_DESCRIPTION}

## 检查维度

### 1. 四节完整性

规划必须包含以下四节，缺一不可：
- [ ] 影响文件列表
- [ ] 公开 API 变更
- [ ] 数据协议变更
- [ ] 需同步修改的文档

### 2. 影响文件列表准确性

- 文件路径是否真实存在（或合理的新建路径）？
- 是否有明显遗漏的文件？举例：
  - 新增公开 API 但没列 \`GrowingAnalytics/Index.ets\` / \`GrowingAnalytics/obfuscation-rules.txt\`
  - 修改事件字段但没列对应的 EventBuilder / 测试文件
  - 修改某模块但没列相关的单元测试文件
- 有没有列了但实际不需要改的文件（scope creep）？

### 3. 公开 API 变更一致性

- 如果变更类型是"新增/修改/删除"，是否在"影响文件列表"中包含了 \`index.ets\` 和 \`obfuscation-rules.txt\`？
- 如果是新增/修改，签名是否完整（参数类型、返回类型、泛型）？
- 如果是删除/重命名，是否考虑了兼容性（deprecated 标注、迁移指南）？

### 4. 数据协议变更覆盖

- 涉及字段变更时，"影响产品线"列是否完整？SaaS/NewSaaS/CDP 三种模式的字段要求不同
- 是否有潜在被遗漏的产品线？
- 字段类型是否与 Android/iOS SDK 对齐（如果跨端）？
- 如果涉及 Protobuf schema，是否同步更新了 .proto 文件？

### 5. 文档同步完整性

- 公开 API 变更是否在"需同步修改的文档"中列了 \`docs/GrowingAnalytics/interfaces/*.md\`？
- 涉及核心模块改动是否列了对应的 \`docs/GrowingAnalytics/<module>/*.md\`？
- 涉及 SaaS/NewSaaS 模式差异是否列了 README_SaaS.md？

### 6. 任务拆分质量（如涉及 subagent-driven-development）

如果规划包含多个任务：
- 任务是否大部分相互独立（适合 subagent 并行执行）？
- 任务粒度是否合理（不要太大以至于超过 subagent 承载，也不要太小以至于调度开销 > 实施成本）？
- 任务依赖关系是否清晰（哪些任务必须先做）？

### 7. 场景覆盖

常见场景遗漏：
- **autotrack 改动**：是否考虑了 Hybrid/Flutter/Native 三种场景？SaaS 模式不支持无埋点，是否需要在 SaaS 模式下跳过？
- **session 改动**：是否考虑了前台/后台/APP_CLOSED 三种触发时机？
- **事件改动**：是否考虑了 Protobuf / JSON 双格式？是否考虑了 compressEnabled / encryptEnabled 开关影响？
- **Config 改动**：是否考虑了三种工厂模式（NewSaaS/SaaS/CDP）的默认值差异？

## 输出格式

### 问题

#### Critical（必须修复，阻塞 plan 通过）
- [问题描述]

#### Important（应当修复，建议修复后再请求用户确认）
- [问题描述]

#### Suggestion（建议优化，不阻塞）
- [问题描述]

（无问题时写"无"）

### 检查清单

- [ ] 四节完整
- [ ] 影响文件列表准确无遗漏
- [ ] 公开 API 变更一致（同步 index.ets 和 obfuscation-rules.txt）
- [ ] 数据协议变更产品线完整
- [ ] 文档同步列表完整
- [ ] 任务拆分合理（如多任务）
- [ ] 场景覆盖完整

### 结论

**通过** / **需要修改** / **需要讨论**

## 审查原则

- 具体到位：每个问题指向 plan 中的具体段落或条目
- 不做表演式认同
- 发现规划本身的缺陷（不是格式，而是思考漏洞）要明确指出
- 如果任务描述本身模糊，建议先澄清需求而非强行过 plan
`
})
```

## 占位符说明

| 占位符 | 来源 |
|--------|------|
| `{PLAN_FILE_PATH}` | 刚保存的 plan 文件路径 |
| `{PLAN_FULL_TEXT}` | plan 文件的完整内容（粘贴全文，不让 reviewer 读文件） |
| `{ORIGINAL_TASK_DESCRIPTION}` | 用户原始需求描述或任务背景 |

## 处理审查结果

```
reviewer 返回结果
  ↓
判断结论
  ├── "通过" → 向用户展示 plan + reviewer 摘要，请求确认
  ├── "需要修改"
  │     ├── Critical → 修改 plan 文件，重新 dispatch reviewer（计第 N 轮）
  │     └── Important → 修改 plan 文件，重新 dispatch reviewer（计第 N 轮）
  │     （Suggestion 可记录，不阻塞）
  │
  │     ⚠️ 如果第 2 轮后仍有 Critical/Important：
  │        → 停止循环，向用户说明"plan 已两轮审查仍有问题，需要讨论"
  │        → 不再盲目循环
  │
  └── "需要讨论" → 向用户说明疑虑，讨论后决定
```

**不要向用户隐藏审查结果。** 即使通过，也在请求用户确认时附上 reviewer 的摘要（如"plan reviewer 通过，无 Critical/Important 问题"），让用户知道 plan 经过了独立审查。

## 避免这么想

| 想法 | 现实 |
|---|---|
| "自己写的 plan 自己审就行" | 自审替代不了独立审查，reviewer 是新鲜 context |
| "跳过 reviewer 直接请求用户确认" | Planning Gate 的独立审查是硬性流程的一部分，不是可选步骤 |
| "reviewer 说 Important 我觉得是 Suggestion" | 可以 push back，但要有技术理由，不是感觉 |
| "修完 Critical 不用重新 dispatch" | 必须重新 dispatch，不可自判"已修好" |
| "审了两轮还有问题就先过吧" | 第 2 轮后仍有 Critical/Important → 停下讨论，不盲目循环 |

## 关联 skill

- **上游触发：** `writing-plans` 产出 plan 文件后、请求用户确认前
- **调度 subagent：** `general-purpose` subagent（本 skill 内嵌 prompt 模板，不需专门 agent）
- **完成后交接：** 通过 → 向用户展示 plan + reviewer 摘要请求确认 → 进入实施
- **替代路径：** 未触发 Planning Gate 的小改动 → 不走本 skill
