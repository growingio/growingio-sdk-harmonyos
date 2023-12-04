import util from '@ohos.util'
import EventSender from '../event/EventSender'
import VisitEvent from '../event/VisitEvent'
import { GrowingAnalytics } from '../interfaces/GrowingAnalytics'


export enum SessionState {
  Foreground,
  Background
}

export default class Session {
  static sessionId: string = null
  static sessionState: SessionState = SessionState.Foreground
  private static _latestOnBackgroundTime: number = 0

  static onForeground() {
    this.sessionState = SessionState.Foreground
    if (this._latestOnBackgroundTime == 0) {
      return
    }
    var core = GrowingAnalytics.core
    if (core) {
      let config = core.config
      if (Date.now() - this._latestOnBackgroundTime >= config.sessionInterval * 1000) {
        this.refreshSession()
      }
    }
  }

  static onBackground() {
    this.sessionState = SessionState.Background
    this._latestOnBackgroundTime = Date.now()
  }

  static refreshSession() {
    this.sessionId = util.generateRandomUUID(false)
    this.generateVisit()
  }

  static async generateVisit() {
    let config = GrowingAnalytics.core.config
    if (!config.dataCollectionEnabled) {
      return
    }
    let e = await VisitEvent.create()
    EventSender.sendEvent(e)
  }
}