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