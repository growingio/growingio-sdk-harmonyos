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

import Event, { EventType, AttributesType } from '../Event'
import EventBuilder from '../EventBuilder'
import GrowingContext from '../../core/Context'
import Util from '../../utils/Util'
import AnalyticsCore from '../../core/AnalyticsCore'

export class SaaSVisitorEvent extends Event {
  static visitorAttributes: Record<string, AttributesType> = {}

  static async create(
    attributes: AttributesType,
    context: GrowingContext,
    shouldCacheAttributesInMemory: boolean = true
  ): Promise<SaaSVisitorEvent> {
    if (shouldCacheAttributesInMemory) {
      SaaSVisitorEvent.visitorAttributes[context.trackerId] = Util.cloneObject(attributes)
    }

    let event = new SaaSVisitorEvent()
    event.attributes = attributes
    event.eventType = EventType.SaaS_Vstr
    return await EventBuilder.build(event, context)
  }

  static async sendVisitorIfNeeded(context: GrowingContext) {
    let attributes = SaaSVisitorEvent.visitorAttributes[context.trackerId]
    if (!attributes) {
       return
    }
    let p = await SaaSVisitorEvent.create(attributes, context, false)
    AnalyticsCore.writeEventToDisk(p, context)
  }
}

export class SaaSEvarEvent extends Event {
  static async create(
    attributes: AttributesType,
    context: GrowingContext
  ): Promise<SaaSEvarEvent> {
    let event = new SaaSEvarEvent()
    event.attributes = attributes
    event.eventType = EventType.SaaS_Evar
    return await EventBuilder.build(event, context)
  }
}