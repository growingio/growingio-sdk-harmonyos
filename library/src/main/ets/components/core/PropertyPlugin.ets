import Event, { AttributesType, EventScene, EventType } from '../event/Event'
import CustomEvent from '../event/CustomEvent'
import Util from '../utils/Util'
import GrowingContext from './Context'

export default class PropertyPlugin {
  static plugins: PropertyPluginInterface[] = []

  static setPlugin(plugin: PropertyPluginInterface) {
    PropertyPlugin.plugins.push(plugin)
    PropertyPlugin.plugins.sort((a, b) => b.priority() - a.priority())
  }

  static execute<T extends Event>(event: T, eventScene: EventScene, context: GrowingContext) {
    let filter = new EventFilterImpl(event, eventScene, context)
    for (let plugin of PropertyPlugin.plugins) {
      if (!plugin.isMatchedWithFilter(filter)) {
        break
      }
      let attributes = plugin.attributes(event.attributes)
      event.attributes = Util.serializableAttributes(attributes)
    }
  }
}

export interface PropertyPluginInterface {
  attributes(attributes: AttributesType | undefined): AttributesType | undefined
  isMatchedWithFilter(filter: EventFilter): boolean
  priority(): number
}

export interface EventFilter {
  name(): string
  type(): EventType
  time(): number
  isFromHybrid(): boolean
  trackerId(): string
}

class EventFilterImpl<T extends Event> implements EventFilter {
  private _event: T
  private _eventScene: EventScene
  private _context: GrowingContext

  constructor(
    event: T,
    eventScene: EventScene,
    context: GrowingContext
  ) {
    this._event = event
    this._eventScene = eventScene
    this._context = context
  }

  name(): string {
    if (this._event instanceof CustomEvent) {
      return (this._event as CustomEvent).eventName
    }
    return ''
  }

  type(): EventType {
    return this._event.eventType
  }

  time(): number {
    return this._event.timestamp
  }

  isFromHybrid(): boolean {
    return this._eventScene == EventScene.Hybrid
  }

  trackerId(): string {
    return this._context.trackerId
  }
}