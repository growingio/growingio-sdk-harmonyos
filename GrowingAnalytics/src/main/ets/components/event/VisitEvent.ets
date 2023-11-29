import Event, { EventType } from './Event'

export default class VisitEvent extends Event {
  static create(): Promise<VisitEvent> {
    var event = new VisitEvent()
    event.eventType = EventType.Visit
    return event.build()
  }

  toSerialize(): Object {
    return null
  }
}