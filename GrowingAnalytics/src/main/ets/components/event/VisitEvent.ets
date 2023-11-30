import Event, { EventType } from './Event'
import EventBuilder from './EventBuilder'

export default class VisitEvent extends Event {
  static create(): Promise<VisitEvent> {
    var event = new VisitEvent()
    event.eventType = EventType.Visit
    return EventBuilder.build(event)
  }
}