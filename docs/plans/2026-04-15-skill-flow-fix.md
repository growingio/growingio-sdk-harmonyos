# Skill 流转断点修复

> 目标：修复当前 skill 体系中 4 个硬断点（P1–P4）+ 顺手清理 4 个误导点（P5–P8）。
> 不动：P9–P11（灵活度相关，单独议定）。
> 范围：仅改 skill 文档与 meta-skill 路由图；不改代码、不改 agent 身份。

---

## 背景

Phase 3 完成后的 skill 审计发现 11 个流转问题，分类：

- **P1**：`brainstorming/SKILL.md:96` 硬绑定「唯一下游 = writing-plans」，与 Planning Gate 的"小改动直接实施"互相矛盾
- **P2**：`receiving-code-review/SKILL.md` 未写修复完成后的 loop-back（应回 reviewer 复审 + verification-before-completion 重跑）
- **P3**：`systematic-debugging/SKILL.md:119` 写"修复后 → 完成"，未衔接回 verification，高频导致跳过 verify
- **P4**：meta-skill Workflow Routing 图缺连线：TDD 触发点、verify↔debug 回环、review 回环、finishing→git-conventions、发版侧流
- **P5**：SDD 流程图终态未显式接 `finishing-a-development-branch`
- **P6**：`writing-skills` 被误归 Process 类，应独立归 Meta 侧流
- **P7**：ohpm-publish / jira-ticket 侧流在主 Routing 不可见
- **P8**：`<SUBAGENT-STOP>` 歧义——可能被子 agent 读成"完全不用 skill"

---

## 影响文件列表

1. `.agents/skills/brainstorming/SKILL.md`（P1）
2. `.agents/skills/receiving-code-review/SKILL.md`（P2）
3. `.agents/skills/systematic-debugging/SKILL.md`（P3）
4. `.agents/skills/using-growingio-sdk-skills/SKILL.md`（P4、P6、P7、P8）
5. `.agents/skills/subagent-driven-development/SKILL.md`（P5）

---

## 公开 API 变更

无。

## 数据协议变更

无。

## 需同步修改的文档

无（所有变更都在 skill 内闭环；`docs/sdk-engineering-guide.md` 不受影响）。

---

## 任务分解

### Task 1（P1）：brainstorming 下游分叉
**改 `.agents/skills/brainstorming/SKILL.md`**：
- 行 96「**唯一下游**：`writing-plans`」改为：
  > **下游分叉**（brainstorming 完成时自评规格影响面）：
  > - 触发 Planning Gate（预计影响 ≥3 文件 或 改动公开 API）→ `writing-plans`
  > - 未触发 Planning Gate（规格闭合后预计 <3 文件且不动公开 API）→ **跳过 plan**，直接进入实施；实施完走 `sdk-code-review` 模式 B（独立审查）
  > 禁止跳过：不能直接进 `subagent-driven-development`（SDD 需要 plan 作为输入）
- 行 42 Checklist 第 8 条"移交 → 调用 writing-plans skill"改为"根据影响面判断下游（writing-plans 或直接实施）"
- Process Flow ASCII 图终态改为分叉（两个终态方块）

### Task 2（P2）：receiving-code-review 补 loop-back
**改 `.agents/skills/receiving-code-review/SKILL.md`**：
- 新增末尾「下游 / loop-back」节：
  > 反馈项全部实施完成后：
  > 1. **回到同一个 reviewer 复审**（不能自行判断"已修好"）——直接实施路径 re-dispatch `sdk-code-review`；SDD 路径由 SDD 控制器重派 spec-reviewer / code-reviewer
  > 2. **所有项通过后** → `verification-before-completion` 重跑（修复可能破坏既有验证）
  > 3. verify 通过 → `finishing-a-development-branch`
- 增加 Rationalization 行：「"我改得很小，不用重跑 verify"→ "任何修改后 verify 都要重跑，这是 verify 的不变量"」

### Task 3（P3）：systematic-debugging 退出衔接
**改 `.agents/skills/systematic-debugging/SKILL.md`**：
- 行 119「修复后问题消失 → 完成，记录根因」改为：
  > 修复后问题消失 → 记录根因（commit message 或注释）→ **回到 `verification-before-completion` 重跑**。调试过程中的临时改动（日志、调试开关）需在重跑 verify 前清理。
- 新增 Rationalization 行：「"单元测试过了就行，不用整体 verify"→ "debug 可能掩盖其他路径的回归，verify 才是终局"」

### Task 4（P5）：SDD 流程图接 finishing-a-development-branch
**改 `.agents/skills/subagent-driven-development/SKILL.md`**：
- 在"所有任务完成 → dispatch final code-reviewer"之后补一步「最终审查通过 → 进入 `finishing-a-development-branch` skill」
- Process ASCII 图补绿色终态方块 `finishing-a-development-branch`

### Task 5a（P6/P7）：meta-skill Skill Catalog 重分类
**改 `.agents/skills/using-growingio-sdk-skills/SKILL.md`**：
- 把 `writing-skills` 从 Process 类挪到新分类 **Meta 侧流**
- 新增 **Release 侧流** 分类：`jira-ticket`、`ohpm-publish`
- `finishing-a-development-branch` 保留 Closing；新增注释"发版分支 → 触发 Release 侧流"

### Task 5b（P4/P7）：meta-skill Workflow Routing 图重绘
**改 `.agents/skills/using-growingio-sdk-skills/SKILL.md`**，显式画出：
- brainstorming → Planning Gate 判定分叉（接 P1 下游）
- 实施期：`test-driven-development`（核心模块判定条件明确写出）
- `systematic-debugging` 作为"任意阶段失败时可插入"的旁路，退出指回**原失败节点的上一步 verify**
- `verification-before-completion` ⇄ `systematic-debugging` 的回环
- `sdk-code-review` → `receiving-code-review` → 修复 → 重审（loop）
- `finishing-a-development-branch` → `git-conventions`（commit/PR）的显式调用
- `finishing-a-development-branch` 分叉：普通分支 → 结束；发版分支 → `jira-ticket` + `ohpm-publish`

### Task 5c（P8）：meta-skill SUBAGENT-STOP 澄清
**改 `.agents/skills/using-growingio-sdk-skills/SKILL.md`**：
- 现文：「**then SKIP THIS META-SKILL ENTIRELY.**」后追加澄清段：
  > **但这不等于"不用任何 skill"**——子 agent 仍可自主调用与任务相关的域 skill（如 `growingio-arkts-coding-style`、`test-driven-development`、`systematic-debugging`、`verification-before-completion`）。跳过的是 meta-skill 的 **Planning Gate + Workflow Routing + TodoWrite 硬规则**；域 skill 的判断留给子 agent 自行决定。

---

## 任务依赖

- Task 1 / Task 2 / Task 3 / Task 4 / Task 5a / Task 5c 彼此独立，可并行
- Task 5b 依赖 Task 1（Routing 图要画 brainstorming 的分叉下游，与 Task 1 一致）和 Task 5a（新分类名字要先定）

---

## 验证标准（全部可执行）

- [ ] `brainstorming/SKILL.md` 中 `唯一下游` 字符串不再出现；出现 `下游分叉` 或 `Planning Gate` 关键字
- [ ] `brainstorming/SKILL.md` 中同时出现 `writing-plans` 和 `sdk-code-review` 两个下游名字
- [ ] `receiving-code-review/SKILL.md` 出现 `verification-before-completion` 字符串 ≥1 次
- [ ] `receiving-code-review/SKILL.md` Rationalization 表新增至少 1 行含 `verify` 或 `重跑` 关键词
- [ ] `systematic-debugging/SKILL.md` 行 119 附近的「修复后...完成」改写包含 `verification-before-completion` 字符串
- [ ] `subagent-driven-development/SKILL.md` 终态出现 `finishing-a-development-branch` 字符串
- [ ] `using-growingio-sdk-skills/SKILL.md` Skill Catalog 含 `Meta 侧流` 和 `Release 侧流` 两个新分类小节
- [ ] `using-growingio-sdk-skills/SKILL.md` Workflow Routing 图中同时出现：`test-driven-development`、`receiving-code-review`、`git-conventions`、`jira-ticket`、`ohpm-publish` 五个字符串（确认这五条连线被画到图里）
- [ ] `using-growingio-sdk-skills/SKILL.md` `<SUBAGENT-STOP>` 之后 30 行内出现 `但这不等于` 或 `域 skill` 字符串（澄清段存在）
- [ ] `brainstorming/SKILL.md` 分叉条件文本字面包含 Planning Gate 原文关键串 `≥3 文件` 和 `公开 API`（保证判定维度一致，不引入新维度）
- [ ] 双向引用验证：`systematic-debugging/SKILL.md` 含 `verification-before-completion` 且 `verification-before-completion/SKILL.md` 含 `systematic-debugging`（loop 闭合）
- [ ] 双向引用验证：`receiving-code-review/SKILL.md` 含 `sdk-code-review` 且 `sdk-code-review/SKILL.md` 含 `receiving-code-review`
- [ ] 回归扫描：改完 meta-skill 后，`grep -r "^description:" .agents/skills/*/SKILL.md` 每个 description 与新 Routing 图的触发条件无字面冲突（人工抽查一次，grep 列清单）

---

## 风险与缓解

| 风险 | 缓解 |
|---|---|
| Routing 图重绘后变得过于复杂，agent 读不懂 | 保留当前的 ASCII 简图，仅增连线；不引入新符号 |
| Task 5 一次改动太多，回归面大 | 验证标准逐条核查；改完跑 V9/V11 类 grep 验证 |
| brainstorming 下游分叉让 agent 犹豫"该不该走 writing-plans" | 分叉条件就是 Planning Gate 的触发条件原文复制，不引入新判定维度 |
| SUBAGENT-STOP 澄清后被误读为"子 agent 可随意调 meta-skill" | 明写"跳过的是 Planning Gate + Workflow Routing + TodoWrite 硬规则"三项，不留模糊 |
| meta-skill 改动后，现有 skill 的 `description` 触发条件与新 Routing 图不对齐 | Task 5b 完成后执行回归扫描（见验证标准最后一条），grep 全部 description 与新图触发条件对比 |

---

## 不做

- P9（plan-document-review 逃生条款）—— 需先积累几次实际被卡的场景再决定
- P10（TDD↔debug 交叉引用）—— 优先级低，等 TDD skill 整体修订时一起做
- P11（直接实施路径 Routing 图补强）—— Task 5 已覆盖主干，支线留后
