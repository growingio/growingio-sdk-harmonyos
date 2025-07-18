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

import common from '@ohos.app.ability.common'

import { GrowingConfig } from './GrowingConfig'
import AnalyticsCore from '../core/AnalyticsCore'
import { AttributesType as GrowingAttrType } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'

export { AttributesType as GrowingAttrType } from '../utils/Constants'

export interface GrowingAnalyticsInterface {
  isInitializedSuccessfully(): boolean
  setDataCollectionEnabled(enabled: boolean): void
  setLoginUserId(userId: string, userKey?: string): void
  cleanLoginUserId(): void
  track(eventName: string, attributes?: GrowingAttrType, sendTo?: string[]): void
}

export class GrowingAnalytics {
  static start(context: Context, configuration: GrowingConfig) {
    if (GrowingAnalytics.isInitializedSuccessfully()) {
      LogUtil.warn(() => 'Do not initialize GrowingAnalytics repeatedly')
      return
    }
    let config = configuration.copy()
    AnalyticsCore.startCore(context, config)
  }

  static deferStart(context: common.UIAbilityContext, configuration: GrowingConfig) {
    // In the case of delayed initialization, avoid users calling start and ensure that the context is UIAbilityContext
    GrowingAnalytics.start(context, configuration)
  }

  static startSubTracker(trackerId: string, configuration: GrowingConfig) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      LogUtil.error(() => 'Must call GrowingAnalytics.start(context, configuration) first')
      return
    }

    let config = configuration.copy()
    let success = AnalyticsCore.startSubTracker(trackerId, config)
    if (!success) {
      LogUtil.error(() => 'Do not start tracker with the same trackerId or the same accountId and dataSourceId')
    }
  }

  static tracker(trackerId: string): GrowingAnalyticsInterface {
    let tracker = AnalyticsCore.tracker(trackerId)
    if (!tracker.isInitializedSuccessfully()) {
      LogUtil.error(() => 'Please start a subTracker with the trackerId ' + trackerId + ' first')
    }
    return tracker
  }

  static isInitializedSuccessfully(trackerId?: string): boolean {
    if (trackerId) {
      return AnalyticsCore.tracker(trackerId).isInitializedSuccessfully()
    } else {
      return AnalyticsCore.core.isInitializedSuccessfully()
    }
  }

  static setDataCollectionEnabled(enabled: boolean) {
    AnalyticsCore.core.setDataCollectionEnabled(enabled)
  }

  static setLoginUserId(
    userId: string,
    userKey?: string
  ) {
    AnalyticsCore.core.setLoginUserId(userId, userKey)
  }

  static cleanLoginUserId() {
    AnalyticsCore.core.setLoginUserId('')
  }

  static getDeviceId(): string {
    return AnalyticsCore.core.getDeviceId()
  }

  static track(
    eventName: string,
    attributes?: GrowingAttrType,
    sendTo?: string[]
  ) {
    AnalyticsCore.core.track(eventName, attributes, sendTo)
  }

  static setLocation(
    latitude: number,
    longitude: number
  ) {
    AnalyticsCore.setLocation(latitude, longitude)
  }

  static cleanLocation() {
    AnalyticsCore.setLocation(0, 0)
  }
}