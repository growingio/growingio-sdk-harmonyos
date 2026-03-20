# EventTimer - 事件计时器

`EventTimer` 提供事件计时功能，用于统计用户操作时长（如页面停留时间、功能使用时长等）。

## 核心概念

### 计时器状态

```
┌─────────┐     trackTimerStart      ┌──────────┐
│  不存在  │ ───────────────────────▶ │  运行中   │
└─────────┘                          └────┬─────┘
                                          │
                    trackTimerPause       │
                                          ▼
                                     ┌──────────┐
                                     │  已暂停   │
                                     └────┬─────┘
                                          │
                    trackTimerResume      │
                                          ▼
                                     ┌──────────┐
     trackTimerEnd / removeTimer     │  运行中   │ ─────▶ 事件发送（END）
     ─────────────────────────────────▶───────────┘
```

| 状态 | 特征 | 说明 |
|------|------|------|
| 运行中 | `startTime > 0` | 正在计时，时间持续累加 |
| 已暂停 | `startTime == 0` | 暂停计时，`duration` 保存已计时时长 |
| 已结束 | 计时器被删除 | 触发 `trackTimerEnd` 发送事件 |

### 数据结构

```typescript
class EventTimer {
    static timers: Map<string, EventTimer> = new Map()  // 全局计时器表
    eventName: string      // 事件名称
    startTime: number      // 开始时间戳（系统启动时间，毫秒）
    duration: number       // 已累积时长（毫秒）
    trackerId: string      // 所属 Tracker ID
}
```

**timerId 生成规则：**
```typescript
let timerId = eventName + '_' + util.generateRandomUUID(false)
```

示例：`page_stay_12345678-1234-1234-1234-123456789abc`

---

## 核心方法

### 1. trackTimerStart() - 开始计时

```typescript
static trackTimerStart(
    eventName: string,
    context: GrowingContext
): string
```

**流程：**

```
检查 dataCollectionEnabled
    │ 为 false ─────▶ 输出日志，返回空字符串
    │
    ▼ 为 true
获取当前系统时间
    │
    ▼
创建 EventTimer 实例
    │
    ▼
生成 timerId (eventName + UUID)
    │
    ▼
存入 timers Map
    │
    ▼
返回 timerId
```

**代码实现：**

```typescript
static trackTimerStart(eventName: string, context: GrowingContext): string {
    // 检查采集开关
    if (!context.config.dataCollectionEnabled) {
        LogUtil.info(() => 'Failed to start timer...')
        return ''
    }

    // 获取系统启动时间（非 Unix 时间戳）
    let currentTime = systemDatetime.getUptime(
        systemDatetime.TimeType.STARTUP, 
        false
    )
    
    // 创建计时器实例
    let timer = new EventTimer(eventName, currentTime, 0, context.trackerId)
    let timerId = eventName + '_' + util.generateRandomUUID(false)
    
    // 存入全局表
    EventTimer.timers.set(timerId, timer)
    return timerId
}
```

**注意：**
- 使用 `systemDatetime.TimeType.STARTUP` 获取系统启动时间，避免设备时间修改影响
- 每个计时器绑定到创建它的 Tracker 实例

---

### 2. trackTimerPause() - 暂停计时

```typescript
static trackTimerPause(timerId: string): void
```

**流程：**

```
查找 timerId
    │ 不存在 ─────▶ 直接返回
    │
    ▼
检查是否已暂停 (isPaused)
    │ 已暂停 ─────▶ 直接返回
    │
    ▼
记录当前时长：duration = currentTime - startTime
    │
    ▼
设置 startTime = 0（标记为暂停状态）
```

**代码实现：**

```typescript
static trackTimerPause(timerId: string) {
    let timer: EventTimer | undefined = EventTimer.timers.get(timerId)
    if (!timer || timer.isPaused()) {
        return
    }
    
    let startTime = timer.startTime
    timer.startTime = 0  // 标记暂停
    
    let currentTime = systemDatetime.getUptime(
        systemDatetime.TimeType.STARTUP, 
        false
    )
    timer.duration = EventTimer.durationFrom(startTime, currentTime)
}
```

---

### 3. trackTimerResume() - 恢复计时

```typescript
static trackTimerResume(timerId: string): void
```

**流程：**

```
查找 timerId
    │ 不存在 ─────▶ 直接返回
    │
    ▼
检查是否已暂停 (isPaused)
    │ 未暂停 ─────▶ 直接返回
    │
    ▼
更新 startTime = currentTime
```

**代码实现：**

```typescript
static trackTimerResume(timerId: string) {
    let timer: EventTimer | undefined = EventTimer.timers.get(timerId)
    if (!timer || !timer.isPaused()) {
        return
    }
    
    let currentTime = systemDatetime.getUptime(
        systemDatetime.TimeType.STARTUP, 
        false
    )
    timer.startTime = currentTime
}
```

---

### 4. trackTimerEnd() - 结束计时

```typescript
static trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {},
    context: GrowingContext,
    sendTo?: string[]
): void
```

**流程：**

```
检查 dataCollectionEnabled
    │ 为 false ─────▶ 输出日志，直接返回
    │
    ▼
查找 timerId
    │ 不存在 ─────▶ 直接返回
    │
    ▼
验证 trackerId 匹配
    │ 不匹配 ─────▶ 输出警告，直接返回
    │
    ▼
计算总时长：duration = (currentTime - startTime) + savedDuration
    │
    ▼
删除计时器
    │
    ▼
添加 Event_DURATION 属性（秒，保留3位小数）
    │
    ▼
SaaS 模式：发送 FakePageEvent（如果需要）
    │
    ▼
创建并发送 CustomEvent
    │
    ▼
如有 sendTo，转发到指定子 Tracker
```

**代码实现：**

```typescript
static trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {},
    context: GrowingContext,
    sendTo?: string[]
) {
    // 检查采集开关和查找计时器
    let timer: EventTimer | undefined = EventTimer.timers.get(timerId)
    if (!timer) return
    
    // Tracker 权限检查
    if (timer.trackerId != context.trackerId) {
        LogUtil.warn(() => "Track timer end failed, this timer's trackerId...")
        return
    }
    
    let eventName = timer.eventName
    let startTime = timer.startTime
    let duration = timer.duration
    EventTimer.timers.delete(timerId)
    
    // 计算总时长
    let currentTime = systemDatetime.getUptime(
        systemDatetime.TimeType.STARTUP, 
        false
    )
    duration = EventTimer.durationFrom(startTime, currentTime) + duration
    
    // 添加时长属性（转换为秒）
    attributes[Event_DURATION] = (duration / 1000.0).toFixed(3) + ''
    
    // SaaS 模式下可能需要发送 FakePageEvent
    if (context.config.mode == ConfigMode.SaaS) {
        FakePageEvent.sendFakePageIfNeeded(context)
    }
    
    // 创建并发送事件
    let e = CustomEvent.create(eventName, attributes, context)
    AnalyticsCore.writeEventToDisk(e, context)
    
    // 转发到其他 Tracker
    if (sendTo && sendTo.length > 0) {
        AnalyticsCore.sendTo(context.trackerId, sendTo, eventName, attributes)
    }
}
```

**时长计算：**

```typescript
static durationFrom(startTime: number, endTime: number): number {
    if (startTime <= 0) {
        return 0
    }
    let duration = endTime - startTime
    // 限制在 24 小时内，防止异常值
    return (duration > 0 && duration < 24 * 60 * 60 * 1000) ? duration : 0
}
```

---

### 5. removeTimer() - 移除计时器

```typescript
static removeTimer(timerId: string): void
```

**说明：**
- 直接删除计时器，不发送事件
- 用于取消计时场景

---

### 6. clearTrackTimer() - 清空当前 Tracker 的所有计时器

```typescript
static clearTrackTimer(context: GrowingContext): void
```

**说明：**
- 只删除属于指定 Tracker 的计时器
- 用于 Tracker 销毁或重置场景

---

### 7. 应用前后台处理

#### handleAllTimersPause() - 应用进入后台

```typescript
static handleAllTimersPause(): void
```

**触发时机：**
- `ApplicationStateChange` 回调中，应用切换到后台时调用

**处理逻辑：**
```typescript
for (let timer of EventTimer.timers.values()) {
    if (timer.isPaused()) continue
    
    let currentTime = systemDatetime.getUptime(...)
    // 保存当前时长
    timer.duration = EventTimer.durationFrom(timer.startTime, currentTime)
    // 更新 startTime，用于恢复时计算
    timer.startTime = currentTime
}
```

**注意：**
- 并不是真正暂停，而是保存当前进度并更新时间基准
- 这样应用恢复时可以正确计算后台期间的时间

#### handleAllTimersResume() - 应用回到前台

```typescript
static handleAllTimersResume(): void
```

**触发时机：**
- `ApplicationStateChange` 回调中，应用切换到前台时调用

**处理逻辑：**
```typescript
for (let timer of EventTimer.timers.values()) {
    if (timer.isPaused()) continue
    
    let currentTime = systemDatetime.getUptime(...)
    // 更新开始时间为当前时间
    timer.startTime = currentTime
}
```

**设计说明：**
- 应用回到前台时，重置所有计时器的 `startTime`
- 这样后台期间的时间不会被计入（符合业务预期）

---

## 使用示例

### 基本用法

```typescript
// 页面进入时开始计时
const timerId = GrowingAnalytics.trackTimerStart('page_stay')

// 页面销毁时结束计时并发送事件
GrowingAnalytics.trackTimerEnd(timerId, { pageName: 'home' })
```

### 带暂停/恢复的用法

```typescript
class PageModel {
    timerId: string = ''
    
    aboutToAppear() {
        this.timerId = GrowingAnalytics.trackTimerStart('video_play')
    }
    
    onPageHide() {
        // 页面隐藏时暂停
        GrowingAnalytics.trackTimerPause(this.timerId)
    }
    
    onPageShow() {
        // 页面显示时恢复
        GrowingAnalytics.trackTimerResume(this.timerId)
    }
    
    aboutToDisappear() {
        // 页面销毁时结束
        GrowingAnalytics.trackTimerEnd(this.timerId, { videoId: '123' })
    }
}
```

### 子 Tracker 计时器

```typescript
// 为主 Tracker 创建计时器
const mainTimerId = GrowingAnalytics.trackTimerStart('event1')

// 为子 Tracker 创建计时器
const subTracker = GrowingAnalytics.tracker('tracker2')
const subTimerId = subTracker.trackTimerStart('event2')

// 结束计时（注意：必须使用创建时的 Tracker 实例）
GrowingAnalytics.trackTimerEnd(mainTimerId)
subTracker.trackTimerEnd(subTimerId)
```

**注意：**
- 计时器绑定到创建它的 Tracker
- 不能跨 Tracker 结束计时器（会有警告日志）

---

## 时序图

```
应用前台                    应用后台                    应用前台
    │                          │                          │
    │  trackTimerStart         │                          │
    │─────────────────────────▶│                          │
    │                          │                          │
    │  [计时中: 0s -> 10s]      │                          │
    │                          │                          │
    │                          │  handleAllTimersPause    │
    │                          │◀─────────────────────────│
    │                          │  duration = 10s          │
    │                          │                          │
    │         [应用在后台运行 30s]                          │
    │                          │                          │
    │                          │  handleAllTimersResume   │
    │                          │◀─────────────────────────│
    │                          │  startTime = now         │
    │                          │                          │
    │  [计时中: 10s -> 20s]     │                          │
    │                          │                          │
    │  trackTimerEnd           │                          │
    │─────────────────────────▶│                          │
    │  发送事件: duration=20s   │                          │
    │                          │                          │
```

**关键点：**
- 后台 30s 没有被计入时长
- 实际前台运行 20s，事件上报 20s

---

## 注意事项

1. **时间基准**
   - 使用 `systemDatetime.TimeType.STARTUP`（系统启动时间）
   - 不受用户修改设备时间影响
   - 设备重启后会重置

2. **最大时长限制**
   - 单次计时不超过 24 小时
   - 超出部分会被截断为 0

3. **Tracker 隔离**
   - 计时器绑定创建它的 Tracker
   - 跨 Tracker 操作会被拒绝

4. **应用生命周期**
   - 后台自动暂停计时
   - 前台自动恢复计时
   - 应用关闭后计时器丢失（未结束的不发送）

5. **内存管理**
   - 计时器存储在全局 Map 中
   - 记得调用 `trackTimerEnd` 或 `removeTimer` 释放
   - `clearTrackTimer` 可批量清理

---

## 参见

- [interfaces/interfaces.md](../interfaces/interfaces.md) - 计时器 API 使用说明
- [AnalyticsCore](./analytics_core.md) - 事件写入和发送
- [Session](./session.md) - 应用前后台切换处理
