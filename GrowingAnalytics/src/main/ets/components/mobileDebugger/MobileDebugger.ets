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
import rcp from "@hms.collaboration.rcp"

import { LogData, Message, EventData, RefreshScreenshot } from './Model'
import { WebSocket, WebSocketCallbackInterface } from './WebSocket'
import { PluginsInterface } from "../plugins/Plugins"
import EventPersistence from "../event/EventPersistence"
import { Queue } from "./Queue"
import { LogUtil } from "../utils/LogUtil"
import { StatusView } from "./StatusView"
import AppInfo from "../core/AppInfo"
import AnalyticsCore, { SDK_VERSION } from "../core/AnalyticsCore"
import { SnapshotProvider } from "./Snapshot"
import { niceTry } from "../utils/Util"

export default class MobileDebugger implements PluginsInterface, WebSocketCallbackInterface {
  ws: WebSocket = new WebSocket()
  eventQueue: Queue<EventData> = new Queue<EventData>(50)
  logQueue: Queue<LogData> = new Queue<LogData>(100)
  statusView?: StatusView
  snapshotProvider?: SnapshotProvider

  timer: number = -1
  loggerOpen: boolean = false

  constructor() {
    if (!LogUtil.logDebugger) {
      LogUtil.logDebugger = (type: string, message: string) => {
        let log = new LogData(type, message)
        this.logQueue.enqueue(log)
      }
    }
  }

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
    this.snapshotProvider?.stopObserver()
    this.statusView?.hide()

    if (error && error.length > 0) {
      StatusView.showDialog({
        title: '设备已断开连接',
        message: error,
        buttons: [{ text: '知道了', color: '#000000' }]
      })
    }

    this.eventQueue.isLimit = true
    this.logQueue.isLimit = true
    clearInterval(this.timer)
    this.timer = -1
  }

  startSendDebuggerData() {
    if (this.timer > 0) {
      return
    }
    this.timer = setInterval(() => {
      let events = this.eventQueue.dequeue()
      this.ws.sendEvents(events)

      if (this.loggerOpen) {
        let logs = this.logQueue.dequeue()
        this.ws.sendLogs(logs)
      }
    }, 1000)
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
      if (serviceType && serviceType == 'debugger' && wsUrl && wsUrl.length > 0) {
        this.connect(wsUrl)
        return true
      }
    }

    return false
  }

  onEventsDidSend(events: EventPersistence[], request: rcp.Request) {
    let url = request.url.toString()
    for (let i = 0; i < events.length; i++) {
      let e = events[i]
      let eventData = new EventData(url, e.data)
      this.eventQueue.enqueue(eventData)
    }
  }

  // WebSocketCallbackInterface

  onWebSocketOpen(err: BusinessError, value: Object) {
    if (err) {
      return
    }
    this.ws.sendReadyInfo()
  }

  onWebSocketReceive(err: BusinessError, value: string | ArrayBuffer) {
    if (err) {
      return
    }
    try {
      if (typeof value == 'string') {
        let message: Message = JSON.parse(value)
        if (message.msgType == 'ready') {
          // web端ready
          this.ws.sendClientInfo()

          if (!this.snapshotProvider) {
            this.snapshotProvider = new SnapshotProvider(
              (screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) => {
                let screenshot = new RefreshScreenshot(screenWidth, screenHeight, snapshotKey, snapshot)
                this.ws.sendScreenshot(screenshot)
              })
          }
          this.snapshotProvider.startObserver()

          this.eventQueue.isLimit = false
          this.logQueue.isLimit = false
          this.startSendDebuggerData()

          if (!this.statusView) {
            this.statusView = new StatusView('正在进行Debugger(上下拖曳移动)', () => {
              StatusView.showDialog({
                title: '正在进行Debugger',
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
        } else if (message.msgType == 'logger_open') {
          // 发送log信息
          this.loggerOpen = true
        } else if (message.msgType == 'logger_close') {
          // 停止发送log信息
          this.loggerOpen = false
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
    this.stop('当前设备已与Web端断开连接，如需继续调试请扫码重新连接')
  }

  onWebSocketError(err: BusinessError) {
    this.stop('服务器链接失败')
  }
}