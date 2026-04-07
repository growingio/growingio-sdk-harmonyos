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

import EventPersistence from '../event/EventPersistence'
import GrowingContext from '../core/Context'

/**
 * 事件本地存储接口
 *
 * 生产实现：EventDatabase（基于 @ohos.data.relationalStore 加密 RDB）
 * 测试实现：InMemoryEventStore（基于数组，无平台依赖）
 */
export interface IEventStore {
  getEventsByCount(
    maxCount: number,
    maxSize: number,
    context: GrowingContext,
    eventTypes?: string[]
  ): Promise<EventPersistence[]>

  removeEvents(events: EventPersistence[]): Promise<void>

  countOfEvents(
    context: GrowingContext,
    eventTypes?: string[]
  ): Promise<number>
}
