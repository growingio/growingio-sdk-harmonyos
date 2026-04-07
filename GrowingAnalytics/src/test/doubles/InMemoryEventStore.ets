import EventPersistence from '../../main/ets/components/event/EventPersistence'
import GrowingContext from '../../main/ets/components/core/Context'
import { IEventStore } from '../../main/ets/components/interfaces/IEventStore'
import Util from '../../main/ets/components/utils/Util'

/**
 * IEventStore 的内存实现，用于本地单元测试
 *
 * 特性：
 * - 基于数组，无 RDB / relationalStore 依赖
 * - 支持按 eventTypes 过滤（与 EventDatabase.getEventsByCount 行为一致）
 * - 支持按字节大小限制（简化实现：按 JSON 字节累计）
 * - 提供 clear() 方法供 beforeEach 使用
 * - 公开 events 数组供测试断言
 */
export class InMemoryEventStore implements IEventStore {
  events: EventPersistence[] = []

  async getEventsByCount(
    maxCount: number,
    maxSize: number,
    context: GrowingContext,
    eventTypes?: string[]
  ): Promise<EventPersistence[]> {
    let filtered = this.events.filter(e => {
      let accountMatch = e.accountId === context.config.accountId
      let typeMatch = eventTypes ? eventTypes.includes(e.eventType) : true
      return accountMatch && typeMatch
    })

    let result: EventPersistence[] = []
    let totalBytes = 0
    for (let event of filtered) {
      if (result.length >= maxCount) {
        break
      }
      let bytes = Util.sizeOfEventString(event.data)
      if (totalBytes + bytes > maxSize) {
        break
      }
      result.push(event)
      totalBytes += bytes
    }
    return result
  }

  async removeEvents(toRemove: EventPersistence[]): Promise<void> {
    let uuids: Set<string> = new Set(toRemove.map(e => e.uuid))
    this.events = this.events.filter(e => !uuids.has(e.uuid))
  }

  async countOfEvents(
    context: GrowingContext,
    eventTypes?: string[]
  ): Promise<number> {
    return this.events.filter(e => {
      let accountMatch = e.accountId === context.config.accountId
      let typeMatch = eventTypes ? eventTypes.includes(e.eventType) : true
      return accountMatch && typeMatch
    }).length
  }

  /** 测试辅助：直接插入事件（不经过 context 校验） */
  inject(event: EventPersistence): void {
    this.events.push(event)
  }

  /** 测试辅助：清空所有事件 */
  clear(): void {
    this.events = []
  }
}
