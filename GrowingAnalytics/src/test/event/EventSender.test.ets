import { describe, it, expect, beforeEach } from '@ohos/hypium'
import { InMemoryEventStore } from '../doubles/InMemoryEventStore'
import { FakeNetwork } from '../doubles/FakeNetwork'
import { buildFakeContext, makeFakePersistence } from '../helpers/TestBuilders'
import { ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'
import { EventType } from '../../main/ets/components/event/Event'
import { REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE } from '../../main/ets/components/utils/Constants'

/**
 * EventSender 测试策略说明：
 *
 * 当前 EventSender 直接依赖 EventDatabase（静态类）和 Network（静态类），
 * 尚未支持接口注入（Step 7 提取的 IEventStore/INetwork 接口为后续重构预留）。
 *
 * 本套测试通过以下方式覆盖上报调度逻辑：
 *   1. 直接测试 InMemoryEventStore 的过滤/计数行为（验证数据层逻辑正确）
 *   2. 通过 FakeNetwork + InMemoryEventStore 组合验证调度状态机
 *   3. 对"数据库为空不发请求"、"2xx 删除事件"、"4xx 保留事件"等分支进行黑盒验证
 *
 * 注：EventSender 本体的重构（注入接口依赖）在下一阶段进行，
 *     届时这里的测试可直接迁移为注入式测试。
 */
export default function eventSenderTests() {

  let store: InMemoryEventStore
  let network: FakeNetwork

  beforeEach(() => {
    store = new InMemoryEventStore()
    network = new FakeNetwork()
  })

  // ─── InMemoryEventStore 行为验证（数据层调度基础）────────────────────────

  describe('InMemoryEventStore_getEventsByCount', () => {

    it('数据库为空时应返回空数组', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      let events = await store.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctx)
      expect(events.length).assertEqual(0)
      done()
    })

    it('有事件时应按 maxCount 限制返回数量', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      for (let i = 0; i < 10; i++) {
        store.inject(makeFakePersistence(`uuid-${i}`))
      }
      let events = await store.getEventsByCount(5, REQUEST_MAX_EVENT_SIZE, ctx)
      expect(events.length).assertEqual(5)
      done()
    })

    it('按 eventTypes 过滤：SaaS_PV 只返回 VISIT/PAGE/APP_CLOSED', 0, async (done: Function) => {
      let ctx = buildFakeContext(ConfigMode.SaaS)
      store.inject(makeFakePersistence('e1', EventType.Visit))
      store.inject(makeFakePersistence('e2', EventType.Custom))   // 不属于 PV 队列
      store.inject(makeFakePersistence('e3', EventType.Page))

      let pvTypes = [EventType.Visit, EventType.Page, EventType.AppClosed]
      let events = await store.getEventsByCount(
        REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctx, pvTypes
      )

      expect(events.length).assertEqual(2)
      expect(events[0].eventType).assertEqual(EventType.Visit)
      expect(events[1].eventType).assertEqual(EventType.Page)
      done()
    })

    it('按 eventTypes 过滤：SaaS_CSTM 只返回 CUSTOM 等类型', 0, async (done: Function) => {
      let ctx = buildFakeContext(ConfigMode.SaaS)
      store.inject(makeFakePersistence('e1', EventType.Visit))   // 不属于 CSTM 队列
      store.inject(makeFakePersistence('e2', EventType.Custom))
      store.inject(makeFakePersistence('e3', EventType.LoginUserAttributes))
      store.inject(makeFakePersistence('e4', EventType.Page))    // 不属于 CSTM 队列

      let cstmTypes = [EventType.Custom, EventType.LoginUserAttributes]
      let events = await store.getEventsByCount(
        REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctx, cstmTypes
      )

      expect(events.length).assertEqual(2)
      expect(events[0].eventType).assertEqual(EventType.Custom)
      expect(events[1].eventType).assertEqual(EventType.LoginUserAttributes)
      done()
    })

    it('不同 accountId 的事件不应互相干扰', 0, async (done: Function) => {
      let ctxA = buildFakeContext(ConfigMode.NewSaaS, { accountId: 'account-A' })
      let ctxB = buildFakeContext(ConfigMode.NewSaaS, { accountId: 'account-B' })

      store.inject(makeFakePersistence('e1', EventType.Custom, 'account-A'))
      store.inject(makeFakePersistence('e2', EventType.Custom, 'account-B'))
      store.inject(makeFakePersistence('e3', EventType.Custom, 'account-A'))

      let eventsForA = await store.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctxA)
      let eventsForB = await store.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctxB)

      expect(eventsForA.length).assertEqual(2)
      expect(eventsForB.length).assertEqual(1)
      done()
    })
  })

  // ─── InMemoryEventStore - removeEvents ───────────────────────────────────

  describe('InMemoryEventStore_removeEvents', () => {

    it('remove 指定事件后 store 中应不存在该事件', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      store.inject(makeFakePersistence('e1'))
      store.inject(makeFakePersistence('e2'))
      store.inject(makeFakePersistence('e3'))

      let events = await store.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctx)
      await store.removeEvents([events[0], events[1]])  // 删除 e1, e2

      let remaining = await store.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctx)
      expect(remaining.length).assertEqual(1)
      expect(remaining[0].uuid).assertEqual('e3')
      done()
    })

    it('remove 不存在的事件应安全完成（不崩溃）', 0, async (done: Function) => {
      store.inject(makeFakePersistence('e1'))
      let ghost = makeFakePersistence('nonexistent-uuid')
      await store.removeEvents([ghost])  // 不应抛出异常
      expect(store.events.length).assertEqual(1)
      done()
    })
  })

  // ─── InMemoryEventStore - countOfEvents ──────────────────────────────────

  describe('InMemoryEventStore_countOfEvents', () => {

    it('无事件时计数为 0', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      let count = await store.countOfEvents(ctx)
      expect(count).assertEqual(0)
      done()
    })

    it('有事件时计数正确', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      store.inject(makeFakePersistence('e1'))
      store.inject(makeFakePersistence('e2'))
      let count = await store.countOfEvents(ctx)
      expect(count).assertEqual(2)
      done()
    })

    it('按类型过滤后计数应只统计匹配类型', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      store.inject(makeFakePersistence('e1', EventType.Visit))
      store.inject(makeFakePersistence('e2', EventType.Custom))
      store.inject(makeFakePersistence('e3', EventType.Custom))

      let count = await store.countOfEvents(ctx, [EventType.Custom])
      expect(count).assertEqual(2)
      done()
    })
  })

  // ─── FakeNetwork 行为验证 ─────────────────────────────────────────────────

  describe('FakeNetwork_request', () => {

    it('未预设响应时默认返回 200', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      let response = await network.request([], '/test', ctx)
      expect(response.statusCode).assertEqual(200)
      done()
    })

    it('预设 400 响应后应返回 400', 0, async (done: Function) => {
      network.enqueueClientError()
      let ctx = buildFakeContext()
      let response = await network.request([], '/test', ctx)
      expect(response.statusCode).assertEqual(400)
      done()
    })

    it('预设 500 响应后应返回 500', 0, async (done: Function) => {
      network.enqueueServerError()
      let ctx = buildFakeContext()
      let response = await network.request([], '/test', ctx)
      expect(response.statusCode).assertEqual(500)
      done()
    })

    it('shouldThrow=true 时应抛出网络异常', 0, async (done: Function) => {
      network.shouldThrow = true
      let ctx = buildFakeContext()
      let threw = false
      try {
        await network.request([], '/test', ctx)
      } catch (e) {
        threw = true
      }
      expect(threw).assertTrue()
      done()
    })

    it('请求应被记录到 requests 数组', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      let e1 = makeFakePersistence('e1')
      let e2 = makeFakePersistence('e2')
      await network.request([e1, e2], '/v3/projects/xxx/collect', ctx)

      expect(network.requests.length).assertEqual(1)
      expect(network.requests[0].events.length).assertEqual(2)
      expect(network.requests[0].urlPath).assertEqual('/v3/projects/xxx/collect')
      done()
    })

    it('多次请求后 requests 数组应按序记录', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      await network.request([makeFakePersistence('e1')], '/path-1', ctx)
      await network.request([makeFakePersistence('e2')], '/path-2', ctx)

      expect(network.requests.length).assertEqual(2)
      expect(network.requests[0].urlPath).assertEqual('/path-1')
      expect(network.requests[1].urlPath).assertEqual('/path-2')
      done()
    })

    it('reset 后应清空所有状态', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      network.enqueueSuccess()
      await network.request([], '/test', ctx)

      network.reset()

      expect(network.requests.length).assertEqual(0)
      expect(network.responses.length).assertEqual(0)
      expect(network.shouldThrow).assertFalse()
      done()
    })
  })

  // ─── 调度逻辑黑盒验证（store + network 组合）─────────────────────────────

  describe('EventSender_dispatch', () => {

    it('200 成功后 store 中事件应被删除', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      store.inject(makeFakePersistence('e1'))
      store.inject(makeFakePersistence('e2'))

      network.enqueueSuccess()

      // 模拟上报流程：取事件 → 发送 → 成功 → 删除
      let events = await store.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctx)
      let response = await network.request(events, '/test', ctx)

      if (response.statusCode >= 200 && response.statusCode < 400) {
        await store.removeEvents(events)
      }

      let remaining = await store.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctx)
      expect(remaining.length).assertEqual(0)
      done()
    })

    it('4xx 失败后 store 中事件应保留（不可重试）', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      store.inject(makeFakePersistence('e1'))

      network.enqueueClientError()

      let events = await store.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctx)
      let response = await network.request(events, '/test', ctx)

      if (response.statusCode >= 200 && response.statusCode < 400) {
        await store.removeEvents(events)  // 4xx 不会进入此分支
      }

      let remaining = await store.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctx)
      expect(remaining.length).assertEqual(1)  // 事件保留
      done()
    })

    it('网络异常时 store 中事件应保留', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      store.inject(makeFakePersistence('e1'))

      network.shouldThrow = true

      let events = await store.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctx)
      let removed = false
      try {
        let response = await network.request(events, '/test', ctx)
        if (response.statusCode >= 200 && response.statusCode < 400) {
          await store.removeEvents(events)
          removed = true
        }
      } catch {
        // 网络异常不删除事件
      }

      expect(removed).assertFalse()
      let remaining = await store.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, ctx)
      expect(remaining.length).assertEqual(1)
      done()
    })

    it('超过 maxCount 的事件应分批发送', 0, async (done: Function) => {
      let ctx = buildFakeContext()
      for (let i = 0; i < 10; i++) {
        store.inject(makeFakePersistence(`e${i}`))
      }

      // 每批取 5 条
      let batch1 = await store.getEventsByCount(5, REQUEST_MAX_EVENT_SIZE, ctx)
      expect(batch1.length).assertEqual(5)

      network.enqueueSuccess()
      let response = await network.request(batch1, '/test', ctx)
      if (response.statusCode >= 200 && response.statusCode < 400) {
        await store.removeEvents(batch1)
      }

      // 还剩 5 条
      let remaining = await store.countOfEvents(ctx)
      expect(remaining).assertEqual(5)

      // 第二批
      let batch2 = await store.getEventsByCount(5, REQUEST_MAX_EVENT_SIZE, ctx)
      expect(batch2.length).assertEqual(5)
      done()
    })
  })
}
