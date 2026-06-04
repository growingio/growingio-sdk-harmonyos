/**
 * @license
 * Copyright (C) 2026 Beijing Yishu Technology Co., Ltd.
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
import { Message } from './Model'

export class ClientInit implements Message {
  msgId: string = 'client_init'
  ai: string
  spn: string
  sdkVersion: string = SDK_VERSION
  appVersion: string
  protocolVersion: number = 1

  constructor(ai: string, spn: string, appVersion: string) {
    this.ai = ai
    this.spn = spn
    this.appVersion = appVersion
  }
}

export class ClientQuit implements Message {
  msgId: string = 'client_quit'
}

export class SdkConfig {
  sdkVersion: string = SDK_VERSION
  appVersion: string
  isTrackWebView: boolean

  constructor(appVersion: string, isTrackWebView: boolean) {
    this.appVersion = appVersion
    this.isTrackWebView = isTrackWebView
  }
}

export class ImpressElement {
  nodeType: string
  xpath: string
  domain: string
  page: string = ''
  index: string | undefined = undefined
  content: string | undefined = undefined
  isClickable: number = 0
  isContainer: boolean = false
  isTab: boolean = false
  isWebview: number = 0
  zLevel: number = 0
  left: number = 0
  top: number = 0
  width: number = 0
  height: number = 0
  parentXPath: string | undefined = undefined

  constructor(nodeType: string, xpath: string, domain: string) {
    this.nodeType = nodeType
    this.xpath = xpath
    this.domain = domain
  }
}

export class UserAction implements Message {
  msgId: string = 'user_action'
  userAction: string
  title: string
  page: string
  domain: string
  screenshot: string
  screenshotWidth: number
  screenshotHeight: number
  sdkVersion: string = SDK_VERSION
  appVersion: string
  actionDesc: string
  sdkConfig: SdkConfig
  sk: number
  impress: Array<ImpressElement> = []
  targets: Array<ImpressElement> | undefined = undefined

  constructor(
    userAction: string,
    actionDesc: string,
    title: string,
    page: string,
    domain: string,
    screenshot: string,
    screenshotWidth: number,
    screenshotHeight: number,
    appVersion: string,
    sdkConfig: SdkConfig,
    sk: number,
  ) {
    this.userAction = userAction
    this.actionDesc = actionDesc
    this.title = title
    this.page = page
    this.domain = domain
    this.screenshot = screenshot
    this.screenshotWidth = screenshotWidth
    this.screenshotHeight = screenshotHeight
    this.appVersion = appVersion
    this.sdkConfig = sdkConfig
    this.sk = sk
  }
}
