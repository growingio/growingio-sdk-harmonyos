import { describe, it, expect, beforeEach } from '@ohos/hypium'
import UserIdentifier from '../../main/ets/components/core/UserIdentifier'
import Session from '../../main/ets/components/core/Session'
import GrowingContext from '../../main/ets/components/core/Context'
import { ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'

/**
 * 构造测试用的最小 GrowingContext 替身
 *
 * 覆盖 UserIdentifier 使用到的字段：
 *   - trackerId
 *   - config.idMappingEnabled
 *   - config.mode
 *   - config.accountId / dataSourceId（saveToPreferences 后缀拼接）
 *   - config.dataCollectionEnabled（Session.generateVisit 早返回保护）
 */
interface MinimalUserConfig {
  idMappingEnabled: boolean
  mode: ConfigMode
  accountId: string
  dataSourceId: string
  dataCollectionEnabled: boolean
}

interface MinimalUserContext {
  trackerId: string
  config: MinimalUserConfig
}

function makeUserContext(
  trackerId: string,
  idMappingEnabled: boolean = false,
  mode: ConfigMode = ConfigMode.NewSaaS,
  dataCollectionEnabled: boolean = false
): GrowingContext {
  let config: MinimalUserConfig = {
    idMappingEnabled: idMappingEnabled,
    mode: mode,
    accountId: 'test-acct',
    dataSourceId: 'test-ds',
    dataCollectionEnabled: dataCollectionEnabled
  }
  let ctx: MinimalUserContext = {
    trackerId: trackerId,
    config: config
  }
  return ctx as ESObject as GrowingContext
}

/**
 * UserIdentifier 测试策略说明：
 *
 * 部分操作涉及 Session 副作用链：
 *   setLoginUserId (A→B) → userIdDidChanged → Session.refreshSession
 *     → Session.generateVisit → AnalyticsCore.writeEventToDisk
 *
 * 为使单元测试不依赖 AnalyticsCore：
 *   - 使用 context.config.dataCollectionEnabled = false，
 *     Session.generateVisit 在入口处短路返回，整条链路安全可测
 *
 * 本套测试覆盖：
 *   1. initUser / initMultiUser 从 Preferences 加载（测试环境下返回默认值）
 *   2. getUser：trackerId 隔离
 *   3. setLoginUserId：长度校验、幂等性、清空、idMapping 控制
 *   4. setLoginUserId：A→B 切换触发 Session.refreshSession
 *   5. setLoginUserId：CDP 空→有触发 Session.generateVisit
 *   6. _reset 隔离
 *
 * 依赖 Session / AnalyticsCore 的完整副作用链在 ohosTest 集成测试中覆盖。
 */
export default function userIdentifierTests() {

  // ─── initUser ─────────────────────────────────────────────────────────────

  describe('UserIdentifier_initUser', () => {

    beforeEach(() => {
      UserIdentifier._reset()
      Session._reset()
      GrowingContext._reset()
    })

    it('首次 initUser 应创建空 userId 的用户（Preferences 未初始化返回默认值）', 0, () => {
      let ctx = makeUserContext('tracker-1')
      UserIdentifier.initUser(ctx)

      let user = UserIdentifier.getUser(ctx)
      expect(user).assertInstanceOf('Object')
      expect(user!.userId).assertEqual('')
      expect(user!.userKey).assertEqual('')
    })

    it('不同 tracker 的 initUser 应相互隔离', 0, () => {
      let ctxA = makeUserContext('tracker-A')
      let ctxB = makeUserContext('tracker-B')
      UserIdentifier.initUser(ctxA)
      UserIdentifier.initUser(ctxB)

      expect(UserIdentifier.getUser(ctxA)!.userId).assertEqual('')
      expect(UserIdentifier.getUser(ctxB)!.userId).assertEqual('')
    })
  })

  // ─── initMultiUser ────────────────────────────────────────────────────────

  describe('UserIdentifier_initMultiUser', () => {

    beforeEach(() => {
      UserIdentifier._reset()
      Session._reset()
      GrowingContext._reset()
    })

    it('initMultiUser 读取不存在的 suffix key 应返回空字符串', 0, () => {
      let ctx = makeUserContext('sub-tracker')
      UserIdentifier.initMultiUser(ctx)

      let user = UserIdentifier.getUser(ctx)
      expect(user).assertInstanceOf('Object')
      expect(user!.userId).assertEqual('')
      expect(user!.userKey).assertEqual('')
    })
  })

  // ─── getUser ──────────────────────────────────────────────────────────────

  describe('UserIdentifier_getUser', () => {

    beforeEach(() => {
      UserIdentifier._reset()
      Session._reset()
      GrowingContext._reset()
    })

    it('未 init 的 tracker 应返回 undefined', 0, () => {
      let ctx = makeUserContext('tracker-1')
      expect(UserIdentifier.getUser(ctx)).assertUndefined()
    })

    it('initUser 后 getUser 应返回对应对象', 0, () => {
      let ctx = makeUserContext('tracker-1')
      UserIdentifier.initUser(ctx)
      expect(UserIdentifier.getUser(ctx)).assertInstanceOf('Object')
    })

    it('getUser 按 trackerId 严格隔离', 0, () => {
      let ctxA = makeUserContext('A')
      let ctxB = makeUserContext('B')
      UserIdentifier.initUser(ctxA)

      expect(UserIdentifier.getUser(ctxA)).assertInstanceOf('Object')
      expect(UserIdentifier.getUser(ctxB)).assertUndefined()
    })
  })

  // ─── setLoginUserId：参数校验 ─────────────────────────────────────────────

  describe('UserIdentifier_setLoginUserId_validation', () => {

    beforeEach(() => {
      UserIdentifier._reset()
      Session._reset()
      GrowingContext._reset()
    })

    it('userId 长度超过 1000 应被静默忽略', 0, () => {
      let ctx = makeUserContext('t1')
      UserIdentifier.initUser(ctx)

      let longId = 'a'.repeat(1001)
      UserIdentifier.setLoginUserId(longId, '', ctx)

      expect(UserIdentifier.getUser(ctx)!.userId).assertEqual('')
    })

    it('userKey 长度超过 1000 应被静默忽略，整个调用被跳过', 0, () => {
      let ctx = makeUserContext('t1', true)
      UserIdentifier.initUser(ctx)
      // 先设置一个合法 userId
      UserIdentifier.setLoginUserId('user-A', '', ctx)

      let longKey = 'k'.repeat(1001)
      UserIdentifier.setLoginUserId('user-B', longKey, ctx)

      // userKey 超限，整个调用被忽略，userId 也不变
      expect(UserIdentifier.getUser(ctx)!.userId).assertEqual('user-A')
    })

    it('userId 恰好 1000 个字符应被接受', 0, () => {
      let ctx = makeUserContext('t1')
      UserIdentifier.initUser(ctx)

      let exactId = 'a'.repeat(1000)
      UserIdentifier.setLoginUserId(exactId, '', ctx)

      expect(UserIdentifier.getUser(ctx)!.userId).assertEqual(exactId)
    })

    it('user 不存在时调用 setLoginUserId 应静默忽略（不崩溃）', 0, () => {
      let ctx = makeUserContext('t1')
      // 不调用 initUser，users Map 为空
      UserIdentifier.setLoginUserId('any-id', '', ctx)
      expect(UserIdentifier.getUser(ctx)).assertUndefined()
    })
  })

  // ─── setLoginUserId：清空 userId ──────────────────────────────────────────

  describe('UserIdentifier_setLoginUserId_clear', () => {

    beforeEach(() => {
      UserIdentifier._reset()
      Session._reset()
      GrowingContext._reset()
    })

    it('传入空 userId 应清空 userId 和 userKey', 0, () => {
      let ctx = makeUserContext('t1', true)
      UserIdentifier.initUser(ctx)
      UserIdentifier.setLoginUserId('user-A', 'key-A', ctx)

      UserIdentifier.setLoginUserId('', '', ctx)

      let user = UserIdentifier.getUser(ctx)!
      expect(user.userId).assertEqual('')
      expect(user.userKey).assertEqual('')
    })
  })

  // ─── setLoginUserId：幂等性 ───────────────────────────────────────────────

  describe('UserIdentifier_setLoginUserId_idempotent', () => {

    beforeEach(() => {
      UserIdentifier._reset()
      Session._reset()
      GrowingContext._reset()
    })

    it('userId 和 userKey 均不变时应跳过（返回同一对象引用）', 0, () => {
      let ctx = makeUserContext('t1', true)
      UserIdentifier.initUser(ctx)
      UserIdentifier.setLoginUserId('user-A', 'key-A', ctx)

      let userBefore = UserIdentifier.getUser(ctx)!
      UserIdentifier.setLoginUserId('user-A', 'key-A', ctx)
      let userAfter = UserIdentifier.getUser(ctx)!

      expect(userAfter === userBefore).assertTrue()
    })
  })

  // ─── setLoginUserId：idMappingEnabled 控制 ────────────────────────────────

  describe('UserIdentifier_setLoginUserId_idMapping', () => {

    beforeEach(() => {
      UserIdentifier._reset()
      Session._reset()
      GrowingContext._reset()
    })

    it('idMappingEnabled=false 时传入的 userKey 应被强制置空', 0, () => {
      let ctx = makeUserContext('t1', false)
      UserIdentifier.initUser(ctx)

      UserIdentifier.setLoginUserId('user-A', 'should-be-ignored', ctx)

      let user = UserIdentifier.getUser(ctx)!
      expect(user.userId).assertEqual('user-A')
      expect(user.userKey).assertEqual('')
    })

    it('idMappingEnabled=true 时 userKey 应正常保存', 0, () => {
      let ctx = makeUserContext('t1', true)
      UserIdentifier.initUser(ctx)

      UserIdentifier.setLoginUserId('user-A', 'key-A', ctx)

      let user = UserIdentifier.getUser(ctx)!
      expect(user.userId).assertEqual('user-A')
      expect(user.userKey).assertEqual('key-A')
    })
  })

  // ─── setLoginUserId：A→B 用户切换触发 Session 刷新 ────────────────────────

  describe('UserIdentifier_setLoginUserId_userChange', () => {

    /**
     * 使用 dataCollectionEnabled=false 阻断 AnalyticsCore.writeEventToDisk 调用，
     * 仅验证 Session 层的 sessionId 刷新行为。
     */

    beforeEach(() => {
      UserIdentifier._reset()
      Session._reset()
      GrowingContext._reset()
    })

    it('A→B 切换应触发 Session 刷新（sessionId 发生变化）', 0, () => {
      let ctx = makeUserContext('t1', false, ConfigMode.NewSaaS, false)
      UserIdentifier.initUser(ctx)

      // 先设置 user-A（从空→A，不触发刷新）
      UserIdentifier.setLoginUserId('user-A', '', ctx)

      // 为 tracker 预置 session，便于观察 sessionId 变化
      let oldSessionId = 'session-before-change'
      Session.sessions.push(new Session(oldSessionId, 't1'))

      // 切换到 user-B（A→B，应触发 refreshSession）
      UserIdentifier.setLoginUserId('user-B', '', ctx)

      // sessionId 应已被刷新（新值与旧值不同）
      let newSessionId = Session.getSessionId(ctx)
      expect(newSessionId === oldSessionId).assertFalse()
      expect(newSessionId === undefined).assertFalse()
    })

    it('相同 userId 重复设置不应刷新 session', 0, () => {
      let ctx = makeUserContext('t1', false, ConfigMode.NewSaaS, false)
      UserIdentifier.initUser(ctx)
      UserIdentifier.setLoginUserId('user-A', '', ctx)

      let fixedSessionId = 'session-stable'
      Session.sessions.push(new Session(fixedSessionId, 't1'))

      // 再次设置相同 userId，幂等，不触发刷新
      UserIdentifier.setLoginUserId('user-A', '', ctx)

      expect(Session.getSessionId(ctx)).assertEqual(fixedSessionId)
    })
  })

  // ─── setLoginUserId：CDP 空→有触发 generateVisit ──────────────────────────

  describe('UserIdentifier_setLoginUserId_CDP', () => {

    beforeEach(() => {
      UserIdentifier._reset()
      Session._reset()
      GrowingContext._reset()
    })

    it('CDP 模式：空 userId → 有效 userId 应触发 Session.generateVisit（dataCollectionEnabled=false 保护）', 0, () => {
      let ctx = makeUserContext('t1', false, ConfigMode.CDP, false)
      UserIdentifier.initUser(ctx)

      // 从空到有（触发 generateVisit，但 dataCollectionEnabled=false 所以 generateVisit 立即返回）
      // 验证：不崩溃，userId 正确更新
      UserIdentifier.setLoginUserId('cdp-user', '', ctx)

      expect(UserIdentifier.getUser(ctx)!.userId).assertEqual('cdp-user')
    })

    it('CDP 模式：A→B 切换应走 refreshSession 分支，sessionId 刷新', 0, () => {
      let ctx = makeUserContext('t1', false, ConfigMode.CDP, false)
      UserIdentifier.initUser(ctx)
      UserIdentifier.setLoginUserId('cdp-A', '', ctx)

      let oldSessionId = 'cdp-session-old'
      Session.sessions.push(new Session(oldSessionId, 't1'))

      // A→B，应走 refreshSession 路径
      UserIdentifier.setLoginUserId('cdp-B', '', ctx)

      let newSessionId = Session.getSessionId(ctx)
      expect(newSessionId === oldSessionId).assertFalse()
    })
  })

  // ─── _reset 隔离验证 ──────────────────────────────────────────────────────

  describe('UserIdentifier_reset_isolation', () => {

    beforeEach(() => {
      UserIdentifier._reset()
      Session._reset()
      GrowingContext._reset()
    })

    it('_reset 应清空 users Map', 0, () => {
      let ctx = makeUserContext('t1')
      UserIdentifier.initUser(ctx)
      expect(UserIdentifier.getUser(ctx)).assertInstanceOf('Object')

      UserIdentifier._reset()

      expect(UserIdentifier.getUser(ctx)).assertUndefined()
    })

    it('_reset 应重置 userInfo 为空对象', 0, () => {
      let ctx = makeUserContext('t1')
      UserIdentifier.initUser(ctx)
      UserIdentifier._reset()

      // _reset 后重新 initUser，应读到空 userInfo
      let ctx2 = makeUserContext('t2')
      UserIdentifier.initUser(ctx2)
      expect(UserIdentifier.getUser(ctx2)!.userId).assertEqual('')
    })
  })
}
