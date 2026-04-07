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

import rcp from '@hms.collaboration.rcp'
import EventPersistence from '../event/EventPersistence'
import GrowingContext from '../core/Context'

/**
 * 网络请求接口
 *
 * 生产实现：Network（基于 @hms.collaboration.rcp）
 * 测试实现：FakeNetwork（预设响应队列，记录发出的请求）
 */
export interface INetwork {
  request(
    events: EventPersistence[],
    urlPath: string,
    context: GrowingContext
  ): Promise<rcp.Response>
}
