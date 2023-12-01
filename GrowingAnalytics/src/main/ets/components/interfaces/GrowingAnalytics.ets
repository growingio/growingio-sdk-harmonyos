import AnalyticsCore from '../core/AnalyticsCore'
import { GrowingConfig } from './GrowingConfig'
import { AttributesType, SDK_VERSION } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import EventTimer from '../core/EventTimer'

export class GrowingAnalytics {
  static core: AnalyticsCore = null
  private static _isInitializedSuccessfully: boolean = false

  static start = (
    context: Context,
    configuration: GrowingConfig
  ) => {
    if (GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    let config = configuration.copy()
    GrowingAnalytics.core = new AnalyticsCore(context, config)
    GrowingAnalytics._isInitializedSuccessfully = true
    LogUtil.debugEnabled = config.debugEnabled
    LogUtil.info('Thank you very much for using GrowingIO. We will do our best to provide you with the best service. '
    + 'GrowingIO version: ' + SDK_VERSION)

    GrowingAnalytics.core.session.generateVisit()
  }

  static isInitializedSuccessfully = () => {
    return GrowingAnalytics._isInitializedSuccessfully
  }

  static setDataCollectionEnabled = (enabled: boolean) => {
    GrowingAnalytics.core.setDataCollectionEnabled(enabled)
  }

  static setLoginUserId = (
    userId: string,
    userKey: string = ''
  ) => {
    GrowingAnalytics.core.setLoginUserId(userId, userKey)
  }

  static setLocation = (
    latitude: number,
    longitude: number
  ) => {
    GrowingAnalytics.core.setLocation(latitude, longitude)
  }

  static cleanLocation = () => {
    GrowingAnalytics.core.setLocation(0, 0)
  }

  static setLoginUserAttributes = (
    attributes: AttributesType
  ) => {
    GrowingAnalytics.core.setLoginUserAttributes(attributes)
  }

  static getDeviceId = async () => {
    return await GrowingAnalytics.core.getDeviceId()
  }

  static track = (
  eventName: string,
  attributes: AttributesType = null
  ) => {
    GrowingAnalytics.core.track(eventName, attributes)
  }

  static trackTimerStart = async (
    eventName: string
  ) => {
    return await EventTimer.trackTimerStart(eventName)
  }

  static trackTimerPause = (
    timerId: string
  ) => {
    EventTimer.trackTimerPause(timerId)
  }

  static trackTimerResume = (
    timerId: string
  ) => {
    EventTimer.trackTimerResume(timerId)
  }

  static trackTimerEnd = (
    timerId: string,
    attributes: AttributesType = {}
  ) => {
    EventTimer.trackTimerEnd(timerId, attributes)
  }

  static removeTimer = (
    timerId: string
  ) => {
    EventTimer.removeTimer(timerId)
  }

  static clearTrackTimer = () => {
    EventTimer.clearAllTimers()
  }

  static setGeneralProps = (
    props: AttributesType
  ) => {
    GrowingAnalytics.core.generalProps.setGeneralProps(props)
  }

  static removeGeneralProps = (
    keys: string[]
  ) => {
    GrowingAnalytics.core.generalProps.removeGeneralProps(keys)
  }

  static clearGeneralProps = () => {
    GrowingAnalytics.core.generalProps.clearGeneralProps()
  }

  static onForeground = () => {
    GrowingAnalytics.core.session.onForeground()
    EventTimer.handleAllTimersResume()
  }

  static onBackground = () => {
    GrowingAnalytics.core.session.onBackground()
    EventTimer.handleAllTimersPause()
  }
}