import rcp from '@hms.collaboration.rcp'
import EventPersistence from '../../main/ets/components/event/EventPersistence'
import GrowingContext from '../../main/ets/components/core/Context'
import { INetwork } from '../../main/ets/components/interfaces/INetwork'

/** 记录 FakeNetwork 收到的请求，供测试断言验证 */
export interface SentRequest {
  events: EventPersistence[]
  urlPath: string
}

/**
 * INetwork 的测试替身，用于本地单元测试
 *
 * 特性：
 * - 预设响应队列（responses）：依次弹出返回，模拟各种 HTTP 状态码
 * - 请求记录数组（requests）：记录所有已发出的请求，供 expect 断言
 * - 支持模拟网络异常（通过 shouldThrow 标志）
 * - 提供 reset() 方法供 beforeEach 使用
 */
export class FakeNetwork implements INetwork {
  /** 预设的响应队列，按顺序返回；队列为空时默认返回 200 */
  responses: Array<{ statusCode: number }> = []

  /** 是否在下次请求时抛出网络异常（模拟超时/断网） */
  shouldThrow: boolean = false

  /** 已发出的请求记录 */
  requests: SentRequest[] = []

  async request(
    events: EventPersistence[],
    urlPath: string,
    context: GrowingContext
  ): Promise<rcp.Response> {
    this.requests.push({ events: [...events], urlPath })

    if (this.shouldThrow) {
      throw new Error('FakeNetwork: simulated network error')
    }

    let preset = this.responses.shift()
    let statusCode = preset?.statusCode ?? 200

    // 构造最小 rcp.Response 替身
    return {
      statusCode,
      request: {
        url: 'https://fake.growingio.com' + urlPath,
        content: JSON.stringify(events.map(e => e.data))
      }
    } as unknown as rcp.Response
  }

  /** 预设一个成功响应（200）*/
  enqueueSuccess(): void {
    this.responses.push({ statusCode: 200 })
  }

  /** 预设一个客户端错误响应（400）*/
  enqueueClientError(): void {
    this.responses.push({ statusCode: 400 })
  }

  /** 预设一个服务端错误响应（500）*/
  enqueueServerError(): void {
    this.responses.push({ statusCode: 500 })
  }

  /** 测试辅助：重置所有状态 */
  reset(): void {
    this.responses = []
    this.requests = []
    this.shouldThrow = false
  }
}
