import { describe, it, expect, beforeEach } from '@ohos/hypium'
import GrowingContext from '../../main/ets/components/core/Context'
import { GrowingConfig, ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'

function makeConfig(
  accountId: string,
  dataSourceId: string,
  mode: ConfigMode = ConfigMode.NewSaaS
): GrowingConfig {
  let config = new GrowingConfig()
  config.accountId = accountId
  config.dataSourceId = dataSourceId
  config.mode = mode
  config.urlScheme = 'growing.test'
  config.dataCollectionServerHost = 'https://test.growingio.com'
  return config
}

/**
 * GrowingContext 测试策略说明：
 *
 * GrowingContext 构造函数内部会创建 EventSender 对象并注册 emitter 监听，
 * 但这些监听在测试期间不会被触发，不影响测试安全性。
 *
 * 本套测试覆盖：
 *   1. contexts Map 的增删查管理
 *   2. defaultContext 的设置与判断
 *   3. hasSimilarContext 的去重逻辑
 *   4. SaaS 模式下 EventSender 的数量差异
 *   5. _reset() 的隔离保证
 */
export default function contextTests() {

  // ─── 初始状态 ─────────────────────────────────────────────────────────────

  describe('Context_initialState', () => {

    beforeEach(() => {
      GrowingContext._reset()
    })

    it('初始 contexts 应为空', 0, () => {
      expect(GrowingContext.contexts.size).assertEqual(0)
    })

    it('初始 defaultContext 应为 undefined', 0, () => {
      expect(GrowingContext.getDefaultContext()).assertUndefined()
    })
  })

  // ─── setContext / getContext ──────────────────────────────────────────────

  describe('Context_setAndGetContext', () => {

    beforeEach(() => {
      GrowingContext._reset()
    })

    it('setContext 后 getContext 应返回对应 context', 0, () => {
      let config = makeConfig('acct-1', 'ds-1')
      GrowingContext.setContext('tracker-1', config)

      let ctx = GrowingContext.getContext('tracker-1')
      expect(ctx).assertInstanceOf('Object')
      expect(ctx!.trackerId).assertEqual('tracker-1')
      expect(ctx!.config.accountId).assertEqual('acct-1')
    })

    it('多个 tracker 应互不影响', 0, () => {
      GrowingContext.setContext('tracker-A', makeConfig('acct-A', 'ds-A'))
      GrowingContext.setContext('tracker-B', makeConfig('acct-B', 'ds-B'))

      expect(GrowingContext.getContext('tracker-A')!.config.accountId).assertEqual('acct-A')
      expect(GrowingContext.getContext('tracker-B')!.config.accountId).assertEqual('acct-B')
    })

    it('getContext 查询不存在的 trackerId 应返回 undefined', 0, () => {
      GrowingContext.setContext('tracker-1', makeConfig('a', 'b'))
      expect(GrowingContext.getContext('nonexistent')).assertUndefined()
    })

    it('contexts.size 应随 setContext 增长', 0, () => {
      GrowingContext.setContext('t1', makeConfig('a1', 'd1'))
      GrowingContext.setContext('t2', makeConfig('a2', 'd2'))
      expect(GrowingContext.contexts.size).assertEqual(2)
    })

    it('同一 trackerId 重复 setContext 应覆盖（size 不变）', 0, () => {
      GrowingContext.setContext('t1', makeConfig('a1', 'd1'))
      GrowingContext.setContext('t1', makeConfig('a2', 'd2'))
      expect(GrowingContext.contexts.size).assertEqual(1)
      expect(GrowingContext.getContext('t1')!.config.accountId).assertEqual('a2')
    })
  })

  // ─── setDefaultContext / getDefaultContext / isDefaultContext ─────────────

  describe('Context_defaultContext', () => {

    beforeEach(() => {
      GrowingContext._reset()
    })

    it('setDefaultContext 后 getDefaultContext 应返回该 context', 0, () => {
      let config = makeConfig('acct-main', 'ds-main')
      GrowingContext.setDefaultContext(config)

      let ctx = GrowingContext.getDefaultContext()
      expect(ctx).assertInstanceOf('Object')
      expect(ctx!.config.accountId).assertEqual('acct-main')
    })

    it('defaultContext 的 trackerId 应为 MAIN_TRACKER_ID', 0, () => {
      GrowingContext.setDefaultContext(makeConfig('a', 'b'))
      let ctx = GrowingContext.getDefaultContext()!
      expect(ctx.trackerId).assertEqual('__GrowingAnalyticsCore')
    })

    it('defaultContext 同时注册到 contexts Map', 0, () => {
      GrowingContext.setDefaultContext(makeConfig('a', 'b'))
      let ctx = GrowingContext.getContext('__GrowingAnalyticsCore')
      expect(ctx).assertInstanceOf('Object')
    })

    it('isDefaultContext 对 defaultContext 返回 true', 0, () => {
      GrowingContext.setDefaultContext(makeConfig('a', 'b'))
      let ctx = GrowingContext.getDefaultContext()!
      expect(GrowingContext.isDefaultContext(ctx)).assertTrue()
    })

    it('isDefaultContext 对非 defaultContext 返回 false', 0, () => {
      GrowingContext.setDefaultContext(makeConfig('a', 'b'))
      GrowingContext.setContext('sub-tracker', makeConfig('c', 'd'))
      let subCtx = GrowingContext.getContext('sub-tracker')!
      expect(GrowingContext.isDefaultContext(subCtx)).assertFalse()
    })
  })

  // ─── hasSimilarContext ───────────────────────────────────────────────────

  describe('Context_hasSimilarContext', () => {

    beforeEach(() => {
      GrowingContext._reset()
    })

    it('contexts 为空时应返回 false', 0, () => {
      let config = makeConfig('a', 'b')
      expect(GrowingContext.hasSimilarContext('t1', config)).assertFalse()
    })

    it('相同 trackerId 应判定为 similar', 0, () => {
      GrowingContext.setContext('tracker-1', makeConfig('acct-A', 'ds-A'))

      let newConfig = makeConfig('acct-B', 'ds-B')
      expect(GrowingContext.hasSimilarContext('tracker-1', newConfig)).assertTrue()
    })

    it('不同 trackerId 但相同 accountId+dataSourceId 应判定为 similar', 0, () => {
      GrowingContext.setContext('tracker-1', makeConfig('acct-A', 'ds-A'))

      let newConfig = makeConfig('acct-A', 'ds-A')
      expect(GrowingContext.hasSimilarContext('tracker-2', newConfig)).assertTrue()
    })

    it('不同 trackerId 且不同 accountId+dataSourceId 应返回 false', 0, () => {
      GrowingContext.setContext('tracker-1', makeConfig('acct-A', 'ds-A'))

      let newConfig = makeConfig('acct-B', 'ds-B')
      expect(GrowingContext.hasSimilarContext('tracker-2', newConfig)).assertFalse()
    })

    it('accountId 相同但 dataSourceId 不同应返回 false', 0, () => {
      GrowingContext.setContext('tracker-1', makeConfig('acct-A', 'ds-1'))

      let newConfig = makeConfig('acct-A', 'ds-2')
      expect(GrowingContext.hasSimilarContext('tracker-2', newConfig)).assertFalse()
    })

    it('多个 context 中只要有一个匹配就应返回 true', 0, () => {
      GrowingContext.setContext('t1', makeConfig('a1', 'd1'))
      GrowingContext.setContext('t2', makeConfig('a2', 'd2'))
      GrowingContext.setContext('t3', makeConfig('a3', 'd3'))

      let newConfig = makeConfig('a2', 'd2')
      expect(GrowingContext.hasSimilarContext('t-new', newConfig)).assertTrue()
    })
  })

  // ─── EventSender 数量（SaaS vs NewSaaS）──────────────────────────────────

  describe('Context_eventSender_count', () => {

    beforeEach(() => {
      GrowingContext._reset()
    })

    it('NewSaaS 模式应创建 1 个 EventSender', 0, () => {
      GrowingContext.setContext('t1', makeConfig('a', 'b', ConfigMode.NewSaaS))
      let ctx = GrowingContext.getContext('t1')!
      expect(ctx.eventSender.length).assertEqual(1)
    })

    it('CDP 模式应创建 1 个 EventSender', 0, () => {
      GrowingContext.setContext('t1', makeConfig('a', 'b', ConfigMode.CDP))
      let ctx = GrowingContext.getContext('t1')!
      expect(ctx.eventSender.length).assertEqual(1)
    })

    it('SaaS 模式应创建 3 个 EventSender（PV + CSTM + OTHER）', 0, () => {
      GrowingContext.setContext('t1', makeConfig('a', 'b', ConfigMode.SaaS))
      let ctx = GrowingContext.getContext('t1')!
      expect(ctx.eventSender.length).assertEqual(3)
    })
  })

  // ─── _reset 隔离验证 ──────────────────────────────────────────────────────

  describe('Context_reset_isolation', () => {

    beforeEach(() => {
      GrowingContext._reset()
    })

    it('_reset 应清空 contexts Map', 0, () => {
      GrowingContext.setContext('t1', makeConfig('a', 'b'))
      GrowingContext.setContext('t2', makeConfig('c', 'd'))
      GrowingContext._reset()
      expect(GrowingContext.contexts.size).assertEqual(0)
    })

    it('_reset 应清空 defaultContext', 0, () => {
      GrowingContext.setDefaultContext(makeConfig('a', 'b'))
      GrowingContext._reset()
      expect(GrowingContext.getDefaultContext()).assertUndefined()
    })

    it('_reset 后 getContext 应返回 undefined', 0, () => {
      GrowingContext.setContext('t1', makeConfig('a', 'b'))
      GrowingContext._reset()
      expect(GrowingContext.getContext('t1')).assertUndefined()
    })
  })
}
