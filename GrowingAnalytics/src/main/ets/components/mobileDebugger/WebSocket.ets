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

import DeviceInfo from "../core/DeviceInfo"
import AppInfo from "../core/AppInfo"
import GrowingContext from "../core/Context"
import { ClientInfo, ClientInfoData, DebuggerData, EventData, LogData, LoggerData, Quit, ReadyInfo,
  RefreshScreenshot } from './Model'

export interface WebSocketCallbackInterface {
  onWebSocketOpen(err: BusinessError, value: Object): void
  onWebSocketReceive(err: BusinessError, value: string | ArrayBuffer): void
  onWebSocketClose(err: BusinessError, value: webSocket.CloseResult): void
  onWebSocketError(err: BusinessError): void
}

export class WebSocket {
  ws?: webSocket.WebSocket
  queue: string[] = []
  isUploading: boolean = false

  connect(url: string, callback: WebSocketCallbackInterface): Promise<boolean> {
    this.disconnect()

    let ws = webSocket.createWebSocket()
    this.ws = ws
    ws.on('open', (err: BusinessError, value: Object) => {
      callback.onWebSocketOpen(err, value)
    })
    ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
      callback.onWebSocketReceive(err, value)
    })
    ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
      callback.onWebSocketClose(err, value)
    })
    ws.on('error', (err: BusinessError) => {
      callback.onWebSocketError(err)
    })
    return ws.connect(url)
  }

  disconnect() {
    if (!this.ws) {
      return
    }

    let latestSocket = this.ws
    this.queue = []
    latestSocket.send(JSON.stringify(new Quit())).then(() => {
      latestSocket.close()
    })
  }

  send(message: string) {
    this.queue.push(message)
    this.sendIfNeeded()
  }

  sendIfNeeded() {
    if (this.isUploading) {
      return
    }
    this.isUploading = true

    let message = this.queue.shift()
    if (message && message.length > 0) {
      this.ws?.send(message).then(() => {
        this.isUploading = false
        if (this.queue.length > 0) {
          this.sendIfNeeded()
        }
      }).catch((e: Error) => {
        this.queue = [message as string, ...this.queue]
        this.isUploading = false
      })
    }
  }

  sendReadyInfo() {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    let readyInfo = new ReadyInfo(
      context.config.accountId,
      Date.now(),
      AppInfo.domain,
      DeviceInfo.screenWidth,
      DeviceInfo.screenHeight,
      context.config.urlScheme
    )
    this.send(JSON.stringify(readyInfo))
  }

  sendClientInfo() {
    let clientInfoData = new ClientInfoData(
      DeviceInfo.platformVersion,
      AppInfo.appVersion,
      AppInfo.appChannel ?? '',
      DeviceInfo.deviceType,
      DeviceInfo.deviceBrand,
      DeviceInfo.deviceModel,
    )
    let clientInfo = new ClientInfo(clientInfoData)
    this.send(JSON.stringify(clientInfo))
  }

  sendLogs(logs: Array<LogData>) {
    if (logs.length == 0) {
      return
    }
    let loggerData = new LoggerData(logs)
    this.send(JSON.stringify(loggerData))
  }

  sendEvents(events: Array<EventData>) {
    if (events.length == 0) {
      return
    }
    for (let i = 0; i < events.length; i++) {
      let event = events[i]
      let debuggerData = new DebuggerData(event)
      this.send(JSON.stringify(debuggerData))
    }
  }

  sendScreenshot(screenshot: RefreshScreenshot) {
    this.send(JSON.stringify(screenshot))
  }
}