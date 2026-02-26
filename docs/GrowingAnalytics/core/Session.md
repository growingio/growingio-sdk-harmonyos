# Session 会话管理逻辑详解

> **模块归属**: 核心模块 (core)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/core/Session.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 中 `Session` 模块的逻辑实现，包括会话生命周期管理、会话超时判断、前后台切换处理等。

## 目录

- [概述](#概述)
- [核心概念](#核心概念)
- [会话状态管理](#会话状态管理)
- [前后台切换处理](#前后台切换处理)
- [会话刷新机制](#会话刷新机制)
- [会话超时判断](#会话超时判断)
- [相关事件生成](#相关事件生成)
- [多 Tracker 支持](#多-tracker-支持)

---

## 概述

`Session`（会话）是 GrowingIO SDK 中用于标识用户一次连续访问的概念。会话管理模块负责：

1. **会话创建与维护**：生成唯一会话 ID，管理会话生命周期
2. **前后台切换处理**：监听应用状态变化，判断会话是否超时
3. **会话超时判断**：根据后台停留时间决定是否刷新会话
4. **相关事件生成**：VISIT 事件（会话开始）和 APP_CLOSED 事件（会话结束）

### 会话生命周期

```
应用启动 / 会话超时
        │
        ▼
┌─────────────────────┐
│   refreshSession()  │
│   生成新 Session ID │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   generateVisit()   │
│   发送 VISIT 事件   │
└────────┬────────────┘
         │
         ▼
   ┌─────────────┐
   │  会话进行中  │
   │ (Foreground) │
   └──────┬──────┘
          │
          │ 应用切后台
          ▼
   ┌─────────────┐
   │   onBackground │
   │ 记录后台时间  │
   │ 发送 APP_CLOSED │
   └──────┬──────┘
          │
          │ 应用切前台
          ▼
   ┌─────────────┐
   │   onForeground │
   │ 检查超时?     │
   └──────┬──────┘
          │
     ┌────┴────┐
     ▼         ▼
   【超时】   【未超时】
     │         │
     ▼         ▼
 refreshSession() 继续当前会话
     │
     ▼
  generateVisit()
```

---

## 核心概念

### Session 类

```typescript
export default class Session {
  sessionId: string                    // 会话唯一标识（UUID）
  trackerId: string                    // 所属 Tracker ID
  latestOnBackgroundTime: number       // 上次进入后台的时间戳
  
  static sessionState: SessionState = SessionState.Foreground  // 全局会话状态
  static sessions: Array<Session> = [] // 多 Tracker 会话列表
}
```

### 会话状态枚举

```typescript
export enum SessionState {
  Foreground,   // 前台状态
  Background    // 后台状态
}
```

### 会话配置参数

```typescript
// GrowingConfig 中的会话相关配置
class GrowingConfig {
  _sessionInterval: number = 30 * 1000  // 默认 30 秒
  
  set sessionInterval(interval: number) {
    if (interval <= 0) {
      return
    }
    this._sessionInterval = interval * 1000  // 转换为毫秒
  }
  
  get sessionInterval(): number {
    return this._sessionInterval / 1000  // 转换为秒
  }
}
```

### 会话超时判定

| 场景 | 判定条件 | 结果 |
|------|---------|------|
| 进入后台 | 记录 `latestOnBackgroundTime` | 会话可能超时 |
| 返回前台 | `当前时间 - latestOnBackgroundTime >= _sessionInterval` | 刷新会话 |
| 返回前台 | `当前时间 - latestOnBackgroundTime < _sessionInterval` | 继续原会话 |

---

## 会话状态管理

### 全局会话状态

```typescript
static sessionState: SessionState = SessionState.Foreground
```

- 全局只有一个会话状态，所有 Tracker 共享
- 用于 Autotrack 等模块判断应用当前状态
- 用于计时器的暂停/恢复

### 会话列表

```typescript
static sessions: Array<Session> = []
```

- 支持多 Tracker，每个 Tracker 有独立的 Session
- 前后台切换时，同时处理所有 Tracker 的 Session

---

## 前后台切换处理

### 进入前台处理

```typescript
static onForeground() {
  LogUtil.info(() => 'Session state set to foreground')
  
  // 1. 更新全局状态
  Session.sessionState = SessionState.Foreground
  
  // 2. 遍历所有 Tracker 的 Session
  Session.sessions.forEach(session => {
    // 首次初始化或之前就是前台状态
    if (session.latestOnBackgroundTime == 0) {
      return
    }

    let context = GrowingContext.getContext(session.trackerId)!
    
    // 3. 判断会话是否超时
    if (Date.now() - session.latestOnBackgroundTime >= context.config._sessionInterval) {
      LogUtil.info(() => 'current session is outdated, trackerId = ' + context.trackerId)
      // 会话超时，刷新 Session
      Session.refreshSession(context)
    }
    
    // 4. 重置后台时间
    session.latestOnBackgroundTime = 0
  })

  // 5. 广播前台状态变化事件
  emitter.emit(EMIT_EVENT_SESSION_STATE_FOREGROUND)
}
```

### 进入后台处理

```typescript
static onBackground() {
  LogUtil.info(() => 'Session state set to background')
  
  // 1. 更新全局状态
  Session.sessionState = SessionState.Background
  
  // 2. 遍历所有 Tracker 的 Session
  Session.sessions.forEach(session => {
    // 记录进入后台的时间
    session.latestOnBackgroundTime = Date.now()

    let context = GrowingContext.getContext(session.trackerId)!
    
    // 3. 生成 APP_CLOSED 事件
    Session.generateAppClosed(context)
  })
}
```

### 处理流程图

```
应用生命周期回调
        │
   ┌────┴────┐
   ▼         ▼
前台       后台
   │         │
   ▼         ▼
┌─────────┐ ┌─────────┐
│onForeground│ │onBackground│
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│sessionState│ │sessionState│
│=Foreground│ │=Background │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│遍历sessions│ │遍历sessions│
│检查超时  │ │记录时间   │
│刷新Session│ │发送AppClosed│
└────┬────┘ └─────────┘
     │
     ▼
┌─────────┐
│emit     │
│SESSION_ │
│STATE_   │
│FOREGROUND│
└─────────┘
```

---

## 会话刷新机制

### refreshSession()

```typescript
static refreshSession(context: GrowingContext) {
  LogUtil.info(() => 'Refresh Session for tracker = ' + context.trackerId)
  
  // 1. 查找现有 Session
  let session: Session | undefined = undefined
  for (let s of Session.sessions) {
    if (s.trackerId == context.trackerId) {
      session = s
      break
    }
  }
  
  let isRefresh: boolean = false
  
  if (session) {
    // 2a. 刷新现有 Session
    session.sessionId = util.generateRandomUUID(false)
    isRefresh = true
  } else {
    // 2b. 创建新 Session
    session = new Session(util.generateRandomUUID(false), context.trackerId)
    Session.sessions.push(session)
  }
  
  // 3. 生成 VISIT 事件
  Session.generateVisit(context)
  
  // 4. SaaS 模式：发送访客事件
  if (isRefresh && context.config.mode == ConfigMode.SaaS) {
    SaaSVisitorEvent.sendVisitorIfNeeded(context)
  }
}
```

### 刷新流程图

```
refreshSession(context)
        │
        ▼
┌─────────────────────┐
│ 查找 Tracker 对应   │
│ 的 Session          │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
【存在】    【不存在】
    │         │
    ▼         ▼
生成新      创建新
SessionID   Session
加入列表    
    │         │
    └────┬────┘
         │
         ▼
┌─────────────────────┐
│ generateVisit()     │
│ 发送 VISIT 事件     │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 是刷新且 SaaS 模式？│
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【是】    【否】
    │         │
    ▼         ▼
发送访客事件  结束
```

---

## 会话超时判断

### 超时判定逻辑

```typescript
// 进入前台时判断
if (Date.now() - session.latestOnBackgroundTime >= context.config._sessionInterval) {
  // 会话超时，需要刷新
  Session.refreshSession(context)
}
```

### 场景分析

| 场景 | latestOnBackgroundTime | 判定结果 | 说明 |
|------|----------------------|---------|------|
| 首次初始化 | `0` | 跳过检查 | 直接返回，不判断超时 |
| 正常前台切后台再切前台 | 有值 | 判断是否超时 | 根据间隔决定 |
| 快速切换（< 30s） | 有值 | 不超時 | 继续原会话 |
| 长时间后台（>= 30s） | 有值 | 超时 | 生成新会话 |

### 超时时间配置

```typescript
let config = new GrowingConfig()
config.sessionInterval = 30  // 设置 30 秒（实际存储为 30000 毫秒）
```

**默认配置**:
- 默认值：30 秒
- 最小值：1 秒
- 存储单位：毫秒（内部）
- 显示单位：秒（API）

---

## 相关事件生成

### VISIT 事件（会话开始）

```typescript
static generateVisit(context: GrowingContext) {
  if (!context.config.dataCollectionEnabled) {
    LogUtil.info(() => 'Failed to generate visit, dataCollectionEnabled is false')
    return
  }
  
  LogUtil.info(() => 'Generate visit for tracker = ' + context.trackerId)
  
  // 创建 VISIT 事件
  let e = VisitEvent.create(context)
  AnalyticsCore.writeEventToDisk(e, context)

  // SaaS 模式：发送假页面事件（兼容旧版）
  if (context.config.mode == ConfigMode.SaaS) {
    FakePageEvent.sendFakePageIfNeeded(context)
  }
}
```

**触发时机**:
1. SDK 初始化时
2. 会话超时时
3. 手动调用 `setDataCollectionEnabled(true)` 时（CDP 模式生成 VISIT）

### APP_CLOSED 事件（会话结束）

```typescript
static generateAppClosed(context: GrowingContext) {
  if (!context.config.dataCollectionEnabled) {
    return
  }
  
  // 创建 APP_CLOSED 事件
  let e = AppClosedEvent.create(context)
  AnalyticsCore.writeEventToDisk(e, context)
}
```

**触发时机**:
- 应用进入后台时
- 包含本次会话的时长信息

---

## 多 Tracker 支持

### 会话隔离

每个 Tracker 拥有独立的 Session：

```typescript
// Tracker A
GrowingAnalytics.start(context, configA)  // Session A

// Tracker B
GrowingAnalytics.startSubTracker('trackerB', configB)  // Session B

// 两个 Session 互相独立
// 各自有自己的 sessionId、latestOnBackgroundTime
```

### 状态共享

全局会话状态 `sessionState` 所有 Tracker 共享：

```typescript
// 所有 Tracker 共享同一个 SessionState
Session.sessionState = SessionState.Foreground  // 或 Background
```

这意味着：
- 应用切后台时，所有 Tracker 同时生成 APP_CLOSED
- 应用切前台时，每个 Tracker 独立判断是否会话超时
- 超时的 Tracker 刷新 Session，未超时的保持原 Session

### 多 Tracker 场景示例

```
Tracker A                    Tracker B
   │                            │
   │ 应用切后台                  │ 应用切后台
   ▼                            ▼
记录时间戳                      记录时间戳
生成 APP_CLOSED                生成 APP_CLOSED
   │                            │
   │ 应用切前台（40秒后）         │ 应用切前台（40秒后）
   ▼                            ▼
检查: 40s >= 30s              检查: 40s >= 30s
结果: 超时                    结果: 超时
   │                            │
   ▼                            ▼
刷新 Session A                刷新 Session B
生成 VISIT A                  生成 VISIT B
```

---

## 总结

Session 模块是 GrowingIO SDK 中管理用户会话的核心组件，其设计特点包括：

1. **全局状态管理**：全局共享 `sessionState`，统一应用前后台状态
2. **多 Tracker 支持**：每个 Tracker 拥有独立的 Session 实例
3. **超时判断**：基于后台停留时间判断是否刷新会话（默认 30 秒）
4. **事件驱动**：会话刷新自动生成 VISIT，进入后台自动生成 APP_CLOSED
5. **状态广播**：通过 emitter 通知其他模块状态变化

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
