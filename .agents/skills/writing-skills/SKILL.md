---
name: writing-skills
description: Use when creating a new skill or editing an existing skill in .agents/skills/ — enforces description format, structure, and token budget
---

# Writing Skills

写 skill = 用文档塑造 agent 行为。规范必须严格，否则 skill 形状走样、触发不稳。

## 核心原则

- **Description 只描述"何时触发"，不描述"做什么"**。描述里写流程会导致 agent 直接按描述行事，跳过 skill 正文。
- **一个 skill 一件事**。跨职责的拆成多个。
- **Token 预算**：频繁注入的 meta-skill < 200 words；其他 skill < 500 words 目标值（硬上限无，但每次超 500 需自问是否该拆）。

## 什么是 skill

- **是**：复用的技术、模式、参考，用于指导未来 agent 实例
- **不是**：一次问题解决的叙事、项目特定约定（后者放 CLAUDE.md / 工程指南）

## 目录结构

```
.agents/skills/
  <skill-name>/
    SKILL.md               # 主文件（必须）
    <supporting-file>.md   # 仅当内容 >100 行或是可复用 prompt 模板
```

命名用小写连字符：`brainstorming`、`writing-plans`、`subagent-driven-development`。动词/动名词优先。

## Frontmatter（只允许两字段）

```yaml
---
name: skill-name-with-hyphens
description: Use when <triggering condition>
---
```

- `name`：仅字母、数字、连字符
- `description`：
  - 以 `Use when` 开头
  - 第三人称
  - 只讲触发条件（症状、场景、上下文），不讲工作流
  - 尽量 < 500 字符
  - 可加具体错误信息、关键字，方便检索

## 合格 / 不合格示例

```yaml
# ❌ 描述了流程
description: Use when executing plans - dispatches subagent per task with review between tasks

# ❌ 太抽象
description: 用于异步测试

# ❌ 第一人称
description: I help you write skills

# ✅ 只讲触发
description: Use when executing an implementation plan with independent tasks in the current session

# ✅ 含具体症状/关键字
description: Use when tests have race conditions, timing dependencies, or pass/fail inconsistently
```

## SKILL.md 正文结构（推荐）

```markdown
# <Skill Name>

## 核心原则 / Overview
1–2 句讲清这是什么、为什么。

## 何时用 / 不用
触发信号 + 不适用场景。

## 流程 / Checklist
编号步骤，discipline 类必须带"转 TodoWrite"提示。

## Quick Reference（可选）
表格/要点，扫读用。

## Rationalizations（discipline 类必备）
| 借口 | 现实 |
|---|---|

## Red Flags（discipline 类必备）
若想出 X / Y / Z，说明正在找借口，STOP。

## 下游 / 关联 skill
明确下游、禁止跳过的中间 skill。
```

## Skill 类型

| 类型 | 例 | 特点 |
|---|---|---|
| **Rigid / Discipline** | TDD、verification-before-completion、Planning Gate | 必须带 Rationalizations + Red Flags 表；不留口子 |
| **Flexible / Pattern** | growingio-arkts-coding-style、receiving-code-review | 原则可按场景取舍；不需 Red Flags |
| **Reference** | git-conventions、ohpm-publish | 查询式，结构化条目优先 |

每个 skill 在正文开头声明自己属于哪一类。

## 堵漏（针对 Rigid skill）

- 明说"违反字面 = 违反精神"，切断"我遵循精神"的借口
- Rationalizations 表把基线测试中 agent 实际用过的借口逐条列入
- Red Flags 列出"自我催眠的症状"
- 不要只写规则，要把每个逃逸路径**显式禁止**

## 反模式

- ❌ **描述里写工作流** → agent 直接按描述走，跳过正文
- ❌ **叙事式"我们那次遇到…"** → 不可复用
- ❌ **多语言稀释** → 挑一个最能讲清楚的语言给一个优秀示例
- ❌ **把项目特定规则塞 skill** → 应放 CLAUDE.md / `docs/sdk-engineering-guide.md`
- ❌ **滥用 flowchart ASCII** → 非必要不画；真要画就画清楚的小图，不要 step1/step2 这种无语义标签

## 交叉引用其他 skill

用 skill 名称，显式标记依赖强度：

```
REQUIRED SUB-SKILL: test-driven-development
REQUIRED BACKGROUND: systematic-debugging
```

不要用 `@path/SKILL.md` 强制加载（会炸上下文）。

## Checklist（新建或修改 skill 时 **转成 TodoWrite** 逐条过）

- [ ] 名称只含字母/数字/连字符
- [ ] frontmatter 仅 `name` + `description` 两字段
- [ ] description 以 `Use when` 开头，只讲触发
- [ ] description 无工作流/流程描述
- [ ] 正文声明 skill 类型（Rigid / Flexible / Reference）
- [ ] Rigid skill 带 Rationalizations 表 + Red Flags 表
- [ ] 字数符合预算（meta < 200；常规 < 500 目标）
- [ ] 有一个真实场景的例子（不是填空模板）
- [ ] 交叉引用用名称 + 依赖强度，不用 `@` 强制加载
- [ ] 若是修改：对比修改前后，解释为什么这个改动必要（避免仅因"看起来更漂亮"改）

## Rationalizations（写 skill 时常见借口）

| 借口 | 现实 |
|---|---|
| "描述里顺带说下流程更清楚" | agent 会照描述行事，跳过 skill 正文；触发精度下降 |
| "这 skill 太短，不值得单独建" | 短 skill = 清晰触发；长 skill 才是问题 |
| "多语言示例更全面" | 多语言 = 每个都平庸；一个好例子 > 五个模板 |
| "我记得之前这样写过，抄一下" | skill 在演进；每次用读当前版本，修改也读当前版本 |

## Bottom Line

> 写 skill 就是用文档做回归测试：description 是触发断言，正文是断言通过后的行为。description 错了，agent 根本不会进正文。
