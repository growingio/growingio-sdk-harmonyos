# Phase 3：对齐 superpowers 架构（skills 流程闭环 + 文档瘦身）

> 目标：把 GrowingIO HarmonyOS SDK 的 agent 架构对齐度从 ~85% 推到 ~95%。
> 范围：PR 对比后确认需要补的 5 个偏差点（用户确认的 3、4、5、6、7 项）。
> 不在本次范围：skills 目录迁移（用户已用软链接解决）、hook 跨平台 polyglot。

---

## 背景

对标 `https://github.com/obra/superpowers` 的 skills 架构，当前仓库仍存在：

- **(3) 缺 `brainstorming` skill**：模糊需求 → 规格的前置阶段，当前仅由 persona 一句"如歧义问一个澄清问题"兜底。
- **(4) 缺 `writing-skills` skill**：未来新增 skill 无规范，写出来形状会走样。
- **(5) meta-skill 未强制 TodoWrite**：superpowers 流程图明写 "Has checklist? → Create TodoWrite todo per item"，我们缺。
- **(6) `docs/sdk-engineering-guide.md` 全量注入**：169 行经 CLAUDE.md `@` 引用每轮都进上下文，长期看会与 skill 内容重复。
- **(7) persona 与 guide 重复段落**：`engineering-harmonyos-sdk-engineer.md` 的"沟通风格"和"技术决策优先级"与 `sdk-engineering-guide.md` 末尾同名段落字面重复。

---

## 影响文件列表

**新增**：
1. `.agents/skills/brainstorming/SKILL.md`
2. `.agents/skills/writing-skills/SKILL.md`
3. `docs/sdk-critical-rules.md`（从 guide 中拆出的"Critical Rules"一节，按需读取）
4. `docs/sdk-doc-routing.md`（从 guide 中拆出的"文档路由 + 按场景读取表"，按需读取）
5. `docs/sdk-build-commands.md`（从 guide 中拆出的"构建命令"，按需读取）

**修改**：
6. `.agents/skills/using-growingio-sdk-skills/SKILL.md` — 加 TodoWrite 强制点；Workflow Routing 在"Understand intent"之后插入 brainstorming 分支；Skill Catalog 新增 brainstorming / writing-skills。
7. `docs/sdk-engineering-guide.md` — 瘦身为"索引 + 使命 + 健康指标 + 沟通风格"，删除 Critical Rules / 文档路由表 / 构建命令（改为跳转链接）；删除与 persona 重复的"沟通风格"和"技术决策优先级"的其中一份（guide 保留 persona 删）。
8. `.claude/agents/engineering-harmonyos-sdk-engineer.md` — 作为"沟通风格 + 技术决策优先级"唯一事实源保留；删除与 guide 文件说明重复的"领域知识"节下冗余描述。
9. `CLAUDE.md` — 不再 `@` 引用完整 guide 全文；改为仅引用精简后的 guide 作为索引（文件瘦身后字节自然减少）。

---

## 公开 API 变更

无（本次仅改 agent 架构与文档）。

---

## 数据协议变更

无。

---

## 需同步修改的文档

- `AGENTS.md`：如提及 skill 目录或 guide 结构，需同步；检查后确定是否改。
- `CLAUDE.md`：调整 `@docs/sdk-engineering-guide.md` 引用说明（不再"全量加载领域知识"，而是"索引与使命"）。

---

## 任务分解（可独立推进）

### Task 1：新增 `brainstorming` skill
- 复制 superpowers `brainstorming/SKILL.md` 结构
- 本地化：spec 保存路径改 `docs/specs/YYYY-MM-DD-<topic>.md`；终态改为"invoke `writing-plans` skill"；保留 HARD-GATE、Checklist、Process Flow、Anti-Pattern 四节；删除 Visual Companion 分支（SDK 场景暂不需要）
- frontmatter: `description: Use when receiving an ambiguous feature request, when scope is unclear, or before writing any plan — explores intent and requirements through guided dialogue`
- 本地新增节：SDK 专有澄清问题清单（三种模式选择？是否影响公开 API？是否涉及数据协议？是否需要多端一致性校验？）

### Task 2：新增 `writing-skills` skill
- 复制 superpowers `writing-skills/SKILL.md` 的关键节：Overview（TDD for docs）、What is a Skill、Directory Structure、SKILL.md Structure、CSO（Rich Description）、Token Efficiency、Anti-Patterns、Checklist
- 删除：Flowchart 章节（暂不引入 graphviz 工具链）、persuasion-principles 引用、render-graphs.js 相关
- 本地化：skill 存放路径 `.agents/skills/<name>/SKILL.md`；要求 description 以 "Use when..." 开头；要求附带 rationalization 表（如果是 discipline skill）
- frontmatter: `description: Use when creating a new skill or editing an existing skill in .agents/skills/ — enforces description format, structure, and token budget`

### Task 3：meta-skill 加 TodoWrite 强制点
- 改 `using-growingio-sdk-skills/SKILL.md`
- 在 "The Rule" 节后插入新节 **"Skill Checklist → TodoWrite"**：
  > 当被调用的 skill 包含步骤清单（Checklist / 编号步骤 / "You MUST..."）时，控制器 **必须**立即调 `TodoWrite` 把每一条转为独立 todo，并在 Skill 指示完成步骤后更新状态。禁止仅在脑内执行 checklist。
- 对应 Rationalization 表新增：「步骤很清楚不用落盘」→「脑内 checklist 漏项率极高，落盘 30 秒，绝无例外」
- Workflow Routing 决策树在"Understand intent"分支新增：若请求模糊或规格不清 → invoke `brainstorming`

### Task 4a：拆出三个独立文档
- 新增 `docs/sdk-critical-rules.md`：迁出 guide 的"SDK 设计红线 + ArkTS 开发规范"两小节（逐字迁移，不改写）
- 新增 `docs/sdk-doc-routing.md`：迁出"项目文档路由（含按场景读取表）"整节
- 新增 `docs/sdk-build-commands.md`：迁出"构建命令"整节

### Task 4b：瘦身 guide
- 改 `docs/sdk-engineering-guide.md`：上述三节替换为一行跳转链接（"详见 docs/sdk-critical-rules.md"）；保留"产品与使命 / 核心职责 / 持续积累的知识域 / SDK 健康指标 / 进阶能力"；删除与 persona 重复的"沟通风格 / 技术决策优先级"两节
- 改 `CLAUDE.md`：说明 guide 仅为"产品使命 + 文档索引"，Critical Rules/路由/命令为 lazy load，并在注释中显式列出三个拆分文档的路径，防止 agent 初始化时静默缺失红线

### Task 4c：清理 persona 重复段落
- 改 `.claude/agents/engineering-harmonyos-sdk-engineer.md`：作为"沟通风格 + 技术决策优先级"单一事实源；在"领域知识"节改为指向拆分后的三个文档（按需读取）

依赖：4a → 4b → 4c

### Task 5：AGENTS.md 同步检查
- 通读 `AGENTS.md`，若提及已迁移段落（Critical Rules / 构建命令 / 按场景读取）需更新为新路径或跳转说明

---

## 任务依赖关系

- Task 1、Task 2、Task 4a 彼此独立，可并行
- Task 3 依赖 Task 1（Routing 引用 brainstorming 名字）
- Task 4b 依赖 Task 4a；Task 4c 依赖 Task 4b
- Task 5 依赖 Task 4c 完成后核对

---

## 验证标准（全部为客观可执行检查）

- [ ] `.agents/skills/brainstorming/SKILL.md` 和 `.agents/skills/writing-skills/SKILL.md` frontmatter 只含 `name` + `description` 两字段，`description` 字段值以 `Use when` 开头
- [ ] `using-growingio-sdk-skills/SKILL.md` 的 Rationalization 表至少有一行包含 `TodoWrite` 字符串；Red Flags 表至少有一行包含 `checklist` 或 `落盘` 关键字
- [ ] `using-growingio-sdk-skills/SKILL.md` 的 Workflow Routing 文本中出现 `brainstorming` 字符串
- [ ] `docs/sdk-engineering-guide.md` 行数 `< 80`（`wc -l`）
- [ ] `docs/sdk-critical-rules.md`、`docs/sdk-doc-routing.md`、`docs/sdk-build-commands.md` 三个文件存在
- [ ] diff 验证：`docs/sdk-critical-rules.md` 字面包含原 guide 中 `初始化前零采集`、`主线程零阻塞`、`不重复上报`、`最小权限原则`、`ArkTS 严格模式`、`Stage 模型`、`HAR 打包` 全部 7 个关键串
- [ ] diff 验证：`docs/sdk-doc-routing.md` 字面包含原"按场景读取"表全部 14 行
- [ ] diff 验证：`docs/sdk-build-commands.md` 字面包含 `assembleHar`、`assembleHap`、`clean` 三条命令
- [ ] 去重 grep 验证：对关键串 `数据精准第一`、`对接入方友好`、`性能意识`、`隐私合规敬畏`、`多端一致性`、`技术决策优先级`，在 `docs/sdk-engineering-guide.md` 和 `.claude/agents/engineering-harmonyos-sdk-engineer.md` 两文件合计出现次数 ≤ 出现于 persona 的次数（即 guide 中 0 次）
- [ ] `AGENTS.md` 中 `Critical Rules`、`构建命令`、`按场景读取` 三个字符串若存在，必须指向新路径或跳转说明（人工抽查）
- [ ] `CLAUDE.md` 中显式出现三个拆分文档路径：`docs/sdk-critical-rules.md`、`docs/sdk-doc-routing.md`、`docs/sdk-build-commands.md`

---

## 风险与缓解

| 风险 | 缓解 |
|---|---|
| 拆分文档后，skill 内找不到 Critical Rules | persona 的"领域知识"节明写三个文档路径；meta-skill 在 Workflow Routing 的"Read relevant docs"步骤指向新路径 |
| brainstorming 被滥用（所有请求都走一遍）| skill 描述精确限定触发：仅模糊需求 / 范围不清 / 写 plan 前；HARD-GATE 后留逃生条款「user explicitly says "skip brainstorming"」 |
| TodoWrite 强制点与 subagent-driven-development 已有 checklist 冲突 | 明确："控制器对 meta-skill 流程强制 TodoWrite；subagent 内部不强制（因其生命期短）" |
| guide 瘦身后 Critical Rules 从自动注入降为 lazy load，agent 初始化时可能静默缺失红线 | CLAUDE.md 中显式列出三个拆分文档路径作为注释索引；persona 的"领域知识"节明写"修改代码前必读 `docs/sdk-critical-rules.md`"硬性要求 |

---

## 不做的事

- 不迁移 `.agents/skills/` → `.claude/skills/`（用户用软链接已解决）
- 不做跨平台 hook polyglot
- 不引入 graphviz / render-graphs 工具链
- 不引入 eval / 红队测试（Phase 5 再议）
