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

## Skill Catalog (by category)

### Process skills (check FIRST — they decide HOW to approach the task)
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
- `finishing-a-development-branch` — after verification & review pass, to close out the branch
- `git-conventions` — writing commit messages, branch names, PR titles

### Domain skills
- `growingio-arkts-coding-style` — writing/reviewing `.ets`/`.ts` files
- `ohpm-publish` — publishing the SDK HAR to OHPM registry
- `jira-ticket` — creating a release tracking ticket in Jira

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

## Workflow Routing (decision tree)

```
User request received
  │
  ▼
Invoke using-growingio-sdk-skills (you are here)
  │
  ▼
Understand intent → if ambiguous, ask ONE clarifying question
  │
  ▼
Read relevant docs (docs/sdk-engineering-guide.md → "按场景读取" table)
  │
  ▼
Planning Gate triggered? (≥3 files OR public API change)
  ├─ YES → writing-plans → plan-document-review → WAIT FOR USER CONFIRM
  │         │
  │         ▼
  │       Tasks mostly independent AND ≥3 tasks?
  │         ├─ YES → subagent-driven-development (you are controller, don't code)
  │         └─ NO  → implement directly, apply test-driven-development on core paths
  │
  └─ NO  → implement directly (single-responsibility edits)
            │
            ▼
          Encountered build/test/runtime error? → systematic-debugging
  │
  ▼
Code review?
  ├─ Had a plan → sdk-code-review (full: spec-reviewer → code-reviewer)
  ├─ No plan, ≤5 files, no public API change → sdk-code-review (code-reviewer only)
  └─ Trivial change (< 3 files, no public API) → may skip
  │
  ▼
verification-before-completion (run actual verify command, read full output)
  │
  ▼
finishing-a-development-branch (commit/PR/merge decision)
  │
  ▼
Done
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

## User Instructions Override

User instructions say WHAT to accomplish — they don't override HOW (skills).
"Add feature X" does not mean "skip Planning Gate". "Fix bug Y" does not mean "skip verification".
Only explicit "skip the plan / skip the review" overrides the skill.

## Domain Context

Domain knowledge (product mission, SDK red lines, module docs routing, build commands, health metrics) lives in `docs/sdk-engineering-guide.md`. This skill does NOT duplicate it — read that doc for WHAT to build; read skills for HOW to build.

---

**Remember:** The persona defines who you are. Skills define how you work. This meta-skill is your entry gate — invoke it first, every time.
