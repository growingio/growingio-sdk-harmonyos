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
import taskpool from '@ohos.taskpool'

import GrowingContext from './Context'
import EventPersistence from '../event/EventPersistence'
import { ConfigMode } from '../interfaces/GrowingConfig'
import { processEvents } from '../utils/Concurrent'
import Util from '../utils/Util'
import { LogUtil } from '../utils/LogUtil'

interface RequestResult {
  headers: Record<string, string>
  body: ArrayBuffer
}

export interface NetworkResult {
  response: http.HttpResponse
  url: string
}

export default class Network {
  static async request(events: EventPersistence[], urlPath: string, context: GrowingContext): Promise<NetworkResult> {
    let time = Date.now()
    let url = Network.generateUrl(time, urlPath, context)
    try {
      let requestResult = await Network.generateRequestOptions(time, events, context)
      let headers = requestResult.headers
      let body = requestResult.body
      let httpRequest = http.createHttp()
      try {
        let response = await httpRequest.request(url, {
          method: http.RequestMethod.POST,
          header: headers,
          extraData: body,
          connectTimeout: context.config.requestOptions._connectTimeout,
          readTimeout: context.config.requestOptions._transferTimeout,
        })
        return { response, url }
      } finally {
        httpRequest.destroy()
      }
    } catch (error) {
      LogUtil.error(() => 'Failed to send network request: ' + error)
      return Promise.reject(error)
    }
  }

  static async generateRequestOptions(
    time: number,
    events: EventPersistence[],
    context: GrowingContext
  ): Promise<RequestResult> {
    let useProtobuf = context.config.useProtobuf
    if (context.config.mode == ConfigMode.SaaS) {
      // SaaS mode has no protobuf support
      useProtobuf = false
    }

    let processTask = new taskpool.Task(processEvents, events, useProtobuf, context.config.compressEnabled)
    let serialize: ArrayBuffer
    try {
      serialize = await taskpool.execute(processTask) as ArrayBuffer
    } catch (error) {
      LogUtil.error(() => 'Failed to execute taskpool task: ' + error)
      return Promise.reject(error)
    }
    if (context.config.encryptEnabled) {
      serialize = Util.encrypt(serialize, time)
    }

    let headers = Network.generateHeaders(time, useProtobuf, context)
    let result: RequestResult = { headers: headers, body: serialize }
    return result
  }

  static generateHeaders(time: number, useProtobuf: boolean, context: GrowingContext): Record<string, string> {
    let headers: Record<string, string> = {
      "Content-Type": useProtobuf ? "application/protobuf" : "application/json",
      "Accept": "application/json",
      "X-Timestamp": time + ''
    }

    if (context.config.compressEnabled) {
      headers['X-Compress-Codec'] = '2'
    }

    if (context.config.encryptEnabled) {
      headers['X-Crypt-Codec'] = '1'
    }

    return headers
  }

  static generateUrl(time: number, urlPath: string, context: GrowingContext): string {
    let config = context.config
    let serverHost = config.dataCollectionServerHost
    if (serverHost.endsWith('/')) {
      serverHost = serverHost.substring(0, serverHost.length - 1)
    }
    let accountId = config.accountId
    return serverHost + urlPath.replace('accountId', accountId) + '?stm=' + String(time)
  }
}
