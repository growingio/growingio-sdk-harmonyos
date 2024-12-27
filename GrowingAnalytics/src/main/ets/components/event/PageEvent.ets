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

export interface Page {
  path: string | undefined
  title: string | undefined
  timestamp: number
  attributes: AttributesType | undefined

  // mode SaaS
  referralPage: string | undefined
}

export default class PageEvent extends Event implements Page {
  path: string | undefined = undefined
  title: string | undefined = undefined

  // mode SaaS
  private static lastPage: Record<string, Page> = {}
  referralPage: string | undefined = undefined

  static create(
    path: string,
    title: string,
    attributes: AttributesType,
    context: GrowingContext
  ): PageEvent {
    let event = new PageEvent()
    event.path = path
    event.title = title ?? undefined
    event.attributes = attributes
    event.eventType = EventType.Page

    if (context.config.mode == ConfigMode.SaaS) {
      let lastPage = PageEvent.getLastPage(context)
      if (lastPage) {
        event.referralPage = lastPage.path
      }
      PageEvent.setLastPage(event, context)
    }

    return EventBuilder.build(event, context)
  }

  static getLastPage(context: GrowingContext): Page | undefined {
    return PageEvent.lastPage[context.trackerId]
  }

  static setLastPage(page: Page, context: GrowingContext) {
    PageEvent.lastPage[context.trackerId] = page
  }
}