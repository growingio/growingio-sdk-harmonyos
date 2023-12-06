import { GrowingConfig } from '../interfaces/GrowingConfig'
import AppInfo from './AppInfo'
import DeviceInfo from './DeviceInfo'
import EventTimer from './EventTimer'
import GeneralProps from './GeneralProps'
import Session from './Session'
import UserIdentifier from './UserIdentifier'
import CustomEvent from '../event/CustomEvent'
import EventBuilder from '../event/EventBuilder'
import EventSender from '../event/EventSender'
import LoginUserAttributesEvent from '../event/LoginUserAttributesEvent'
import { AttributesType } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'

export default class AnalyticsCore {
  static core: AnalyticsCore = null

  config: GrowingConfig
  location: Location

  constructor(config: GrowingConfig) {
    this.config = config
    this.location = new Location()
  }

  static async startCore(context: Context, config: GrowingConfig) {
    let core = new AnalyticsCore(config)
    AnalyticsCore.core = core
    this.setAbilityLifecycleCallback(context)
    await SharedPreferences.initWithContext(context)
    await AppInfo.initAppInfo()
    await DeviceInfo.initDeviceInfo()
    await UserIdentifier.initUser()
    await EventBuilder.initEventBuilder()
  }

  static setAbilityLifecycleCallback(context: Context) {
    let abilityLifecycleCallback = {
      onAbilityCreate(ability) {
      },
      onWindowStageCreate(ability, windowStage) {
      },
      onWindowStageActive(ability, windowStage) {
        Session.onForeground()
        EventTimer.handleAllTimersResume()
      },
      onWindowStageInactive(ability, windowStage) {
        Session.onBackground()
        EventTimer.handleAllTimersPause()
      },
      onWindowStageDestroy(ability, windowStage) {
      },
      onAbilityDestroy(ability) {
      },
      onAbilityForeground(ability) {
      },
      onAbilityBackground(ability) {
      },
      onAbilityContinue(ability) {
      }
    }
    context.getApplicationContext().on('abilityLifecycle', abilityLifecycleCallback)
  }

  setDataCollectionEnabled(enabled: boolean) {
    let config = this.config
    if (config.dataCollectionEnabled == enabled) {
      return
    }
    LogUtil.info('Set dataCollectionEnabled: ' + enabled)
    config.dataCollectionEnabled = enabled
    if (enabled) {
      Session.refreshSession()
    }
  }

  setLoginUserId(
    userId: string,
    userKey: string = ''
  ) {
    UserIdentifier.setLoginUserId(userId, userKey)
  }

  setLocation(
    latitude: number,
    longitude: number
  ) {
    this.location.latitude = latitude
    this.location.longitude = longitude
  }

  setLoginUserAttributes(
    attributes: AttributesType
  ) {
    let e = LoginUserAttributesEvent.create(attributes)
    EventSender.sendEvent(e)
    LogUtil.info('Set loginUserAttributes: ' + JSON.stringify(attributes))
  }

  getDeviceId() {
    return DeviceInfo.deviceId
  }

  track(
    eventName: string,
    attributes: AttributesType = {}
  ) {
    let generalProps = GeneralProps.getGeneralProps()
    let e = CustomEvent.create(eventName, { ...generalProps, ...attributes })
    EventSender.sendEvent(e)
    LogUtil.info('Track custom event with eventName: ' + eventName + ', attributes: ' + JSON.stringify(attributes)
    + ', current generalProps: ' + JSON.stringify(generalProps))
  }

  async trackTimerStart(eventName: string): Promise<string> {
    return await EventTimer.trackTimerStart(eventName)
  }

  async trackTimerPause(timerId: string) {
    await EventTimer.trackTimerPause(timerId)
  }

  async trackTimerResume(timerId: string) {
    await EventTimer.trackTimerResume(timerId)
  }

  async trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {}
  ) {
    await EventTimer.trackTimerEnd(timerId, attributes)
  }

  removeTimer(timerId: string) {
    EventTimer.removeTimer(timerId)
  }

  clearTrackTimer() {
    EventTimer.clearTrackTimer()
  }

  setGeneralProps(props: AttributesType) {
    GeneralProps.setGeneralProps(props)
  }

  removeGeneralProps(keys: string[]) {
    GeneralProps.removeGeneralProps(keys)
  }

  clearGeneralProps() {
    GeneralProps.clearGeneralProps()
  }
}

class Location {
  latitude: number = 0
  longitude: number = 0
}