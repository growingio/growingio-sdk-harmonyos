---
name: using-growingio-sdk-skills
description: Use at the start of every interaction with the GrowingIO HarmonyOS SDK engineer agent — establishes skill invocation discipline and workflow routing BEFORE any response including clarifying questions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task — this includes but is not limited to:

- `code-reviewer` / `spec-reviewer` (reviewing code or specs)
- implementer subagents dispatched by `subagent-driven-development`
- any general-purpose agent invoked via the `Agent` / `Task` tool with a specific assigned task
- any subagent whose prompt explicitly hands you a narrow job

**then SKIP THIS META-SKILL ENTIRELY.** Do not apply the routing, Planning Gate, or workflow below. Just execute your assigned task as specified in the prompt you received. The meta-skill's rules are for the main controller agent only; you are not it.

**但"跳过 meta-skill"不等于"不用任何 skill"**：子 agent 仍可（且应当）自主调用与任务相关的**域 skill**，例如：
- `growingio-arkts-coding-style`（写/审 `.ets`/`.ts` 时）
- `test-driven-development`（实现核心路径时）
- `systematic-debugging`（遇到 build/test/runtime 失败时）
- `verification-before-completion`（声称任务完成前）

跳过的**只是** meta-skill 的三项硬规则：**Planning Gate + Workflow Routing + TodoWrite 强制**。域 skill 的判断由子 agent 按自身任务自行决定。

Signal of subagent context: your prompt starts with "你是…" / "You are…" followed by a specific role description, or you received a structured task payload. In contrast, the main controller receives raw user messages.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you MUST invoke the skill. This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

# Using GrowingIO SDK Skills

This is the **entry gate** for the GrowingIO HarmonyOS SDK engineer (main controller agent).

## How this skill reaches you

The full content of this SKILL.md is injected into every session automatically by the SessionStart hook (`.claude/hooks/session-start.sh`), and re-injected after `/clear` or auto-compact. You do NOT need to call the `Skill` tool to load it — it is already in your context when you start responding.

If you see this content and you are NOT the main controller (see `<SUBAGENT-STOP>` above), ignore it and execute your assigned task.

## What this skill does

Before any response — including clarifying questions — follow the Workflow Routing below to decide which task-specific skills apply, then invoke them via the `Skill` tool.

## Instruction Priority

When conflicts arise, resolve by this order:

1. **User's explicit instructions** (CLAUDE.md, direct messages, in-conversation corrections) — highest
2. **SDK skills** (including this meta-skill, planning gate logic, workflow routing) — override default behavior
3. **Default model behavior** — lowest

If the user says "skip the plan this time" and a skill says "always write a plan," follow the user.

## The Rule

**Invoke relevant skills BEFORE any response or action.** Even a 1% chance a skill applies means invoke it. If the invoked skill turns out to be wrong, you can drop it — but you must check first.

## Skill Checklist → TodoWrite (HARD RULE)

当被调用的 skill 包含步骤清单（"Checklist"、编号步骤、"You MUST..."、"必须完成以下"），控制器 **必须**立即调用 `TaskCreate` 把每一条转为独立 todo，并在完成每一步后用 `TaskUpdate` 更新状态。**禁止只在脑内执行 checklist**——脑内 checklist 的漏项率极高，落盘到 todo 才有约束力。

此规则对控制器（主 agent）强制；subagent 因其生命周期短、目标单一，可自行判断是否需要。

## Skill Catalog (by category)

### Process skills (check FIRST — they decide HOW to approach the task)
- `brainstorming` — 模糊需求 / 范围不清 / 写 plan 前，做"一次一个问题"的规格收敛
- `writing-plans` — drafting an implementation plan in `docs/plans/`
- `plan-document-review` — reviewing a plan doc for completeness before user confirmation
- `subagent-driven-development` — executing a plan by dispatching fresh subagents with two-stage review
- `systematic-debugging` — any build/test/runtime failure where root cause is unclear
- `test-driven-development` — implementing core SDK paths (event pipeline, storage, network)

### Review skills
- `sdk-code-review` — completed a feature/bugfix/refactor, or before merge, or user asked for review
- `receiving-code-review` — processing feedback from a reviewer subagent or human

### Closing skills
- `verification-before-completion` — before claiming work is done/fixed/ready
- `finishing-a-development-branch` — after verification & review pass, to close out the branch（普通分支收尾 / 发版分支 → 触发 Release 侧流）
- `git-conventions` — writing commit messages, branch names, PR titles

### Domain skills
- `growingio-arkts-coding-style` — writing/reviewing `.ets`/`.ts` files

### Release 侧流（仅发版分支激活，不走主流程）
- `jira-ticket` — 创建发版 Jira ticket（版本号确定后、`ohpm-publish` 之前）
- `ohpm-publish` — publishing the SDK HAR to OHPM registry

### Meta 侧流（改 skill / 改 agent 本身时才用，不走主流程）
- `writing-skills` — 新建或修改 `.agents/skills/` 下任何 SKILL.md 时

## Planning Gate (HARD GATE)

Before writing ANY code, check these triggers:

**Trigger (any ONE suffices):**
- Affected file count ≥ 3
- Any change to the public API surface (symbols exported from `index.ets`)

**If triggered:**
1. Invoke `writing-plans` → save plan to `docs/plans/YYYY-MM-DD-<feature>.md`
2. Invoke `plan-document-review` → dispatch reviewer subagent for the plan
3. Show the user the plan path + reviewer summary, explicitly ask for confirmation
4. **Do NOT touch any source file until the user replies with confirmation ("确认" / "OK" / "继续")**

Required sections in every plan (missing any = incomplete):
- 影响文件列表
- 公开 API 变更（无则填"无"）
- 数据协议变更（无则填"无"）
- 需同步修改的文档（无则填"无"）

### Planning Gate Rationalizations (all invalid)

| Excuse | Reality |
|--------|---------|
| "改动很简单，不需要规划" | 简单改动也有影响面，规划 2 分钟没有例外 |
| "先改完再补规划" | 规划的价值在事前对齐，事后补写无价值 |
| "用户没要求规划" | 触发条件满足即强制，不需用户单独要求 |
| "只改内部实现，不影响公开 API" | 内部实现影响 ≥3 文件同样触发 |
| "这次先快速改，下次规范" | 没有"下次规范"，规则从第一次执行 |
| "步骤很清楚，我脑内过一遍 checklist 就行，不用 TodoWrite" | 脑内 checklist 漏项率极高；TaskCreate 落盘 30 秒，无例外 |
| "需求我看懂了，不用 brainstorming" | 看懂字面 ≠ 规格闭合；brainstorming 把假设写下来给用户挑错 |

## Workflow Routing (decision tree)

> 图中**实线**是主干，**虚线/旁路**是可插入的 skill（遇到对应情况随时跳转）。每个 `→` 都是一次 skill invoke。

```
User request received
  │
  ▼
Invoke using-growingio-sdk-skills (you are here)
  │
  ▼
Understand intent
  │
  ▼
需求模糊 / 范围不清 / 无规格?
  ├─ YES → brainstorming → 产出 docs/specs/YYYY-MM-DD-<topic>.md → 用户确认
  │          │
  │          ▼
  │        brainstorming 自评影响面（按 Planning Gate 触发条件）
  │          ├─ ≥3 files OR public API change → 进主干 writing-plans
  │          └─ <3 files AND no public API     → 进主干 直接实施（跳过 plan）
  └─ NO  → 继续
  │
  ▼
Read relevant docs (docs/sdk-doc-routing.md 按场景读取表;
                    docs/sdk-critical-rules.md 若改核心模块必读)
  │
  ▼
Planning Gate: ≥3 files OR public API change ?
  │
  ├─ YES ─────────────────────────────────────────────┐
  │     │                                              │
  │     ▼                                              │
  │   writing-plans → plan-document-review             │
  │     → WAIT FOR USER CONFIRM                        │
  │     │                                              │
  │     ▼                                              │
  │   Tasks ≥3 且大部分独立?                            │
  │     ├─ YES → subagent-driven-development           │
  │     │          (控制器不写代码；subagent 内部按需用      │
  │     │           TDD / growingio-arkts-coding-style  │
  │     │           / systematic-debugging)            │
  │     │                                              │
  │     └─ NO  → 直接实施（单一职责 edits）               │
  │                                                    │
  └─ NO ── 直接实施（单一职责 edits） ───────────────────┘
                       │
                       │  实施期可随时插入的旁路 skill：
                       │    ┊ 改核心模块（事件管道/存储/网络） → test-driven-development
                       │    ┊ 写/审 .ets / .ts                  → growingio-arkts-coding-style
                       │    ┊ 任何阶段 build/test/runtime 失败 → systematic-debugging
                       │                                        (修完 → 回到失败前的上一步)
                       ▼
           verification-before-completion (跑真实 verify 命令，读完整输出)
                       │
                       ├─ 失败 → systematic-debugging → （修完）→ 回本步骤重跑 ─┐
                       │                                                     │
                       └─ 通过                                               │
                       │◄────────────────────────────────────────────────────┘
                       ▼
           Code review
             ├─ 有 plan → sdk-code-review 模式 A（spec-reviewer → code-reviewer）
             ├─ 无 plan + ≤5 files + 不动公开 API → sdk-code-review 模式 B（仅 code-reviewer）
             └─ 琐碎改动（<3 files 且不动公开 API）→ 可跳过
                       │
                       ├─ 需修改 → receiving-code-review → 修复
                       │              → 重派同一 reviewer 复审 ─────────────┐
                       │              → 回 verification-before-completion 重跑
                       │                                                    │
                       └─ 通过                                              │
                       │◄───────────────────────────────────────────────────┘
                       ▼
           finishing-a-development-branch
             ├─ 普通分支 → 使用 git-conventions 规范 commit / PR / 分支名
             │            → Done
             │
             └─ 发版分支（version 字段变更）→ 侧流：
                    jira-ticket（发版单）→ ohpm-publish（发布 HAR）
                    → 使用 git-conventions 规范 tag 命名
                    → Done
```

**Meta 侧流**（与上图主流程正交，改 skill 本身时激活）：
```
修改 .agents/skills/*/SKILL.md → writing-skills → 按其 Checklist 走完
```

## Skill Types

- **Rigid** (TDD, Planning Gate, verification-before-completion, systematic-debugging): follow exactly, do not adapt away the discipline
- **Flexible** (domain patterns, coding style): adapt principles to context

The skill itself declares which type it is.

## Red Flags — STOP if you catch yourself thinking these

| Thought | Reality |
|---------|---------|
| "这是个简单问题，直接回答就行" | 问题也是任务，先查 skill |
| "先读一下代码再说" | skill 告诉你怎么读 |
| "小改动不用走流程" | Planning Gate 的触发条件本身就是"小改动"判定器 |
| "我记得这个 skill 的内容" | skill 会演进，每次用读当前版本 |
| "用户没要求，跳过吧" | skill 适用性由触发条件判定，不由用户触发 |
| "先做一点再补流程" | 补不回来，从第一步就按流程走 |
| "这个场景有点特殊" | 没有特殊，Rigid skill 没有例外 |
| "我在 subagent 里，不需要查" | 看 `<SUBAGENT-STOP>` — 只有控制器跳过，其他要查 |
| "skill 里的 checklist 我记住了，不用落盘 TodoWrite" | 落盘是约束力，不是记忆术；立刻 TaskCreate |
| "先直接写 plan，跳过 brainstorming" | 需求模糊时 plan 的输入就是错的；先走 brainstorming 收敛规格 |

## User Instructions Override

User instructions say WHAT to accomplish — they don't override HOW (skills).
"Add feature X" does not mean "skip Planning Gate". "Fix bug Y" does not mean "skip verification".
Only explicit "skip the plan / skip the review" overrides the skill.

## Domain Context

领域知识拆分为若干 lazy-load 文档：

- `docs/sdk-engineering-guide.md` — 产品使命、核心职责索引、健康指标（精简版）
- `docs/sdk-critical-rules.md` — 修改核心模块前 **必读**
- `docs/sdk-doc-routing.md` — 按场景读取的模块文档索引
- `docs/sdk-build-commands.md` — hvigor 构建命令

本 skill 不重复这些内容——读文档知道 WHAT to build，读 skill 知道 HOW to build。

---

**Remember:** The persona defines who you are. Skills define how you work. This meta-skill is your entry gate — invoke it first, every time.
