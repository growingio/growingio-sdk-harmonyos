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
import UIAbility from '@ohos.app.ability.UIAbility'
import window from '@ohos.window'
import webview from '@ohos.web.webview'

import { GrowingConfig } from './GrowingConfig'
import Autotrack from '../autotrack/Autotrack'
import AnalyticsCore from '../core/AnalyticsCore'
import Flutter from '../core/Flutter'
import GeneralProps from '../core/GeneralProps'
import {
  AttributesType as GrowingAttrType,
  JavaScriptProxyType as GrowingJSProxyType,
  SaaSJavaScriptConfigType
} from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'

export {
  AttributesType as GrowingAttrType,
  JavaScriptProxyType as GrowingJSProxyType,
  AUTOTRACK_ELEMENT_ID as GrowingAutotrackElementID
} from '../utils/Constants'

export interface GrowingAnalyticsInterface {
  isInitializedSuccessfully(): boolean
  setDataCollectionEnabled(enabled: boolean): void
  setLoginUserId(userId: string, userKey?: string): void
  cleanLoginUserId(): void

  setLoginUserAttributes(attributes: GrowingAttrType): void
  track(eventName: string, attributes?: GrowingAttrType, sendTo?: string[]): void
  trackTimerStart(eventName: string): string
  trackTimerPause(timerId: string): void
  trackTimerResume(timerId: string): void
  trackTimerEnd(timerId: string, attributes?: GrowingAttrType, sendTo?: string[]): void
  removeTimer(timerId: string): void
  clearTrackTimer(): void

  createHybridProxy(controller: webview.WebviewController): GrowingJSProxyType | undefined

  // mode SaaS
  setPeopleVariable(attributes: GrowingAttrType): void
  setEvar(attributes: GrowingAttrType): void
  setVisitor(attributes: GrowingAttrType): void
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

  static onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage) {
    Autotrack.startObserver(windowStage)
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

  static createHybridProxy(controller: webview.WebviewController): GrowingJSProxyType | undefined {
    return AnalyticsCore.core.createHybridProxy(controller)
  }

  static javaScriptOnDocumentStart(
    scriptRules?: Array<string>,
    saasJavaScriptConfig?: SaaSJavaScriptConfigType): Array<ScriptItem> {
    return AnalyticsCore.core.javaScriptOnDocumentStart(scriptRules, saasJavaScriptConfig)
  }

  static javaScriptOnDocumentEnd(scriptRules?: Array<string>): Array<ScriptItem> {
    return AnalyticsCore.core.javaScriptOnDocumentEnd(scriptRules)
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

  static setLoginUserAttributes(attributes: GrowingAttrType) {
    AnalyticsCore.core.setLoginUserAttributes(attributes)
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

  static trackTimerStart(eventName: string): string {
    return AnalyticsCore.core.trackTimerStart(eventName)
  }

  static trackTimerPause(timerId: string) {
    AnalyticsCore.core.trackTimerPause(timerId)
  }

  static trackTimerResume(timerId: string) {
    AnalyticsCore.core.trackTimerResume(timerId)
  }

  static trackTimerEnd(
    timerId: string,
    attributes?: GrowingAttrType,
    sendTo?: string[]
  ) {
    AnalyticsCore.core.trackTimerEnd(timerId, attributes, sendTo)
  }

  static removeTimer(timerId: string) {
    AnalyticsCore.core.removeTimer(timerId)
  }

  static clearTrackTimer() {
    AnalyticsCore.core.clearTrackTimer()
  }

  static setGeneralProps(props: GrowingAttrType) {
    GeneralProps.setGeneralProps(props)
  }

  static removeGeneralProps(keys: string[]) {
    GeneralProps.removeGeneralProps(keys)
  }

  static clearGeneralProps() {
    GeneralProps.clearGeneralProps()
  }

  static setDynamicGeneralProps(generator: () => GrowingAttrType) {
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

  static setPeopleVariable(attributes: GrowingAttrType) {
    AnalyticsCore.core.setPeopleVariable(attributes)
  }

  static setEvar(attributes: GrowingAttrType) {
    AnalyticsCore.core.setEvar(attributes)
  }

  static setVisitor(attributes: GrowingAttrType) {
    AnalyticsCore.core.setVisitor(attributes)
  }

  static trackFlutterPage(argument: Map<string, Object>) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      LogUtil.error(() => 'Must call GrowingAnalytics.start(context, configuration) first')
      return
    }
    if (argument == null || argument == undefined) {
      return
    }
    Flutter.trackFlutterPage(argument)
  }

  static trackFlutterClickEvent(argument: Map<string, Object>) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      LogUtil.error(() => 'Must call GrowingAnalytics.start(context, configuration) first')
      return
    }
    if (argument == null || argument == undefined) {
      return
    }
    Flutter.trackFlutterClickEvent(argument)
  }

  static handleOpenURL(uri: string): boolean {
    return AnalyticsCore.handleOpenURL(uri)
  }
}