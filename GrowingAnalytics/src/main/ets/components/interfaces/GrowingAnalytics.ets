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
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    GrowingAnalytics.core.setDataCollectionEnabled(enabled)
  }

  static setLoginUserId = (
    userId: string,
    userKey: string = ''
  ) => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    GrowingAnalytics.core.setLoginUserId(userId, userKey)
  }

  static setLocation = (
    latitude: number,
    longitude: number
  ) => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    GrowingAnalytics.core.setLocation(latitude, longitude)
  }

  static cleanLocation = () => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    GrowingAnalytics.core.setLocation(0, 0)
  }

  static setLoginUserAttributes = (
    attributes: AttributesType
  ) => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    GrowingAnalytics.core.setLoginUserAttributes(attributes)
  }

  static getDeviceId = async () => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return ''
    }
    return await GrowingAnalytics.core.getDeviceId()
  }

  static track = (
  eventName: string,
  attributes: AttributesType = null
  ) => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    GrowingAnalytics.core.track(eventName, attributes)
  }

  static trackTimerStart = async (
    eventName: string
  ) => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return ''
    }
    return await EventTimer.trackTimerStart(eventName)
  }

  static trackTimerPause = (
    timerId: string
  ) => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    EventTimer.trackTimerPause(timerId)
  }

  static trackTimerResume = (
    timerId: string
  ) => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    EventTimer.trackTimerResume(timerId)
  }

  static trackTimerEnd = (
    timerId: string,
    attributes: AttributesType = {}
  ) => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    EventTimer.trackTimerEnd(timerId, attributes)
  }

  static removeTimer = (
    timerId: string
  ) => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    EventTimer.removeTimer(timerId)
  }

  static clearTrackTimer = () => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    EventTimer.clearAllTimers()
  }

  static setGeneralProps = (
    props: AttributesType
  ) => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    GrowingAnalytics.core.generalProps.setGeneralProps(props)
  }

  static removeGeneralProps = (
    keys: string[]
  ) => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    GrowingAnalytics.core.generalProps.removeGeneralProps(keys)
  }

  static clearGeneralProps = () => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    GrowingAnalytics.core.generalProps.clearGeneralProps()
  }

  static onForeground = () => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    GrowingAnalytics.core.session.onForeground()
    EventTimer.handleAllTimersResume()
  }

  static onBackground = () => {
    if (!GrowingAnalytics._isInitializedSuccessfully) {
      return
    }
    GrowingAnalytics.core.session.onBackground()
    EventTimer.handleAllTimersPause()
  }
}