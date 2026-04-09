import { describe, it, expect } from '@ohos/hypium'
import rcp from '@hms.collaboration.rcp'
import { runSendCycle, SendResult } from '../../main/ets/components/event/EventSender'
import { makeFakePersistence } from '../helpers/TestBuilders'
import { REQUEST_MAX_EVENT_COUNT } from '../../main/ets/components/utils/Constants'
import EventPersistence from '../../main/ets/components/event/EventPersistence'

/** 构造测试用的最小 SendResult */
function fakeSendResult(statusCode: number): SendResult {
  let request = new rcp.Request('https://fake.growingio.com/collect')
  return { statusCode: statusCode, request: request } as SendResult
}

export default function eventSendCycleTests() {

  describe('runSendCycle_emptyStore', () => {

    it('DB 为空时不调用 sendEvents，返回 false', 0, async (done: Function) => {
      let sendCalled = false

      const hasMore = await runSendCycle({
        fetchEvents: () => Promise.resolve([] as EventPersistence[]),
        sendEvents: async (_events: EventPersistence[]): Promise<SendResult> => {
          sendCalled = true
          return fakeSendResult(200)
        },
        removeEvents: (_events: EventPersistence[]) => Promise.resolve(),
        afterRemove: (_events: EventPersistence[], _request: rcp.Request) => {},
        countRemaining: () => Promise.resolve(0)
      })

      expect(hasMore).assertFalse()
      expect(sendCalled).assertFalse()
      done()
    })
  })

  describe('runSendCycle_successPath', () => {

    it('200 成功后调用 removeEvents，无剩余时返回 false', 0, async (done: Function) => {
      const e1 = makeFakePersistence('e1')
      const e2 = makeFakePersistence('e2')
      let removedEvents: EventPersistence[] = []

      const hasMore = await runSendCycle({
        fetchEvents: () => Promise.resolve([e1, e2]),
        sendEvents: async (_events: EventPersistence[]): Promise<SendResult> => fakeSendResult(200),
        removeEvents: (events: EventPersistence[]) => {
          removedEvents = events
          return Promise.resolve()
        },
        afterRemove: (_events: EventPersistence[], _request: rcp.Request) => {},
        countRemaining: () => Promise.resolve(0)
      })

      expect(hasMore).assertFalse()
      expect(removedEvents.length).assertEqual(2)
      expect(removedEvents[0].uuid).assertEqual('e1')
      expect(removedEvents[1].uuid).assertEqual('e2')
      done()
    })

    it('200 成功后剩余事件超过 maxCount 时返回 true', 0, async (done: Function) => {
      const hasMore = await runSendCycle({
        fetchEvents: () => Promise.resolve([makeFakePersistence('e1')]),
        sendEvents: async (_events: EventPersistence[]): Promise<SendResult> => fakeSendResult(200),
        removeEvents: (_events: EventPersistence[]) => Promise.resolve(),
        afterRemove: (_events: EventPersistence[], _request: rcp.Request) => {},
        countRemaining: () => Promise.resolve(REQUEST_MAX_EVENT_COUNT + 1)
      })

      expect(hasMore).assertTrue()
      done()
    })

    it('302 也属于成功范围，应触发 removeEvents', 0, async (done: Function) => {
      let removeCalled = false

      await runSendCycle({
        fetchEvents: () => Promise.resolve([makeFakePersistence('e1')]),
        sendEvents: async (_events: EventPersistence[]): Promise<SendResult> => fakeSendResult(302),
        removeEvents: (_events: EventPersistence[]) => {
          removeCalled = true
          return Promise.resolve()
        },
        afterRemove: (_events: EventPersistence[], _request: rcp.Request) => {},
        countRemaining: () => Promise.resolve(0)
      })

      expect(removeCalled).assertTrue()
      done()
    })
  })

  describe('runSendCycle_afterRemove', () => {

    it('afterRemove 应在 removeEvents 之后调用，并收到 request', 0, async (done: Function) => {
      const callOrder: string[] = []
      let receivedRequest: rcp.Request | null = null

      await runSendCycle({
        fetchEvents: () => Promise.resolve([makeFakePersistence('e1')]),
        sendEvents: async (_events: EventPersistence[]): Promise<SendResult> => fakeSendResult(200),
        removeEvents: (_events: EventPersistence[]) => {
          callOrder.push('remove')
          return Promise.resolve()
        },
        afterRemove: (_events: EventPersistence[], request: rcp.Request) => {
          callOrder.push('afterRemove')
          receivedRequest = request
        },
        countRemaining: () => Promise.resolve(0)
      })

      expect(callOrder[0]).assertEqual('remove')
      expect(callOrder[1]).assertEqual('afterRemove')
      expect(receivedRequest !== null).assertTrue()
      done()
    })

    it('发送失败时不调用 afterRemove', 0, async (done: Function) => {
      let afterRemoveCalled = false

      await runSendCycle({
        fetchEvents: () => Promise.resolve([makeFakePersistence('e1')]),
        sendEvents: async (_events: EventPersistence[]): Promise<SendResult> => fakeSendResult(400),
        removeEvents: (_events: EventPersistence[]) => Promise.resolve(),
        afterRemove: (_events: EventPersistence[], _request: rcp.Request) => {
          afterRemoveCalled = true
        },
        countRemaining: () => Promise.resolve(0)
      })

      expect(afterRemoveCalled).assertFalse()
      done()
    })
  })

  describe('runSendCycle_failurePath', () => {

    it('400 失败时不调用 removeEvents，返回 false', 0, async (done: Function) => {
      let removeCalled = false

      const hasMore = await runSendCycle({
        fetchEvents: () => Promise.resolve([makeFakePersistence('e1')]),
        sendEvents: async (_events: EventPersistence[]): Promise<SendResult> => fakeSendResult(400),
        removeEvents: (_events: EventPersistence[]) => {
          removeCalled = true
          return Promise.resolve()
        },
        afterRemove: (_events: EventPersistence[], _request: rcp.Request) => {},
        countRemaining: () => Promise.resolve(0)
      })

      expect(hasMore).assertFalse()
      expect(removeCalled).assertFalse()
      done()
    })

    it('500 失败时不调用 removeEvents，返回 false', 0, async (done: Function) => {
      let removeCalled = false

      const hasMore = await runSendCycle({
        fetchEvents: () => Promise.resolve([makeFakePersistence('e1')]),
        sendEvents: async (_events: EventPersistence[]): Promise<SendResult> => fakeSendResult(500),
        removeEvents: (_events: EventPersistence[]) => {
          removeCalled = true
          return Promise.resolve()
        },
        afterRemove: (_events: EventPersistence[], _request: rcp.Request) => {},
        countRemaining: () => Promise.resolve(0)
      })

      expect(hasMore).assertFalse()
      expect(removeCalled).assertFalse()
      done()
    })
  })

  describe('runSendCycle_networkException', () => {

    it('sendEvents 抛出异常时不调用 removeEvents，异常向上传播', 0, async (done: Function) => {
      let removeCalled = false
      let caught = false

      try {
        await runSendCycle({
          fetchEvents: () => Promise.resolve([makeFakePersistence('e1')]),
          sendEvents: async (_events: EventPersistence[]): Promise<SendResult> => {
            throw new Error('network timeout')
          },
          removeEvents: (_events: EventPersistence[]) => {
            removeCalled = true
            return Promise.resolve()
          },
          afterRemove: (_events: EventPersistence[], _request: rcp.Request) => {},
          countRemaining: () => Promise.resolve(0)
        })
      } catch (_e) {
        caught = true
      }

      expect(caught).assertTrue()
      expect(removeCalled).assertFalse()
      done()
    })
  })
}
