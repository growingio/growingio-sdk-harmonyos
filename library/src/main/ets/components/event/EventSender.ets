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

import http from '@ohos.net.http'

import EventDatabase from './EventDatabase'
import GrowingContext from '../core/Context'
import { REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'

export default class EventSender {
  static isUploading: boolean = false

  static async sendEvent(context: GrowingContext) {
    if (!context.config.dataCollectionEnabled) {
      return
    }

    if (EventSender.isUploading) {
      return
    }

    let events = await EventDatabase.getEventsByCount(REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE, context)
    if (events.length == 0) {
      return
    }
    EventSender.isUploading = true
    let serialize = events.map(event => String(event.data)).join(',')
    let request = http.createHttp()
    let url = EventSender.url(context)

    request.request(url, {
      method: http.RequestMethod.POST,
      connectTimeout: 30000,
      readTimeout: 30000,
      extraData: '[' + serialize + ']',
      header: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Timestamp": Date.now() + ''
      }
    }, (e, v) => {
      if (e) {
        LogUtil.info('Request Failure, error: ' + JSON.stringify(e))
        EventSender.isUploading = false
      } else {
        LogUtil.info('Request Success, Url = ' + url)
        LogUtil.info('Send event = ' + serialize)

        EventDatabase.removeEvents(events).then(() => {
          EventSender.isUploading = false
          EventDatabase.countOfEvents(context).then(count => {
            if (count > REQUEST_MAX_EVENT_COUNT) {
              EventSender.sendEvent(context)
            }
          })
        })
      }
      request.destroy()
    })
  }

  static url(context: GrowingContext) {
    let config = context.config
    let serverHost = config.dataCollectionServerHost
    let accountId = config.accountId
    return serverHost + '/v3/projects/' + accountId + '/collect?stm=' + Date.now()
  }
}