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

export class GrowingAnalytics {
  static async start(
    context: Context,
    configuration: GrowingConfig
  ) {
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
    Session.refreshSession()
  }

  static isInitializedSuccessfully(): boolean {
    return AnalyticsCore.core != null
  }

  static setDataCollectionEnabled(enabled: boolean) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.setDataCollectionEnabled(enabled)
  }

  static setLoginUserId(
    userId: string,
    userKey: string = ''
  ) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.setLoginUserId(userId, userKey)
  }

  static cleanLoginUserId() {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.setLoginUserId('')
  }

  static setLocation(
    latitude: number,
    longitude: number
  ) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.setLocation(latitude, longitude)
  }

  static cleanLocation() {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.setLocation(0, 0)
  }

  static setLoginUserAttributes(attributes: AttributesType) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.setLoginUserAttributes(attributes)
  }

  static getDeviceId(): string {
    if (!AnalyticsCore.core) {
      return ''
    }
    return AnalyticsCore.core.getDeviceId()
  }

  static track(
    eventName: string,
    attributes: AttributesType = {}
  ) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.track(eventName, attributes)
  }

  static async trackTimerStart(eventName: string): Promise<string> {
    if (!AnalyticsCore.core) {
      return ''
    }
    return await AnalyticsCore.core.trackTimerStart(eventName)
  }

  static async trackTimerPause(timerId: string) {
    if (!AnalyticsCore.core) {
      return
    }
    await AnalyticsCore.core.trackTimerPause(timerId)
  }

  static async trackTimerResume(timerId: string) {
    if (!AnalyticsCore.core) {
      return
    }
    await AnalyticsCore.core.trackTimerResume(timerId)
  }

  static async trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {}
  ) {
    if (!AnalyticsCore.core) {
      return
    }
    await AnalyticsCore.core.trackTimerEnd(timerId, attributes)
  }

  static removeTimer(timerId: string) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.removeTimer(timerId)
  }

  static clearTrackTimer() {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.clearTrackTimer()
  }

  static setGeneralProps(props: AttributesType) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.setGeneralProps(props)
  }

  static removeGeneralProps(keys: string[]) {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.removeGeneralProps(keys)
  }

  static clearGeneralProps() {
    if (!AnalyticsCore.core) {
      return
    }
    AnalyticsCore.core.clearGeneralProps()
  }
}