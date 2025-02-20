/**
 * @license
 * Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.
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

export class Queue<T> {
  data: Array<T> = []

  isLimit: boolean
  limitSize: number

  constructor(limitSize: number) {
    this.isLimit = true
    this.limitSize = limitSize > 0 ? limitSize : 50
  }

  dequeue(): Array<T> {
    let data = [...this.data]
    this.data = []
    return data
  }

  enqueue(d: T) {
    if (this.isLimit) {
      while (this.data.length > this.limitSize) {
        this.data.shift()
      }
    }
    this.data.push(d)
  }
}