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

// @doc-impl GrowingAnalytics.md

import common from '@ohos.app.ability.common'
import UIAbility from '@ohos.app.ability.UIAbility'
import window from '@ohos.window'
import webview from '@ohos.web.webview'

import { GrowingConfig } from './GrowingConfig'
import { GrowingImpressionConfig, GrowingImpressionDelegate } from './GrowingImpression'
import Autotrack from '../autotrack/Autotrack'
import ViewImpression from '../autotrack/ViewImpression'
import AnalyticsCore from '../core/AnalyticsCore'
import { Flutter } from '../core/Flutter'
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
export { Flutter as GrowingFlutterPlugin } from '../core/Flutter'
export { GrowingImpressionConfig, GrowingImpressionDelegate } from './GrowingImpression'
export { UniApp as GrowingUniAppPlugin } from '../core/UniApp'

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

  createHybridProxy(controller: webview.WebviewController, webviewId?: string): GrowingJSProxyType | undefined

  // mode SaaS
  setPeopleVariable(attributes: GrowingAttrType): void
  setEvar(attributes: GrowingAttrType): void
  setVisitor(attributes: GrowingAttrType): void
}

export class GrowingAnalytics {
  private static _config?: GrowingConfig

  static configure(configuration: GrowingConfig) {
    if (GrowingAnalytics._config) {
      LogUtil.warn(() => 'Do not configure GrowingAnalytics repeatedly')
      return
    }
    GrowingAnalytics._config = configuration.copy()
  }

  static startAnalytics(context: Context) {
    if (!GrowingAnalytics._config) {
      LogUtil.warn(() => 'Must call GrowingAnalytics.configure(configuration) first')
      return
    }
    GrowingAnalytics.start(context, GrowingAnalytics._config)
  }

  static start(context: Context, configuration: GrowingConfig) {
    if (GrowingAnalytics.isInitializedSuccessfully()) {
      LogUtil.warn(() => 'Do not initialize GrowingAnalytics repeatedly')
      return
    }
    let config = configuration.copy()
    AnalyticsCore.startCore(context, config)
  }

  static deferStart(context: common.UIAbilityContext, configuration?: GrowingConfig) {
    // In the case of delayed initialization, avoid users calling start and ensure that the context is UIAbilityContext
    let config = configuration ?? GrowingAnalytics._config
    if (!config) {
      LogUtil.warn(() => 'Must call GrowingAnalytics.configure(configuration) first')
      return
    }
    GrowingAnalytics.start(context, config)
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

  static createHybridProxy(controller: webview.WebviewController, webviewId?: string): GrowingJSProxyType | undefined {
    return AnalyticsCore.core.createHybridProxy(controller, webviewId)
  }

  static javaScriptOnDocumentStart(
    scriptRules?: Array<string>,
    saasJavaScriptConfig?: SaaSJavaScriptConfigType): Array<ScriptItem> {
    return AnalyticsCore.core.javaScriptOnDocumentStart(scriptRules, saasJavaScriptConfig)
  }

  static javaScriptOnDocumentEnd(scriptRules?: Array<string>): Array<ScriptItem> {
    return AnalyticsCore.core.javaScriptOnDocumentEnd(scriptRules)
  }

  static onPageEnd(controller: webview.WebviewController, webviewId?: string): Promise<void> {
    return AnalyticsCore.core.onPageEnd(controller, webviewId)
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

  static trackFlutterCircleData(argument: Map<string, Object>) {
    if (!GrowingAnalytics.isInitializedSuccessfully()) {
      LogUtil.error(() => 'Must call GrowingAnalytics.start(context, configuration) first')
      return
    }
    if (argument == null || argument == undefined) {
      return
    }
    Flutter.trackFlutterCircleData(argument)
  }

  /**
   * 标记曝光元素，元素满足曝光条件时发送对应的埋点事件
   * 组件需通过 .id() 设置唯一的 componentId，建议在该组件的 onAppear 中调用
   * @param componentId 组件 id
   * @param eventName 埋点事件名
   * @param attributes 事件属性（可选）
   * @param identifier 曝光标识。同一组件可挂载多个 identifier 不同的曝光标记；
   *                   不传时写入默认槽位。config 指定不可重复曝光时必须传入（可选）
   * @param config 单元素曝光配置，不传则使用全局配置 GrowingConfig.viewImpressionConfig（可选）
   */
  static trackViewImpression(
    componentId: string,
    eventName: string,
    attributes?: GrowingAttrType,
    identifier?: string,
    config?: GrowingImpressionConfig
  ) {
    ViewImpression.mark(componentId, eventName, attributes, identifier, config)
  }

  /**
   * 仅更新已标记元素的属性，不重置曝光状态、不触发重新曝光
   */
  static updateViewImpressionAttributes(componentId: string, attributes: GrowingAttrType, identifier?: string) {
    ViewImpression.updateAttributes(componentId, attributes, identifier)
  }

  /**
   * 移除组件上的曝光标记；传入 identifier 时只移除该标记，否则移除全部
   */
  static stopTrackViewImpression(componentId: string, identifier?: string) {
    ViewImpression.unmark(componentId, identifier)
  }

  /**
   * 添加曝光回调；重复添加同一个对象只生效一次，不再需要时请调用 removeViewImpressionDelegate 移除
   */
  static addViewImpressionDelegate(delegate: GrowingImpressionDelegate) {
    ViewImpression.addDelegate(delegate)
  }

  static removeViewImpressionDelegate(delegate: GrowingImpressionDelegate) {
    ViewImpression.removeDelegate(delegate)
  }

  /**
   * 清除某个标识的"已曝光"记录，之后该标识的元素可再次曝光。
   * 仅对配置了不可重复曝光的元素有意义，适用于下拉刷新、切换数据源等场景
   */
  static resetViewImpressionState(identifier: string) {
    if (!identifier || identifier.length == 0) {
      return
    }
    ViewImpression.resetState(identifier)
  }

  /**
   * 清除全部"已曝光"记录
   */
  static resetAllViewImpressionState() {
    ViewImpression.resetState()
  }

  static handleOpenURL(uri: string): boolean {
    return AnalyticsCore.handleOpenURL(uri)
  }
}