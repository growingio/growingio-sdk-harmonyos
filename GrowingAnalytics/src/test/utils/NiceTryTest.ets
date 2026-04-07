import { describe, it, expect } from '@ohos/hypium'
import { niceTry, niceTryAsync } from '../../main/ets/components/utils/Util'

export default function niceTryTests() {

  describe('niceTry - 同步版本', () => {

    it('执行成功时应返回函数结果', 0, () => {
      let result = niceTry(() => 42)
      expect(result).assertEqual(42)
    })

    it('执行成功时返回字符串', 0, () => {
      let result = niceTry(() => 'hello')
      expect(result).assertEqual('hello')
    })

    it('抛出异常且无 fallback 时应返回 undefined', 0, () => {
      let result = niceTry(() => {
        throw new Error('boom')
      })
      expect(result).assertUndefined()
    })

    it('抛出异常时应返回 fallback 值（数字）', 0, () => {
      let result = niceTry(() => {
        throw new Error('fail')
      }, -1)
      expect(result).assertEqual(-1)
    })

    it('抛出异常时应返回 fallback 值（字符串）', 0, () => {
      let result = niceTry(() => {
        throw new Error('fail')
      }, 'default')
      expect(result).assertEqual('default')
    })

    it('抛出异常时应返回 fallback 值（对象）', 0, () => {
      let fallback: Record<string, string> = { key: 'safe' }
      let result = niceTry<Record<string, string>>(() => {
        throw new Error('fail')
      }, fallback)
      expect(result!['key']).assertEqual('safe')
    })

    it('函数内部访问嵌套 undefined 属性时应被安全捕获', 0, () => {
      let obj: Record<string, object> | undefined = undefined
      let result = niceTry(() => obj!['key'], 'fallback')
      expect(result).assertEqual('fallback')
    })
  })

  describe('niceTryAsync - 异步版本', () => {

    it('异步执行成功时应返回 resolved 值', 0, async (done: Function) => {
      let result = await niceTryAsync(async () => 'async-result')
      expect(result).assertEqual('async-result')
      done()
    })

    it('异步抛出异常且无 fallback 时应返回 undefined', 0, async (done: Function) => {
      let result = await niceTryAsync(async () => {
        throw new Error('async fail')
      })
      expect(result).assertUndefined()
      done()
    })

    it('异步抛出异常时应返回 fallback', 0, async (done: Function) => {
      let result = await niceTryAsync(async () => {
        throw new Error('async fail')
      }, 'safe-fallback')
      expect(result).assertEqual('safe-fallback')
      done()
    })

    it('Promise.reject 时应返回 fallback', 0, async (done: Function) => {
      let result = await niceTryAsync(() => Promise.reject(new Error('rejected')), 0)
      expect(result).assertEqual(0)
      done()
    })
  })
}
