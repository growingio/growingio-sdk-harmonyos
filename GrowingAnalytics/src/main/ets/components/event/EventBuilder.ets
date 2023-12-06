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

import Event from './Event'
import AnalyticsCore from '../core/AnalyticsCore'
import AppInfo from '../core/AppInfo'
import DeviceInfo from '../core/DeviceInfo'
import Session, { SessionState } from '../core/Session'
import UserIdentifier from '../core/UserIdentifier'
import { SDK_VERSION, PREFERENCE_EVENT_SEQUENCE_ID } from '../utils/Constants'
import SharedPreferences from '../utils/SharedPreferences'

export default class EventBuilder {
  private static _eventSequenceId: number

  static async initEventBuilder() {
    this._eventSequenceId = await SharedPreferences.getValue(PREFERENCE_EVENT_SEQUENCE_ID, 0) as number
  }

  static build<T extends Event>(event: T): T {
    event.sessionId = Session.sessionId
    event.appState = Session.sessionState === SessionState.Foreground ? 'FOREGROUND' : 'BACKGROUND'
    event.timestamp = Date.now()
    event.sdkVersion = SDK_VERSION

    // device info
    event.deviceId = DeviceInfo.deviceId
    event.platform = DeviceInfo.platform
    event.platformVersion = DeviceInfo.platformVersion
    event.screenHeight = DeviceInfo.screenHeight
    event.screenWidth = DeviceInfo.screenWidth
    event.deviceBrand = DeviceInfo.deviceBrand
    event.deviceModel = DeviceInfo.deviceModel
    event.deviceType = DeviceInfo.deviceType
    event.language = DeviceInfo.language
    event.timezoneOffset = DeviceInfo.timezoneOffset
    event.networkState = DeviceInfo.networkState

    // app info
    event.domain = AppInfo.domain
    event.appChannel = AppInfo.appChannel
    event.appName = AppInfo.appName
    event.appVersion = AppInfo.appVersion

    let core = AnalyticsCore.core
    event.dataSourceId = core.config.dataSourceId
    event.urlScheme = core.config.urlScheme
    event.latitude = Math.abs(core.location.latitude) > 0 ? core.location.latitude : undefined
    event.longitude = Math.abs(core.location.longitude) > 0 ? core.location.longitude : undefined

    let userId = UserIdentifier.curUserId
    event.userId = userId.length > 0 ? userId : undefined
    let userKey = UserIdentifier.curUserKey
    event.userKey = userKey.length > 0 ? userKey : undefined

    this.updateEventSequenceId()
    event.eventSequenceId = this._eventSequenceId
    return event
  }

  private static updateEventSequenceId() {
    this._eventSequenceId = this._eventSequenceId + 1
    SharedPreferences.put(PREFERENCE_EVENT_SEQUENCE_ID, this._eventSequenceId)
  }
}