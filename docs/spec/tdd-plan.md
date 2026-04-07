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

### Step 1 · 测试基础设施搭建 ✅

**目标**：配置测试依赖、规范目录结构、更新测试套件入口。

- [x] `GrowingAnalytics/oh-package.json5` 添加 `@ohos/hypium` 和 `@ohos/hamock` devDependencies
- [x] 重建 `GrowingAnalytics/src/test/` 目录结构：
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
- [x] 更新 `LocalUnit.test.ets` 汇总入口，导入所有子套件
- **Commit**：`test: setup test directory structure and add hypium dependency`

---

### Step 2 · Phase 1：Util.ts 纯函数测试 ✅

**目标**：覆盖 `Util.ts` 所有公开方法，建立首批真实业务断言。

测试文件：`test/utils/UtilTest.ets`

覆盖方法：

- [x] `serializableAttributes` — 数组 `||` 拼接、空对象返回 undefined、混合类型转 string
- [x] `getHintFromTime` — 时间戳末字节提取
- [x] `encrypt` — XOR 自反性验证（加密两次还原原文）
- [x] `validateEventSize` — 正常通过 / 超 1.8MB 返回 error attributes
- [x] `concatObject` — 后者覆盖前者同名字段
- [x] `mapToObject` — Map 正确转为普通对象
- [x] `removeKeysForObject` — 指定 key 被删除，其余保留
- [x] `sizeOfEventString` — ASCII 字节数、中文 UTF-8 字节数、空串
- [x] `toSerializeByMeasurementProtocolV2` — CUSTOM/PAGE/VISIT/APP_CLOSED 字段映射、网络状态枚举映射
- [x] `toSerializeByMeasurementProtocolV3` — 不含 `timezoneOffset`、不含 `xcontent`

测试文件：`test/utils/NiceTryTest.ets`

- [x] `niceTry` — 正常执行 / 异常返回 undefined / 异常返回 fallback
- [x] `niceTryAsync` — 异步正常执行 / 异步异常返回 fallback

- **Commit**：`test: add Phase 1 pure function tests for Util.ts`

---

### Step 3 · Phase 1：GrowingConfig 校验逻辑测试 ✅

**目标**：覆盖配置类的三种模式工厂方法、setter/getter 边界值、bitmask 逻辑。

测试文件：`test/interfaces/GrowingConfigTest.ets`

- [x] `NewSaaS()` — 正确设置 mode / accountId / dataSourceId / useProtobuf
- [x] `SaaS()` — mode=SaaS / 默认 serverHost
- [x] `CDP()` — mode=CDP / 必填字段
- [x] `sessionInterval` setter — 正数转毫秒存储 / 非正数被忽略（保持默认值）
- [x] `dataUploadInterval` setter/getter — 秒↔毫秒转换
- [x] `dataValidityPeriod` setter — 范围限制（3-30 天）
- [x] `IgnoreFields` bitmask — 单字段位独立、`IgnoreFieldsAll` 包含所有位
- [x] `copy()` 验证逻辑 — 必填字段缺失时抛出错误

- **Commit**：`test: add Phase 1 GrowingConfig validation tests`

---

### Step 4 · 静态单例可重置改造 ✅

**目标**：为所有静态状态类添加 `_reset()` 方法，确保测试用例间状态隔离。

改造文件：

- [x] `core/Session.ets` — `static _reset(): void`（清空 sessions 数组、重置 sessionState）
- [x] `core/EventTimer.ets` — `static _reset(): void`（清空 timers Map）
- [x] `core/UserIdentifier.ets` — `static _reset(): void`（清空 users Map）
- [x] `event/EventBuilder.ets` — `static _reset(): void`（清空 _eventSequenceIds）

**约定**：
- 方法名以 `_` 开头，标记为仅供测试使用
- `consumer-rules.txt` 保留 `_reset` 符号名（防止混淆后测试无法调用）
- 不在任何生产代码路径中调用

- **Commit**：`refactor: add _reset() to static singleton classes for test isolation`

---

### Step 5 · Phase 2：EventTimer 状态机测试 ✅

**目标**：覆盖计时器的完整状态机：start → pause → resume → end。

测试文件：`test/core/EventTimerTest.ets`

- [x] `durationFrom` — 正常时间段 / startTime=0 返回 0 / 超 24h 返回 0 / endTime < startTime 返回 0
- [x] `isPaused` — startTime=0 时为 true / startTime>0 时为 false
- [x] `trackTimerPause` — 正常 pause 后 startTime 归零 / 对已 pause 的 timer 无副作用
- [x] `trackTimerResume` — 对运行中的 timer 无副作用 / 不存在 id 静默忽略
- [x] `removeTimer` — 从 Map 删除
- [x] `clearTrackTimer` — 只删除指定 trackerId 的计时器，不影响其他 tracker
- [x] `handleAllTimersPause` — 已 paused 的不受影响
- [x] `handleAllTimersResume` — paused 计时器 startTime 不被修改
- 每个用例 `beforeEach` 调用 `EventTimer._reset()`

- **Commit**：`test: add Phase 2 EventTimer state machine tests`

---

### Step 6 · Phase 2：Session 核心决策逻辑测试 ✅

**目标**：覆盖 session 超时判断、sessionId 查找规则（不测 emitter 副作用）。

测试文件：`test/core/SessionTest.ets`

- [x] sessionInterval 超时判断纯逻辑（直接验证数学条件）
- [x] `getSessionId` — 存在时返回正确 sessionId / 不存在时返回 undefined
- [x] 多 tracker 共存时各自隔离
- [x] `sessionState` 状态标志读写
- [x] sessions 数组管理（push / latestOnBackgroundTime 更新）
- [x] `_reset()` 保证跨用例状态隔离
- 每个用例 `beforeEach` 调用 `Session._reset()`

- **Commit**：`test: add Phase 2 Session core decision logic tests`

---

### Step 7 · IO 层接口提取 + 测试替身 ✅

**目标**：为平台 IO 层提取接口，创建可在本地单元测试中使用的内存实现。

**接口文件**（新建）：

- [x] `interfaces/IStorage.ets` — `put(key, value)` / `getValue(key, defValue)`
- [x] `interfaces/IEventStore.ets` — `getEventsByCount` / `removeEvents` / `countOfEvents`
- [x] `interfaces/INetwork.ets` — `request(events, urlPath, context)` → `Promise<rcp.Response>`

**生产实现适配**（接口预留，下阶段重构时对接）：

- [ ] `SharedPreferences` implement `IStorage`
- [ ] `EventDatabase` implement `IEventStore`
- [ ] `Network` implement `INetwork`

**测试替身**（新建，放在 `test/doubles/`）：

- [x] `InMemoryStorage.ets` — 基于 Map 的 IStorage 实现，带 `clear()` / `snapshot()` 方法
- [x] `InMemoryEventStore.ets` — 基于数组的 IEventStore 实现，支持类型过滤/大小限制/账号隔离
- [x] `FakeNetwork.ets` — 预设响应队列 + 请求记录，带 `enqueueSuccess/enqueueClientError/enqueueServerError/reset()` 方法

**工厂方法**（新建 `test/helpers/TestBuilders.ets`）：

- [x] `buildFakeContext(mode, overrides?)` — 返回最小 GrowingContext 替身
- [x] `makeFakePersistence(uuid, eventType?, accountId?, dataSourceId?)` — 返回 EventPersistence 实例

- **Commit**：`refactor: extract IO layer interfaces and add in-memory test doubles`

---

### Step 8 · Phase 3：EventPersistence 测试 ✅

**目标**：覆盖 `fromDatabase` 字段保留、大事件降级逻辑、序列化格式验证。

测试文件：`test/event/EventPersistenceTest.ets`

- [x] `fromDatabase` — 6 个字段全部正确保留
- [x] 大事件降级 — 通过 `Util.validateEventSize` 验证：正常事件通过 / 超 1.8MB 携带 `growing_error_msg`
- [x] NewSaaS 序列化（V3）— 合法 JSON / 过滤 timezoneOffset
- [x] SaaS 序列化（V2）— CUSTOM t=cstm / VISIT t=vst
- [x] uuid 唯一性约定 — fromDatabase 不生成新 uuid

- **Commit**：`test: add Phase 3 EventPersistence serialization tests`

---

### Step 9 · Phase 3：EventSender 调度逻辑测试 ✅

**目标**：用 `FakeNetwork` + `InMemoryEventStore` 覆盖上报调度的核心分支。

测试文件：`test/event/EventSenderTest.ets`

- [x] 数据库无事件 → getEventsByCount 返回空数组
- [x] 网络 200 成功 → 事件从 store 删除
- [x] 网络 4xx 失败 → 事件保留在 store（不可重试）
- [x] 网络异常（throw）→ 事件保留在 store
- [x] `SaaS_PV` 类型过滤 → 只处理 VISIT/PAGE/APP_CLOSED，CUSTOM 留在库中
- [x] `SaaS_CSTM` 类型过滤 → 只处理 CUSTOM/LOGIN_USER_ATTRIBUTES，PAGE 留在库中
- [x] 分批发送 → 超过 maxCount 后 store 中剩余事件可继续取出
- [x] accountId 隔离 → 不同账号事件互不干扰
- [x] FakeNetwork 行为验证（响应预设、请求记录、shouldThrow、reset）

- **Commit**：`test: add Phase 3 EventSender dispatch logic tests`

---

### Step 10 · Phase 4：Network URL/Header 生成测试 ✅

**目标**：覆盖 `Network.generateUrl` 和 `Network.generateHeaders` 的纯计算逻辑（不涉及真实 RCP）。

测试文件：`test/core/NetworkTest.ets`

- [x] `generateUrl` NewSaaS — URL 包含 accountId，`/v3/projects/{accountId}/collect` 模板正确替换
- [x] `generateUrl` SaaS PV — `/v3/{accountId}/harmonyos/pv` 模板正确替换
- [x] `generateUrl` SaaS CSTM — `/v3/{accountId}/harmonyos/cstm` 模板正确替换
- [x] `generateUrl` 包含 `stm` 时间戳参数
- [x] `generateUrl` serverHost 末尾斜杠自动去除
- [x] `generateHeaders` useProtobuf=true → Content-Type 为 `application/protobuf`
- [x] `generateHeaders` useProtobuf=false → Content-Type 为 `application/json`
- [x] `generateHeaders` Accept 始终为 `application/json`
- [x] `generateHeaders` X-Timestamp 包含时间戳值
- [x] `generateHeaders` encryptEnabled=true → 包含 `X-Crypt-Codec: 1`
- [x] `generateHeaders` compressEnabled=true → 包含 `X-Compress-Codec: 2`
- [x] 同时启用/禁用加密压缩的组合场景

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
