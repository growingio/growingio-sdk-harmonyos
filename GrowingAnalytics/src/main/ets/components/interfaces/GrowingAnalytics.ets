import AnalyticsCore from '../core/AnalyticsCore'
import { GrowingConfig } from './GrowingConfig'
import { AttributesType, SDK_VERSION } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import EventTimer from '../core/EventTimer'
import Session from '../core/Session'

export class GrowingAnalytics {
  static core: AnalyticsCore = null

  static start(
    context: Context,
    configuration: GrowingConfig
  ) {
    if (this.core) {
      return
    }
    let config = configuration.copy()
    this.core = new AnalyticsCore(context, config)
    LogUtil.debugEnabled = config.debugEnabled
    LogUtil.info('Thank you very much for using GrowingIO. We will do our best to provide you with the best service. '
    + 'GrowingIO version: ' + SDK_VERSION)

    Session.refreshSession()
  }

  static isInitializedSuccessfully(): boolean {
    return this.core != null
  }

  static setDataCollectionEnabled(enabled: boolean) {
    if (!this.core) {
      return
    }
    this.core.setDataCollectionEnabled(enabled)
  }

  static setLoginUserId(
    userId: string,
    userKey: string = ''
  ) {
    if (!this.core) {
      return
    }
    this.core.setLoginUserId(userId, userKey)
  }

  static setLocation(
    latitude: number,
    longitude: number
  ) {
    if (!this.core) {
      return
    }
    this.core.setLocation(latitude, longitude)
  }

  static cleanLocation() {
    if (!this.core) {
      return
    }
    this.core.setLocation(0, 0)
  }

  static setLoginUserAttributes(attributes: AttributesType) {
    if (!this.core) {
      return
    }
    this.core.setLoginUserAttributes(attributes)
  }

  static async getDeviceId(): Promise<string> {
    if (!this.core) {
      return ''
    }
    return await this.core.getDeviceId()
  }

  static track(
    eventName: string,
    attributes: AttributesType = null
  ) {
    if (!this.core) {
      return
    }
    this.core.track(eventName, attributes)
  }

  static async trackTimerStart(eventName: string): Promise<string> {
    if (!this.core) {
      return ''
    }
    return await EventTimer.trackTimerStart(eventName)
  }

  static trackTimerPause(timerId: string) {
    if (!this.core) {
      return
    }
    EventTimer.trackTimerPause(timerId)
  }

  static trackTimerResume(timerId: string) {
    if (!this.core) {
      return
    }
    EventTimer.trackTimerResume(timerId)
  }

  static trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {}
  ) {
    if (!this.core) {
      return
    }
    EventTimer.trackTimerEnd(timerId, attributes)
  }

  static removeTimer(timerId: string) {
    if (!this.core) {
      return
    }
    EventTimer.removeTimer(timerId)
  }

  static clearTrackTimer() {
    if (!this.core) {
      return
    }
    EventTimer.clearAllTimers()
  }

  static setGeneralProps(props: AttributesType) {
    if (!this.core) {
      return
    }
    this.core.generalProps.setGeneralProps(props)
  }

  static removeGeneralProps(keys: string[]) {
    if (!this.core) {
      return
    }
    this.core.generalProps.removeGeneralProps(keys)
  }

  static clearGeneralProps() {
    if (!this.core) {
      return
    }
    this.core.generalProps.clearGeneralProps()
  }

  static onForeground() {
    Session.onForeground()
    EventTimer.handleAllTimersResume()
  }

  static onBackground() {
    Session.onBackground()
    EventTimer.handleAllTimersPause()
  }
}