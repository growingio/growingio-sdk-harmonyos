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
import EventDatabase from './EventDatabase'
import Network from '../core/Network'
import GrowingContext from '../core/Context'
import { EMIT_EVENT_DATABASE_FLUSH, REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'

const URL_PATH_NEW_SAAS = '/v3/projects/accountId/collect'

export default class EventSender {
  urlPath: string
  trackerId: string
  eventTypes: string[] | undefined = undefined
  isUploading: boolean = false

  constructor(trackerId: string) {
    this.trackerId = trackerId
    this.urlPath = URL_PATH_NEW_SAAS
    // 保证首个VISIT及时发送
    emitter.once(EMIT_EVENT_DATABASE_FLUSH, () => {
      this.sendEvent()
    })
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
      this.eventTypes
    )
    if (events.length == 0) {
      this.isUploading = false
      return
    }

    try {
      let response = await Network.request(events, this.urlPath, context)
      if (response.statusCode >= 200 && response.statusCode < 400) {
        LogUtil.info(() => 'Request Success, Url = ' + response.request.url)
        LogUtil.info(() => 'Send event = ' + response.request.content)

        await EventDatabase.removeEvents([...events])
        this.isUploading = false
        let count = await EventDatabase.countOfEvents(context, this.eventTypes)
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