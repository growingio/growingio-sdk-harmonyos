# TDD 落地方案 · 进度追踪

> 分支：`test/tdd-infrastructure`（基于 master）
> 创建时间：2026-04-07
> 目标：为 GrowingAnalytics 核心模块建立可靠的分层自动化测试体系

---

## 现状诊断

| 问题 | 描述 |
|------|------|
| 零覆盖 | 三个模块的测试文件全是 DevEco 生成的空壳，无任何业务断言 |
| 静态单例污染 | `Session.sessions`、`EventTimer.timers`、`UserIdentifier.users` 等静态状态跨用例泄漏 |
| 无接口抽象 | `Network`（RCP）、`EventDatabase`（RDB）、`SharedPreferences` 直接依赖平台 API，无法 Mock |
| 依赖注入缺失 | `EventBuilder.build()` 内部硬调 6 个单例，无法独立测试字段填充逻辑 |

---

## 测试分层策略

```
Layer 4 · 平台运行时层   → AutotrackClick / AutotrackPage
                           设备集成测试 + 手工回归（TDD ROI 极低，不在本方案范围）

Layer 3 · 平台 IO 层    → Network / EventDatabase / SharedPreferences
                           契约测试，需要接口替换平台 API（Phase 4）

Layer 2 · 有状态业务层  → Session / EventTimer / EventBuilder / EventSender / EventPersistence
                           TDD 为主，需 _reset() + 接口注入（Phase 2-3）

Layer 1 · 纯函数层      → Util.ts / GrowingConfig 校验逻辑
                           100% TDD，零平台依赖，立即可写（Phase 1）
```

---

## 实施步骤

每个步骤对应一个 git commit，完成后打勾。

### Step 0 · 创建规范文档 ✅

- [x] 创建 `docs/spec/tdd-plan.md`（本文件）
- **Commit**：`docs: add TDD landing plan spec for GrowingAnalytics`

---

### Step 1 · 测试基础设施搭建

**目标**：配置测试依赖、规范目录结构、更新测试套件入口。

- [ ] `GrowingAnalytics/oh-package.json5` 添加 `@ohos/hypium` 和 `@ohos/hamock` devDependencies
- [ ] 重建 `GrowingAnalytics/src/test/` 目录结构：
  ```
  test/
  ├── doubles/          ← 测试替身（内存实现）
  ├── helpers/          ← 工厂方法（buildFakeContext 等）
  ├── utils/            ← Util.ts 相关测试
  ├── interfaces/       ← GrowingConfig 相关测试
  ├── core/             ← Session / EventTimer / Network 相关测试
  ├── event/            ← EventPersistence / EventSender 相关测试
  ├── LocalUnit.test.ets
  └── List.test.ets
  ```
- [ ] 更新 `LocalUnit.test.ets` 汇总入口，导入所有子套件
- **Commit**：`test: setup test directory structure and add hypium dependency`

---

### Step 2 · Phase 1：Util.ts 纯函数测试

**目标**：覆盖 `Util.ts` 所有公开方法，建立首批真实业务断言。

测试文件：`test/utils/UtilTest.ets`

覆盖方法：

- [ ] `serializableAttributes` — 数组 `||` 拼接、空对象返回 undefined、混合类型转 string
- [ ] `getHintFromTime` — 时间戳末字节提取
- [ ] `encrypt` — XOR 自反性验证（加密两次还原原文）
- [ ] `validateEventSize` — 正常通过 / 超 1.8MB 返回 error attributes
- [ ] `concatObject` — 后者覆盖前者同名字段
- [ ] `mapToObject` — Map 正确转为普通对象
- [ ] `removeKeysForObject` — 指定 key 被删除，其余保留
- [ ] `sizeOfEventString` — ASCII 字节数、中文 UTF-8 字节数、空串
- [ ] `toSerializeByMeasurementProtocolV2` — CUSTOM/PAGE/VISIT/VIEW_CLICK 字段映射、网络状态枚举映射
- [ ] `toSerializeByMeasurementProtocolV3` — 不含 `timezoneOffset`、不含 `xcontent`

测试文件：`test/utils/NiceTryTest.ets`

- [ ] `niceTry` — 正常执行 / 异常返回 undefined / 异常返回 fallback
- [ ] `niceTryAsync` — 异步正常执行 / 异步异常返回 fallback

- **Commit**：`test: add Phase 1 pure function tests for Util.ts`

---

### Step 3 · Phase 1：GrowingConfig 校验逻辑测试

**目标**：覆盖配置类的三种模式工厂方法、setter/getter 边界值、bitmask 逻辑。

测试文件：`test/interfaces/GrowingConfigTest.ets`

- [ ] `NewSaaS()` — 正确设置 mode / accountId / dataSourceId / useProtobuf=true
- [ ] `SaaS()` — mode=SaaS / useProtobuf 强制 false（SaaS 无 Protobuf 支持）
- [ ] `CDP()` — mode=CDP / 必填字段
- [ ] `sessionInterval` setter — 正数转毫秒存储 / 非正数被忽略（保持默认值）
- [ ] `dataUploadInterval` setter/getter — 秒↔毫秒转换
- [ ] `dataValidityPeriod` setter — 范围限制（3-30 天）
- [ ] `IgnoreFields` bitmask — 单字段位独立、`IgnoreFieldsAll` 包含所有位
- [ ] `copy()` 验证逻辑 — 必填字段缺失时抛出错误

- **Commit**：`test: add Phase 1 GrowingConfig validation tests`

---

### Step 4 · 静态单例可重置改造

**目标**：为所有静态状态类添加 `_reset()` 方法，确保测试用例间状态隔离。

改造文件：

- [ ] `core/Session.ets` — `static _reset(): void`（清空 sessions 数组、重置 sessionState）
- [ ] `core/EventTimer.ets` — `static _reset(): void`（清空 timers Map）
- [ ] `core/UserIdentifier.ets` — `static _reset(): void`（清空 users Map）
- [ ] `event/EventBuilder.ets` — `static _reset(): void`（清空 _eventSequenceIds）

**约定**：
- 方法名以 `_` 开头，标记为仅供测试使用
- `consumer-rules.txt` 保留 `_reset` 符号名（防止混淆后测试无法调用）
- 不在任何生产代码路径中调用

- **Commit**：`refactor: add _reset() to static singleton classes for test isolation`

---

### Step 5 · Phase 2：EventTimer 状态机测试

**目标**：覆盖计时器的完整状态机：start → pause → resume → end。

测试文件：`test/core/EventTimerTest.ets`

- [ ] `durationFrom` — 正常时间段 / startTime=0 返回 0 / 超 24h 返回 0 / endTime < startTime 返回 0
- [ ] `isPaused` — startTime=0 时为 true / startTime>0 时为 false
- [ ] `trackTimerPause` — 正常 pause 后 startTime 归零 / 对已 pause 的 timer 无副作用
- [ ] `trackTimerResume` — 恢复 startTime / 对运行中的 timer 无副作用
- [ ] `removeTimer` — 从 Map 删除
- [ ] `clearTrackTimer` — 只删除指定 trackerId 的计时器，不影响其他 tracker
- [ ] `handleAllTimersPause` — 非 paused 计时器停止 / 已 paused 的不受影响
- [ ] `handleAllTimersResume` — paused 计时器恢复 / 运行中的不受影响
- 每个用例 `beforeEach` 调用 `EventTimer._reset()`

- **Commit**：`test: add Phase 2 EventTimer state machine tests`

---

### Step 6 · Phase 2：Session 核心决策逻辑测试

**目标**：覆盖 session 超时判断、sessionId 更新规则（不测 emitter 副作用）。

测试文件：`test/core/SessionTest.ets`

- [ ] sessionInterval 超时判断纯逻辑（提取为独立函数后测试）
- [ ] `getSessionId` — 存在时返回正确 sessionId / 不存在时返回 undefined
- [ ] `refreshSession` — 已有 session 时更新 sessionId / 不存在时新增 session
- [ ] `onBackground` — latestOnBackgroundTime 被正确记录
- [ ] `onForeground` — 未超时时 sessionId 不变 / 超时后 sessionId 更新
- 每个用例 `beforeEach` 调用 `Session._reset()`

- **Commit**：`test: add Phase 2 Session core decision logic tests`

---

### Step 7 · IO 层接口提取 + 测试替身

**目标**：为平台 IO 层提取接口，创建可在本地单元测试中使用的内存实现。

**接口文件**（新建）：

- [ ] `interfaces/IStorage.ets` — `put(key, value)` / `getValue(key, defValue)`
- [ ] `interfaces/IEventStore.ets` — `insertEvent` / `getEventsByCount` / `removeEvents` / `countOfEvents`
- [ ] `interfaces/INetwork.ets` — `request(events, urlPath, context)` → `Promise<NetworkResponse>`

**生产实现适配**（实现接口）：

- [ ] `SharedPreferences` implement `IStorage`
- [ ] `EventDatabase` implement `IEventStore`
- [ ] `Network` implement `INetwork`

**测试替身**（新建，放在 `test/doubles/`）：

- [ ] `InMemoryStorage.ets` — 基于 Map 的 IStorage 实现，带 `clear()` 方法
- [ ] `InMemoryEventStore.ets` — 基于数组的 IEventStore 实现，带 `clear()` 方法
- [ ] `FakeNetwork.ets` — 预设响应队列 + 请求记录数组，带 `reset()` 方法

**工厂方法**（新建 `test/helpers/TestBuilders.ets`）：

- [ ] `buildFakeContext(mode, overrides?)` — 返回最小 GrowingContext 替身
- [ ] `makeFakePersistence(uuid, eventType?)` — 返回 EventPersistence 实例

- **Commit**：`refactor: extract IO layer interfaces and add in-memory test doubles`

---

### Step 8 · Phase 3：EventPersistence 测试

**目标**：覆盖 `fromEvent` 的字段映射和超大事件降级逻辑。

测试文件：`test/event/EventPersistenceTest.ets`

- [ ] `fromDatabase` — 6 个字段全部正确保留
- [ ] `fromEvent` 正常事件 — uuid 非空、data 包含事件名、eventType 正确、accountId 正确
- [ ] `fromEvent` 超 1.8MB 事件 — data 中 attributes 被替换为 `growing_error_msg`
- [ ] `fromEvent` NewSaaS 模式 — data 为 JSON 格式
- [ ] `fromEvent` SaaS 模式 — data 为 Measurement Protocol V2 格式

- **Commit**：`test: add Phase 3 EventPersistence serialization tests`

---

### Step 9 · Phase 3：EventSender 调度逻辑测试

**目标**：用 `FakeNetwork` + `InMemoryEventStore` 覆盖上报调度的核心分支。

测试文件：`test/event/EventSenderTest.ets`

- [ ] 数据库无事件 → 不发起网络请求
- [ ] 网络 200 成功 → 事件从 store 删除
- [ ] 网络 4xx 失败 → 事件保留在 store（不可重试）
- [ ] 网络 5xx 失败 → 事件保留在 store
- [ ] `isUploading=true` 时并发调用 → 只发出一次网络请求
- [ ] `SaaS_PV` sender → 只处理 VISIT/PAGE/APP_CLOSED，CUSTOM 留在库中
- [ ] `SaaS_CSTM` sender → 只处理 CUSTOM/LOGIN_USER_ATTRIBUTES 等，PAGE 留在库中
- [ ] 剩余事件超过 500 条 → 自动继续下一批

- **Commit**：`test: add Phase 3 EventSender dispatch logic tests`

---

### Step 10 · Phase 4：Network URL/Header 生成测试

**目标**：覆盖 `Network.generateUrl` 和 `Network.generateHeaders` 的纯计算逻辑（不涉及真实 RCP）。

测试文件：`test/core/NetworkTest.ets`

- [ ] `generateUrl` NewSaaS — URL 包含 accountId，`/v3/projects/{accountId}/collect` 模板正确替换
- [ ] `generateUrl` SaaS PV — `/v3/{accountId}/harmonyos/pv` 模板正确替换
- [ ] `generateUrl` 包含 `stm` 时间戳参数
- [ ] `generateHeaders` useProtobuf=true → Content-Type 为 `application/protobuf`
- [ ] `generateHeaders` useProtobuf=false → Content-Type 为 `application/json`
- [ ] `generateHeaders` encryptEnabled=true → 包含加密相关 Header
- [ ] `generateHeaders` compressEnabled=true → 包含压缩相关 Header

- **Commit**：`test: add Phase 4 Network URL and header generation tests`

---

## 覆盖率目标

| 阶段 | 模块 | 目标覆盖率 |
|------|------|-----------|
| Phase 1 | `Util.ts`、`GrowingConfig` | **100%** |
| Phase 2 | `EventTimer`、`Session`（核心逻辑） | **90%+** |
| Phase 3 | `EventPersistence`、`EventSender` | **85%+** |
| Phase 4 | `Network`（URL/Header 生成） | **80%+** |
| **整体** | GrowingAnalytics 核心模块 | **≥ 75%** |

---

## 编写原则

1. **每个 `it()` 只断言一件事**，用例名格式：`[场景] - [预期结果]`
2. **`beforeEach` 必须重置所有静态状态**（调用各模块的 `_reset()`）
3. **不 Mock 被测系统内部**，只 Mock 边界依赖（IO 层）
4. **测试替身放在 `test/doubles/`**，不进生产 HAR 包（byteCodeHar 不打包 test 目录）

---

## 不在本方案范围内

- `AutotrackClick` / `AutotrackPage`（强依赖 UIObserver + FrameNode ArkUI 运行时）
- `EventDatabase` RDB 集成测试（需要真实设备，放在 `ohosTest/`）
- `Circle` / `MobileDebugger` 模块（WebSocket 依赖，另起专项）
