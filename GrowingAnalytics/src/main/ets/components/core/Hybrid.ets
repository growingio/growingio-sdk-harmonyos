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

import webview from '@ohos.web.webview'

import AnalyticsCore, { SDK_VERSION } from './AnalyticsCore'
import AppInfo from './AppInfo'
import GrowingContext from './Context'
import DeviceInfo, { SDK_PLATFORM } from './DeviceInfo'
import UserIdentifier from './UserIdentifier'
import { EventScene, EventType } from '../event/Event'
import LoginUserAttributesEvent from '../event/LoginUserAttributesEvent'
import PageEvent from '../event/PageEvent'
import HybridCustomEvent from '../event/hybrid/HybridCustomEvent'
import HybridPageEvent from '../event/hybrid/HybridPageEvent'
import HybridViewElementEvent from '../event/hybrid/HybridViewElementEvent'
import { SaaSEvarEvent, SaaSVisitorEvent } from '../event/saas/SaaSTrackEvent'
import { AttributesType, JavaScriptProxyType, SaaSJavaScriptConfigType } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import { ConfigMode } from '../interfaces/GrowingConfig'

export default class Hybrid {
  name: string = 'GrowingWebViewJavascriptBridge'
  methodList: string[] = [
    'getConfiguration',
    'dispatchEvent',
    'getDomTree',
    'onDomChanged',
    'setNativeUserId',
    'setNativeUserIdAndUserKey',
    'clearNativeUserId',
    'clearNativeUserIdAndUserKey',
  ]
  controller: webview.WebviewController
  context: GrowingContext
  configuration: string

  constructor(
    controller: webview.WebviewController,
    context: GrowingContext
  ) {
    this.controller = controller
    this.context = context
    this.configuration = JSON.stringify({
      "projectId": context.config.accountId,
      "dataSourceId": context.config.dataSourceId,
      "appPackage": AppInfo.domain,
      "appId": context.config.urlScheme,
      "nativeSdkVersion": SDK_VERSION,
      "nativeSdkVersionCode": 1
    })
  }

  static createHybridProxy(controller: webview.WebviewController, context: GrowingContext): JavaScriptProxyType {
    let hybrid = context.config.mode == ConfigMode.SaaS && context.config.hybridAutotrackEnabled
      ? new SaaSHybrid(controller, context)
      : new Hybrid(controller, context)
    return {
      object: hybrid,
      name: hybrid.name,
      methodList: hybrid.methodList,
      controller: controller
    }
  }

  static javaScriptOnDocumentStart(
    context: GrowingContext,
    scriptRules: Array<string> = ['*'],
    saasJavaScriptConfig: SaaSJavaScriptConfigType = {
      hashTagEnabled: false,
      impEnabled: false
    }): Array<ScriptItem> {
    let scripts: Array<ScriptItem> = []
    if (context.config.mode == ConfigMode.SaaS && context.config.hybridAutotrackEnabled) {
      let config: AttributesType = {
        enableHT: saasJavaScriptConfig.hashTagEnabled,
        disableImp: !saasJavaScriptConfig.impEnabled,
        phoneWidth: DeviceInfo.screenWidth,
        phoneHeight: DeviceInfo.screenHeight,
        protocolVersion:  1
      }
      scripts.push({
        script: 'window._vds_hybrid_config = ' + JSON.stringify(config), scriptRules: scriptRules
      })
    }
    return scripts
  }

  static javaScriptOnDocumentEnd(
    context: GrowingContext,
    scriptRules: Array<string> = ['*']
  ): Array<ScriptItem> {
    let scripts: Array<ScriptItem> = []
    if (context.config.mode == ConfigMode.SaaS && context.config.hybridAutotrackEnabled) {
      let sdkVersion = SDK_VERSION
      let sdkPlatform = SDK_PLATFORM
      let hybridSrc = 'https://assets.giocdn.com/sdk/hybrid/2.0/gio_hybrid.min.js?sdkVer='
        + sdkVersion + '&platform=' + sdkPlatform
      let wrapper = 'javascript:(function(){try{if(window.self==window.top||document.head.childElementCount||'
        + 'document.body.childElementCount){var p=document.createElement(\'script\');p.src=\'gio_hybrid_src\';'
        + 'document.head.appendChild(p);}}catch(e){}})()'
      let hybridJavaScript = wrapper.replace('gio_hybrid_src', hybridSrc)
      scripts.push({
        script: hybridJavaScript, scriptRules: scriptRules
      })
    }
    return scripts
  }

  getConfiguration = (): string => {
    return this.configuration
  }

  dispatchEvent = (eventString: string): void => {
    try {
      LogUtil.info(() => "[Hybrid] dispatchEvent: " + JSON.stringify(JSON.parse(eventString), null, 4))

      if (!this.context.config.dataCollectionEnabled) {
        LogUtil.info(() => 'Failed to dispatch hybrid event, dataCollectionEnabled is false')
        return
      }

      let event: Record<string, Object> = JSON.parse(eventString)
      let eventType: string = event.eventType as string
      if (eventType == EventType.Custom) {
        let e = HybridCustomEvent.create(
          event.eventName as string,
          event.attributes as AttributesType,
          event.path as string,
          event.query as string,
          event.timestamp as number,
          event.domain as string,
          this.context
        )
        AnalyticsCore.writeEventToDisk(e, this.context, EventScene.Hybrid)
      } else if (eventType == EventType.Page) {
        let e = HybridPageEvent.create(
          event.title as string,
          event.referralPage as string,
          event.protocolType as string,
          event.attributes as AttributesType,
          event.path as string,
          event.query as string,
          event.timestamp as number,
          event.domain as string,
          this.context
        )
        AnalyticsCore.writeEventToDisk(e, this.context, EventScene.Hybrid)
      } else if (eventType == EventType.ViewClick || eventType == EventType.ViewChange) {
        let e = HybridViewElementEvent.create(
          event.textValue as string,
          event.xpath as string,
          event.xcontent as string,
          event.index as number,
          event.hyperlink as string,
          event.attributes as AttributesType,
          event.path as string,
          event.query as string,
          event.timestamp as number,
          event.domain as string,
          eventType,
          this.context
        )
        AnalyticsCore.writeEventToDisk(e, this.context, EventScene.Hybrid)
      } else if (eventType == EventType.LoginUserAttributes) {
        let e = LoginUserAttributesEvent.create(event.attributes as AttributesType, this.context)
        AnalyticsCore.writeEventToDisk(e, this.context, EventScene.Hybrid)
      } else if (this.context.config.mode == ConfigMode.SaaS) {
        // hybridAutotrackEnabled == false，集成埋点SDK对应的Hybrid JS SDK: gio_hybrid_track.js
        SaaSHybridTrackEventHandler.eventHandler(event, this.context)
      }
    } catch (e) {
      LogUtil.error(() => "Failed to dispatch event. code = " + e.code + ", message = " + e.message)
    }
  }

  getDomTree = (): void => {
    LogUtil.info(() => "圈选获取节点信息失败！请集成 gioHybridCircle 插件后重试！")
  }

  onDomChanged = (): void => {
    // LogUtil.info(() => "[Hybrid] onDomChanged")
  }

  setNativeUserId = (userId: string): void => {
    LogUtil.info(() => "[Hybrid] setNativeUserId: " + userId)
    UserIdentifier.setLoginUserId(userId, '', this.context)
  }

  setNativeUserIdAndUserKey = (userId: string, userKey: string): void => {
    LogUtil.info(() => "[Hybrid] setNativeUserId: " + userId + "and userKey: " + userKey)
    UserIdentifier.setLoginUserId(userId, userKey, this.context)
  }

  clearNativeUserId = (): void => {
    LogUtil.info(() => "[Hybrid] clearNativeUserId")
    UserIdentifier.setLoginUserId('', '', this.context)
  }

  clearNativeUserIdAndUserKey = (): void => {
    LogUtil.info(() => "[Hybrid] clearNativeUserIdAndUserKey")
    UserIdentifier.setLoginUserId('', '', this.context)
  }
}

class SaaSHybrid {
  name: string = '_vds_bridge'
  methodList: string[] = [
    'saveEvent',
    'setUserId',
    'clearUserId',
    'setVisitor',
    'hoverNodes',
    'webCircleHybridEvent',
    'onDOMChanged',
  ]
  controller: webview.WebviewController
  context: GrowingContext

  constructor(
    controller: webview.WebviewController,
    context: GrowingContext
  ) {
    this.controller = controller
    this.context = context
  }

  saveEvent = (eventString: string): void => {
    try {
      LogUtil.info(() => "[SaaS] [Hybrid] saveEvent: " + JSON.stringify(JSON.parse(eventString), null, 4))

      if (!this.context.config.dataCollectionEnabled) {
        LogUtil.info(() => 'Failed to save hybrid event, dataCollectionEnabled is false')
        return
      }

      let event: Record<string, Object> = JSON.parse(eventString)
      let eventType: string = event.t as string
      if (eventType == 'page') {
        let p = String(event.p ?? '')
        let rp = String(event.rp ?? '')
        let tl = String(event.tl ?? '')
        let lastPage = PageEvent.getLastPage(this.context)
        if (lastPage) {
          p = (lastPage.path ?? '') + '::' + p
          rp = (lastPage.path ?? '') + '::' + rp
          tl = (lastPage.title ?? '') + '::' + tl
        }
        let d = AppInfo.domain + '::' + String(event.d ?? '')
        let e = HybridPageEvent.create(
          tl,
          rp,
          '',
          event.var as AttributesType,
          p,
          event.q as string,
          event.tm as number,
          d,
          this.context
        )
        AnalyticsCore.writeEventToDisk(e, this.context, EventScene.Hybrid)
      } else {
        // 埋点事件
        SaaSHybridTrackEventHandler.eventHandler(event, this.context)
      }
    } catch (e) {
      LogUtil.error(() => "Failed to save hybrid event. code = " + e.code + ", message = " + e.message)
    }
  }

  setUserId = (userId: string): void => {
    LogUtil.info(() => "[SaaS] [Hybrid] setUserId: " + userId)
    UserIdentifier.setLoginUserId(userId, '', this.context)
  }

  clearUserId = (): void => {
    LogUtil.info(() => "[SaaS] [Hybrid] clearUserId")
    UserIdentifier.setLoginUserId('', '', this.context)
  }

  setVisitor = (visitor: string): void => {
    // LogUtil.info(() => "[SaaS] [Hybrid] setVisitor: " + visitor)
  }

  hoverNodes = (message: string): void => {
    // LogUtil.info(() => "[SaaS] [Hybrid] hoverNodes: " + message)
  }

  webCircleHybridEvent = (message: string): void => {
    // LogUtil.info(() => "[SaaS] [Hybrid] webCircleHybridEvent: " + message)
  }

  onDOMChanged = (): void => {
    // LogUtil.info(() => "[SaaS] [Hybrid] onDOMChanged")
  }
}

class SaaSHybridTrackEventHandler {
  static eventHandler(event: Record<string, Object>, context: GrowingContext) {
    let t: string = String(event.t ?? '')
    let attributes: AttributesType = event.var as (AttributesType | undefined) ?? {}
    if (t == 'cstm') {
      let eventName: string = event.n as string
      if (eventName.length > 0) {
        let p = String(event.p ?? '')
        let lastPage = PageEvent.getLastPage(context)
        if (lastPage) {
          p = (lastPage.path ?? '') + '::' + p
        }
        let d = AppInfo.domain + '::' + String(event.d ?? '')
        let e = HybridCustomEvent.create(
          eventName,
          attributes,
          p,
          event.q as string,
          event.tm as number,
          d,
          context)
        e.pageShowTimestamp = event.ptm as number
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      }
    } else if (Object.keys(attributes).length > 0) {
      if (t == 'ppl') {
        let e = LoginUserAttributesEvent.create(attributes, context)
        e.domain = e.domain + '::' + String(event.d ?? '')
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      } else if (t == 'evar') {
        let e = SaaSEvarEvent.create(attributes, context)
        e.domain = e.domain + '::' + String(event.d ?? '')
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      } else if (t == 'vstr') {
        let e = SaaSVisitorEvent.create(attributes, context)
        e.domain = e.domain + '::' + String(event.d ?? '')
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      }
    }
  }
}