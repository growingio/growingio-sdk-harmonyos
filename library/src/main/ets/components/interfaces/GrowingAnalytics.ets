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

import AnalyticsCore from '../core/AnalyticsCore'
import { GrowingConfig } from './GrowingConfig'
import Session from '../core/Session'
import { AttributesType } from '../utils/Constants'
import GrowingContext from '../core/Context'
export { AttributesType as GrowingAttrType } from '../utils/Constants'

export interface GrowingAnalyticsInterface {
   setDataCollectionEnabled(enabled: boolean)
   setLoginUserId(userId: string, userKey: string)
   cleanLoginUserId()

   setLoginUserAttributes(attributes: AttributesType)
   track(eventName: string, attributes: AttributesType)
   trackTimerStart(eventName: string): Promise<string>
   trackTimerPause(timerId: string)
   trackTimerResume(timerId: string)
   trackTimerEnd(timerId: string, attributes: AttributesType)
   removeTimer(timerId: string)
   clearTrackTimer()

   setGeneralProps(props: AttributesType)
   removeGeneralProps(keys: string[])
   clearGeneralProps()
}

export class GrowingAnalytics {
  static async start(context: Context, configuration: GrowingConfig): Promise<void> {
    if (AnalyticsCore.core) {
      console.warn('[GrowingAnalytics] Do not initialize GrowingAnalytics repeatedly')
      return
    }
    if (!context.stageMode) {
      console.error('[GrowingAnalytics] Only support stageMode(HarmonyOS 3.1+, API 9+)')
      return
    }
    let config = configuration.copy()
    await AnalyticsCore.startCore(context, config)
    Session.refreshSession(GrowingContext.getDefaultContext())
  }

  static startMultiTracker(trackerId: string, configuration: GrowingConfig) {
    if (!AnalyticsCore.core) {
      console.error('[GrowingAnalytics] Must call GrowingAnalytics.start(context, configuration) first')
      return
    }

    let config = configuration.copy()
    let success = AnalyticsCore.startMultiTracker(trackerId, config)
    if (success) {
      Session.refreshSession(GrowingContext.getContext(trackerId))
    } else {
      console.error('[GrowingAnalytics] Do not start tracker with same trackerId')
    }
  }

  static tracker<T extends GrowingAnalyticsInterface>(trackerId: string): T | undefined {
    return AnalyticsCore.tracker(trackerId) as unknown as T | undefined
  }

  static isInitializedSuccessfully(trackerId?: string): boolean {
    if (trackerId && trackerId.length > 0) {
      return AnalyticsCore.tracker(trackerId) != undefined
    } else {
      return AnalyticsCore.core != undefined
    }
  }

  static setDataCollectionEnabled(enabled: boolean) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core.setDataCollectionEnabled(enabled)
  }

  static setLoginUserId(
    userId: string,
    userKey: string = ''
  ) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core.setLoginUserId(userId, userKey)
  }

  static cleanLoginUserId() {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core.setLoginUserId('')
  }

  static setLoginUserAttributes(attributes: AttributesType) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core.setLoginUserAttributes(attributes)
  }

  static getDeviceId(): string {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return ''
    }
    return AnalyticsCore.core.getDeviceId()
  }

  static track(
    eventName: string,
    attributes: AttributesType = {}
  ) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core.track(eventName, attributes)
  }

  static async trackTimerStart(eventName: string): Promise<string> {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return ''
    }
    return await AnalyticsCore.core.trackTimerStart(eventName)
  }

  static async trackTimerPause(timerId: string) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    await AnalyticsCore.core.trackTimerPause(timerId)
  }

  static async trackTimerResume(timerId: string) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    await AnalyticsCore.core.trackTimerResume(timerId)
  }

  static async trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {}
  ) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    await AnalyticsCore.core.trackTimerEnd(timerId, attributes)
  }

  static removeTimer(timerId: string) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core.removeTimer(timerId)
  }

  static clearTrackTimer() {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core.clearTrackTimer()
  }

  static setGeneralProps(props: AttributesType) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core.setGeneralProps(props)
  }

  static removeGeneralProps(keys: string[]) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core.removeGeneralProps(keys)
  }

  static clearGeneralProps() {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core.clearGeneralProps()
  }

  static setLocation(
    latitude: number,
    longitude: number
  ) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.setLocation(latitude, longitude)
  }

  static cleanLocation() {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.setLocation(0, 0)
  }
}