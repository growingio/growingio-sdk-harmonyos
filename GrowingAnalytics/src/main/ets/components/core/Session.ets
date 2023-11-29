import util from '@ohos.util';
import EventSender from '../event/EventSender';
import VisitEvent from '../event/VisitEvent';
import { GrowingAnalytics } from '../interfaces/GrowingAnalytics';

export default class Session {
  sessionId: string = null
  sentVisitAfterRefreshSession: boolean = false
  private _latestOnBackgroundTime: number = 0
  private _state: SessionState = SessionState.Foreground

  static instance: Session = null
  constructor() {
    this.refreshSession()
  }

  static sharedInstance(): Session {
    if (this.instance == null) {
      this.instance = new Session()
    }
    return this.instance
  }

  onForeground() {
    this._state = SessionState.Foreground
    if (this._latestOnBackgroundTime == 0) {
      return
    }
    var config = GrowingAnalytics.core.config
    if (new Date().getUTCMilliseconds() - this._latestOnBackgroundTime >= config.sessionInterval) {
      this.refreshSession()
      this.generateVisit()
    }
  }

  onBackground() {
    this._state = SessionState.Background
    var date = new Date()
    this._latestOnBackgroundTime = date.getUTCMilliseconds()
  }

  refreshSession() {
    this.sessionId = util.generateRandomUUID(false)
    this.sentVisitAfterRefreshSession = false
  }

  async generateVisit() {
    var config = GrowingAnalytics.core.config
    if (!config.dataCollectionEnabled) {
      return
    }
    this.sentVisitAfterRefreshSession = true
    var e = await VisitEvent.create()
    EventSender.sendEvent(e)
  }
}

export enum SessionState {
  Foreground,
  Background
}