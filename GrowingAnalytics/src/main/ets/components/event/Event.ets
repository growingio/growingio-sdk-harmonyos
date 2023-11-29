import AppInfo from '../core/AppInfo'
import DeviceInfo from '../core/DeviceInfo'
import Session from '../core/Session'
import UserIdentifier from '../core/UserIdentifier'
import { GrowingAnalytics } from '../interfaces/GrowingAnalytics'
import { PREFERENCE_EVENT_SEQUENCE_ID } from '../utils/Constants'

export default class Event {
  userId: string = ''
  userKey: string = ''
  sessionId: string = ''
  eventSequenceId: number = 0
  networkState: string = ''
  timestamp: number = 0
  latitude: number = 0
  longitude: number = 0
  sdkVersion: string = ''
  dataSourceId: string = ''
  urlScheme: string = ''

  eventType: EventType = EventType.Visit
  sendPolicy: SendPolicy = SendPolicy.Normal

  // deviceInfo
  deviceId: string = ''
  platform: string = ''
  platformVersion: string = ''
  screenHeight: number = 0
  screenWidth: number = 0
  deviceBrand: string = ''
  deviceModel: string = ''
  deviceType: string = ''
  language: string = ''
  timezoneOffset: string = ''

  // appInfo
  domain: string = ''
  appState: string = ''
  appChannel: string = ''
  appName: string = ''
  appVersion: string = ''

  async build<T extends Event>(this: T): Promise<T> {
    var userIdentifier = UserIdentifier.sharedInstance()
    var userId = await userIdentifier.userId()
    this.userId = userId
    var userKey = await userIdentifier.userKey()
    this.userKey = userKey
    this.sessionId = Session.sharedInstance().sessionId
    this.eventSequenceId = await this.updateEventSequenceId()
    this.networkState = 'WiFi'
    this.timestamp = new Date().getUTCMilliseconds()
    this.sdkVersion = '1.0.0'
    this.dataSourceId = GrowingAnalytics.core.config.dataSourceId
    this.urlScheme = GrowingAnalytics.core.config.urlScheme

    var deviceInfo = DeviceInfo.sharedInstance()
    this.deviceId = deviceInfo.deviceId
    this.platform = deviceInfo.platform
    this.platformVersion = deviceInfo.platformVersion
    this.screenHeight = deviceInfo.screenHeight
    this.screenWidth = deviceInfo.screenWidth
    this.deviceBrand = deviceInfo.deviceBrand
    this.deviceModel = deviceInfo.deviceModel
    this.deviceType = deviceInfo.deviceType
    this.language = deviceInfo.language
    this.timezoneOffset = deviceInfo.timezoneOffset

    var appInfo = AppInfo.sharedInstance()
    this.domain = appInfo.domain
    this.appState = appInfo.appState
    this.appChannel = appInfo.appChannel
    this.appName = appInfo.appName
    this.appVersion = appInfo.appVersion

    return this
  }

  async updateEventSequenceId(): Promise<number> {
    var se = await GrowingAnalytics.core.preferences.getValue(PREFERENCE_EVENT_SEQUENCE_ID) as number
    GrowingAnalytics.core.preferences.put(se + 1, PREFERENCE_EVENT_SEQUENCE_ID)
    return se
  }

  toSerialize(): Object {
    return null
  }
}

export enum EventType {
  Visit = 'VISIT',
  Custom = 'CUSTOM'
}

export enum SendPolicy {
  Instant,
  Normal
}