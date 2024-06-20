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

import http from '@ohos.net.http'

import EventDatabase from '../EventDatabase'
import GrowingContext from '../../core/Context'
import { REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE } from '../../utils/Constants'
import { LogUtil } from '../../utils/LogUtil'
import Util from '../../utils/Util'
import { EventType } from '../Event'

export default class PVEventSender {
  static isUploading: boolean = false

  static async sendEvent(context: GrowingContext) {
    if (!context.config.dataCollectionEnabled) {
      return
    }

    if (PVEventSender.isUploading) {
      return
    }

    let events = await EventDatabase.getEventsByCount(
      REQUEST_MAX_EVENT_COUNT,
      REQUEST_MAX_EVENT_SIZE,
      context,
      [EventType.Visit, EventType.Page]
    )
    if (events.length == 0) {
      return
    }

    PVEventSender.isUploading = true

    let serialize: string | ArrayBuffer = '[' + events.map(event => String(event.data)).join(',') + ']'
    let curTime = Date.now()
    let header: Record<string, string> = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-Timestamp": curTime + ''
    }

    if (context.config.compressEnabled) {
      serialize = Util.compress(serialize as string)
      header['X-Compress-Codec'] = '2'
    }

    if (context.config.encryptEnabled) {
      serialize = Util.encrypt(serialize, curTime)
      header['X-Crypt-Codec'] = '1'
    }

    let request = http.createHttp()
    let url = PVEventSender.url(context, curTime)

    request.request(url, {
      method: http.RequestMethod.POST,
      connectTimeout: context.config.requestOptions._connectTimeout,
      readTimeout: context.config.requestOptions._readTimeout,
      extraData: serialize,
      header: header
    }, (e, v) => {
      if (v) {
        if (v.responseCode >= 200 && v.responseCode < 400) {
          LogUtil.info(() => 'Request Success, Url = ' + url)
          LogUtil.info(() => 'Send event = ' + serialize)

          EventDatabase.removeEvents(events).then(() => {
            PVEventSender.isUploading = false
            EventDatabase.countOfEvents(context, [EventType.Visit, EventType.Page]).then(count => {
              if (count > REQUEST_MAX_EVENT_COUNT) {
                PVEventSender.sendEvent(context)
              }
            })
          })
        } else {
          LogUtil.info(() => 'Request Failure, responseCode: ' + String(v.responseCode))
          PVEventSender.isUploading = false
        }
      } else {
        if (e) {
          LogUtil.info(() => 'Request Failure, error: ' + JSON.stringify(e))
        }
        PVEventSender.isUploading = false
      }
      request.destroy()
    })
  }

  static url(context: GrowingContext, time: number) {
    let config = context.config
    let serverHost = config.dataCollectionServerHost
    let accountId = config.accountId
    return serverHost + '/v3/' + accountId + '/harmonyos/pv?stm=' + time
  }
}