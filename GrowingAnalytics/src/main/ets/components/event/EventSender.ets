import Event from './Event'

export default class EventSender {
  static sendEvent = <T extends Event>(
  event: T
  ) => {
    var serialize = event.toSerialize()

  }
}