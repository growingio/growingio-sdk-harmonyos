/**
 * @license
 * Copyright (C) 2023 Beijing Yishu Technology Co., Ltd.
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

import GrowingContext from '../core/Context'
import DeviceInfo from '../core/DeviceInfo'
import { ConfigMode } from '../interfaces/GrowingConfig'
import Util from '../utils/Util'
import { AttributesType } from '../utils/Constants'

export { AttributesType } from '../utils/Constants'

export default abstract class Event {
  userId: string | undefined = undefined
  userKey: string | undefined = undefined
  sessionId: string = ''
  eventSequenceId: number = 0
  networkState: string = ''
  timestamp: number = 0
  latitude: number | undefined = undefined
  longitude: number | undefined = undefined
  sdkVersion: string = ''
  dataSourceId: string = ''
  urlScheme: string = ''
  attributes: AttributesType | undefined = undefined

  eventType: EventType = EventType.Visit

  // deviceInfo
  deviceId: string = ''
  platform: string = ''
  platformVersion: string = ''
  screenHeight: number = 0
  screenWidth: number = 0
  deviceBrand: string = ''
  deviceModel: string = ''
  deviceType: string = ''
  language: string = ''
  timezoneOffset: string = ''

  // appInfo
  domain: string = ''
  appState: string = ''
  appName: string = ''
  appVersion: string = ''
  appChannel: string | undefined = undefined

  toSerialize(context: GrowingContext): string {
    let mode = context.config.mode
    if (mode == ConfigMode.SaaS) {
      return Util.toSerializeByMeasurementProtocolV2(this, DeviceInfo.networkState)
    } else if (mode == ConfigMode.CDP) {
      return Util.toSerializeByMeasurementProtocolV3(this)
    } else {
      return JSON.stringify(this)
    }
  }
}

export enum EventType {
  Visit = 'VISIT',
  Custom = 'CUSTOM',
  LoginUserAttributes = 'LOGIN_USER_ATTRIBUTES',
  Page = 'PAGE',
  ViewClick = 'VIEW_CLICK',
  ViewChange = 'VIEW_CHANGE',
  AppClosed = 'APP_CLOSED',

  // mode SaaS
  SaaS_Evar = 'evar',
  SaaS_Vstr = 'vstr',
  SaaS_Pvar = 'pvar',
}

export enum EventScene {
  Native = 0,
  Hybrid,
  Flutter
}