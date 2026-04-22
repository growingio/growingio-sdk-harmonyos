---
name: writing-skills
description: Use when creating a new skill, editing an existing skill, or verifying a skill works before deployment
---

# Writing Skills

**Writing skills IS Test-Driven Development applied to process documentation.**

You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

## The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

This applies to NEW skills AND EDITS to existing skills.

Write skill before testing? Delete it. Start over.
Edit skill without testing? Same violation.

**No exceptions:**
- Not for "simple additions"
- Not for "just adding a section"
- Not for "documentation updates"
- Don't keep untested changes as "reference"
- Don't "adapt" while running tests
- Delete means delete

## What is a Skill?

- **Is**：Reusable technique, pattern, or reference guide for future agent instances
- **Is NOT**：Narrative about a one-time problem solve; project-specific convention (put those in CLAUDE.md / `docs/sdk-engineering-guide.md`)

## Skill Types (two orthogonal dimensions)

### 本质分类（这个 skill 是什么）

| Type | Description | Example |
|---|---|---|
| **Technique** | 具体方法，有步骤可循 | `test-driven-development`, `systematic-debugging` |
| **Pattern** | 思维模型，指导如何思考 | `brainstorming` |
| **Reference** | 查询式，结构化条目 | `git-conventions`, `ohpm-publish` |

### 执行纪律标签（这个 skill 怎么执行）

| Label | Meaning | Requirement |
|---|---|---|
| **Rigid** | 必须严格遵守，不得适配 | 必须带 Rationalizations 表 + Red Flags |
| **Flexible** | 原则可按场景取舍 | 不需 Rationalizations |

两个维度正交。一个 skill 同时有本质类型和执行标签，如：`test-driven-development` = Technique + Rigid；`git-conventions` = Reference + Flexible。

**每个 skill 必须在正文开头声明两个维度。**

## Directory Structure

```
.agents/skills/
  <skill-name>/
    SKILL.md               # Main file (required)
    <supporting-file>.md   # Only when content >100 lines or is a reusable prompt template
```

Naming: lowercase with hyphens, verb/gerund preferred: `brainstorming`, `writing-plans`, `subagent-driven-development`.

## Frontmatter (only two fields)

```yaml
---
name: skill-name-with-hyphens
description: Use when <triggering condition>
---
```

- `name`: letters, numbers, hyphens only
- `description`: see "Claude Search Optimization" below for detailed rules

## Claude Search Optimization (CSO)

CSO determines whether future agents **find and correctly use** your skill. Description is the single most important line.

### Description Rules

- Start with `Use when` / `Use before` / `Use after` (temporal triggers allowed)
- Third person
- **ONLY describe triggering conditions** — symptoms, situations, contexts
- **NEVER summarize the skill's process or workflow**
- Keep under 500 characters

### WHY: Description Workflow = Agent Skips Body

Testing revealed: when a description summarizes workflow, Claude follows the description instead of reading the full skill. A description saying "code review between tasks" caused Claude to do ONE review, even though the skill body clearly showed TWO reviews (spec compliance then code quality).

When the description was changed to just triggering conditions (no workflow summary), Claude correctly read the body and followed the two-stage process.

**The trap:** Descriptions that summarize workflow create a shortcut Claude will take. The skill body becomes documentation Claude skips.

### Examples

```yaml
# ❌ BAD: Summarizes workflow — Claude may follow this instead of reading skill
description: Use when executing plans - dispatches subagent per task with code review between tasks

# ❌ BAD: Too much process detail
description: Use for TDD - write test first, watch it fail, write minimal code, refactor

# ❌ BAD: Too abstract
description: 用于异步测试

# ❌ BAD: First person
description: I help you write skills

# ✅ GOOD: Just triggering conditions
description: Use when executing an implementation plan with independent tasks in the current session

# ✅ GOOD: Temporal trigger + symptoms
description: Use before claiming work is complete, fixed, or ready to review

# ✅ GOOD: Includes specific keywords for discovery
description: Use when facing ArkTS compile errors, hvigor build failures, or any technical problem where root cause is unclear
```

### Keyword Coverage

Use words agents would search for:
- Error messages: "Hook timed out", "hvigor build failure"
- Symptoms: "flaky", "race condition", "context pollution"
- Synonyms: "timeout/hang/freeze", "cleanup/teardown"
- Tools: actual commands, library names, file types

## SKILL.md Body Structure (recommended)

```markdown
# <Skill Name>

> **Type:** Technique | **Discipline:** Rigid

## Overview
1–2 sentences: what is this, core principle.

## When to Use / Not to Use
Triggering signals + exclusions.

## Process / Checklist
Numbered steps. Rigid skills must note "convert to TodoWrite".

## Quick Reference (optional)
Table or bullets for scanning.

## Rationalizations (Rigid skills required)
| Excuse | Reality |
|---|---|

## Red Flags (Rigid skills required)
If you think X / Y / Z, STOP.

## Related Skills
Explicit names + dependency strength (REQUIRED / OPTIONAL).
```

## Token Efficiency

**Target word counts:**
- Meta-skill (injected every session): < 200 words
- Frequently-loaded skills: < 300 words
- Other skills: < 500 words target (no hard cap, but > 500 → ask "should I split?")

**Techniques:**
- Cross-reference other skills by name, don't repeat their content
- One excellent example > five mediocre ones
- Inline code for < 50 lines; separate file for > 100 lines
- Don't explain what's obvious from context

## RED-GREEN-REFACTOR for Skills

### RED: Baseline Test

Run pressure scenario with subagent WITHOUT the skill. Document:
- What choices did they make?
- What rationalizations did they use (verbatim)?
- Which pressures triggered violations?

### GREEN: Write Minimal Skill

Address those specific rationalizations. Don't add content for hypothetical cases. Run same scenarios WITH skill — agent should now comply.

### REFACTOR: Close Loopholes

Agent found new rationalization? Add explicit counter. Re-test until bulletproof.

### Bulletproofing (for Rigid skills)

- State "violating the letter = violating the spirit" early — cuts off "I'm following the spirit" escape
- Build Rationalizations table from actual baseline test verbatims, not imagined excuses
- Create Red Flags list for self-check
- Explicitly forbid specific workarounds, not just state the rule

## STOP: Deployment Discipline

**After writing or editing ANY skill, STOP and complete deployment before moving on.**

**Do NOT:**
- Create/edit multiple skills in batch without testing each
- Move to next skill before current one is verified
- Skip testing because "batching is more efficient"

## Cross-Referencing Other Skills

Use skill name with explicit dependency marker:
- ✅ `**REQUIRED:** test-driven-development`
- ✅ `**OPTIONAL:** growingio-arkts-coding-style`
- ❌ `@path/SKILL.md` (force-loads, burns context)

## Anti-Patterns

- ❌ **Description summarizes workflow** → agent shortcuts the body
- ❌ **Narrative "we once encountered..."** → not reusable
- ❌ **Multi-language dilution** → one excellent example in the most relevant language
- ❌ **Project-specific rules in skill** → put in CLAUDE.md / `docs/sdk-engineering-guide.md`
- ❌ **Flowchart for linear steps** → use numbered list; reserve flowchart for non-obvious decisions

## Checklist (convert to TodoWrite for each new/edited skill)

**RED Phase:**
- [ ] Create pressure scenarios (3+ combined pressures for Rigid skills)
- [ ] Run scenarios WITHOUT skill — document baseline behavior verbatim
- [ ] Identify patterns in rationalizations/failures

**GREEN Phase:**
- [ ] Name: letters/numbers/hyphens only
- [ ] Frontmatter: only `name` + `description`
- [ ] Description: starts with `Use when/before/after`, triggering only, no workflow
- [ ] Body: declares type (Technique/Pattern/Reference) + discipline (Rigid/Flexible)
- [ ] Rigid skill: has Rationalizations table + Red Flags (from baseline verbatims)
- [ ] Word count within budget
- [ ] One real-scenario example (not fill-in template)
- [ ] Cross-references use name + dependency strength, no `@` force-load
- [ ] Run scenarios WITH skill — verify agents now comply

**REFACTOR Phase:**
- [ ] Identify NEW rationalizations from testing
- [ ] Add explicit counters
- [ ] Re-test until bulletproof

**Deployment:**
- [ ] Commit and push
- [ ] If editing: explain why this change is necessary (not just "looks better")

## Rationalizations

| Excuse | Reality |
|---|---|
| "Skill is obviously clear, no need to test" | Clear to you ≠ clear to agents. Test it. |
| "It's just a reference, testing is overkill" | References have gaps. Test retrieval + application. |
| "Description needs a bit of workflow context for clarity" | Testing proved: workflow in description → agent skips body |
| "This skill is too short to be worth a file" | Short skill = clear trigger; long skill is the problem |
| "I'll test if problems emerge" | Problems = agents misusing skill in production. Test BEFORE. |
| "I remember how this skill works, let me just edit" | Skills evolve; read current version before any edit |
| "Multiple language examples are more comprehensive" | Multiple = each mediocre; one great example > five templates |
| "Just adding a section, no test needed" | Same Iron Law. Edit without test = violation. |

## Red Flags — STOP if you catch yourself thinking these

- "I'll write the skill first, test later" → Delete. Start with RED.
- "This edit is too small to test" → No edit is too small. Iron Law.
- "I'm confident it's good" → Overconfidence guarantees issues.
- "Batching multiple skills is more efficient" → Deploy each one before starting next.
- "The description needs to explain what this skill does so people know" → That's what the body is for. Description = trigger only.
