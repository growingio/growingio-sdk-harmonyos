/**
 * @license
 * Copyright (C) 2024 Beijing Yishu Technology Co., Ltd.
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
import GrowingContext from '../core/Context'
import { ConfigMode } from '../interfaces/GrowingConfig'

export default class ViewElementEvent extends Event {
  path: string | undefined = undefined
  textValue: string | undefined = undefined
  xpath: string | undefined = undefined
  xcontent: string | undefined = undefined
  index: number | undefined = undefined

  // mode CDP
  pageShowTimestamp: number | undefined = undefined

  static create(
    path: string,
    pageShowTimestamp: number,
    textValue: string,
    xpath: string,
    xcontent: string,
    index: number,
    attributes: AttributesType,
    eventType: EventType,
    context: GrowingContext
  ): ViewElementEvent {
    let event = new ViewElementEvent()
    event.path = String(path ?? '')
    if (context.config.mode == ConfigMode.CDP) {
      event.pageShowTimestamp = pageShowTimestamp > 0 ? pageShowTimestamp : Date.now()
    }
    event.textValue = textValue && textValue.length > 0 ? textValue : undefined
    event.xpath = xpath
    event.xcontent = xcontent
    event.index = index && index > 0 ? index : undefined
    event.attributes = attributes
    event.eventType = eventType
    return EventBuilder.build(event, context)
  }
}