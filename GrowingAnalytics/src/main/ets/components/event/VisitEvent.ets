import Event, { EventType } from './Event'
import Session from '../core/Session'

export default class VisitEvent extends Event {
  static create(): Promise<VisitEvent> {
    var event = new VisitEvent()
    event.eventType = EventType.Visit
    event.sessionId = Session.sharedInstance().sessionId
    return event.build()
  }

  toSerialize(): Object {
    return null
  }
}