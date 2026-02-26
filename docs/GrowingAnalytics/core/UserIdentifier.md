# UserIdentifier 用户标识逻辑详解

> **模块归属**: 核心模块 (core)  
> **源文件**: `GrowingAnalytics/src/main/ets/components/core/UserIdentifier.ets`  

本文档详细描述 GrowingIO HarmonyOS SDK 的用户标识管理逻辑，包括设备 ID 生成、登录用户绑定、ID Mapping 机制等。

## 目录

- [概述](#概述)
- [核心概念](#核心概念)
- [设备 ID (deviceId)](#设备-id-deviceid)
- [登录用户管理](#登录用户管理)
- [ID Mapping 机制](#id-mapping-机制)
- [多 Tracker 支持](#多-tracker-支持)
- [用户切换与会话刷新](#用户切换与会话刷新)

---

## 概述

`UserIdentifier` 模块负责管理 SDK 的用户标识体系，包括：

1. **设备 ID (deviceId)**: 唯一标识设备的 UUID，持久化存储
2. **登录用户 ID (userId)**: 标识登录用户，支持动态设置/清除
3. **用户 Key (userKey)**: ID Mapping 场景下用于关联多平台用户

### 用户标识体系

```
┌─────────────────────────────────────────────────────────────┐
│                      用户标识体系                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  设备标识 (自动)              登录标识 (手动)                │
│  ┌──────────────┐            ┌──────────────┐               │
│  │   deviceId   │            │    userId    │               │
│  │  (UUID生成)  │◀───────────│  (业务传入)  │               │
│  │   持久存储   │            │   持久存储   │               │
│  └──────────────┘            └──────────────┘               │
│                                       │                     │
│                                       │ ID Mapping          │
│                                       ▼                     │
│                              ┌──────────────┐               │
│                              │   userKey    │               │
│                              │  (关联标识)  │               │
│                              └──────────────┘               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 核心概念

### UserIdentifier 类

```typescript
class UserIdentifier {
  userId: string                    // 登录用户 ID
  userKey: string                   // 用户 Key（ID Mapping）
  private latestNonnullUserId: string  // 最新的非空用户 ID
  
  static users: Map<string, UserIdentifier> = new Map()  // 多 Tracker 用户映射
  static userInfo: object                                 // 用户信息缓存
}
```

### 持久化存储

用户标识使用 `SharedPreferences` 进行持久化存储：

| Key | 说明 |
|-----|------|
| `growing_user_identifier` | 用户信息 JSON 字符串 |
| `growing_user_id` | 用户 ID（主 Tracker）|
| `growing_user_key` | 用户 Key（主 Tracker）|
| `growing_user_id_{accountId}_{dataSourceId}` | 用户 ID（子 Tracker）|
| `growing_user_key_{accountId}_{dataSourceId}` | 用户 Key（子 Tracker）|

---

## 设备 ID (deviceId)

### 生成逻辑

设备 ID 在 `DeviceInfo.initDeviceInfo()` 中生成：

```typescript
let deviceId = SharedPreferences.getValue(PREFERENCE_DEVICE_ID) as string
if (deviceId == '') {
  // 首次使用，生成新的 UUID
deviceId = util.generateRandomUUID(false)
  SharedPreferences.put(PREFERENCE_DEVICE_ID, deviceId)
}
DeviceInfo.deviceId = deviceId
```

### 特点

- **生成方式**: 使用 `util.generateRandomUUID(false)` 生成 UUID
- **持久化**: 存储在 `SharedPreferences` 中，应用卸载后重新生成
- **作用范围**: 每个设备唯一，用于匿名用户识别
- **不可清除**: 除非应用卸载或清除数据，否则保持不变

---

## 登录用户管理

### 初始化用户

```typescript
static initUser(context: GrowingContext) {
  // 1. 从持久化存储读取用户信息
  let userInfoString = SharedPreferences.getValue(PREFERENCE_USER_IDENTIFIER, '{}') as string
  let userInfo = JSON.parse(userInfoString) as object
  UserIdentifier.userInfo = userInfo

  // 2. 读取 userId 和 userKey
  let userId = (userInfo[PREFERENCE_USER_ID] as string | undefined) ?? ''
  let userKey = (userInfo[PREFERENCE_USER_KEY] as string | undefined) ?? ''
  
  // 3. 创建 UserIdentifier 实例
  let user = new UserIdentifier(userId, userKey)
  UserIdentifier.users.set(context.trackerId, user)

  // 4. 记录日志
  let message = 'UserId from preferences is ' + userId
  if (context.config.mode == ConfigMode.NewSaaS || context.config.mode == ConfigMode.CDP) {
    if (context.config.idMappingEnabled == true) {
      message += ', userKey from preferences is ' + userKey
    }
  }
  LogUtil.info(() => message)
}
```

### 设置登录用户

```typescript
static setLoginUserId(userId: string, userKey: string = '', context: GrowingContext) {
  // 1. 如果未开启 ID Mapping，忽略 userKey
  if (context.config.idMappingEnabled == false) {
    userKey = ''
  }

  // 2. 长度限制（最大 1000 字符）
  if (userId && userId.length > 1000) {
    return
  }
  if (userKey && userKey.length > 1000) {
    return
  }

  let user = UserIdentifier.users.get(context.trackerId)
  if (user) {
    // 3. 清除用户
    if (userId == null || userId.length == 0) {
      LogUtil.info(() => 'Clear loginUserId')
      user.userId = ''
      user.userKey = ''
      user.saveToPreferences(context)
      return
    }

    // 4. 无变化则直接返回
    if (userId === user.userId && userKey === user.userKey) {
      return
    }

    // 5. 记录用户变化日志
    let message = 'LoginUserId for ' + context.trackerId + ' did changed...'
    LogUtil.info(() => message)

    // 6. 更新用户信息
    user.userId = userId
    user.userKey = userKey
    user.saveToPreferences(context)
    
    // 7. 触发用户变化回调
    user.userIdDidChanged(userId, context)
  }
}
```

### 持久化存储

```typescript
saveToPreferences(context: GrowingContext) {
  let userInfo = UserIdentifier.userInfo
  
  if (GrowingContext.isDefaultContext(context)) {
    // 主 Tracker
    userInfo[PREFERENCE_USER_ID] = String(this.userId)
    userInfo[PREFERENCE_USER_KEY] = String(this.userKey)
  } else {
    // 子 Tracker：使用 accountId + dataSourceId 作为后缀区分
    let suffix = '_' + context.config.accountId + '_' + context.config.dataSourceId
    userInfo[PREFERENCE_USER_ID + suffix] = String(this.userId)
    userInfo[PREFERENCE_USER_KEY + suffix] = String(this.userKey)
  }
  
  SharedPreferences.put(PREFERENCE_USER_IDENTIFIER, JSON.stringify(userInfo))
}
```

---

## ID Mapping 机制

### 什么是 ID Mapping

ID Mapping 是 GrowingIO 提供的一种跨平台用户关联机制，允许将不同平台、不同设备的用户标识关联到同一个用户上。

### 启用 ID Mapping

```typescript
let config = new GrowingConfig()
  .NewSaaS('accountId', 'dataSourceId', 'urlScheme')
config.idMappingEnabled = true  // 启用 ID Mapping
```

### ID Mapping 工作原理

```
┌─────────────────────────────────────────────────────────────────┐
│                      ID Mapping 关联                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  平台 A (手机 App)              平台 B (Web)                     │
│  ┌──────────────┐              ┌──────────────┐                 │
│  │  deviceId-A  │              │  deviceId-B  │                 │
│  │     +        │              │     +        │                 │
│  │  userId-X    │◀────────────▶│  userId-X    │                 │
│  │     +        │              │     +        │                 │
│  │  userKey-P   │              │  userKey-Q   │                 │
│  └──────────────┘              └──────────────┘                 │
│         │                             │                         │
│         └─────────────┬───────────────┘                         │
│                       │                                         │
│                       ▼                                         │
│              ┌────────────────┐                                 │
│              │  GrowingIO 平台 │                                 │
│              │  关联为同一用户  │                                 │
│              └────────────────┘                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### userKey 的作用

- 用于区分同一 userId 在不同平台的身份
- 例如：`userKey = "app"` 表示手机端，`userKey = "web"` 表示 Web 端
- 服务端根据 userId + userKey 进行用户关联

---

## 多 Tracker 支持

### 子 Tracker 用户初始化

```typescript
static initMultiUser(context: GrowingContext) {
  let userInfo = UserIdentifier.userInfo

  // 使用 accountId + dataSourceId 作为后缀
  let suffix = '_' + context.config.accountId + '_' + context.config.dataSourceId
  let userId = (userInfo[PREFERENCE_USER_ID + suffix] as string | undefined) ?? ''
  let userKey = (userInfo[PREFERENCE_USER_KEY + suffix] as string | undefined) ?? ''
  
  let user = new UserIdentifier(userId, userKey)
  UserIdentifier.users.set(context.trackerId, user)

  // 记录日志
  let message = 'UserId for ' + context.trackerId + ' from preferences is ' + userId
  if (context.config.mode == ConfigMode.NewSaaS || context.config.mode == ConfigMode.CDP) {
    if (context.config.idMappingEnabled == true) {
      message += ', userKey from preferences is ' + userKey
    }
  }
  LogUtil.info(() => message)
}
```

### 用户隔离

每个 Tracker 拥有独立的用户标识：

```typescript
// Tracker A (项目 A)
GrowingAnalytics.start(context, configA)
// users['__GrowingAnalyticsCore'] = { userId: 'userA', userKey: '' }

// Tracker B (项目 B)
GrowingAnalytics.startSubTracker('trackerB', configB)
// users['trackerB'] = { userId: 'userB', userKey: '' }
```

### 存储 Key 规则

| 类型 | Key 格式 |
|------|---------|
| 主 Tracker | `growing_user_id` / `growing_user_key` |
| 子 Tracker | `growing_user_id_{accountId}_{dataSourceId}` / `growing_user_key_{accountId}_{dataSourceId}` |

---

## 用户切换与会话刷新

### 用户变化回调

当登录用户发生变化时，触发会话刷新逻辑：

```typescript
userIdDidChanged(userId: string, context: GrowingContext) {
  let oldUserId = this.latestNonnullUserId
  this.latestNonnullUserId = userId

  // 场景 1: A → B（切换用户）
  if (oldUserId && oldUserId.length > 0 && oldUserId != userId) {
    // 用户切换，刷新 Session（生成新的会话）
    Session.refreshSession(context)
  } 
  // 场景 2: 匿名 → 登录（CDP 模式）
  else if (context.config.mode == ConfigMode.CDP) {
    if (oldUserId == null || oldUserId.length == 0) {
      // 首次登录，生成 VISIT 事件
      Session.generateVisit(context)
    }
  }
}
```

### 场景分析

| 场景 | oldUserId | newUserId | 处理逻辑 |
|------|-----------|-----------|---------|
| 匿名 → 登录 | '' | 'userA' | CDP: 生成 VISIT；其他: 仅更新 userId |
| 登录 A → 登录 B | 'userA' | 'userB' | 刷新 Session（新会话） |
| 登录 → 登出 | 'userA' | '' | 仅清除 userId |
| 无变化 | 'userA' | 'userA' | 无操作 |

### 流程图

```
调用 setLoginUserId(userId, userKey)
    │
    ▼
┌─────────────────────┐
│ ID Mapping 未开启？ │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 清空 userKey        │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 长度检查 (>1000)    │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ 获取当前 user       │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ userId 为空？       │
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  【是】    【否】
    │         │
    ▼         ▼
 清除用户   检查变化
    │         │
    │    ┌────┴────┐
    │    ▼         ▼
    │  【变化】  【无变化】
    │    │         │
    │    ▼         │
    │  更新用户    │
    │  保存配置    │
    │  触发回调    │
    │    │         │
    └────┴─────────┘
              │
              ▼
        userIdDidChanged()
              │
              ▼
        ┌─────────────┐
        │  A → B ?    │
        └──────┬──────┘
               │
          ┌────┴────┐
          ▼         ▼
        【是】    【否】
          │         │
          ▼         ▼
    refreshSession()  ┌─────────────┐
    刷新会话         │ CDP 模式？  │
                     └──────┬──────┘
                            │
                       ┌────┴────┐
                       ▼         ▼
                     【是】    【否】
                       │         │
                       ▼         ▼
                  generateVisit() 结束
                  生成 VISIT
```

---

## API 使用示例

### 设置登录用户

```typescript
// 普通设置
GrowingAnalytics.setLoginUserId('user123')

// 带 userKey（ID Mapping 场景）
GrowingAnalytics.setLoginUserId('user123', 'app')

// 清除登录用户（登出）
GrowingAnalytics.cleanLoginUserId()
```

### 获取用户 ID

```typescript
// 获取 deviceId
let deviceId = GrowingAnalytics.getDeviceId()

// userId 会在事件中自动填充，无需手动获取
```

### 子 Tracker 设置用户

```typescript
// 为特定 Tracker 设置用户
GrowingAnalytics.tracker('trackerB').setLoginUserId('user456')
```

---

## 总结

UserIdentifier 模块提供了完整的用户标识管理功能：

1. **设备 ID**: 自动生成 UUID，持久化存储，用于匿名用户识别
2. **登录用户**: 支持动态设置/清除，持久化存储
3. **ID Mapping**: 通过 userKey 支持跨平台用户关联
4. **多 Tracker**: 每个 Tracker 独立的用户标识管理
5. **会话联动**: 用户切换自动触发会话刷新

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
