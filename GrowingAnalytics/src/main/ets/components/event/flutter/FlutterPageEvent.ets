/**
 * @license
* Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.
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

import Event, { EventType, AttributesType } from './../Event'
import { Page } from './../PageEvent'
import EventBuilder from './../EventBuilder'
import GrowingContext from '../../core/Context'
import DeviceInfo from '../../core/DeviceInfo'

export default class FlutterPageEvent extends Event implements Page {
  path: string | undefined = undefined
  title: string | undefined = undefined
  orientation: string | undefined = undefined
  referralPage: string | undefined = undefined

  static create(
    path: string,
    title: string,
    attributes: AttributesType,
    timestamp: number,
    referralPage: string | undefined,
    context: GrowingContext
  ): FlutterPageEvent {
    let event = new FlutterPageEvent()
    event.path = path
    event.title = title ?? undefined
    event.attributes = attributes
    event.timestamp = timestamp
    event.orientation = DeviceInfo.orientation
    event.eventType = EventType.Page
    event.referralPage = referralPage ?? undefined

    return EventBuilder.build(event, context)
  }
}