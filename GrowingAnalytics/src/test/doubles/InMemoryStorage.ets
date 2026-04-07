import preferences from '@ohos.data.preferences'
import { IStorage } from '../../main/ets/components/interfaces/IStorage'

/**
 * IStorage 的内存实现，用于本地单元测试
 *
 * 特性：
 * - 基于 Map，无任何平台 API 依赖
 * - 提供 clear() 方法，供 beforeEach 调用重置状态
 * - 完全同步，无需 Context
 */
export class InMemoryStorage implements IStorage {
  private store: Map<string, preferences.ValueType> = new Map()

  async put(key: string, value: preferences.ValueType): Promise<void> {
    this.store.set(key, value)
  }

  getValue(key: string, defValue: preferences.ValueType = ''): preferences.ValueType {
    return this.store.has(key) ? this.store.get(key)! : defValue
  }

  /** 测试辅助：清空所有存储数据 */
  clear(): void {
    this.store.clear()
  }

  /** 测试辅助：获取当前存储内容（断言用） */
  snapshot(): Map<string, preferences.ValueType> {
    return new Map(this.store)
  }
}
