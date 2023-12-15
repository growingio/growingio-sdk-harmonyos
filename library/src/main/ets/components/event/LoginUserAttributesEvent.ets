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
import Util from '../utils/Util'

export default class LoginUserAttributesEvent extends Event {
  attributes: AttributesType = {}

  static create(attributes: AttributesType): LoginUserAttributesEvent {
    let event = new LoginUserAttributesEvent()
    event.attributes = Util.convertAttributes(attributes) as AttributesType
    event.eventType = EventType.LoginUserAttributes
    return EventBuilder.build(event)
  }
}