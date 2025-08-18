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
import taskpool from '@ohos.taskpool'

import GrowingContext from './Context'
import EventPersistence from '../event/EventPersistence'
import { ConfigMode } from '../interfaces/GrowingConfig'
import { processEvents } from '../utils/Concurrent'
import Util from '../utils/Util'
import { LogUtil } from '../utils/LogUtil'

export default class Network {
  static session: rcp.Session

  static initNetwork(context: GrowingContext) {
    try {
      Network.session = rcp.createSession()
    } catch (error) {
      LogUtil.error(() =>'Failed to create RCP session:' + error)
    }
  }

  static async request(events: EventPersistence[], urlPath: string, context: GrowingContext): Promise<rcp.Response> {
    if (!Network.session) {
      return Promise.reject(new Error('Network session not initialized'))
    }

    let curTime = Date.now()
    let url = Network.generateUrl(curTime, urlPath, context)
    try {
      let request = await Network.generateRequest(curTime, url, events, context)
      return Network.session.fetch(request)
    } catch (error) {
      LogUtil.error(() => 'Failed to generate request: ' + error)
      return Promise.reject(error)
    }
  }

  static async generateRequest(time: number, url: string, events: EventPersistence[], context: GrowingContext): Promise<rcp.Request> {
    let useProtobuf = context.config.useProtobuf
    if (context.config.mode == ConfigMode.SaaS) {
      // SaaS mode have not protobuf support
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
    let request = new rcp.Request(url, "POST", headers, serialize)
    const tracingConfig: rcp.TracingConfiguration = {
      collectTimeInfo: true
    }

    const requestConfig: rcp.Configuration = {
      transfer: {
        timeout: {
          connectMs: context.config.requestOptions._connectTimeout,
          transferMs: context.config.requestOptions._transferTimeout,
        }
      },
      tracing: tracingConfig,
    }
    request.configuration = requestConfig
    return request
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
      serverHost = serverHost.substring(0, serverHost.length - 2)
    }
    let accountId = config.accountId
    return serverHost + urlPath.replace('accountId', accountId) + '?stm=' + String(time)
  }
}