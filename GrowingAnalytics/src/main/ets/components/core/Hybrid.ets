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

// @doc-impl Hybrid.md

import webview from '@ohos.web.webview'

import AnalyticsCore, { SDK_VERSION } from './AnalyticsCore'
import AppInfo from './AppInfo'
import GrowingContext from './Context'
import DeviceInfo, { SDK_PLATFORM } from './DeviceInfo'
import Session from './Session'
import UserIdentifier from './UserIdentifier'
import { EventScene, EventType } from '../event/Event'
import LoginUserAttributesEvent from '../event/LoginUserAttributesEvent'
import PageEvent from '../event/PageEvent'
import HybridCustomEvent from '../event/hybrid/HybridCustomEvent'
import HybridPageEvent from '../event/hybrid/HybridPageEvent'
import HybridViewElementEvent from '../event/hybrid/HybridViewElementEvent'
import ViewElementEvent from '../event/ViewElementEvent'
import { SaaSEvarEvent, SaaSVisitorEvent } from '../event/saas/SaaSTrackEvent'
import { AttributesType, JavaScriptProxyType, PATH_SEPARATOR, SaaSJavaScriptConfigType } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import { ConfigMode } from '../interfaces/GrowingConfig'
import SaaSPageVarEvent from '../event/saas/SaaSPageVarEvent'
import AutotrackClick from '../autotrack/AutotrackClick'
import Plugins from '../plugins/Plugins'
import { niceTryAsync } from '../utils/Util'

export default class Hybrid {
  private static _hybrids: Record<string, Hybrid> = {}

  name: string = 'GrowingWebViewJavascriptBridge'
  methodList: string[] = [
    'getConfiguration',
    'dispatchEvent',
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

  static createHybridProxy(controller: webview.WebviewController, webviewId: string | undefined, context: GrowingContext): JavaScriptProxyType {
    if (context.config.mode == ConfigMode.NewSaaS) {
      let hybrid = new Hybrid(controller, context)
      if (webviewId && webviewId.length > 0) {
        Hybrid._hybrids[webviewId] = hybrid
      }
      return {
        object: hybrid,
        name: hybrid.name,
        methodList: hybrid.methodList,
        controller: controller
      }
    } else if (context.config.mode == ConfigMode.SaaS && context.config.hybridAutotrackEnabled) {
      let hybrid = new SaaSHybrid(controller, context, webviewId)
      return {
        object: hybrid,
        name: hybrid.name,
        methodList: hybrid.methodList,
        controller: controller
      }
    } else {
      let hybrid = new Hybrid(controller, context)
      return {
        object: hybrid,
        name: hybrid.name,
        methodList: hybrid.methodList,
        controller: controller
      }
    }
  }

  static async getDomTreeById(webviewId: string, left: number, top: number, width: number, height: number): Promise<string> {
    let hybrid = Hybrid._hybrids[webviewId]
    if (hybrid == null || hybrid == undefined) {
      return ''
    }
    if (!GrowingContext.isDefaultContext(hybrid.context)) {
      // 只有主实例可以打通hybrid无埋点圈选，子实例只能发不能圈
      return ''
    }
    let controller = hybrid.controller
    let zLevel = 100
    let js = `window.GrowingWebViewJavascriptBridge.getDomTree(${left}, ${top}, ${width}, ${height}, ${zLevel})`
    let elements = await niceTryAsync(() => controller.runJavaScript(js))
    return elements ?? ''
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
        phoneWidth: DeviceInfo.screenWidth ?? DeviceInfo.defaultScreenWidth,
        phoneHeight: DeviceInfo.screenHeight ?? DeviceInfo.defaultScreenHeight,
        protocolVersion:  1
      }
      scripts.push({
        script: 'window._vds_hybrid_config = ' + JSON.stringify(config), scriptRules: scriptRules
      })

      let nativeInfo: AttributesType = {
        ai: context.config.accountId,
        d: AppInfo.domain,
        u: DeviceInfo.deviceId,
        s: Session.getSessionId(context) ?? '',
        cs1: UserIdentifier.getUser(context)?.userId ?? '',
        p: PageEvent.getLastPage(context)?.path ?? ''
      }
      scripts.push({
        script: 'window._vds_hybrid_native_info = ' + JSON.stringify(nativeInfo), scriptRules: scriptRules
      })
    }
    return scripts
  }

  static saasCircleEnabled: boolean = false

  static async handleSaaSCircleEventFromServer(dict: Record<string, Object>): Promise<void> {
    await SaaSHybrid.handleCircleEventFromServer(dict)
  }

  static async onPageEnd(controller: webview.WebviewController, context: GrowingContext, webviewId?: string): Promise<void> {
    if (context.config.mode != ConfigMode.SaaS || !Hybrid.saasCircleEnabled) {
      return
    }
    if (webviewId && webviewId.length > 0) {
      let xpath = Hybrid._getNativeXPathByWebViewId(webviewId)
      if (xpath.length > 0) {
        let updateX = 'if(window._vds_hybrid_native_info){window._vds_hybrid_native_info.x=\'' + xpath + '\'}'
        await niceTryAsync(() => controller.runJavaScript(updateX))
      }
    }
    let circleUrl = 'https://assets.giocdn.com/sdk/hybrid/2.0/vds_web_circle_plugin.min.js?sdkVer='
      + SDK_VERSION + '&platform=' + SDK_PLATFORM
    let js = '(function(){try{var p=document.createElement(\'script\');p.src=\'' + circleUrl + '\';document.head.appendChild(p);}catch(e){}})()'
    await niceTryAsync(() => controller.runJavaScript(js))
  }

  private static _getNativeXPathByWebViewId(webviewId: string): string {
    try {
      let frameNode = AnalyticsCore.uiContent.getAttachedFrameNodeById(webviewId)
      if (!frameNode) {
        return ''
      }
      let xpathInfo = AutotrackClick.getXpathInfo(frameNode)
      let xpath = ''
      for (let i = xpathInfo.xpath.length - 1; i >= 0; i--) {
        xpath += PATH_SEPARATOR + xpathInfo.xpath[i] + '[' + xpathInfo.xcontent[i] + ']'
      }
      return xpath
    } catch (e) {
      return ''
    }
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
        SaaSHybridEventHandler.eventHandler(event, this.context)
      }
    } catch (e) {
      LogUtil.error(() => "Failed to dispatch event. code = " + e.code + ", message = " + e.message)
    }
  }

  onDomChanged = (): void => {
    Plugins.onWebViewDomTreeChanged()
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
  static _saasHybrids: SaaSHybrid[] = []

  static async handleCircleEventFromServer(dict: Record<string, Object>): Promise<void> {
    const xVal = dict['x'] !== undefined ? Number(dict['x']) : NaN
    const yVal = dict['y'] !== undefined ? Number(dict['y']) : NaN
    const hasXY = !isNaN(xVal) && !isNaN(yVal)

    // 有 x/y 坐标时，只转发给命中该点的 WebView；否则广播给所有 WebView
    let hybridsToNotify: SaaSHybrid[]
    let hitFrameLeft: number = 0
    let hitFrameTop: number = 0
    let hitHybrid: SaaSHybrid | undefined = undefined
    if (hasXY && AnalyticsCore.uiContent) {
      for (let hybrid of SaaSHybrid._saasHybrids) {
        if (hybrid.webviewId && hybrid.webviewId.length > 0) {
          try {
            let frameNode = AnalyticsCore.uiContent.getAttachedFrameNodeById(hybrid.webviewId)
            if (frameNode) {
              let json = frameNode.getInspectorInfo() as Record<string, Object>
              let rect = json['$rect'] as string | undefined
              if (rect) {
                let matches = rect.match(/\[([\d.]+),\s*([\d.]+)\],\[([\d.]+),\s*([\d.]+)\]/)
                if (matches && matches.length >= 5) {
                  let leftVp   = AnalyticsCore.uiContent.px2vp(parseFloat(matches[1]))
                  let topVp    = AnalyticsCore.uiContent.px2vp(parseFloat(matches[2]))
                  let rightVp  = AnalyticsCore.uiContent.px2vp(parseFloat(matches[3]))
                  let bottomVp = AnalyticsCore.uiContent.px2vp(parseFloat(matches[4]))
                  if (xVal >= leftVp && xVal <= rightVp &&
                      yVal >= topVp  && yVal <= bottomVp) {
                    hitHybrid = hybrid
                    let pos = frameNode.getPositionToWindowWithTransform()
                    hitFrameLeft = pos.x
                    hitFrameTop = pos.y
                    break
                  }
                }
              }
            }
          } catch (e) {}
        }
      }
      hybridsToNotify = hitHybrid ? [hitHybrid] : []
    } else {
      hybridsToNotify = [...SaaSHybrid._saasHybrids]
    }

    for (let hybrid of hybridsToNotify) {
      let frameLeft = 0
      let frameTop = 0
      if (hasXY && hitHybrid === hybrid) {
        frameLeft = hitFrameLeft
        frameTop = hitFrameTop
      } else if (hybrid.webviewId && hybrid.webviewId.length > 0 && AnalyticsCore.uiContent) {
        try {
          let frameNode = AnalyticsCore.uiContent.getAttachedFrameNodeById(hybrid.webviewId)
          if (frameNode) {
            let pos = frameNode.getPositionToWindowWithTransform()
            frameLeft = pos.x
            frameTop = pos.y
          }
        } catch (e) {}
      }

      // changeXYtoHybrid: 服务端 vp 坐标 → WebView 本地 CSS 坐标（HarmonyOS 上 1CSS px = 1vp）
      let localDict: Record<string, Object> = JSON.parse(JSON.stringify(dict))
      if (localDict['x'] !== undefined) {
        let val = Number(localDict['x'])
        if (!isNaN(val)) {
          localDict['x'] = val - frameLeft
        }
      }
      if (localDict['y'] !== undefined) {
        let val = Number(localDict['y'])
        if (!isNaN(val)) {
          localDict['y'] = val - frameTop
        }
      }
      if (localDict['ex'] !== undefined) {
        localDict['ex'] = (localDict['ex'] as number) - frameLeft
      }
      if (localDict['ey'] !== undefined) {
        localDict['ey'] = (localDict['ey'] as number) - frameTop
      }
      let jsonStr = JSON.stringify(localDict)
      await niceTryAsync(() => hybrid.controller.runJavaScript(`window._vds_hybrid.helper.handleWebEvent(${jsonStr})`))
    }
  }

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
  webviewId?: string

  constructor(
    controller: webview.WebviewController,
    context: GrowingContext,
    webviewId?: string
  ) {
    this.controller = controller
    this.context = context
    this.webviewId = webviewId
    if (webviewId && webviewId.length > 0) {
      let idx = SaaSHybrid._saasHybrids.findIndex(h => h.webviewId === webviewId)
      if (idx >= 0) {
        SaaSHybrid._saasHybrids.splice(idx, 1, this)
      } else {
        SaaSHybrid._saasHybrids.push(this)
      }
    } else {
      let idx = SaaSHybrid._saasHybrids.findIndex(h => h.controller === controller)
      if (idx >= 0) {
        SaaSHybrid._saasHybrids.splice(idx, 1, this)
      } else {
        SaaSHybrid._saasHybrids.push(this)
      }
    }
  }

  saveEvent = (eventString: string): void => {
    try {
      LogUtil.info(() => "[SaaS] [Hybrid] saveEvent: " + JSON.stringify(JSON.parse(eventString), null, 4))

      if (!this.context.config.dataCollectionEnabled) {
        LogUtil.info(() => 'Failed to save hybrid event, dataCollectionEnabled is false')
        return
      }

      let event: Record<string, Object> = JSON.parse(eventString)
      SaaSHybridEventHandler.eventHandler(event, this.context)
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
    if (!Hybrid.saasCircleEnabled) {
      return
    }
    LogUtil.info(() => "[SaaS] [Hybrid] webCircleHybridEvent: " + message)
    Plugins.onWebViewSaaSCircleEvent(message, this.webviewId)
  }

  onDOMChanged = (): void => {
    Plugins.onWebViewDomTreeChanged()
  }
}

class SaaSHybridEventHandler {
  static eventHandler(event: Record<string, Object>, context: GrowingContext) {
    let t: string = String(event.t ?? '')
    let attributes: AttributesType = event.var as (AttributesType | undefined) ?? {}
    let d = AppInfo.domain + '::' + String(event.d ?? '')
    if (t == 'clck' || t == 'chng') {
      let elements = event.e as Array<Record<string, Object>> | undefined
      if (!elements || elements.length == 0) {
        return
      }
      let p = String(event.p ?? '')
      let lastPage = PageEvent.getLastPage(context)
      if (lastPage) {
        p = (lastPage.path ?? '') + '::' + p
      }
      let q = event.q as string | undefined
      let ptm = event.ptm as number
      let tm = event.tm as number
      let eventType = t == 'clck' ? EventType.ViewClick : EventType.ViewChange
      for (let element of elements) {
        let xpath = String(element.x ?? '')
        let textValue = String(element.v ?? '')
        let index = element.idx as number
        let hyperlink = element.h as string | undefined
        let e = ViewElementEvent.create(p, ptm, textValue, xpath, '', index, {}, eventType, context)
        if (t == 'chng' && textValue.length > 0) {
          e.textValue = textValue
        }
        e.query = q
        e.hyperlink = hyperlink
        e.domain = d
        e.timestamp = tm
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      }
    } else if (t == 'cstm' || t == 'pvar' || t == 'page') {
      let p = String(event.p ?? '')
      let lastPage = PageEvent.getLastPage(context)
      if (lastPage) {
        p = (lastPage.path ?? '') + '::' + p
      }
      if (t == 'page') {
        let rp = String(event.rp ?? '')
        let tl = String(event.tl ?? '')
        if (lastPage) {
          rp = (lastPage.path ?? '') + '::' + rp
          tl = (lastPage.title ?? '') + '::' + tl
        }
        let e = HybridPageEvent.create(
          tl,
          rp,
          '',
          event.var as AttributesType,
          p,
          event.q as string,
          event.tm as number,
          d,
          context
        )
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      } else if (t == 'cstm') {
        let eventName: string = event.n as string
        if (eventName.length > 0) {
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
      } else if (t == 'pvar') {
        let e = SaaSPageVarEvent.create(
          attributes,
          p,
          event.ptm as number,
          context)
        e.domain = d
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      }
    } else if (Object.keys(attributes).length > 0) {
      if (t == 'ppl') {
        let e = LoginUserAttributesEvent.create(attributes, context)
        e.domain = d
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      } else if (t == 'evar') {
        let e = SaaSEvarEvent.create(attributes, context)
        e.domain = d
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      } else if (t == 'vstr') {
        let e = SaaSVisitorEvent.create(attributes, context)
        e.domain = d
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Hybrid)
      }
    }
  }
}