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

import EventSender, { EventSenderType } from '../event/EventSender'
import { ConfigMode, GrowingConfig } from '../interfaces/GrowingConfig'

export default class GrowingContext {
  trackerId: string
  config: GrowingConfig
  eventSender: EventSender[] = []
  static contexts: Map<string, GrowingContext> = new Map()
  static defaultContext: GrowingContext | undefined = undefined

  constructor(trackerId: string, config: GrowingConfig) {
    this.trackerId = trackerId
    this.config = config

    if (config.mode == ConfigMode.SaaS) {
      this.eventSender.push(new EventSender(EventSenderType.SaaS_PV, this.trackerId))
      this.eventSender.push(new EventSender(EventSenderType.SaaS_CSTM, this.trackerId))
    } else {
      this.eventSender.push(new EventSender(EventSenderType.NewSaaS, this.trackerId))
    }
  }

  static hasSimilarContext(trackerId: string, configuration: GrowingConfig): boolean {
    let hasSimilarContext = false
    for (let context of GrowingContext.contexts.values()) {
      if (context.trackerId == trackerId) {
        hasSimilarContext = true
        break
      }
      let config: GrowingConfig = context.config
      if (config.accountId == configuration.accountId &&
        config.dataSourceId == configuration.dataSourceId) {
        hasSimilarContext = true
        break
      }
    }
    return hasSimilarContext
  }

  static getContext(trackerId: string): GrowingContext | undefined {
    return GrowingContext.contexts.get(trackerId)
  }

  static setContext(trackerId: string, configuration: GrowingConfig) {
    let context = new GrowingContext(trackerId, configuration)
    GrowingContext.contexts.set(trackerId, context)
  }

  static setDefaultContext(configuration: GrowingConfig) {
    let trackerId = '__GrowingAnalyticsCore'
    let context = new GrowingContext(trackerId, configuration)
    GrowingContext.defaultContext = context
    GrowingContext.contexts.set(trackerId, context)
  }

  static getDefaultContext(): GrowingContext | undefined {
    return GrowingContext.defaultContext
  }

  static isDefaultContext(context: GrowingContext): boolean {
    return context == GrowingContext.defaultContext
  }
}