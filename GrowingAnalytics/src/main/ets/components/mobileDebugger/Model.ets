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

import { SDK_VERSION } from '../core/AnalyticsCore'
import { AttributesType } from '../utils/Constants'
import Util from '../utils/Util'

export interface Message {
  msgType: string
}

export class ReadyInfo implements Message {
  msgType: string = 'ready'
  os: string = 'HarmonyOS'
  projectId: string
  timestamp: number
  domain: string
  sdkVersion: string = SDK_VERSION
  sdkVersionCode: string = SDK_VERSION
  screenWidth: number
  screenHeight: number
  urlScheme: string

  constructor(
    projectId: string,
    timestamp: number,
    domain: string,
    screenWidth: number,
    screenHeight: number,
    urlScheme: string,
  ) {
    this.projectId = projectId
    this.timestamp = timestamp
    this.domain = domain
    this.screenWidth = screenWidth
    this.screenHeight = screenHeight
    this.urlScheme = urlScheme
  }
}

export class CircleReadyInfo implements Message {
  msgType: string = 'ready'
  os: string = 'HarmonyOS'
  projectId: string
  timestamp: number
  domain: string
  sdkVersion: string = SDK_VERSION
  appVersion: string
  screenWidth: number
  screenHeight: number
  urlScheme: string

  constructor(
    projectId: string,
    timestamp: number,
    domain: string,
    screenWidth: number,
    screenHeight: number,
    urlScheme: string,
    appVersion: string,
  ) {
    this.projectId = projectId
    this.timestamp = timestamp
    this.domain = domain
    this.screenWidth = screenWidth
    this.screenHeight = screenHeight
    this.urlScheme = urlScheme
    this.appVersion = appVersion
  }
}

export class ClientInfo implements Message {
  msgType: string = 'client_info'
  sdkVersion: string = SDK_VERSION
  data: ClientInfoData

  constructor(data: ClientInfoData) {
    this.data = data
  }
}

export class ClientInfoData {
  os: string = 'HarmonyOS'
  osVersion: string
  appVersion: string
  appChannel: string
  deviceType: string
  deviceBrand: string
  deviceModel: string

  constructor(
    osVersion: string,
    appVersion: string,
    appChannel: string,
    deviceType: string,
    deviceBrand: string,
    deviceModel: string
  ) {
    this.osVersion = osVersion
    this.appVersion = appVersion
    this.appChannel = appChannel
    this.deviceType = deviceType
    this.deviceBrand = deviceBrand
    this.deviceModel = deviceModel
  }
}

export class LoggerData implements Message {
  msgType: string = 'logger_data'
  sdkVersion: string = SDK_VERSION
  data: Array<LogData>

  constructor(data: Array<LogData>) {
    this.data = data
  }
}

export class LogData {
  type: string
  subType: string
  message: string
  time: number

  constructor(type: string, message: string) {
    this.type = type
    this.subType = ''
    this.message = message
    this.time = Date.now()
  }
}

export class DebuggerData implements Message {
  msgType: string = 'debugger_data'
  sdkVersion: string = SDK_VERSION
  data: EventData

  constructor(data: EventData) {
    this.data = data
  }
}

export class EventData {
  url: string

  deviceId?: string
  userId?: string
  gioId?: string
  sessionId?: string
  dataSourceId?: string
  eventType?: string
  platform?: string
  timestamp?: number
  domain?: string
  path?: string
  query?: string
  title?: string
  referralPage?: string
  globalSequenceId?: number
  eventSequenceId?: number
  screenHeight?: number
  screenWidth?: number
  language?: string
  sdkVersion?: string
  appVersion?: string
  eventName?: string
  attributes?: AttributesType
  protocolType?: string
  textValue?: string
  xpath?: string
  index?: number
  hyperlink?: string
  urlScheme?: string
  appState?: string
  networkState?: string
  appChannel?: string
  platformVersion?: string
  deviceBrand?: string
  deviceModel?: string
  deviceType?: string
  appName?: string
  latitude?: number
  longitude?: number
  oaid?: string
  orientation?: string
  userKey?: string
  xcontent?: string
  timezoneOffset?: string

  constructor(url: string, event: string) {
    this.url = url
    this.parseEvent(event)
  }

  parseEvent(event: string) {
    let e = JSON.parse(event) as EventData
    this.deviceId = e.deviceId
    this.userId = e.userId
    this.gioId = e.gioId
    this.sessionId = e.sessionId
    this.dataSourceId = e.dataSourceId
    this.eventType = e.eventType
    this.platform = e.platform
    this.timestamp = e.timestamp
    this.domain = e.domain
    this.path = e.path
    this.query = e.query
    this.title = e.title
    this.referralPage = e.referralPage
    this.globalSequenceId = e.globalSequenceId
    this.eventSequenceId = e.eventSequenceId
    this.screenHeight = e.screenHeight
    this.screenWidth = e.screenWidth
    this.language = e.language
    this.sdkVersion = e.sdkVersion
    this.appVersion = e.appVersion
    this.eventName = e.eventName
    this.attributes = e.attributes ? Util.serializableAttributes(e.attributes) : undefined
    this.protocolType = e.protocolType
    this.textValue = e.textValue
    this.xpath = e.xpath
    this.index = e.index
    this.hyperlink = e.hyperlink
    this.urlScheme = e.urlScheme
    this.appState = e.appState
    this.networkState = e.networkState
    this.appChannel = e.appChannel
    this.platformVersion = e.platformVersion
    this.deviceBrand = e.deviceBrand
    this.deviceModel = e.deviceModel
    this.deviceType = e.deviceType
    this.appName = e.appName
    this.latitude = e.latitude
    this.longitude = e.longitude
    this.oaid = e.oaid
    this.orientation = e.orientation
    this.userKey = e.userKey
    this.xcontent = e.xcontent
    this.timezoneOffset = e.timezoneOffset
  }
}

export class Quit implements Message {
  msgType: string = 'quit'
}

export class RefreshScreenshot implements Message {
  msgType: string = 'refreshScreenshot'
  scale: number = 1
  screenWidth: number
  screenHeight: number
  snapshotKey: number
  screenshot: string
  pages?: Array<ScreenshotPage>
  elements?: Array<ScreenshotElement>

  constructor(screenWidth: number, screenHeight: number, snapshotKey: number, screenshot: string) {
    this.screenWidth = screenWidth
    this.screenHeight = screenHeight
    this.snapshotKey = snapshotKey
    this.screenshot = screenshot
  }
}

export class ScreenshotPage {
  left: number
  top: number
  width: number
  height: number
  path: string
  title?: string

  constructor(
    left: number,
    top: number,
    width: number,
    height: number,
    path: string,
    title?: string,
  ) {
    this.left = left
    this.top = top
    this.width = width
    this.height = height
    this.path = path
    this.title = title
  }
}

export class ScreenshotElement {
  nodeType: string
  domain: string
  isContainer: boolean
  left: number
  top: number
  width: number
  height: number
  zLevel: number
  xpath: string
  xcontent: string
  page: string
  index?: number
  parentXPath?: string
  parentXContent?: string

  constructor(
    nodeType: string,
    domain: string,
    isContainer: boolean,
    left: number,
    top: number,
    width: number,
    height: number,
    zLevel: number,
    xpath: string,
    xcontent: string,
    page: string,
    index?: number,
    parentXPath?: string,
    parentXContent?: string,
  ) {
    this.nodeType = nodeType
    this.domain = domain
    this.isContainer = isContainer
    this.left = left
    this.top = top
    this.width = width
    this.height = height
    this.zLevel = zLevel
    this.xpath = xpath
    this.xcontent = xcontent
    this.page = page
    this.index = index
    this.parentXPath = parentXPath
    this.parentXContent = parentXContent
  }
}