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

import emitter from '@ohos.events.emitter'
import collections from '@arkts.collections'

import EventDatabase from './EventDatabase'
import Network from '../core/Network'
import GrowingContext from '../core/Context'
import { EMIT_EVENT_DATABASE_FLUSH, REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import { EventType } from './Event'
import Plugins from '../plugins/Plugins'

export enum EventSenderType {
  NewSaaS = 0,
  SaaS_PV,
  SaaS_CSTM
}

@Sendable
export default class EventSender {
  urlPath: string
  trackerId: string
  eventTypes: collections.Array<string> = new collections.Array<string>()
  isUploading: boolean = false

  constructor(type: EventSenderType, trackerId: string) {
    this.trackerId = trackerId
    switch (type) {
      case EventSenderType.NewSaaS:
        this.urlPath = '/v3/projects/accountId/collect'
        // 保证首个VISIT及时发送
        emitter.once(EMIT_EVENT_DATABASE_FLUSH, () => {
          this.sendEvent()
        })
        break
      case EventSenderType.SaaS_PV:
        this.urlPath = '/v3/accountId/harmonyos/pv'
        this.eventTypes = new collections.Array<string>(EventType.Visit, EventType.Page, EventType.AppClosed)
        // 保证首个VISIT及时发送
        emitter.once(EMIT_EVENT_DATABASE_FLUSH, () => {
          this.sendEvent()
        })
        break
      case EventSenderType.SaaS_CSTM:
        this.urlPath = '/v3/accountId/harmonyos/cstm'
        this.eventTypes = new collections.Array<string>(
          EventType.Custom,
          EventType.LoginUserAttributes,
          EventType.SaaS_Evar,
          EventType.SaaS_Vstr,
          EventType.SaaS_Pvar
        )
        break
    }
  }

  static async sendEvent(context: GrowingContext) {
    for (let eventSender of context.eventSender) {
      await eventSender.sendEvent(context)
    }
  }
  
  async sendEvent(gContext?: GrowingContext) {
    if (this.isUploading) {
      return
    }
    this.isUploading = true

    let context = gContext ?? GrowingContext.getContext(this.trackerId) as GrowingContext
    let events = await EventDatabase.getEventsByCount(
      REQUEST_MAX_EVENT_COUNT,
      REQUEST_MAX_EVENT_SIZE,
      context,
      [...this.eventTypes]
    )
    if (events.length == 0) {
      this.isUploading = false
      return
    }

    try {
      let response = await Network.request(events, this.urlPath, context)
      Plugins.onResponseReceive(response)
      if (response.statusCode >= 200 && response.statusCode < 400) {
        LogUtil.info(() => 'Request Success, Url = ' + response.request.url)
        LogUtil.info(() => 'Send event = ' + response.request.content)

        await EventDatabase.removeEvents([...events])
        Plugins.onEventsDidSend(events, response.request)
        Plugins.onEventsRemoveFromDisk(events.map(e => e.uuid))
        this.isUploading = false
        let count = await EventDatabase.countOfEvents(context, [...this.eventTypes])
        if (count > REQUEST_MAX_EVENT_COUNT) {
          this.sendEvent(context)
        }
      } else {
        LogUtil.info(() => 'Request Failure, responseCode: ' + String(response.statusCode))
        this.isUploading = false
      }
    } catch (e) {
      LogUtil.info(() => 'Request Failure, error: ' + JSON.stringify(e))
      this.isUploading = false
    }
  }
}