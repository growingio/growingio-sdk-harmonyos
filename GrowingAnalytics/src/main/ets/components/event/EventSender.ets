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

import rcp from '@hms.collaboration.rcp'
import emitter from '@ohos.events.emitter'
import EventDatabase from './EventDatabase'
import EventPersistence from './EventPersistence'
import Network from '../core/Network'
import GrowingContext from '../core/Context'
import { EMIT_EVENT_DATABASE_FLUSH, REQUEST_MAX_EVENT_COUNT, REQUEST_MAX_EVENT_SIZE } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import { EventType } from './Event'
import Plugins from '../plugins/Plugins'

const URL_PATH_NEW_SAAS = '/v3/projects/accountId/collect'
const URL_PATH_SAAS_PV = '/v3/accountId/harmonyos/pv'
const URL_PATH_SAAS_CSTM = '/v3/accountId/harmonyos/cstm'

/**
 * sendEvents 的返回结果，将 statusCode 和 request 显式绑定，
 * 避免调用方通过闭包共享可变状态。
 */
export interface SendResult {
  statusCode: number
  request: rcp.Request
}

/**
 * 上报调度核心 IO 依赖
 *
 * 通过回调注入的方式将调度决策逻辑与平台 IO 解耦，
 * 使 runSendCycle 成为可独立测试的纯调度函数。
 * 每个回调职责单一，回调之间不共享可变状态。
 */
export interface SendCycleIO {
  fetchEvents: () => Promise<EventPersistence[]>
  sendEvents: (events: EventPersistence[]) => Promise<SendResult>
  removeEvents: (events: EventPersistence[]) => Promise<void>
  afterRemove: (events: EventPersistence[], request: rcp.Request) => void
  countRemaining: () => Promise<number>
}

/**
 * 单次上报调度循环（纯调度逻辑，不依赖任何平台 API）
 *
 * 决策规则：
 * - DB 为空 → 不发请求，返回 false
 * - 发送成功（2xx-3xx） → 删除事件，若还有更多返回 true，否则 false
 * - 发送失败（4xx/5xx）→ 不删除，返回 false
 * - sendEvents 抛出异常 → 不删除，异常向上传播
 *
 * @returns true 表示还有事件需要继续发送（调用方负责递归）
 */
export async function runSendCycle(io: SendCycleIO): Promise<boolean> {
  const events = await io.fetchEvents()
  if (events.length === 0) {
    return false
  }

  const result = await io.sendEvents(events)

  if (result.statusCode >= 200 && result.statusCode < 400) {
    await io.removeEvents(events)
    io.afterRemove(events, result.request)
    const count = await io.countRemaining()
    return count > REQUEST_MAX_EVENT_COUNT
  }

  return false
}

export enum EventSenderType {
  NewSaaS = 0,
  SaaS_PV,
  SaaS_CSTM
}

export default class EventSender {
  urlPath: string
  trackerId: string
  eventTypes: string[] | undefined = undefined
  isUploading: boolean = false

  constructor(type: EventSenderType, trackerId: string) {
    this.trackerId = trackerId
    switch (type) {
      case EventSenderType.NewSaaS:
        this.urlPath = URL_PATH_NEW_SAAS
        // 保证首个VISIT及时发送
        emitter.once(EMIT_EVENT_DATABASE_FLUSH, () => {
          this.sendEvent()
        })
        break
      case EventSenderType.SaaS_PV:
        this.urlPath = URL_PATH_SAAS_PV
        this.eventTypes = [EventType.Visit, EventType.Page, EventType.AppClosed]
        // 保证首个VISIT及时发送
        emitter.once(EMIT_EVENT_DATABASE_FLUSH, () => {
          this.sendEvent()
        })
        break
      case EventSenderType.SaaS_CSTM:
        this.urlPath = URL_PATH_SAAS_CSTM
        this.eventTypes = [
          EventType.Custom,
          EventType.LoginUserAttributes,
          EventType.SaaS_Evar,
          EventType.SaaS_Vstr,
          EventType.SaaS_Pvar
        ]
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

    let maybeContext = gContext ?? GrowingContext.getContext(this.trackerId)
    if (!maybeContext) {
      return
    }
    const context: GrowingContext = maybeContext

    this.isUploading = true

    try {
      const urlPath = this.urlPath
      const eventTypes = this.eventTypes
      const hasMore = await runSendCycle({
        fetchEvents: () => EventDatabase.getEventsByCount(
          REQUEST_MAX_EVENT_COUNT,
          REQUEST_MAX_EVENT_SIZE,
          context,
          eventTypes
        ),
        sendEvents: async (events: EventPersistence[]): Promise<SendResult> => {
          let response = await Network.request(events, urlPath, context)
          Plugins.onResponseReceive(response)
          if (response.statusCode >= 200 && response.statusCode < 400) {
            LogUtil.info(() => 'Request Success, Url = ' + response.request.url)
            LogUtil.info(() => 'Send event = ' + response.request.content)
          } else {
            LogUtil.info(() => 'Request Failure, responseCode: ' + String(response.statusCode))
          }
          return { statusCode: response.statusCode, request: response.request } as SendResult
        },
        removeEvents: (events: EventPersistence[]): Promise<void> => EventDatabase.removeEvents([...events]),
        afterRemove: (events: EventPersistence[], request: rcp.Request) => {
          Plugins.onEventsDidSend(events, request)
          Plugins.onEventsRemoveFromDisk(events.map(e => e.uuid))
        },
        countRemaining: () => EventDatabase.countOfEvents(context, eventTypes)
      })

      this.isUploading = false
      if (hasMore) {
        this.sendEvent(context)
      }
    } catch (e) {
      LogUtil.info(() => 'Request Failure, error: ' + JSON.stringify(e))
      this.isUploading = false
    }
  }
}