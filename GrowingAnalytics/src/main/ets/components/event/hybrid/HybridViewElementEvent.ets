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

import HybridEvent from './HybridEvent'
import Event, { EventType, AttributesType } from '../Event'
import EventBuilder from '../EventBuilder'
import GrowingContext from '../../core/Context'

export default class HybridViewElementEvent extends Event implements HybridEvent {
  textValue: string | undefined = undefined
  xpath: string | undefined = undefined
  xcontent: string | undefined = undefined
  index: number | undefined = undefined
  hyperlink: string | undefined = undefined
  path: string | undefined = undefined
  query: string | undefined = undefined

  static async create(
    textValue: string,
    xpath: string,
    xcontent: string,
    index: number,
    hyperlink: string,
    attributes: AttributesType,
    path: string,
    query: string,
    timestamp: number,
    domain: string,
    eventType: EventType,
    context: GrowingContext
  ): Promise<HybridViewElementEvent> {
    let event = new HybridViewElementEvent()
    event.textValue = textValue
    event.xpath = xpath
    event.xcontent = xcontent
    event.index = index && index > 0 ? index : undefined
    event.hyperlink = hyperlink
    event.attributes = attributes
    event.path = path
    event.query = query
    event.timestamp = Number(timestamp ?? 0)
    event.domain = String(domain ?? '')
    event.eventType = eventType
    return await EventBuilder.build(event, context)
  }
}