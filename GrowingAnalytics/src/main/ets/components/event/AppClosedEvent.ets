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

import Event, { EventType } from './Event'
import EventBuilder from './EventBuilder'
import GrowingContext from '../core/Context'
import PageEvent from './PageEvent'
import { ConfigMode } from '../interfaces/GrowingConfig'

export default class AppClosedEvent extends Event {

  // mode SaaS
  path: string | undefined = undefined

  static create(context: GrowingContext): AppClosedEvent {
    let event = new AppClosedEvent()
    event.eventType = EventType.AppClosed

    if (context.config.mode == ConfigMode.SaaS) {
      let lastPage = PageEvent.getLastPage(context)
      if (lastPage) {
        event.path = lastPage.path ?? ''
      }
    }

    return EventBuilder.build(event, context)
  }
}