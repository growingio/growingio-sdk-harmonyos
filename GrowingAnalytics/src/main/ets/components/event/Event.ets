export { AttributesType } from '../utils/Constants'

export default abstract class Event {
  userId: string
  userKey: string
  sessionId: string
  eventSequenceId: number
  networkState: string
  timestamp: number
  latitude: number
  longitude: number
  sdkVersion: string
  dataSourceId: string
  urlScheme: string

  eventType: EventType = EventType.Visit

  // deviceInfo
  deviceId: string
  platform: string
  platformVersion: string
  screenHeight: number
  screenWidth: number
  deviceBrand: string
  deviceModel: string
  deviceType: string
  language: string
  timezoneOffset: string

  // appInfo
  domain: string
  appState: string
  appChannel: string
  appName: string
  appVersion: string

  toSerialize(): string {
    return JSON.stringify(this)
  }
}

export enum EventType {
  Visit = 'VISIT',
  Custom = 'CUSTOM',
  LoginUserAttributes = 'LOGIN_USER_ATTRIBUTES'
}