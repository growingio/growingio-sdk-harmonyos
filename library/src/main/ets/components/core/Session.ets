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

import AnalyticsCore from './AnalyticsCore'
import GrowingContext from './Context'
import VisitEvent from '../event/VisitEvent'
import FakePageEvent from '../event/saas/FakePageEvent'
import { LogUtil } from '../utils/LogUtil'
import { ConfigMode } from '../interfaces/GrowingConfig'

export enum SessionState {
  Foreground,
  Background
}

export default class Session {
  sessionId: string
  trackerId: string
  latestOnBackgroundTime: number
  static sessionState: SessionState = SessionState.Foreground
  static sessions: Array<Session> = []

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
    Session.sessionState = SessionState.Foreground
    Session.sessions.forEach(session => {
      if (session.latestOnBackgroundTime == 0) {
        return
      }

      let context = GrowingContext.getContext(session.trackerId)!
      if (Date.now() - session.latestOnBackgroundTime >= context.config._sessionInterval) {
        LogUtil.info(() => 'current session is outdated, trackerId = ' + context.trackerId)
        Session.refreshSession(context)
      }
    })
  }

  static onBackground() {
    LogUtil.info(() => 'Session state set to background')
    Session.sessionState = SessionState.Background
    Session.sessions.forEach(session => {
      session.latestOnBackgroundTime = Date.now()
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
    if (session) {
      session.sessionId = util.generateRandomUUID(false)
    } else {
      session = new Session(util.generateRandomUUID(false), context.trackerId)
      Session.sessions.push(session)
    }
    Session.generateVisit(context)
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
    LogUtil.info(() => 'Generate Visit for tracker = ' + context.trackerId)
    if (!context.config.dataCollectionEnabled) {
      LogUtil.info(() => 'Failed to Generate Visit, dataCollectionEnabled is false')
      return
    }
    let e = VisitEvent.create(context)
    AnalyticsCore.writeEventToDisk(e, context)

    if (context.config.mode == ConfigMode.SaaS) {
      let p = FakePageEvent.create(context)
      AnalyticsCore.writeEventToDisk(p, context)
    }
  }
}