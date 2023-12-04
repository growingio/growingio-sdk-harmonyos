import { GrowingConfig } from '../interfaces/GrowingConfig'
import DeviceInfo from './DeviceInfo'
import EventTimer from './EventTimer'
import GeneralProps from './GeneralProps'
import Session from './Session'
import UserIdentifier from './UserIdentifier'
import CustomEvent from '../event/CustomEvent'
import EventSender from '../event/EventSender'
import LoginUserAttributesEvent from '../event/LoginUserAttributesEvent'
import { AttributesType } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'

export default class AnalyticsCore {
  static core: AnalyticsCore = null

  config: GrowingConfig
  location: Location

  constructor(context: Context, config: GrowingConfig) {
    SharedPreferences.configContext(context)
    this.config = config
    this.location = new Location()
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

  async setLoginUserId(
    userId: string,
    userKey: string = ''
  ) {
    let userIdentifier = await UserIdentifier.sharedInstance()
    userIdentifier.setLoginUserId(userId, userKey)
  }

  setLocation(
    latitude: number,
    longitude: number
  ) {
    this.location.latitude = latitude
    this.location.longitude = longitude
  }

  async setLoginUserAttributes(
    attributes: AttributesType
  ) {
    let e = await LoginUserAttributesEvent.create(attributes)
    EventSender.sendEvent(e)
    LogUtil.info('Set loginUserAttributes: ' + JSON.stringify(attributes))
  }

  async getDeviceId() {
    let deviceInfo = await DeviceInfo.sharedInstance()
    return deviceInfo.deviceId
  }

  async track(
    eventName: string,
    attributes: AttributesType = {}
  ) {
    let generalProps = GeneralProps.getGeneralProps()
    let e = await CustomEvent.create(eventName, { ...generalProps, ...attributes })
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