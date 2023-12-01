import util from '@ohos.util'
import EventSender from '../event/EventSender'
import VisitEvent from '../event/VisitEvent'
import { GrowingAnalytics } from '../interfaces/GrowingAnalytics'

export default class Session {
  sessionId: string = null
  sentVisitAfterRefreshSession: boolean = false
  private _latestOnBackgroundTime: number = 0
  sessionState: SessionState = SessionState.Foreground

  constructor() {
    this.refreshSession()
  }

  onForeground() {
    this.sessionState = SessionState.Foreground
    if (this._latestOnBackgroundTime == 0) {
      return
    }
    let config = GrowingAnalytics.core.config
    if (Date.now() - this._latestOnBackgroundTime >= config.sessionInterval * 1000) {
      this.refreshSession()
      this.generateVisit()
    }
  }

  onBackground() {
    this.sessionState = SessionState.Background
    this._latestOnBackgroundTime = Date.now()
  }

  refreshSession() {
    this.sessionId = util.generateRandomUUID(false)
    this.sentVisitAfterRefreshSession = false
  }

  async generateVisit() {
    let config = GrowingAnalytics.core.config
    if (!config.dataCollectionEnabled) {
      return
    }
    this.sentVisitAfterRefreshSession = true
    let e = await VisitEvent.create()
    EventSender.sendEvent(e)
  }
}

export enum SessionState {
  Foreground,
  Background
}