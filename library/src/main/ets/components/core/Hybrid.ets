import webview from '@ohos.web.webview'

import AnalyticsCore from './AnalyticsCore'
import AppInfo from './AppInfo'
import GrowingContext from './Context'
import UserIdentifier from './UserIdentifier'
import { EventType } from '../event/Event'
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
  hybridConfiguration: string

  constructor(
    controller: webview.WebviewController,
    context: GrowingContext
  ) {
    this.controller = controller
    this.context = context
    this.hybridConfiguration = JSON.stringify({
      "projectId": context.config.accountId,
      "dataSourceId": context.config.dataSourceId,
      "appPackage": AppInfo.domain,
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

  getConfiguration(): string {
    return this.hybridConfiguration
  }

  dispatchEvent(eventString: string) {
    try {
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
        AnalyticsCore.writeEventToDisk(e, this.context)
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
        AnalyticsCore.writeEventToDisk(e, this.context)
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
        AnalyticsCore.writeEventToDisk(e, this.context)
      } else if (eventType == EventType.LoginUserAttributes) {
        let e = LoginUserAttributesEvent.create(event.attributes as AttributesType, this.context)
        AnalyticsCore.writeEventToDisk(e, this.context)
      }
    } catch (e) {
      LogUtil.error("Failed to dispatch event. code = " + e.code + ", message = " + e.message)
    }
  }

  getDomTree() {
    LogUtil.info("%c [GrowingIO]：圈选获取节点信息失败！请集成 gioHybridCircle 插件后重试！", "color: #F59E0B;")
  }

  onDomChanged() {

  }

  setNativeUserId(userId: string) {
    UserIdentifier.setLoginUserId(userId, '', this.context)
  }

  setNativeUserIdAndUserKey(userId: string, userKey: string) {
    UserIdentifier.setLoginUserId(userId, userKey, this.context)
  }

  clearNativeUserId() {
    UserIdentifier.setLoginUserId('', '', this.context)
  }

  clearNativeUserIdAndUserKey() {
    UserIdentifier.setLoginUserId('', '', this.context)
  }
}