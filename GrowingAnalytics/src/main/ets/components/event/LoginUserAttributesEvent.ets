import Event, { EventType, AttributesType } from './Event'
import EventBuilder from './EventBuilder'

export default class LoginUserAttributesEvent extends Event {
  attributes: AttributesType

  static create(attributes: AttributesType): Promise<LoginUserAttributesEvent> {
    var event = new LoginUserAttributesEvent()
    event.attributes = attributes
    event.eventType = EventType.LoginUserAttributes
    return EventBuilder.build(event)
  }
}