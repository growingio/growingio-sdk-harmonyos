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
import GrowingContext from '../core/Context'
import PageEvent from './PageEvent'
import { ConfigMode } from '../interfaces/GrowingConfig'

export default class CustomEvent extends Event {
  eventName: string = ''

  // mode SaaS
  path: string | undefined = undefined
  pageShowTimestamp: number | undefined = undefined

  static create(
    eventName: string,
    attributes: AttributesType,
    context: GrowingContext
  ): CustomEvent {
    let event = new CustomEvent()
    event.eventName = eventName
    event.attributes = attributes
    event.eventType = EventType.Custom

    if (context.config.mode == ConfigMode.SaaS) {
      if (PageEvent.lastPage) {
        event.path = PageEvent.lastPage.path ?? ''
        event.pageShowTimestamp = PageEvent.lastPage.timestamp ?? 0
      }
    }

    return EventBuilder.build(event, context)
  }
}