import Event, { EventType } from './Event'

export default class CustomEvent extends Event {
  eventName: string = ''
  attributes: object

  static create(eventName: string, attributes: object): Promise<CustomEvent> {
    var event = new CustomEvent()
    event.eventName = eventName
    event.attributes = attributes
    event.eventType = EventType.Custom
    return event.build()
  }

  toSerialize(): Object {
    return null
  }
}