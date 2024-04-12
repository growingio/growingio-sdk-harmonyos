/**
 * @license
 * Copyright (C) 2023 Beijing Yishu Technology Co., Ltd.
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

import util from '@ohos.util'
import GrowingContext from '../core/Context'

import Event from './Event'

export default class EventPersistence {
  uuid: string
  data: string
  eventType: string
  sdkVersion: string
  accountId: string
  dataSourceId: string

  constructor(
    uuid: string,
    data: string,
    eventType: string,
    sdkVersion: string,
    accountId: string,
    dataSourceId: string
  ) {
    this.uuid = uuid
    this.data = data
    this.eventType = eventType
    this.sdkVersion = sdkVersion
    this.accountId = accountId
    this.dataSourceId = dataSourceId
  }

  static fromEvent<T extends Event>(
    event: T,
    context: GrowingContext
  ): EventPersistence {
    let uuid = util.generateRandomUUID(false)
    let data = event.toSerialize()
    let eventType = event.eventType
    let sdkVersion = event.sdkVersion
    let accountId = context.config.accountId
    let dataSourceId = context.config.dataSourceId
    let e = new EventPersistence(uuid, data, eventType, sdkVersion, accountId, dataSourceId)
    return e
  }

  static fromDatabase(
    uuid: string,
    data: string,
    eventType: string,
    sdkVersion: string,
    accountId: string,
    dataSourceId: string
  ): EventPersistence {
    let e = new EventPersistence(uuid, data, eventType, sdkVersion, accountId, dataSourceId)
    return e
  }
}