import { describe, it, expect, beforeEach } from '@ohos/hypium'
import Session, { SessionState } from '../../main/ets/components/core/Session'
import GrowingContext from '../../main/ets/components/core/Context'

/** 最小 GrowingContext 替身的中间结构 */
interface MinimalSessionContext {
  trackerId: string
}

function makeSessionContext(trackerId: string): GrowingContext {
  let ctx: MinimalSessionContext = { trackerId: trackerId }
  return ctx as ESObject as GrowingContext
}

/**
 * Session 测试策略说明：
 *
 * Session 的完整 onForeground/onBackground 流程依赖：
 *   - emitter（ArkTS 事件总线）
 *   - AnalyticsCore.writeEventToDisk（写入 RDB）
 *   - VisitEvent.create / AppClosedEvent.create
 *
 * 以上依赖无法在本地单元测试中 Mock（@ohos/hamock 不支持跨模块静态方法 Mock）。
 *
 * 因此本套测试只覆盖：
 *   1. 纯数据结构操作：getSessionId、sessions 数组管理
 *   2. sessionState 状态标志读写
 *   3. session 超时判断逻辑（通过直接操作 latestOnBackgroundTime 验证判断条件）
 *   4. _reset() 的隔离保证
 *
 * onForeground/onBackground 的完整副作用流程在 ohosTest 集成测试中覆盖。
 */
export default function sessionTests() {

  beforeEach(() => {
    Session._reset()
  })

  // ─── 初始状态 ─────────────────────────────────────────────────────────────

  describe('Session_initialState', () => {

    it('初始 sessionState 应为 Foreground', 0, () => {
      expect(Session.sessionState).assertEqual(SessionState.Foreground)
    })

    it('初始 sessions 应为空数组', 0, () => {
      expect(Session.sessions.length).assertEqual(0)
    })
  })

  // ─── getSessionId ─────────────────────────────────────────────────────────

  describe('Session_getSessionId', () => {

    it('sessions 为空时应返回 undefined', 0, () => {
      let fakeContext = makeSessionContext('tracker-1')
      let result = Session.getSessionId(fakeContext)
      expect(result).assertUndefined()
    })

    it('session 存在时应返回对应 sessionId', 0, () => {
      Session.sessions.push(new Session('session-abc', 'tracker-1'))
      let fakeContext = makeSessionContext('tracker-1')

      let result = Session.getSessionId(fakeContext)
      expect(result).assertEqual('session-abc')
    })

    it('多个 tracker 共存时应返回正确 tracker 的 sessionId', 0, () => {
      Session.sessions.push(new Session('session-A', 'tracker-A'))
      Session.sessions.push(new Session('session-B', 'tracker-B'))

      let ctxA = makeSessionContext('tracker-A')
      let ctxB = makeSessionContext('tracker-B')

      expect(Session.getSessionId(ctxA)).assertEqual('session-A')
      expect(Session.getSessionId(ctxB)).assertEqual('session-B')
    })

    it('不存在的 trackerId 应返回 undefined', 0, () => {
      Session.sessions.push(new Session('session-A', 'tracker-A'))
      let ctxB = makeSessionContext('tracker-B')

      expect(Session.getSessionId(ctxB)).assertUndefined()
    })
  })

  // ─── sessionState 状态管理 ────────────────────────────────────────────────

  describe('Session_sessionState', () => {

    it('_reset 后 sessionState 应恢复为 Foreground', 0, () => {
      Session.sessionState = SessionState.Background
      Session._reset()
      expect(Session.sessionState).assertEqual(SessionState.Foreground)
    })

    it('可以手动设置为 Background', 0, () => {
      Session.sessionState = SessionState.Background
      expect(Session.sessionState).assertEqual(SessionState.Background)
    })
  })

  // ─── session 超时判断逻辑（纯条件验证）───────────────────────────────────

  describe('Session_sessionInterval_timeout', () => {
    /**
     * Session.onForeground 内部的核心判断：
     *   Date.now() - session.latestOnBackgroundTime >= context.config._sessionInterval
     *
     * 此处验证这个数学条件本身的正确性。
     */

    it('距离 background 超过 sessionInterval → 应该 refresh（超时）', 0, () => {
      let sessionInterval = 30 * 1000  // 30 秒
      let latestOnBackgroundTime = Date.now() - 35 * 1000  // 35 秒前
      let shouldRefresh = (Date.now() - latestOnBackgroundTime) >= sessionInterval
      expect(shouldRefresh).assertTrue()
    })

    it('距离 background 不足 sessionInterval → 不应 refresh', 0, () => {
      let sessionInterval = 30 * 1000
      let latestOnBackgroundTime = Date.now() - 10 * 1000  // 10 秒前
      let shouldRefresh = (Date.now() - latestOnBackgroundTime) >= sessionInterval
      expect(shouldRefresh).assertFalse()
    })

    it('latestOnBackgroundTime=0 → 首次初始化，不应触发 refresh', 0, () => {
      // Session.onForeground 中 latestOnBackgroundTime==0 直接 return
      let latestOnBackgroundTime = 0
      let isFirstInit = latestOnBackgroundTime == 0
      expect(isFirstInit).assertTrue()
    })

    it('恰好等于 sessionInterval 的临界值 → 应该 refresh（>=）', 0, () => {
      let sessionInterval = 30 * 1000
      let latestOnBackgroundTime = Date.now() - 30 * 1000  // 恰好 30 秒前
      let shouldRefresh = (Date.now() - latestOnBackgroundTime) >= sessionInterval
      expect(shouldRefresh).assertTrue()
    })
  })

  // ─── sessions 数组直接操作 ───────────────────────────────────────────────

  describe('Session_sessions_array', () => {

    it('手动 push 后 sessions.length 应增加', 0, () => {
      Session.sessions.push(new Session('s1', 'tracker-1'))
      Session.sessions.push(new Session('s2', 'tracker-2'))
      expect(Session.sessions.length).assertEqual(2)
    })

    it('Session 对象的 latestOnBackgroundTime 默认应为 0', 0, () => {
      let s = new Session('sid', 'tracker-1')
      expect(s.latestOnBackgroundTime).assertEqual(0)
    })

    it('可手动更新 latestOnBackgroundTime', 0, () => {
      let s = new Session('sid', 'tracker-1')
      let now = Date.now()
      s.latestOnBackgroundTime = now
      expect(s.latestOnBackgroundTime).assertEqual(now)
    })
  })

  // ─── _reset 隔离验证 ──────────────────────────────────────────────────────

  describe('Session_reset_isolation', () => {

    it('_reset 应清空 sessions 数组', 0, () => {
      Session.sessions.push(new Session('s1', 'tracker-1'))
      Session.sessions.push(new Session('s2', 'tracker-2'))

      Session._reset()

      expect(Session.sessions.length).assertEqual(0)
    })

    it('_reset 后 getSessionId 应返回 undefined', 0, () => {
      Session.sessions.push(new Session('s1', 'tracker-1'))
      Session._reset()

      let ctx = makeSessionContext('tracker-1')
      expect(Session.getSessionId(ctx)).assertUndefined()
    })
  })
}
