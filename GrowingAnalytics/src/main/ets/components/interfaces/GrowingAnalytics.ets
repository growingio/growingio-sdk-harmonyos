import AnalyticsCore from '../core/AnalyticsCore'
import { GrowingConfig } from './GrowingConfig'
import EventTimer from '../core/EventTimer'
import Session from '../core/Session'
import { AttributesType, SDK_VERSION } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'

export class GrowingAnalytics {
  static start(
    context: Context,
    configuration: GrowingConfig
  ) {
    if (AnalyticsCore.core) {
      LogUtil.warn('Do not initialize GrowingAnalytics repeatedly')
      return
    }
    if (!context.stageMode) {
      LogUtil.error('Only support stageMode(HarmonyOS 3.1+, API 9+)')
      return
    }
    let config = configuration.copy()
    AnalyticsCore.core = new AnalyticsCore(context, config)
    LogUtil.debugEnabled = config.debugEnabled
    LogUtil.info('Thank you very much for using GrowingIO. We will do our best to provide you with the best service. '
    + 'GrowingIO version: ' + SDK_VERSION)

    Session.refreshSession()
  }

  static isInitializedSuccessfully(): boolean {
    return AnalyticsCore.core != null
  }

  static setDataCollectionEnabled(enabled: boolean) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.setDataCollectionEnabled(enabled)
  }

  static async setLoginUserId(
    userId: string,
    userKey: string = ''
  ) {
    if (!AnalyticsCore.core) {
      return
    }
    await AnalyticsCore.core.setLoginUserId(userId, userKey)
  }

  static async cleanLoginUserId() {
    if (!AnalyticsCore.core) {
      return
    }
    await AnalyticsCore.core.setLoginUserId('')
  }

  static setLocation(
    latitude: number,
    longitude: number
  ) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.setLocation(latitude, longitude)
  }

  static cleanLocation() {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.setLocation(0, 0)
  }

  static async setLoginUserAttributes(attributes: AttributesType) {
    if (!AnalyticsCore.core) {
      return
    }
    await AnalyticsCore.core.setLoginUserAttributes(attributes)
  }

  static async getDeviceId(): Promise<string> {
    if (!AnalyticsCore.core) {
      return ''
    }
    return await AnalyticsCore.core.getDeviceId()
  }

  static async track(
    eventName: string,
    attributes: AttributesType = {}
  ) {
    if (!AnalyticsCore.core) {
      return
    }
    await AnalyticsCore.core.track(eventName, attributes)
  }

  static async trackTimerStart(eventName: string): Promise<string> {
    if (!AnalyticsCore.core) {
      return ''
    }
    return await AnalyticsCore.core.trackTimerStart(eventName)
  }

  static async trackTimerPause(timerId: string) {
    if (!AnalyticsCore.core) {
      return
    }
    await AnalyticsCore.core.trackTimerPause(timerId)
  }

  static async trackTimerResume(timerId: string) {
    if (!AnalyticsCore.core) {
      return
    }
    await AnalyticsCore.core.trackTimerResume(timerId)
  }

  static async trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {}
  ) {
    if (!AnalyticsCore.core) {
      return
    }
    await AnalyticsCore.core.trackTimerEnd(timerId, attributes)
  }

  static removeTimer(timerId: string) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.removeTimer(timerId)
  }

  static clearTrackTimer() {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.clearTrackTimer()
  }

  static setGeneralProps(props: AttributesType) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.setGeneralProps(props)
  }

  static removeGeneralProps(keys: string[]) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.removeGeneralProps(keys)
  }

  static clearGeneralProps() {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.clearGeneralProps()
  }
}