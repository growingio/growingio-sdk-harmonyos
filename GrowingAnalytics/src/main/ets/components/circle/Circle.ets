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

import AutotrackPage from "../autotrack/AutotrackPage"
import { EventScene } from "../event/Event"
import { Message, RefreshScreenshot } from '../mobileDebugger/Model'
import { WebSocket, WebSocketCallbackInterface } from '../mobileDebugger/WebSocket'
import { PluginsInterface } from "../plugins/Plugins"
import { StatusView } from "../mobileDebugger/StatusView"
import AppInfo from "../core/AppInfo"
import AnalyticsCore, { SDK_VERSION } from "../core/AnalyticsCore"
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
      this.ws.connect(url, this)
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
    if (AutotrackPage.lastPage) {
      // 当有页面浏览事件生成时，需判断当前页面是否是原生页面
      // 而flutter页面，则应该由flutter sdk触发sendScreenshotForFlutter
      let lastPage = AutotrackPage.lastPage
      if (lastPage.eventScene != EventScene.Native) {
        return
      }
    }
    this._lastSnapshotKey = snapshotKey
    let screenshot = new RefreshScreenshot(screenWidth, screenHeight, snapshotKey, snapshot)
    await CircleElement.setPagesAndElements(screenshot)
    this.ws.sendScreenshot(screenshot)
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
        if (message.msgType == 'ready') {
          // web端ready
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
        } else if (message.msgType == 'incompatible_version') {
          // 版本号不适配
          StatusView.showDialog({
            title: '抱歉',
            message: '您使用的SDK版本号过低，请升级SDK后再使用',
            buttons: [{ text: '知道了', color: '#000000' }]
          })

          this.ws.disconnect()
        }
      }
    } catch (e) {

    }
  }

  onWebSocketClose(err: BusinessError, value: webSocket.CloseResult) {
    this.stop('当前设备已与Web端断开连接，如需继续圈选请扫码重新连接')
  }

  onWebSocketError(err: BusinessError) {
    this.stop('服务器链接失败')
  }
}