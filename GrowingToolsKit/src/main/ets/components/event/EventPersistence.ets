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

import { EventScene, GTKEventPersistence } from '../utils/Constants'

export default class EventPersistence {
  uuid: string
  data: string
  eventType: string
  accountId: string
  dataSourceId: string
  eventScene: EventScene
  createAt: number
  isSend: boolean
  private _event: Event | undefined = undefined

  constructor(
    uuid: string,
    data: string,
    eventType: string,
    accountId: string,
    dataSourceId: string,
    eventScene: EventScene,
    createAt: number = Date.now(),
    isSend: boolean = false
  ) {
    this.uuid = uuid
    this.data = data
    this.eventType = eventType
    this.accountId = accountId
    this.dataSourceId = dataSourceId
    this.eventScene = eventScene
    this.createAt = createAt
    this.isSend = isSend
  }

  static fromEvent<T extends GTKEventPersistence>(
    event: T,
    eventScene: EventScene
  ): EventPersistence {
    let uuid = event.uuid
    let data = event.data
    let eventType = event.eventType
    let accountId = event.accountId
    let dataSourceId = event.dataSourceId
    let e = new EventPersistence(uuid, data, eventType, accountId, dataSourceId, eventScene)
    return e
  }

  static fromDatabase(
    uuid: string,
    data: string,
    eventType: string,
    accountId: string,
    dataSourceId: string,
    eventScene: EventScene,
    createAt: number,
    isSend: boolean
  ): EventPersistence {
    let e = new EventPersistence(uuid, data, eventType, accountId, dataSourceId, eventScene, createAt, isSend)
    return e
  }

  sequenceId(): string {
    let e = this.getEvent()
    return String(e.eventSequenceId ?? e.esid)
  }

  path(): string | undefined {
    let e = this.getEvent()
    if (this.eventType == 'CUSTOM') {
      return String(e.eventName ?? e.n)
    } else if (this.eventType == 'PAGE') {
      return String(e.path ?? e.p)
    } else {
      return undefined
    }
  }

  time(): string {
    let e = this.getEvent()
    let date = new Date(e.timestamp ?? e.tm)
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    const seconds = date.getSeconds().toString().padStart(2, '0')
    return `${hours}:${minutes}:${seconds}`
  }

  day(): string {
    let e = this.getEvent()
    let date = new Date(e.timestamp ?? e.tm)
    return date.toISOString().split('T')[0]
  }

  getEvent(): Event {
    if (!this._event) {
      try {
        this._event = JSON.parse(this.data) as Event
      }catch (e) {
        return {
          eventName: '',
          path: '',
          eventSequenceId: 0,
          timestamp: 0,
          eventType: '',

          // autotrack
          xpath: '',
          xcontent: '',
          textValue: '',
          index: 0,

          // mode SaaS
          n: '',
          p: '',
          esid: 0,
          tm: 0,
        }
      }
    }
    return this._event
  }
}

interface Event {
  eventName: string
  path: string
  eventSequenceId: number
  timestamp: number
  eventType: string

  // autotrack
  xpath: string
  xcontent: string
  textValue: string
  index: number

  // mode SaaS
  n: string
  p: string
  esid: number
  tm: number
}