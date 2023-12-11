import util from '@ohos.util'

import Event from './Event'

export default class EventPersistence {
  uuid: string
  data: string
  eventType: string
  sdkVersion: string

  constructor(
    uuid: string,
    data: string,
    eventType: string,
    sdkVersion: string
  ) {
    this.uuid = uuid
    this.data = data
    this.eventType = eventType
    this.sdkVersion = sdkVersion
  }

  static fromEvent<T extends Event>(
    event: T
  ): EventPersistence {
    let uuid = util.generateRandomUUID(false)
    let data = event.toSerialize()
    let eventType = event.eventType
    let sdkVersion = event.sdkVersion
    let e = new EventPersistence(uuid, data, eventType, sdkVersion)
    return e
  }

  static fromDatabase(
    uuid: string,
    data: string,
    eventType: string,
    sdkVersion: string
  ): EventPersistence {
    let e = new EventPersistence(uuid, data, eventType, sdkVersion)
    return e
  }
}