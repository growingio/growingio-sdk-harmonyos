import util from '@ohos.util'
import EventSender from '../event/EventSender'
import VisitEvent from '../event/VisitEvent'
import { GrowingAnalytics } from '../interfaces/GrowingAnalytics'

export default class Session {
  sessionId: string = null
  sessionState: SessionState = SessionState.Foreground
  private _latestOnBackgroundTime: number = 0

  constructor() {
    this.sessionId = util.generateRandomUUID(false)
  }

  onForeground() {
    this.sessionState = SessionState.Foreground
    if (this._latestOnBackgroundTime == 0) {
      return
    }
    let config = GrowingAnalytics.core.config
    if (Date.now() - this._latestOnBackgroundTime >= config.sessionInterval * 1000) {
      this.refreshSession()
    }
  }

  onBackground() {
    this.sessionState = SessionState.Background
    this._latestOnBackgroundTime = Date.now()
  }

  refreshSession() {
    this.sessionId = util.generateRandomUUID(false)
    this.generateVisit()
  }

  async generateVisit() {
    let config = GrowingAnalytics.core.config
    if (!config.dataCollectionEnabled) {
      return
    }
    let e = await VisitEvent.create()
    EventSender.sendEvent(e)
  }
}

export enum SessionState {
  Foreground,
  Background
}