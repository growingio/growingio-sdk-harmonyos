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
import EventSender from '../event/EventSender'
import VisitEvent from '../event/VisitEvent'
import { LogUtil } from '../utils/LogUtil'

export enum SessionState {
  Foreground,
  Background
}

export default class Session {
  static sessionId: string = null
  static sessionState: SessionState = SessionState.Foreground
  private static _latestOnBackgroundTime: number = 0

  static onForeground() {
    LogUtil.info('Session state set to foreground')
    this.sessionState = SessionState.Foreground
    if (this._latestOnBackgroundTime == 0) {
      return
    }
    var core = AnalyticsCore.core
    if (core) {
      let config = core.config
      if (Date.now() - this._latestOnBackgroundTime >= config.sessionInterval * 1000) {
        LogUtil.info('Latest session is outdated')
        this.refreshSession()
      }
    }
  }

  static onBackground() {
    LogUtil.info('Session state set to background')
    this.sessionState = SessionState.Background
    this._latestOnBackgroundTime = Date.now()
  }

  static refreshSession() {
    LogUtil.info('Refresh Session')
    this.sessionId = util.generateRandomUUID(false)
    this.generateVisit()
  }

  static generateVisit() {
    LogUtil.info('Generate Visit')
    let config = AnalyticsCore.core.config
    if (!config.dataCollectionEnabled) {
      LogUtil.info('Failed to Generate Visit, dataCollectionEnabled is false')
      return
    }
    let e = VisitEvent.create()
    EventSender.sendEvent(e)
  }
}