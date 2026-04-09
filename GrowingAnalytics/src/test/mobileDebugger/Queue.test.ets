/**
 * @license
 * Copyright (C) 2024 Beijing Yishu Technology Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { describe, it, expect } from '@ohos/hypium'
import { Queue } from '../../main/ets/components/mobileDebugger/Queue'

/**
 * Queue<T> 测试策略说明：
 *
 * Queue 是 MobileDebugger 的内部事件/日志缓冲区，
 * 核心行为：
 *   1. enqueue：追加到末尾；超过 limitSize 时从头部丢弃最旧条目
 *   2. dequeue：返回全部数据快照并清空缓冲区
 *   3. limitSize ≤ 0 时回退为默认值 50
 *
 * 无外部依赖，纯数据结构。
 */
export default function queueTests() {

  // ─── 基础入队 / 出队 ──────────────────────────────────────────────────────

  describe('Queue_basic', () => {

    it('enqueue 后 data 长度增加', 0, () => {
      let q = new Queue<string>(10)
      q.enqueue('a')
      q.enqueue('b')
      expect(q.data.length).assertEqual(2)
    })

    it('dequeue 返回所有已入队元素', 0, () => {
      let q = new Queue<number>(10)
      q.enqueue(1)
      q.enqueue(2)
      q.enqueue(3)
      let result = q.dequeue()
      expect(result.length).assertEqual(3)
      expect(result[0]).assertEqual(1)
      expect(result[1]).assertEqual(2)
      expect(result[2]).assertEqual(3)
    })

    it('dequeue 后缓冲区清空', 0, () => {
      let q = new Queue<string>(10)
      q.enqueue('x')
      q.dequeue()
      expect(q.data.length).assertEqual(0)
    })

    it('空队列 dequeue 返回空数组', 0, () => {
      let q = new Queue<string>(10)
      let result = q.dequeue()
      expect(result.length).assertEqual(0)
    })

    it('dequeue 返回快照，后续 enqueue 不影响已返回数组', 0, () => {
      let q = new Queue<number>(10)
      q.enqueue(1)
      let snapshot = q.dequeue()
      q.enqueue(2)
      expect(snapshot.length).assertEqual(1)
    })
  })

  // ─── 容量上限（isLimit = true）────────────────────────────────────────────

  describe('Queue_limit', () => {

    it('入队数量未超过 limitSize 时不丢弃任何条目', 0, () => {
      let q = new Queue<number>(3)
      q.enqueue(1)
      q.enqueue(2)
      q.enqueue(3)
      expect(q.data.length).assertEqual(3)
    })

    it('入队数量超过 limitSize 时丢弃最旧条目', 0, () => {
      let q = new Queue<number>(3)
      q.enqueue(1)
      q.enqueue(2)
      q.enqueue(3)
      q.enqueue(4) // 此时 data.length(3) > limitSize(3) 不成立，所以 4 被追加后长度为 4
      // 注：while (data.length > limitSize) 在 push 前执行
      // 入队第 4 个前：length=3，不满足 >3，不丢弃；push 后 length=4
      // 入队第 5 个前：length=4 > 3，shift 一次变为 3；push 后 length=4
      q.enqueue(5)
      let result = q.dequeue()
      // 最终应保留 [2, 3, 4, 5] 中的最新 4 项（limitSize=3，push 后最多 4 项）
      // 实际：enqueue(5) 前先 shift 一次（丢掉 1），再 push(5)
      expect(result.indexOf(1)).assertEqual(-1) // 最旧的 1 已被丢弃
      expect(result[result.length - 1]).assertEqual(5) // 最新的 5 在末尾
    })

    it('limitSize=1 时始终只保留最新的两项（shift 在 push 之前执行）', 0, () => {
      let q = new Queue<string>(1)
      q.enqueue('a') // length=1, 不超过 1, push → ['a']
      q.enqueue('b') // length=1, 不超过 1, push → ['a','b']
      q.enqueue('c') // length=2 > 1, shift → ['b'], push → ['b','c']
      q.enqueue('d') // length=2 > 1, shift → ['c'], push → ['c','d']
      let result = q.dequeue()
      expect(result.indexOf('a')).assertEqual(-1)
      expect(result.indexOf('b')).assertEqual(-1)
      expect(result[result.length - 1]).assertEqual('d')
    })
  })

  // ─── limitSize 边界值 ────────────────────────────────────────────────────

  describe('Queue_limitSize', () => {

    it('limitSize=0 时回退为默认值 50', 0, () => {
      let q = new Queue<number>(0)
      expect(q.limitSize).assertEqual(50)
    })

    it('limitSize 为负数时回退为默认值 50', 0, () => {
      let q = new Queue<number>(-10)
      expect(q.limitSize).assertEqual(50)
    })

    it('limitSize=1 时 limitSize 正确存储', 0, () => {
      let q = new Queue<number>(1)
      expect(q.limitSize).assertEqual(1)
    })
  })
}
