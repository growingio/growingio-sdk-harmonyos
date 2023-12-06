/**
 * @license
 * Copyright (C) 2023 Beijing Yishu Technology Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Event, { EventType, AttributesType } from './Event'
import EventBuilder from './EventBuilder'

export default class CustomEvent extends Event {
  eventName: string = ''
  attributes: AttributesType

  static create(eventName: string, attributes: AttributesType): CustomEvent {
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