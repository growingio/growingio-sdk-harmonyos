import Event, { EventType, AttributesType } from './Event'
import EventBuilder from './EventBuilder'

export default class CustomEvent extends Event {
  eventName: string = ''
  attributes: AttributesType

  static create(eventName: string, attributes: AttributesType): Promise<CustomEvent> {
    var event = new CustomEvent()
    event.eventName = eventName
    event.attributes = this.convertAttributes(attributes)
    event.eventType = EventType.Custom
    return EventBuilder.build(event)
  }

  static convertAttributes(attributes: AttributesType): { [key: string]: string } {
    var result: { [key: string]: string } = {}
    Object.keys(attributes).forEach(key => {
      var value = attributes[key]
      if (Array.isArray(value)) {
        const stringValue = value.map(String).join('||')
        result[key] = stringValue
      } else {
        result[key] = String(value)
      }
    })
    return result
  }
}