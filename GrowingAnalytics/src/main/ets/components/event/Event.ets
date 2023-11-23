import EventBuilder from './EventBuilder'

export default class Event implements EventBuilder {
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

  eventType: EventType = EventType.Visit
  sendPolicy: SendPolicy = SendPolicy.Normal

  // deviceInfo
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
  urlScheme: string = ''
  domain: string = ''
  appState: string = ''
  appChannel: string = ''
  appName: string = ''
  appVersion: string = ''

  constructor() {
  }

  setUserId(userId: string): EventBuilder {
    this.userId = userId
    return this
  }

  setUserKey(userKey: string): EventBuilder {
    this.userKey = userKey
    return this
  }

  setSessionId(sessionId: string): EventBuilder {
    this.sessionId = sessionId
    return this
  }

  setEventSequenceId(eventSequenceId: number): EventBuilder {
    this.eventSequenceId = eventSequenceId
    return this
  }

  setNetworkState(networkState: string): EventBuilder {
    this.networkState = networkState
    return this
  }

  setTimestamp(timestamp: number): EventBuilder {
    this.timestamp = timestamp
    return this
  }

  setLatitude(latitude: number): EventBuilder {
    this.latitude = latitude
    return this
  }

  setLongitude(longitude: number): EventBuilder {
    this.longitude = longitude
    return this
  }

  setSdkVersion(sdkVersion: string): EventBuilder {
    this.sdkVersion = sdkVersion
    return this
  }

  setDataSourceId(dataSourceId: string): EventBuilder {
    this.dataSourceId = dataSourceId
    return this
  }

  build<T extends EventBuilder>(this: T): T {
    this.setUserId('xx').setUserKey('')
    return this
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