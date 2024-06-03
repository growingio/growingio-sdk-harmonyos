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

import Event, { EventType } from '../Event'
import EventBuilder from '../EventBuilder'
import GrowingContext from '../../core/Context'

const FAKE_PAGE_PATH = "GIOFakePage"

export default class FakePageEvent extends Event {
  path: string = FAKE_PAGE_PATH
  pageShowTimestamp: number = 0

  static create(context: GrowingContext): FakePageEvent {
    let event = new FakePageEvent()
    event.pageShowTimestamp = Date.now()
    event.eventType = EventType.Page
    return EventBuilder.build(event, context)
  }
}