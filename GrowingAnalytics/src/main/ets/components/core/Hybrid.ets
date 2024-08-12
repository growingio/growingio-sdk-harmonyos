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
import UserIdentifier from './UserIdentifier'
import { EventScene, EventType } from '../event/Event'
import HybridCustomEvent from '../event/hybrid/HybridCustomEvent'
import HybridPageEvent from '../event/hybrid/HybridPageEvent'
import HybridViewElementEvent from '../event/hybrid/HybridViewElementEvent'
import LoginUserAttributesEvent from '../event/LoginUserAttributesEvent'
import { AttributesType, JavaScriptProxyType } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'

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
    let hybrid = new Hybrid(controller, context)
    return {
      object: hybrid,
      name: hybrid.name,
      methodList: hybrid.methodList,
      controller: controller
    }
  }

  getConfiguration = (): string => {
    return this.configuration
  }

  dispatchEvent = (eventString: string): void => {
    try {
      LogUtil.info(() => "[Hybrid] dispatchEvent: " + JSON.stringify(JSON.parse(eventString), null, 4))

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