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

import webview from '@ohos.web.webview'

import { GrowingConfig } from './GrowingConfig'
import AnalyticsCore from '../core/AnalyticsCore'
import GrowingContext from '../core/Context'
import GeneralProps from '../core/GeneralProps'
import Session from '../core/Session'
import { AttributesType, JavaScriptProxyType } from '../utils/Constants'
import PropertyPlugin, { PropertyPluginInterface } from '../core/PropertyPlugin'

export { EventType as GrowingEventType } from '../event/Event'
export { PropertyPluginInterface as GrowingPropPlugin, EventFilter as GrowingPropPluginEventFilter } from '../core/PropertyPlugin'
export { AttributesType as GrowingAttrType, JavaScriptProxyType as GrowingJSProxyType } from '../utils/Constants'

export interface GrowingAnalyticsInterface {
   setDataCollectionEnabled(enabled: boolean): void
   setLoginUserId(userId: string, userKey?: string): void
   cleanLoginUserId(): void

   setLoginUserAttributes(attributes: AttributesType): void
   track(eventName: string, attributes: AttributesType, sendTo?: string[]): void
   trackTimerStart(eventName: string): Promise<string>
   trackTimerPause(timerId: string): void
   trackTimerResume(timerId: string): void
   trackTimerEnd(timerId: string, attributes: AttributesType): void
   removeTimer(timerId: string): void
   clearTrackTimer(): void
}

export class GrowingAnalytics {
  static async start(context: Context, configuration: GrowingConfig): Promise<void> {
    if (GrowingAnalytics.isInitializedSuccessfully()) {
      console.warn('[GrowingAnalytics] Do not initialize GrowingAnalytics repeatedly')
      return
    }
    if (!context.stageMode) {
      console.error('[GrowingAnalytics] Only support stageMode(HarmonyOS 3.1+, API 9+)')
      return
    }
    let config = configuration.copy()
    await AnalyticsCore.startCore(context, config)
    Session.refreshSession(GrowingContext.getDefaultContext()!)
  }

  static startSubTracker(trackerId: string, configuration: GrowingConfig) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      console.error('[GrowingAnalytics] Must call GrowingAnalytics.start(context, configuration) first')
      return
    }

    let config = configuration.copy()
    let success = AnalyticsCore.startSubTracker(trackerId, config)
    if (success) {
      Session.refreshSession(GrowingContext.getContext(trackerId)!)
    } else {
      console.error('[GrowingAnalytics] Do not start tracker with same trackerId')
    }
  }

  static tracker(trackerId: string): GrowingAnalyticsInterface | undefined {
    let tracker = AnalyticsCore.tracker(trackerId)
    return tracker
  }

  static createHybridProxy(controller: webview.WebviewController): JavaScriptProxyType | undefined {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return undefined
    }
    return AnalyticsCore.core!.createHybridProxy(controller)
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
    AnalyticsCore.core!.setDataCollectionEnabled(enabled)
  }

  static setLoginUserId(
    userId: string,
    userKey?: string
  ) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core!.setLoginUserId(userId, userKey)
  }

  static cleanLoginUserId() {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core!.setLoginUserId('')
  }

  static setLoginUserAttributes(attributes: AttributesType) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core!.setLoginUserAttributes(attributes)
  }

  static getDeviceId(): string {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return ''
    }
    return AnalyticsCore.core!.getDeviceId()
  }

  static track(
    eventName: string,
    attributes: AttributesType = {},
    sendTo?: string[]
  ) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core!.track(eventName, attributes, sendTo)
  }

  static async trackTimerStart(eventName: string): Promise<string> {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return ''
    }
    return await AnalyticsCore.core!.trackTimerStart(eventName)
  }

  static async trackTimerPause(timerId: string) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    await AnalyticsCore.core!.trackTimerPause(timerId)
  }

  static async trackTimerResume(timerId: string) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    await AnalyticsCore.core!.trackTimerResume(timerId)
  }

  static async trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {}
  ) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    await AnalyticsCore.core!.trackTimerEnd(timerId, attributes)
  }

  static removeTimer(timerId: string) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core!.removeTimer(timerId)
  }

  static clearTrackTimer() {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      return
    }
    AnalyticsCore.core!.clearTrackTimer()
  }

  static setGeneralProps(props: AttributesType) {
    GeneralProps.setGeneralProps(props)
  }

  static removeGeneralProps(keys: string[]) {
    GeneralProps.removeGeneralProps(keys)
  }

  static clearGeneralProps() {
    GeneralProps.clearGeneralProps()
  }

  static setDynamicGeneralProps(generator: () => AttributesType) {
    GeneralProps.setDynamicGeneralProps(generator)
  }

  static setEventPropertyPlugin(plugin: PropertyPluginInterface) {
    PropertyPlugin.setPlugin(plugin)
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