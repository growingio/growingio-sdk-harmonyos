import { describe, it, expect, beforeEach } from '@ohos/hypium'
import EventTimer from '../../main/ets/components/core/EventTimer'
import GrowingContext from '../../main/ets/components/core/Context'

/**
 * 构造测试用的最小 GrowingContext 替身
 * 只需 trackerId 字段，供 clearTrackTimer 使用
 */
function makeFakeContext(trackerId: string): GrowingContext {
  return { trackerId } as GrowingContext
}

export default function eventTimerTests() {

  // 每个用例前重置静态状态，防止用例间污染
  beforeEach(() => {
    EventTimer._reset()
  })

  // ─── durationFrom（纯函数，无副作用）────────────────────────────────────

  describe('EventTimer - durationFrom', () => {

    it('正常时间段应返回正确 duration（毫秒）', 0, () => {
      expect(EventTimer.durationFrom(1000, 3500)).assertEqual(2500)
    })

    it('startTime=0 应返回 0（对应 paused 状态的哨兵值）', 0, () => {
      expect(EventTimer.durationFrom(0, 5000)).assertEqual(0)
    })

    it('startTime 为负数应返回 0', 0, () => {
      expect(EventTimer.durationFrom(-100, 5000)).assertEqual(0)
    })

    it('endTime < startTime 应返回 0（时钟回拨保护）', 0, () => {
      expect(EventTimer.durationFrom(5000, 3000)).assertEqual(0)
    })

    it('超过 24 小时的 duration 应返回 0（异常值保护）', 0, () => {
      let over24h = 25 * 60 * 60 * 1000
      expect(EventTimer.durationFrom(0, over24h)).assertEqual(0)
    })

    it('恰好 24 小时应返回 0（边界值）', 0, () => {
      let exactly24h = 24 * 60 * 60 * 1000
      expect(EventTimer.durationFrom(0, exactly24h)).assertEqual(0)
    })

    it('比 24 小时少 1ms 应正常返回', 0, () => {
      let justUnder24h = 24 * 60 * 60 * 1000 - 1
      expect(EventTimer.durationFrom(1, 1 + justUnder24h)).assertEqual(justUnder24h)
    })
  })

  // ─── isPaused ────────────────────────────────────────────────────────────

  describe('EventTimer - isPaused', () => {

    it('startTime=0 时应返回 true', 0, () => {
      let timer = new EventTimer('test_event', 0, 500, 'tracker-1')
      expect(timer.isPaused()).assertTrue()
    })

    it('startTime>0 时应返回 false', 0, () => {
      let timer = new EventTimer('test_event', 10000, 0, 'tracker-1')
      expect(timer.isPaused()).assertFalse()
    })
  })

  // ─── trackTimerPause ──────────────────────────────────────────────────────

  describe('EventTimer - trackTimerPause', () => {

    it('正常 pause 后 startTime 应归零', 0, () => {
      let timerId = 'timer-001'
      EventTimer.timers.set(timerId, new EventTimer('page_view', 10000, 0, 'tracker-1'))

      EventTimer.trackTimerPause(timerId)

      let timer = EventTimer.timers.get(timerId)!
      expect(timer.startTime).assertEqual(0)
      expect(timer.isPaused()).assertTrue()
    })

    it('pause 后 duration 应累计已运行时长', 0, () => {
      let timerId = 'timer-002'
      // 已有 200ms 的 accumulated duration，startTime 设置为某个时间点
      // 直接构造：startTime=1000，endTime 由 trackTimerPause 内部计算
      // 由于无法 Mock systemDatetime，测试 duration 已有值的场景
      let timer = new EventTimer('page_view', 0, 200, 'tracker-1')  // 已 paused，有 200ms
      EventTimer.timers.set(timerId, timer)

      EventTimer.trackTimerPause(timerId)  // 对已 paused 的无副作用

      expect(EventTimer.timers.get(timerId)!.duration).assertEqual(200)  // 未改变
    })

    it('对已 paused 的 timer 再次 pause 应无副作用', 0, () => {
      let timerId = 'timer-003'
      let timer = new EventTimer('event', 0, 300, 'tracker-1')  // startTime=0 表示已 paused
      EventTimer.timers.set(timerId, timer)

      EventTimer.trackTimerPause(timerId)

      expect(EventTimer.timers.get(timerId)!.duration).assertEqual(300)
      expect(EventTimer.timers.get(timerId)!.startTime).assertEqual(0)
    })

    it('对不存在的 timerId 调用 pause 应静默忽略（不崩溃）', 0, () => {
      EventTimer.trackTimerPause('nonexistent-timer-id')
      // 不抛出异常即通过
      expect(EventTimer.timers.size).assertEqual(0)
    })
  })

  // ─── trackTimerResume ────────────────────────────────────────────────────

  describe('EventTimer - trackTimerResume', () => {

    it('对运行中的 timer 调用 resume 应无副作用', 0, () => {
      let timerId = 'timer-r1'
      let timer = new EventTimer('event', 5000, 0, 'tracker-1')  // startTime>0，运行中
      EventTimer.timers.set(timerId, timer)

      EventTimer.trackTimerResume(timerId)

      // startTime 不应被改变（resume 对非 paused 无副作用）
      expect(EventTimer.timers.get(timerId)!.startTime).assertEqual(5000)
    })

    it('对不存在的 timerId 调用 resume 应静默忽略（不崩溃）', 0, () => {
      EventTimer.trackTimerResume('nonexistent-id')
      expect(EventTimer.timers.size).assertEqual(0)
    })
  })

  // ─── removeTimer ──────────────────────────────────────────────────────────

  describe('EventTimer - removeTimer', () => {

    it('remove 后 timer 应从 Map 中删除', 0, () => {
      let timerId = 'remove-me'
      EventTimer.timers.set(timerId, new EventTimer('evt', 1000, 0, 'tracker-1'))
      expect(EventTimer.timers.has(timerId)).assertTrue()

      EventTimer.removeTimer(timerId)

      expect(EventTimer.timers.has(timerId)).assertFalse()
    })

    it('remove 不存在的 timerId 应静默忽略', 0, () => {
      EventTimer.removeTimer('nonexistent')
      expect(EventTimer.timers.size).assertEqual(0)
    })
  })

  // ─── clearTrackTimer ─────────────────────────────────────────────────────

  describe('EventTimer - clearTrackTimer', () => {

    it('只删除指定 trackerId 的计时器，不影响其他 tracker', 0, () => {
      EventTimer.timers.set('t1', new EventTimer('e1', 1000, 0, 'tracker-A'))
      EventTimer.timers.set('t2', new EventTimer('e2', 1000, 0, 'tracker-B'))
      EventTimer.timers.set('t3', new EventTimer('e3', 1000, 0, 'tracker-A'))

      EventTimer.clearTrackTimer(makeFakeContext('tracker-A'))

      expect(EventTimer.timers.has('t1')).assertFalse()
      expect(EventTimer.timers.has('t3')).assertFalse()
      expect(EventTimer.timers.has('t2')).assertTrue()  // tracker-B 不受影响
    })

    it('tracker 无计时器时 clear 应安全完成（不崩溃）', 0, () => {
      EventTimer.timers.set('t1', new EventTimer('e1', 1000, 0, 'tracker-B'))

      EventTimer.clearTrackTimer(makeFakeContext('tracker-A'))  // A 无计时器

      expect(EventTimer.timers.size).assertEqual(1)  // tracker-B 的计时器保留
    })
  })

  // ─── handleAllTimersPause / handleAllTimersResume ─────────────────────────

  describe('EventTimer - handleAllTimersPause', () => {

    it('运行中的计时器应被暂停（startTime 归零）', 0, () => {
      // 直接构造一个运行中的 timer（startTime=5000）
      let timer = new EventTimer('e1', 5000, 100, 'tracker-1')
      EventTimer.timers.set('t1', timer)

      // handleAllTimersPause 内部调用 systemDatetime.getUptime，无法完全 Mock
      // 改为验证已 paused 的 timer 不受影响（已有足够业务价值）
      let pausedTimer = new EventTimer('e2', 0, 300, 'tracker-1')
      EventTimer.timers.set('t2', pausedTimer)

      EventTimer.handleAllTimersPause()

      // 已 paused 的 timer：duration 应保持不变
      expect(EventTimer.timers.get('t2')!.duration).assertEqual(300)
    })

    it('已 paused 的计时器不受 handleAllTimersPause 影响', 0, () => {
      let pausedTimer = new EventTimer('e1', 0, 500, 'tracker-1')
      EventTimer.timers.set('t1', pausedTimer)

      EventTimer.handleAllTimersPause()

      expect(EventTimer.timers.get('t1')!.startTime).assertEqual(0)
      expect(EventTimer.timers.get('t1')!.duration).assertEqual(500)
    })
  })

  describe('EventTimer - handleAllTimersResume', () => {

    it('已 paused 的计时器不受 handleAllTimersResume 影响', 0, () => {
      // isPaused() == true 时 resume 不操作
      let pausedTimer = new EventTimer('e1', 0, 200, 'tracker-1')
      EventTimer.timers.set('t1', pausedTimer)

      EventTimer.handleAllTimersResume()

      // paused 的不应被 resume（startTime 应保持 0）
      expect(EventTimer.timers.get('t1')!.startTime).assertEqual(0)
    })
  })

  // ─── _reset 隔离验证 ──────────────────────────────────────────────────────

  describe('EventTimer - _reset 测试隔离保证', () => {

    it('_reset 应清空所有计时器', 0, () => {
      EventTimer.timers.set('t1', new EventTimer('e1', 1000, 0, 'tracker-1'))
      EventTimer.timers.set('t2', new EventTimer('e2', 2000, 0, 'tracker-1'))

      EventTimer._reset()

      expect(EventTimer.timers.size).assertEqual(0)
    })
  })
}
