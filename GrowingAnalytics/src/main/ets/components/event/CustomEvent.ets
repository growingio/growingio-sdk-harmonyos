import Event, { EventType, AttributesType } from './Event'
import EventBuilder from './EventBuilder'

export default class CustomEvent extends Event {
  eventName: string = ''
  attributes: AttributesType

  static create(eventName: string, attributes: AttributesType): Promise<CustomEvent> {
    let event = new CustomEvent()
    event.eventName = eventName
    event.attributes = this.convertAttributes(attributes)
    event.eventType = EventType.Custom
    return EventBuilder.build(event)
  }

  static convertAttributes(attributes: AttributesType): { [key: string]: string } {
    let result: { [key: string]: string } = {}
    Object.keys(attributes).forEach(key => {
      let value = attributes[key]
      if (Array.isArray(value)) {
        let stringValue = value.map(String).join('||')
        result[key] = stringValue
      } else {
        result[key] = String(value)
      }
    })
    return Object.keys(result).length > 0 ? result : undefined
  }
}