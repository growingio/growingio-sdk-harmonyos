---
name: brainstorming
description: Use when receiving an ambiguous feature request, when scope is unclear, or before writing any plan — explores intent and requirements through guided dialogue
---

# Brainstorming: 把想法变成规格

把模糊需求通过"一次一个问题"的方式，收敛成一份可用于 `writing-plans` 的设计规格。

<HARD-GATE>
在完成规格并拿到用户批准之前，**不得**调用 `writing-plans`、不得动任何源文件、不得派 subagent 执行实现。
逃生条款：用户明确说 "skip brainstorming"、"已经有规格"、"直接按 X 做" 时可跳过。
</HARD-GATE>

## 何时触发

**必须走本流程**：
- 需求一句话带过（"加个 X 功能"、"优化下 Y"），无验收标准
- 影响范围不清（不知道涉及几种模式 NewSaaS/SaaS/CDP / 是否碰公开 API / 是否改数据协议）
- 用户描述的是"症状"而非"问题"（"用户反馈慢"而非"首次事件上报延迟 >3s"）

**不走本流程**：
- 修 bug 且 root cause 已定位
- 严格按既有规格/issue 实现
- 用户明示"跳过头脑风暴"

## Checklist（必须转成 TodoWrite，逐条完成）

1. **探查项目上下文** — 读 `docs/sdk-engineering-guide.md` 索引、近 3 次 commit、相关模块 doc
2. **抛 SDK 专有澄清问题**（每次一个，多选优先）：
   - 影响哪种模式？仅 NewSaaS / 仅 CDP / 仅 SaaS / 多模式？
   - 是否改动公开 API（`index.ets` 导出符号）？
   - 是否改动数据协议（事件字段、序列化格式、上报路径）？
   - 是否需要多端一致性校验（Android/iOS SDK 已有等价实现时必须对齐命名）？
   - 性能预算？（初始化耗时影响、首屏/内存/包体积增量）
   - 隐私合规影响？（是否采集新字段、是否需进 `ignoreField` 枚举）
3. **提 2–3 个方案** — 每个方案写 trade-off（数据准确性 / 接入成本 / 性能开销 / 包体积），给出你的推荐
4. **分段呈现设计** — 按「问题定义 / 方案选择 / 接口草案 / 数据协议 / 影响面」分节，每节单独拿 approval
5. **写规格文档** — 保存到 `docs/specs/YYYY-MM-DD-<topic>.md`
6. **规格自查** — 有无占位符 `TODO`、有无自相矛盾、范围是否闭合
7. **请用户审阅规格文件** — 等明确 "OK/确认/继续"
8. **移交**（根据影响面判断下游，见下方「下游分叉」） — 不再无条件调用 `writing-plans`

## Process Flow

```
User request
  │
  ▼
Explore project context (guide index + recent commits + module docs)
  │
  ▼
Scope sanity check ── 需求过大？─YES→ 先拆子项目，只对第一个子项目继续
  │ NO
  ▼
Ask clarifying questions (one at a time, multiple-choice preferred)
  │
  ▼
Propose 2–3 approaches with trade-offs
  │
  ▼
Present design in sections → per-section approval
  │
  ▼
Write spec to docs/specs/YYYY-MM-DD-<topic>.md
  │
  ▼
Self-review (placeholders / contradictions / scope)
  │
  ▼
User reviews spec file ── approved? ─NO→ revise
  │ YES
  ▼
影响面自评（按 Planning Gate 触发条件）
  ├─ 预计影响 ≥3 文件 或 改动公开 API → writing-plans
  └─ 预计 <3 文件 且 不动公开 API       → 直接实施 + sdk-code-review 模式 B
```

## Anti-Pattern：「这个需求太简单不需要规格」

每个改动都走流程。简单改动的规格可以只有几行，但**必须**写下来并拿批准。"简单"是最常出错的地方——你以为的简单通常是"我忽略了若干假设"。

## Anti-Pattern：「一次问五个问题」

一次一个问题。多问 = 用户挑 1–2 个回答，其余遗漏。多选题 > 开放题。

## Rationalizations（全部无效）

| 借口 | 现实 |
|---|---|
| "我已经懂了需求" | 你懂的是字面，规格是把假设写下来让用户挑错 |
| "用户会觉得啰嗦" | 比事后返工友好 10 倍 |
| "先写 plan 再说" | plan 以规格为输入；输入错，plan 全错 |
| "bug 修复不用走" | 是，但得先确认 root cause，否则这是个伪装成 bug 的需求 |

## 下游分叉

brainstorming 收敛规格后，按 **Planning Gate 触发条件**自评影响面（原文复制，不引入新判定维度）：

- **预计影响 ≥3 文件 或 改动公开 API** → 进入 `writing-plans` → `plan-document-review` → 用户确认 → SDD 或直接实施
- **预计 <3 文件 且 不动公开 API** → **跳过 plan**，直接实施；实施完走 `sdk-code-review` 模式 B（独立审查，仅 code-reviewer）

**禁止**：不能直接跳 `subagent-driven-development`——SDD 需要 plan 作为输入。
