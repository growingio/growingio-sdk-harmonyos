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

import webSocket from "@ohos.net.webSocket"
import { BusinessError } from '@ohos.base'
import url from "@ohos.url"

import { Message, RefreshScreenshot } from '../mobileDebugger/Model'
import { WebSocket, WebSocketCallbackInterface } from '../mobileDebugger/WebSocket'
import { PluginsInterface } from "../plugins/Plugins"
import { StatusView } from "../mobileDebugger/StatusView"
import AppInfo from "../core/AppInfo"
import AnalyticsCore, { SDK_VERSION } from "../core/AnalyticsCore"
import { SnapshotProvider } from "../mobileDebugger/Snapshot"
import CircleElement from "./CircleElement"

export default class Circle implements PluginsInterface, WebSocketCallbackInterface {
  ws: WebSocket = new WebSocket()
  statusView?: StatusView
  snapshotProvider?: SnapshotProvider

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
    // TODO 关闭 Flutter 圈选数据监听和上报

    this.snapshotProvider?.stopObserver()
    this.statusView?.hide()

    if (error && error.length > 0) {
      StatusView.showDialog({
        title: '设备已断开连接',
        message: error,
        buttons: [{ text: '知道了', color: '#000000' }]
      })
    }
  }

  async sendScreenshot(screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) {
    let screenshot = new RefreshScreenshot(screenWidth, screenHeight, snapshotKey, snapshot)
    await CircleElement.setPagesAndElements(screenshot)
    this.ws.sendScreenshot(screenshot)
  }

  // PluginsInterface

  handleOpenURL(uri: string): boolean {
    if (uri) {
      let urlObject = url.URL.parseURL(uri)
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

          // TODO 开启 Flutter 圈选数据监听和上报
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