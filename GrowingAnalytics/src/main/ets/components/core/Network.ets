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
import GrowingContext from './Context'
import Util from '../utils/Util'

export default class Network {
  static session: rcp.Session

  static initNetwork(context: GrowingContext) {
    Network.session = rcp.createSession()
  }

  static request(events: EventPersistence[], urlPath: string, context: GrowingContext): Promise<rcp.Response> {
    let curTime = Date.now()
    let url = Network.generateUrl(curTime, urlPath, context)
    let request = Network.generateRequest(curTime, url, events, context)
    return Network.session.fetch(request)
  }

  static generateRequest(time: number, url: string, events: EventPersistence[], context: GrowingContext): rcp.Request {
    let useProtobuf = context.config.useProtobuf
    let serialize = Util.toSerialize(useProtobuf, events)
    let headers: Record<string, string> = {
      "Content-Type": useProtobuf ? "application/protobuf" : "application/json",
      "Accept": "application/json",
      "X-Timestamp": time + ''
    }

    if (context.config.compressEnabled) {
      serialize = Util.compress(serialize)
      headers['X-Compress-Codec'] = '2'
    }

    if (context.config.encryptEnabled) {
      serialize = Util.encrypt(serialize, time)
      headers['X-Crypt-Codec'] = '1'
    }

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