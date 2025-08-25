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
import emitter from '@ohos.events.emitter'
import collections from '@arkts.collections'

import AnalyticsCore from './AnalyticsCore'
import GrowingContext from './Context'
import AppClosedEvent from '../event/AppClosedEvent'
import VisitEvent from '../event/VisitEvent'
import FakePageEvent from '../event/saas/FakePageEvent'
import { ConfigMode } from '../interfaces/GrowingConfig'
import { EMIT_EVENT_SESSION_STATE_FOREGROUND } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import { SaaSVisitorEvent } from '../event/saas/SaaSTrackEvent'

"use shared"

@Sendable
export default class Session {
  sessionId: string
  trackerId: string
  latestOnBackgroundTime: number
  static isOnForeground: boolean = true
  static sessions: collections.Array<Session> = new collections.Array()

  constructor(
    sessionId: string,
    trackerId: string,
    latestOnBackgroundTime: number = 0
  ) {
    this.sessionId = sessionId
    this.trackerId = trackerId
    this.latestOnBackgroundTime = latestOnBackgroundTime
  }

  static onForeground() {
    LogUtil.info(() => 'Session state set to foreground')
    Session.isOnForeground = true
    Session.sessions.forEach(session => {
      if (session.latestOnBackgroundTime == 0) {
        // 1.首次初始化
        // 2.上一次sessionState为foreground
        return
      }

      let context = GrowingContext.getContext(session.trackerId)!
      if (Date.now() - session.latestOnBackgroundTime >= context.config._sessionInterval) {
        LogUtil.info(() => 'current session is outdated, trackerId = ' + context.trackerId)
        Session.refreshSession(context)
      }
      session.latestOnBackgroundTime = 0
    })

    emitter.emit(EMIT_EVENT_SESSION_STATE_FOREGROUND)
  }

  static onBackground() {
    LogUtil.info(() => 'Session state set to background')
    Session.isOnForeground = false
    Session.sessions.forEach(session => {
      session.latestOnBackgroundTime = Date.now()

      let context = GrowingContext.getContext(session.trackerId)!
      Session.generateAppClosed(context)
    })
  }

  static refreshSession(context: GrowingContext) {
    LogUtil.info(() => 'Refresh Session for tracker = ' + context.trackerId)
    let session: Session | undefined = undefined
    for (let s of Session.sessions) {
      if (s.trackerId == context.trackerId) {
        session = s
        break
      }
    }
    let isRefresh: boolean = false
    if (session) {
      session.sessionId = util.generateRandomUUID(false)
      isRefresh = true
    } else {
      session = new Session(util.generateRandomUUID(false), context.trackerId)
      Session.sessions.push(session)
    }
    Session.generateVisit(context)
    if (isRefresh && context.config.mode == ConfigMode.SaaS) {
      SaaSVisitorEvent.sendVisitorIfNeeded(context)
    }
  }

  static getSessionId(context: GrowingContext): string | undefined {
    for (let session of Session.sessions) {
      if (session.trackerId == context.trackerId) {
        return session.sessionId
      }
    }
    return undefined
  }

  static generateVisit(context: GrowingContext) {
    if (!context.config.dataCollectionEnabled) {
      LogUtil.info(() => 'Failed to generate visit, dataCollectionEnabled is false')
      return
    }
    LogUtil.info(() => 'Generate visit for tracker = ' + context.trackerId)
    let e = VisitEvent.create(context)
    AnalyticsCore.writeEventToDisk(e, context)

    if (context.config.mode == ConfigMode.SaaS) {
      FakePageEvent.sendFakePageIfNeeded(context)
    }
  }

  static generateAppClosed(context: GrowingContext) {
    if (!context.config.dataCollectionEnabled) {
      return
    }
    let e = AppClosedEvent.create(context)
    AnalyticsCore.writeEventToDisk(e, context)
  }
}