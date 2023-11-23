import Event, { EventType } from './Event'

interface CustomEventBuilder {
  setEventName(eventName: string): CustomEventBuilder
  setAttributes(attributes: object): CustomEventBuilder
}

export default class CustomEvent extends Event implements CustomEventBuilder {
  eventName: string = ''
  attributes: object

  setEventName(eventName: string): CustomEventBuilder {
    this.eventName = eventName
    return this
  }

  setAttributes(attributes: Map<string, string>): CustomEventBuilder {
    this.attributes = attributes
    return this
  }

  static create(eventName: string, attributes: object): CustomEvent {
    var event = new CustomEvent()
    event.setEventName(eventName).setAttributes(attributes)
    event.eventType = EventType.Custom
    return event.build()
  }

  toSerialize(): Object {
    return null
  }
}