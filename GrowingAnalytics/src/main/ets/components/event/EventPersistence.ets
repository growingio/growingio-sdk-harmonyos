import util from '@ohos.util'

import Event from './Event'
import { SDK_VERSION } from '../utils/Constants'

export default class EventPersistence {
  uuid: string
  data: string
  eventType: string
  timestamp: number
  sdkVersion: string

  constructor(
    uuid: string,
    data: string,
    eventType: string,
    timestamp: number,
    sdkVersion: string
  ) {
    this.uuid = uuid
    this.data = data
    this.eventType = eventType
    this.timestamp = timestamp
    this.sdkVersion = sdkVersion
  }

  static fromEvent<T extends Event>(
    event: T
  ): EventPersistence {
    let uuid = util.generateRandomUUID(false)
    let data = event.toSerialize()
    let eventType = event.eventType
    let timestamp = event.timestamp
    let sdkVersion = SDK_VERSION
    let e = new EventPersistence(uuid, data, eventType, timestamp, sdkVersion)
    return e
  }

  static fromDatabase(
    uuid: string,
    data: string,
    eventType: string,
    timestamp: number,
    sdkVersion: string
  ): EventPersistence {
    let e = new EventPersistence(uuid, data, eventType, timestamp, sdkVersion)
    return e
  }
}