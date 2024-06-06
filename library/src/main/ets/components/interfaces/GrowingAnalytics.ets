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
import { LogUtil } from '../utils/LogUtil'

export { AttributesType as GrowingAttrType, JavaScriptProxyType as GrowingJSProxyType } from '../utils/Constants'

export interface GrowingAnalyticsInterface {
  isInitializedSuccessfully(): boolean
  setDataCollectionEnabled(enabled: boolean): void
  setLoginUserId(userId: string, userKey?: string): void
  cleanLoginUserId(): void

  setLoginUserAttributes(attributes: AttributesType): void
  track(eventName: string, attributes: AttributesType, sendTo?: string[]): void
  trackTimerStart(eventName: string): Promise<string>
  trackTimerPause(timerId: string): void
  trackTimerResume(timerId: string): void
  trackTimerEnd(timerId: string, attributes: AttributesType, sendTo?: string[]): void
  removeTimer(timerId: string): void
  clearTrackTimer(): void
}

export class GrowingAnalytics {
  static async start(context: Context, configuration: GrowingConfig): Promise<void> {
    if (GrowingAnalytics.isInitializedSuccessfully()) {
      LogUtil.warn(() => '[GrowingAnalytics] Do not initialize GrowingAnalytics repeatedly')
      return
    }
    if (!context.stageMode) {
      LogUtil.error(() => '[GrowingAnalytics] Only support stageMode')
      return
    }
    let config = configuration.copy()
    await AnalyticsCore.startCore(context, config)
    Session.refreshSession(GrowingContext.getDefaultContext()!)
  }

  static startSubTracker(trackerId: string, configuration: GrowingConfig) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      LogUtil.error(() => '[GrowingAnalytics] Must call GrowingAnalytics.start(context, configuration) first')
      return
    }

    let config = configuration.copy()
    let success = AnalyticsCore.startSubTracker(trackerId, config)
    if (success) {
      Session.refreshSession(GrowingContext.getContext(trackerId)!)
    } else {
      LogUtil.error(() => '[GrowingAnalytics] Do not start tracker with same trackerId/dataSourceId')
    }
  }

  static tracker(trackerId: string): GrowingAnalyticsInterface {
    let tracker = AnalyticsCore.tracker(trackerId)
    if (!tracker.isInitializedSuccessfully()) {
      LogUtil.error(() => '[GrowingAnalytics] Please start a subTracker with the trackerId ' + trackerId + ' first')
    }
    return tracker
  }

  static createHybridProxy(controller: webview.WebviewController): JavaScriptProxyType | undefined {
    return AnalyticsCore.core.createHybridProxy(controller)
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

  static setLoginUserAttributes(attributes: AttributesType) {
    AnalyticsCore.core.setLoginUserAttributes(attributes)
  }

  static getDeviceId(): string {
    return AnalyticsCore.core.getDeviceId()
  }

  static track(
    eventName: string,
    attributes: AttributesType = {},
    sendTo?: string[]
  ) {
    AnalyticsCore.core.track(eventName, attributes, sendTo)
  }

  static async trackTimerStart(eventName: string): Promise<string> {
    return await AnalyticsCore.core.trackTimerStart(eventName)
  }

  static async trackTimerPause(timerId: string) {
    await AnalyticsCore.core.trackTimerPause(timerId)
  }

  static async trackTimerResume(timerId: string) {
    await AnalyticsCore.core.trackTimerResume(timerId)
  }

  static async trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {},
    sendTo?: string[]
  ) {
    await AnalyticsCore.core.trackTimerEnd(timerId, attributes, sendTo)
  }

  static removeTimer(timerId: string) {
    AnalyticsCore.core.removeTimer(timerId)
  }

  static clearTrackTimer() {
    AnalyticsCore.core.clearTrackTimer()
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