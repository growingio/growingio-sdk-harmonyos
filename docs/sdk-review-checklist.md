# SDK 代码审查清单

变更完成后、合并前的自查清单。原先由 `code-reviewer` / `spec-reviewer` 两个 subagent 承载，现已沉淀为文档，由开发者（或 AI 助手）在同一会话内自查。

红线定义见 [`sdk-critical-rules.md`](./sdk-critical-rules.md)，本文档只列**审查动作**。

## 本清单在开发流程中的位置

本项目不使用 agent 编排层——没有 persona agent、没有 reviewer subagent、没有 SessionStart 注入。流程由规范文档承载，skill 靠自身 `description` 被动触发。

```
需求
 │
 ├─ 模糊 / 范围不清 → brainstorming（一次一问，收敛成 docs/specs/ 规格）
 │
 ▼
读相关文档（docs/sdk-doc-routing.md 按场景路由）
 │
 ▼
影响面判定：改动 ≥3 文件 或 涉及公开 API？
 ├─ 是 → writing-plans（落地 docs/plans/YYYY-MM-DD-*.md，用户确认后实施）
 └─ 否 → 直接实施
 │
 ▼
实施（改核心模块走 test-driven-development）
 │
 ▼
verification-before-completion（跑构建 + 测试，不靠"应该没问题"）
 │
 ▼
◀── 本清单：对照下方两部分自查 ──▶
 │
 ▼
finishing-a-development-branch（commit / PR / tag / 分支清理）
```

## 审查步骤

1. `git diff --stat BASE..HEAD` 确认变更文件列表和规模
2. 有对应 plan（`docs/plans/`）则先读 plan，理解变更背景与预期范围
3. `git diff BASE..HEAD -- <file>` 逐文件看具体变更
4. 对照下方两部分逐条核实

---

## Part 1：代码质量

### 1. ArkTS 合规

按 `growingio-arkts-coding-style` skill 的规则检查，重点：

- 语言约束：`any`、解构赋值、索引访问、`var`、`#privateField`
- 格式规范：缩进、行宽、导入顺序、命名规范、许可证头

### 2. SDK 设计红线

逐条核对 [`sdk-critical-rules.md`](./sdk-critical-rules.md)：初始化前零采集、主线程零阻塞、不重复上报、最小权限、公开 API 仅经 `index.ets` 导出。

### 3. 数据协议一致性

- 新增/修改的事件字段命名与 Android/iOS SDK 保持一致
- 字段类型对齐（string / number / boolean）
- 产品线差异处理正确（SaaS vs NewSaaS vs CDP）
- Protobuf schema 与 JSON schema 同步更新（如适用）

### 4. 隐私合规

- 新增采集字段是否需要 `ignoreField` 位掩码支持
- 是否存在未经用户授权的敏感数据采集
- `dataCollectionEnabled = false` 时新代码路径是否被正确拦截

### 5. 混淆与打包

- 新增公开 API 符号已加入 `obfuscation-rules.txt` 的 keep 规则
- 新增内部类/方法未意外暴露在 `index.ets` 中
- HAR 打包配置（`byteCodeHar: true`）未被破坏

> `git push` 前有 PreToolUse hook 跑 `scripts/check_obfuscation_rules.py` 做自动校验，但不要依赖它兜底。

### 6. 工程质量

- 错误处理：外部操作使用 try-catch，不吞异常
- 无冗余代码、无 TODO/FIXME 遗留
- 无硬编码魔法值（应提取为常量）
- 每个文件职责单一、接口清晰，模块可独立理解和测试

---

## Part 2：规格对齐

**前提：不信任自己的完成报告。** 读实际代码，不读报告；因为"我记得写了"就跳过检查，正是漏项的来源。

### 1. 缺失需求

- 规格要求的功能是否全部实现？
- 规划中列出的文件是否都已被修改？
- 公开 API 签名、数据协议变更是否被准确实现？
- 规划要求的文档更新是否已完成？

### 2. 多余工作

- 是否有规格未要求的额外功能？规划外的文件被改动？
- 是否过度工程化（YAGNI）？

### 3. 理解偏差

- 是否曲解了需求、解决了错误的问题？
- 功能方向对但实现方式与规格不符？

---

## 问题分级

| 级别 | 判定标准 | 处理 |
|------|---------|------|
| **Critical** | 会导致数据丢失、崩溃、隐私泄露、协议不兼容 | 必须修复，阻塞合并 |
| **Important** | 违反规范或红线，但不直接造成上述后果 | 合并前处理 |
| **Suggestion** | 可优化项 | 不阻塞 |

存在 Critical 或 Important 即为「需要修改」；涉及架构决策或暴露了规格本身的缺陷，则为「需要讨论」——后者应同时提出修改 plan 的建议。

## 审查原则

- **只看代码，不替自己解释意图**：代码有问题就是有问题
- **具体而非模糊**：每个问题给出精确 `file:line`，不写"某处可能有问题"
- **Critical 要谨慎**：够不上上表标准的不要升级
- **不做表演式认同**：直接给技术结论，不堆砌赞美
