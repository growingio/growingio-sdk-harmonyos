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

import { GrowingConfig } from '../interfaces/GrowingConfig'

export default class GrowingContext {
  trackerId: string
  config: GrowingConfig
  static contexts: Map<string, GrowingContext> = new Map()
  static defaultContext: GrowingContext | undefined = undefined

  constructor(trackerId: string, config: GrowingConfig) {
    this.trackerId = trackerId
    this.config = config
  }

  static getContext(trackerId: string): GrowingContext | undefined {
    return GrowingContext.contexts.get(trackerId)
  }

  static setContext(trackerId: string, configuration: GrowingConfig) {
    let config = configuration.copy()
    let context = new GrowingContext(trackerId, config)
    GrowingContext.contexts.set(trackerId, context)
  }

  static setDefaultContext(configuration: GrowingConfig) {
    let trackerId = '__GrowingAnalyticsCore'
    let config = configuration.copy()
    let context = new GrowingContext(trackerId, config)
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