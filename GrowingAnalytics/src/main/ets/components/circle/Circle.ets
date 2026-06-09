/**
 * @license
 * Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.
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

// @doc-impl Circle.md

import webSocket from "@ohos.net.webSocket"
import { BusinessError } from '@ohos.base'
import url from "@ohos.url"
import buffer from "@ohos.buffer"
import cryptoFramework from "@ohos.security.cryptoFramework"

import AutotrackPage from "../autotrack/AutotrackPage"
import { EventScene, EventType } from "../event/Event"
import EventPersistence from "../event/EventPersistence"
import { Message, RefreshScreenshot } from '../mobileDebugger/Model'
import { ImpressElement, SdkConfig, UserAction } from '../mobileDebugger/SaaSModel'
import { WebSocket, WebSocketCallbackInterface } from '../mobileDebugger/WebSocket'
import { PluginsInterface } from "../plugins/Plugins"
import { StatusView } from "../mobileDebugger/StatusView"
import AppInfo from "../core/AppInfo"
import AnalyticsCore, { SDK_VERSION } from "../core/AnalyticsCore"
import GrowingContext from "../core/Context"
import { ConfigMode } from "../interfaces/GrowingConfig"
import { Flutter } from "../core/Flutter"
import Hybrid from "../core/Hybrid"
import { SnapshotProvider } from "../mobileDebugger/Snapshot"
import CircleElement from "./CircleElement"
import { niceTry } from "../utils/Util"

export default class Circle implements PluginsInterface, WebSocketCallbackInterface {
  ws: WebSocket = new WebSocket()
  statusView?: StatusView
  snapshotProvider?: SnapshotProvider
  private _lastSnapshotKey: number = 0

  connect(url: string) {
    if (AnalyticsCore.mainWindow && AnalyticsCore.uiContent) {
      let context = GrowingContext.getDefaultContext() as GrowingContext
      if (context.config.mode == ConfigMode.SaaS) {
        let timestamp = Date.now()
        let path = url.split('?')[0]
        let signedUrl = url + (url.includes('?') ? '&' : '?') + 'timestamp=' + timestamp
        let signature = sha1Hex(path + ':' + timestamp)
        let header: _SaaSRequestHeader = { Authorization: 'Sign SHA1 ' + signature }
        this.ws.connect(signedUrl, this, header)
      } else {
        this.ws.connect(url, this)
      }
      return
    }
    setTimeout(() => {
      this.connect(url)
    }, 300)
  }

  stop(error?: string) {
    Flutter.onCircleClosed()
    Hybrid.saasCircleEnabled = false
    this.snapshotProvider?.stopObserver()
    this.snapshotProvider = undefined
    this.statusView?.hide()
    this._lastSnapshotKey = 0

    if (error && error.length > 0) {
      StatusView.showDialog({
        title: '设备已断开连接',
        message: error,
        buttons: [{ text: '知道了', color: '#000000' }]
      })
    }
  }

  async sendScreenshot(screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) {
    if (!this.snapshotProvider) {
      return
    }
    if (AutotrackPage.lastPage) {
      // 当有页面浏览事件生成时，需判断当前页面是否是原生页面
      // 而flutter页面，则应该由flutter sdk触发sendScreenshotForFlutter
      let lastPage = AutotrackPage.lastPage
      if (lastPage.eventScene != EventScene.Native) {
        return
      }
    }
    this._lastSnapshotKey = snapshotKey
    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (context.config.mode == ConfigMode.SaaS) {
      await this._sendSaaSUserAction('refresh', '更新截图', screenWidth, screenHeight, snapshotKey, snapshot)
    } else {
      let screenshot = new RefreshScreenshot(screenWidth, screenHeight, snapshotKey, snapshot)
      await CircleElement.setPagesAndElements(screenshot)
      this.ws.sendScreenshot(screenshot)
    }
  }

  private async _sendSaaSUserAction(userAction: string, actionDesc: string,
    screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string,
    clickedXpath?: string): Promise<void> {
    this._lastSnapshotKey = snapshotKey
    let context = GrowingContext.getDefaultContext() as GrowingContext
    let sdkConfig = new SdkConfig(AppInfo.appVersion, context.config.hybridAutotrackEnabled)
    let page = AutotrackPage.lastPage?.path ?? ''
    let title = AutotrackPage.lastPage?.title ?? ''
    let action = new UserAction(userAction, actionDesc, title, page, AppInfo.domain,
      snapshot, screenWidth, screenHeight, AppInfo.appVersion, sdkConfig, snapshotKey)
    let impress = await CircleElement.setImpressElements(screenWidth, screenHeight)
    action.impress = impress
    if (clickedXpath && clickedXpath.length > 0) {
      let targets: Array<ImpressElement> = []
      for (let el of impress) {
        if (el.xpath == clickedXpath) {
          targets.push(el)
        }
      }
      if (targets.length > 0) {
        action.targets = targets
      }
    }
    this.ws.sendSaaSUserAction(action)
  }

  sendScreenshotForFlutter(data: Map<string, Object>) {
    this.snapshotProvider?.getSnapshot((screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) => {
      let screenshot = new RefreshScreenshot(screenWidth, screenHeight, snapshotKey, snapshot)
      CircleElement.setPagesAndElementsForFlutter(screenshot, data)
      this.ws.sendScreenshot(screenshot)
    })
  }

  // PluginsInterface

  handleOpenURL(uri: string): boolean {
    if (uri) {
      let urlObject = niceTry(() => url.URL.parseURL(uri))
      if (!urlObject) {
        return false
      }
      let serviceType = urlObject.params.get('serviceType')
      let wsUrl = urlObject.params.get('wsUrl')
      if (serviceType && serviceType == 'circle' && wsUrl && wsUrl.length > 0) {
        this.connect(wsUrl)
        return true
      }
    }

    return false
  }

  onWebViewDomTreeChanged() {
    this.snapshotProvider?.onDomChanged()
  }

  onEventWroteToDisk(event: EventPersistence, eventScene: number) {
    if (!this.snapshotProvider || eventScene != EventScene.Native) {
      return
    }
    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (context.config.mode != ConfigMode.SaaS) {
      return
    }

    if (event.eventType == EventType.ViewClick) {
      let data = JSON.parse(event.data) as _SaaSEventData
      let nodeName = data.v && data.v.length > 0 ? data.v : '元素'
      let clickedXpath = data.x ?? ''
      this.snapshotProvider.getSnapshot((screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) => {
        this._sendSaaSUserAction('click', '点击了' + nodeName, screenWidth, screenHeight, snapshotKey, snapshot, clickedXpath)
      })
    } else if (event.eventType == EventType.Page) {
      let data = JSON.parse(event.data) as _SaaSEventData
      let pageName = data.tl && data.tl.length > 0 ? data.tl : (data.p ?? '')
      setTimeout(() => {
        this.snapshotProvider?.getSnapshot((screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) => {
          this._sendSaaSUserAction('page', '进入了' + pageName, screenWidth, screenHeight, snapshotKey, snapshot)
        })
      }, 500)
    }
  }

  onWebViewSaaSCircleEvent(message: string, webviewId?: string) {
    try {
      let dict: Record<string, Object> = JSON.parse(message)
      dict['msgId'] = 'hybridEvent'
      dict['sk'] = this._lastSnapshotKey

      let frameLeft = 0
      let frameTop = 0
      if (webviewId && webviewId.length > 0 && AnalyticsCore.uiContent) {
        try {
          let frameNode = AnalyticsCore.uiContent.getAttachedFrameNodeById(webviewId)
          if (frameNode) {
            let pos = frameNode.getPositionToWindowWithTransform()
            frameLeft = pos.x
            frameTop = pos.y
          }
        } catch (e) {}
      }

      for (let key of ['e', 'el', 'heatmap', 'similar']) {
        let arr = dict[key] as Array<Record<string, Object>> | undefined
        if (arr && arr.length > 0) {
          for (let element of arr) {
            this._changeXYtoWeb(element, frameLeft, frameTop)
          }
        }
      }

      this.ws.send(JSON.stringify(dict))
    } catch (e) {
      this.ws.send(message)
    }
  }

  // changeXYtoWeb: WebView JS 物理像素坐标 → 服务端截图 vp 坐标
  // JS 以 phoneWidth（物理px）为基准上报坐标，native 转换为 vp 并加上 WebView 在屏幕中的偏移
  private _changeXYtoWeb(element: Record<string, Object>, frameLeft: number, frameTop: number) {
    if (!AnalyticsCore.uiContent) {
      return
    }
    if (element['ex'] !== undefined) {
      element['ex'] = AnalyticsCore.uiContent.px2vp(element['ex'] as number) + frameLeft
    }
    if (element['ey'] !== undefined) {
      element['ey'] = AnalyticsCore.uiContent.px2vp(element['ey'] as number) + frameTop
    }
    if (element['ew'] !== undefined) {
      element['ew'] = AnalyticsCore.uiContent.px2vp(element['ew'] as number)
    }
    if (element['eh'] !== undefined) {
      element['eh'] = AnalyticsCore.uiContent.px2vp(element['eh'] as number)
    }
    if (element['x'] !== undefined) {
      let val = Number(element['x'])
      if (!isNaN(val)) {
        element['x'] = AnalyticsCore.uiContent.px2vp(val) + frameLeft
      }
    }
    if (element['y'] !== undefined) {
      let val = Number(element['y'])
      if (!isNaN(val)) {
        element['y'] = AnalyticsCore.uiContent.px2vp(val) + frameTop
      }
    }
  }

  // WebSocketCallbackInterface

  onWebSocketOpen(err: BusinessError, value: Object) {
    if (err) {
      return
    }
    this.ws.sendCircleReadyInfo()
  }

  onWebSocketReceive(err: BusinessError, value: string | ArrayBuffer) {
    if (err) {
      return
    }
    try {
      if (typeof value == 'string') {
        if (value.trim().length == 0) {
          return
        }
        let message: Message = JSON.parse(value)
        if (message.msgId == 'hybridEvent') {
          Hybrid.handleSaaSCircleEventFromServer(JSON.parse(value) as Record<string, Object>)
          return
        }
        let context = GrowingContext.getDefaultContext() as GrowingContext
        if (context.config.mode == ConfigMode.SaaS) {
          this._handleSaaSMessage(message)
        } else {
          this._handleMessage(message)
        }
      }
    } catch (e) {

    }
  }

  private _handleSaaSMessage(message: Message) {
    if (message.msgId == 'editor_ready') {
      this._startCircling()
    } else if (message.msgId == 'editor_quit') {
      this.stop('当前设备已与Web端断开连接，如需继续圈选请扫码重新连接')
    } else if (message.msgId == 'incompatible_version') {
      this._showIncompatibleVersion()
    }
  }

  private _handleMessage(message: Message) {
    if (message.msgType == 'ready') {
      this._startCircling()
    } else if (message.msgType == 'incompatible_version') {
      this._showIncompatibleVersion()
    }
  }

  private _startCircling() {
    if (!this.snapshotProvider) {
      this.snapshotProvider = new SnapshotProvider(
        (screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) => {
          this.sendScreenshot(screenWidth, screenHeight, snapshotKey, snapshot)
        })
    }
    this.snapshotProvider.startObserver()

    if (!this.statusView) {
      this.statusView = new StatusView('正在进行圈选(上下拖曳移动)', () => {
        StatusView.showDialog({
          title: '正在进行圈选',
          message: `APP版本: ${AppInfo.appVersion}\nSDK版本: ${SDK_VERSION}`,
          buttons: [
            { text: '继续', color: '#000000' },
            { text: '退出', color: '#000000' }
          ]
        }).then(r => {
          if (r.index == 1) {
            this.ws.disconnect()
          }
        })
      })
    }
    this.statusView.show()

    Flutter.onCircleOpen()
    Hybrid.saasCircleEnabled = true
  }

  private _showIncompatibleVersion() {
    StatusView.showDialog({
      title: '抱歉',
      message: '您使用的SDK版本号过低，请升级SDK后再使用',
      buttons: [{ text: '知道了', color: '#000000' }]
    })
    this.ws.disconnect()
  }

  onWebSocketClose(err: BusinessError, value: webSocket.CloseResult) {
    this.stop('当前设备已与Web端断开连接，如需继续圈选请扫码重新连接')
  }

  onWebSocketError(err: BusinessError) {
    this.stop('服务器链接失败')
  }
}

class _SaaSEventData {
  x: string | undefined = undefined
  v: string | undefined = undefined
  p: string | undefined = undefined
  tl: string | undefined = undefined
}

class _SaaSRequestHeader {
  Authorization: string = ''
}

function sha1Hex(input: string): string {
  return niceTry(() => {
    let md = cryptoFramework.createMd('SHA1')
    let inputBuffer = buffer.from(input, 'utf-8')
    let inputBlob: cryptoFramework.DataBlob = {
      data: new Uint8Array(inputBuffer.buffer, inputBuffer.byteOffset, inputBuffer.length)
    }
    md.updateSync(inputBlob)
    let digest = md.digestSync()
    return buffer.from(digest.data).toString('hex')
  }, '')
}
