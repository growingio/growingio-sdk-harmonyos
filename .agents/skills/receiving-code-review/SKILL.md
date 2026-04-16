---
name: receiving-code-review
description: Use when receiving feedback from code-reviewer subagent or human reviewer
---

# 接收代码审查反馈

> **Type:** Technique | **Discipline:** Rigid

收到 code-reviewer subagent 或人类 reviewer 的反馈后，按本技能规范处理。核心原则：**验证先于实施，澄清先于假设，技术正确性高于社交舒适度。**

## 响应模式

```
收到审查反馈
  ↓
1. READ：完整读完所有反馈，不急于行动
2. UNDERSTAND：用自己的话复述每条要求（或提问）
3. VERIFY：对照代码库现状核实
4. EVALUATE：对本项目是否技术合理？
5. RESPOND：技术性确认或有理据的 push back
6. IMPLEMENT：逐条修复，每条单独测试
```

## STOP-ASK 模式

```
如果反馈中任何一项不明确：
  → 全部暂停，不实施任何一项
  → 先对不明确的项提问澄清
  → 澄清完毕后再开始实施

原因：各项可能相互关联，部分理解 = 错误实施。
```

**示例：**
```
reviewer 返回 6 条问题，你理解 1、2、3、6，不确定 4、5。

❌ 错误：先改 1、2、3、6，回头再问 4、5
✅ 正确："第 1、2、3、6 条已理解。第 4 条和第 5 条需要澄清：
    - 第 4 条提到 'session 边界处理'，是指 onForeground 还是 VISIT 事件？
    - 第 5 条 '协议对齐'，具体是哪个字段？"
```

## 反馈来源分级

### 来自 code-reviewer subagent

```
实施前逐条验证：
  1. 对本代码库技术上正确吗？
  2. 会破坏已有功能吗？
  3. 当前实现是否有特殊原因？
  4. 是否适用于所有产品线（SaaS/NewSaaS/CDP）？
  5. reviewer 是否掌握了完整上下文？

如果建议有误：
  → 用技术理由 push back，不盲目接受

如果无法验证：
  → 明确说"我无法验证这一点，需要 [X] 才能确认。是否继续？"

如果与用户之前的架构决策冲突：
  → 暂停，先与用户确认
```

### 来自用户（人类）

- 信任度更高，理解后直接实施
- 范围不清时仍然要问
- 不做表演式认同，直接行动或技术性确认

## YAGNI 检查

```
当 reviewer 建议"实现得更完善"时：
  → 先 grep 代码库确认是否有实际调用

  如果没有调用："这个接口当前没有调用方，是否需要实现？（YAGNI）"
  如果有调用：按建议实现
```

## 禁止行为

**绝不说：**
- "你说得对！" / "好建议！" / "非常好的反馈！"
- "让我立刻实现" （在验证之前）

**应该说：**
- "已修复。[简述改了什么]"
- "确认是个问题——[具体原因]。已在 `file:line` 修复。"
- 或者直接修复，不多说。

## 何时 Push Back

**应该 push back 的情况：**
- 建议会破坏已有功能
- reviewer 缺少完整上下文
- 违反 YAGNI（功能无实际调用）
- 对本技术栈不适用
- 存在兼容性/历史原因
- 与用户的架构决策冲突

**如何 push back：**
- 给出技术理由，不带防御性
- 提出具体的反例或引用已有测试
- 如涉及架构层面，建议升级给用户决策

## 被证明 push back 有误时

```
✅ "你是对的——我验证了 [X]，确实 [Y]。正在修复。"

❌ 长篇道歉
❌ 解释为什么当时 push back
```

陈述事实，继续工作。

## 实施顺序

```
多条反馈的处理顺序：
  1. 先澄清所有不明确的项（STOP-ASK）
  2. 按以下优先级实施：
     a. Critical（阻塞项：崩溃、数据丢失、隐私泄露）
     b. 简单修复（拼写、导入、格式）
     c. 复杂修复（重构、逻辑变更）
  3. 每条修复后单独验证
  4. 全部完成后确认无回归
```

## 常见错误

| 错误 | 纠正 |
|------|------|
| 表演式认同 | 直接修复或给出技术性回应 |
| 不验证就实施 | 先对照代码库核实 |
| 批量修改不测试 | 逐条修复，逐条验证 |
| 假定 reviewer 一定对 | 检查是否会破坏现有功能 |
| 回避 push back | 技术正确性 > 社交舒适度 |
| 部分理解就开始改 | STOP-ASK，先澄清所有不明确项 |
| 无法验证仍然继续 | 明确说出局限，请求指导 |

## Rationalizations

| Excuse | Reality |
|---|---|
| "reviewer 说的有理，全盘接受避免冲突" | 表演式认同是失职；正确的反应是修复或给技术反驳 |
| "reviewer 这条我觉得不对，忽略就行" | 必须 push back 并给技术理由，不是沉默不处理 |
| "改完了不用重新 dispatch，reviewer 不会再挑出新问题" | Critical/Important 修完必须重新 review，不可自判 |
| "先改 Critical，Important 合并前再说" | Important 也阻塞合并，只有 Suggestion 可延后 |
| "一次把所有意见全改完再验证" | 批量修改后一个点崩了定位困难，逐条修复逐条验证 |
| "部分听懂了就开始改" | 不明确项必须 STOP-ASK，改错的成本高于问一句 |
| "我改得很小，不用重跑 verify" | 任何修改后 verify 都要重跑——这是 `verification-before-completion` 的不变量 |
| "改完 reviewer 一定会通过，不用重新 dispatch 了" | Critical/Important 修完必须重新 review，自判=赌博 |

## Red Flags — STOP if you catch yourself thinking these

- "reviewer 说得对！让我立刻实现" → 表演式认同，先验证再行动
- "这条反馈我不同意，跳过" → 必须 push back 并给技术理由，沉默 ≠ 处理
- "部分理解了就先改能改的" → STOP-ASK，各项可能相互关联，部分理解 = 错误实施
- "改完了不用重新 dispatch 了" → Critical/Important 修完必须重新 review，自判 = 赌博
- "改动很小，不用重跑 verify" → 任何修改后 verify 都要重跑，这是不变量

## 下游 / loop-back（HARD RULE）

反馈项全部实施完成后，**必须**按以下顺序走完回路，不得自行判定"改好了"：

1. **回到同一个 reviewer 复审**（不是新 reviewer，避免上下文丢失）
   - 直接实施路径：重新 dispatch `sdk-code-review` 的同一 reviewer 角色
   - SDD 路径：由 SDD 控制器重派 spec-reviewer（若 spec 未过）或 code-reviewer（若 spec 已过）
2. **所有项通过后** → `verification-before-completion` 重跑（修复可能破坏既有验证，不重跑就是赌博）
3. **verify 通过** → 回到主流程（继续下一任务 / `finishing-a-development-branch`）

## 关联 skill

- **上游触发：** 收到 `sdk-code-review` 的 reviewer subagent 或人类 reviewer 反馈
- **调度 subagent：** 无（本 skill 由实施者执行处理反馈）
- **完成后交接：** 见上方「下游 / loop-back」
- **替代路径：** push back 有据且 reviewer 撤回该条 → 该条无需修改；其他条仍需按 loop-back 流程走
