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
import PageEvent, { Page } from '../PageEvent'
import AnalyticsCore from '../../core/AnalyticsCore'
import GrowingContext from '../../core/Context'

const FAKE_PAGE_PATH = "GIOFakePage"

// mode SaaS
export default class FakePageEvent extends Event implements Page {
  path: string = FAKE_PAGE_PATH
  title: string | undefined = undefined
  referralPage: string | undefined = undefined

  static create(context: GrowingContext): FakePageEvent {
    let event = new FakePageEvent()
    event.eventType = EventType.Page
    PageEvent.setLastPage(event, context)
    return EventBuilder.build(event, context)
  }

  static sendFakePageIfNeeded(context: GrowingContext) {
    if (GrowingContext.isDefaultContext(context) &&
        context.config.autotrackEnabled &&
        context.config.autotrackAllPages) {
      // 当前是主实例，且已开启PAGE无感埋点
      return
    }
    let p = FakePageEvent.create(context)
    AnalyticsCore.writeEventToDisk(p, context)
  }
}