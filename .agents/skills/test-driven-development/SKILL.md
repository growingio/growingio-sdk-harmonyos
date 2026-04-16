---
name: test-driven-development
description: Use when implementing or modifying core SDK paths (event pipeline, storage, network, session management)
---

# Test-Driven Development

> **Type:** Technique | **Discipline:** Rigid

在 SDK 核心路径上，**先写会失败的测试，再写通过测试的最小实现**。测试不是交付后补的文档，而是驱动设计的工具。

**核心原则：** 测试先行 = 接口先行。如果你想不出怎么测，通常是因为接口设计有问题——这正是 TDD 在设计阶段帮你暴露的问题。

## Red-Green-Refactor 循环

### Red：写一个会失败的测试

- 描述你期望的行为（不是实现细节）
- 运行测试，**确认它真的失败**（未失败说明测试没覆盖到目标或已有实现满足）
- 失败信息要清晰到一眼看出缺什么

### Green：写最小实现让测试通过

- 硬编码返回值也可以——目的是让红灯变绿
- 不要在这一步优化、抽象、加功能
- 运行测试，确认绿灯

### Refactor：在测试保护下重构

- 消除重复、改善命名、拆分职责
- 每次小改动后立即跑测试，确认仍然绿灯
- 不改变外部行为，只改变内部结构

**循环节奏：** 红 → 绿 → 重构，单次循环 ≤ 10 分钟。循环拉长 = 步子迈大 = 调试噩梦。

## 何时应用 TDD

### 必用（核心路径）

- **事件管道**：`EventBuilder` / `EventPersistence` / `EventSender`
- **存储层**：RDB 读写、序列化、加密/压缩
- **网络层**：请求构造、重试策略、压缩加密
- **会话管理**：session 生成、超时判定、前后台切换
- **用户标识**：userId / userKey 变更触发的 VISIT / LOGIN_USER_ATTRIBUTES 事件

### 建议用

- 工具函数（XOR 加密、XPath 生成、niceTry 包装）
- 计时器状态机（`EventTimer`）

### 不必用

- 配置类的纯字段赋值
- 文档、注释、类型声明
- ArkUI 组件的纯视觉渲染（放 e2e 覆盖）

## hypium 在本仓库的用法

### 测试文件位置

```
GrowingAnalytics/src/test/
├── core/                  # 核心模块测试（Context / DeviceInfo / EventTimer / Network / Session / UserIdentifier / GeneralProps）
├── event/                 # 事件相关
├── interfaces/            # 公开 API
├── mobileDebugger/
├── utils/
├── doubles/               # 测试替身（mock/stub）
├── helpers/               # 测试辅助（TestBuilders / JsonParser）
├── List.test.ets          # 测试注册入口
└── LocalUnit.test.ets     # 模板
```

**新增测试文件：**
1. 放在对应模块目录（例如 `core/EventSender.test.ets`）
2. 在 `List.test.ets` 中 import 并注册
3. 命名统一用 `<Module>.test.ets`

### 基础骨架

```typescript
import { describe, beforeEach, afterEach, it, expect } from '@ohos/hypium'

export default function eventSenderTest() {
  describe('EventSender', () => {
    beforeEach(() => {
      // 每个 case 前重置状态
    })
    afterEach(() => {
      // 清理副作用
    })
    it('should_batch_at_500_events', 0, () => {
      // Red → Green → Refactor
      expect(actual).assertEqual(expected)
    })
  })
}
```

### 断言 API 速查

| 断言 | 用途 |
|------|------|
| `assertEqual(v)` | 严格相等 |
| `assertTrue()` / `assertFalse()` | 布尔 |
| `assertNull()` / `assertUndefined()` | 空值 |
| `assertContain(v)` | 子串 / 子集 |
| `assertThrowError(msg)` | 异常 |
| `assertDeepEquals(v)` | 对象深比较 |

### Mock 实践

本仓库在 `src/test/doubles/` 下维护**测试替身**，`src/test/helpers/TestBuilders.ets` 提供对象构造器。

- **不要直接 mock 平台 API**：在生产代码中通过依赖注入接收接口，测试时传入 fake
- **Builder 模式**：用 `TestBuilders` 构造 Event / Config 等对象，避免每个测试重复长构造
- **隔离全局单例**：`beforeEach` 中重置 `AnalyticsCore` / `GrowingContext` 的状态

### 运行测试

```bash
# 在 DevEco Studio 中运行 GrowingAnalyticsTest（.run/GrowingAnalyticsTest.run.xml 已配置）
# 或命令行：
hvigorw test --mode module -p module=GrowingAnalytics@default -p product=default
```

核心路径变更后，在 `Step 5: 验证` 阶段必须跑一遍测试，见 engineer persona。

## SDK 测试特有考量

### 异步事件流

事件从 `track()` 调用到入库是异步链路（TaskPool）。测试时：
- 暴露一个等待钩子（如 Promise），不要用 `setTimeout` 轮询
- 或在测试环境注入同步执行器

### 生命周期钩子

`UIAbility.onForeground` / `onBackground` 无法在 hypium 单测中真实触发——通过封装一层 `LifecycleObserver` 接口，测试时直接调用观察者方法。

### Protobuf / JSON 双路径

事件有 Protobuf（NewSaaS/CDP）和 JSON（SaaS）两种序列化路径，**必须分别测**：

```typescript
it('protobuf_path_includes_eventSequenceId', ...)
it('json_path_includes_eventSequenceId', ...)
```

### 开关组合

`compressEnabled` × `encryptEnabled` 共 4 种组合，核心路径至少覆盖：
- 都关（默认最小值对比）
- 都开（生产配置）

### dataCollectionEnabled = false

任何采集路径都必须有"关闭总开关后不采集"的测试，验证隐私合规红线。

## 反模式警告

| 坏味道 | 为什么坏 |
|--------|---------|
| 先写实现再补测试 | 测试退化为"验证代码写了什么"而不是"验证行为正确" |
| 测试跑起来要 > 1 秒 | 慢测试 = 不跑 = 退化为摆设 |
| 一个 `it` 里 10 个 assert | 失败时不知道哪个断言挂了 |
| 测试依赖真实网络 / 真实文件系统 | 脆弱、慢、环境相关 |
| `it.skip` 长期存在 | 要么修，要么删 |

## Rationalizations

| Excuse | Reality |
|---|---|
| "先写实现再补测试" | 测试退化为"验证代码写了什么"，失去发现设计错误的能力 |
| "测试让它过就行，断言改宽松点" | 等于没测——下次回归改动就会悄悄破坏行为 |
| "这块改动太简单不用测试" | 简单代码的 bug 最羞耻；核心路径零例外 |
| "测试加了但没跑失败过" | 没见过 Red 的 Green 不算 Green，可能测的是空实现 |
| "单测跑真实网络/RDB 才真实" | 依赖外部 = 慢 + 脆弱 = 最后没人跑 |
| "一个 it 里多几个 assert 省事" | 失败时定位困难；拆成多个 it |
| "dataCollectionEnabled=false 的路径不用测" | 这是隐私合规红线，必须有"关了就不采集"的测试 |

## Red Flags — STOP if you catch yourself thinking these

- "让我先把实现写完，测试等会补" → 删掉实现，从 Red 开始
- "这个函数太简单了，不需要测试" → 简单代码的 bug 最羞耻，核心路径零例外
- "测试第一次就绿了" → 没见过 Red 的 Green 不可信，检查测试是否真的覆盖了目标行为
- "dataCollectionEnabled=false 的路径不重要" → 这是隐私合规红线，必须有专门测试

## 关联 skill

- **上游触发：** `writing-plans` 在"影响面自查清单"中判定本次涉及核心模块
- **调度 subagent：** 无（本 skill 由实施者执行）
- **完成后交接：** 测试通过 → 继续实施 / 交给 `verification-before-completion` 做最终验证
- **替代路径：** 非核心路径（纯配置 / 文档）→ 跳过 TDD；运行时探索性改动 → `systematic-debugging` 的四阶段先于 TDD
