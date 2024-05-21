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

export default class HybridPageEvent extends Event implements HybridEvent {
  title: string | undefined = undefined
  referralPage: string | undefined = undefined
  protocolType: string | undefined = undefined

  path: string | undefined = undefined
  query: string | undefined = undefined

  static create(
    title: string,
    referralPage: string,
    protocolType: string,
    attributes: AttributesType,
    path: string,
    query: string,
    timestamp: number,
    domain: string,
    context: GrowingContext
  ): HybridPageEvent {
    let event = new HybridPageEvent()
    event.title = title
    event.referralPage = referralPage
    event.protocolType = protocolType
    event.attributes = attributes
    event.path = path
    event.query = query
    event.timestamp = timestamp
    event.domain = domain
    event.eventType = EventType.Page
    return EventBuilder.build(event, context)
  }
}