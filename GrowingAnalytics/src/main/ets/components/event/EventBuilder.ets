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
import AnalyticsCore, { SDK_VERSION } from '../core/AnalyticsCore'
import AppInfo from '../core/AppInfo'
import DeviceInfo from '../core/DeviceInfo'
import GrowingContext from '../core/Context'
import GrowingGeneralProps from '../core/GeneralProps'
import Session, { SessionState } from '../core/Session'
import UserIdentifier from '../core/UserIdentifier'
import { PREFERENCE_EVENT_SEQUENCE_ID } from '../utils/Constants'
import SharedPreferences from '../utils/SharedPreferences'
import Util from '../utils/Util'

export default class EventBuilder {
  private static _eventSequenceId: number

  static initEventBuilder() {
    EventBuilder._eventSequenceId = SharedPreferences.getValue(PREFERENCE_EVENT_SEQUENCE_ID, 0) as number
  }

  static build<T extends Event>(event: T, context: GrowingContext): T {
    event.sessionId = Session.getSessionId(context)!
    event.appState = Session.sessionState === SessionState.Foreground ? 'FOREGROUND' : 'BACKGROUND'
    event.timestamp = event.timestamp > 0 ? event.timestamp : Date.now()
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
    event.domain = event.domain || AppInfo.domain
    event.appChannel = AppInfo.appChannel
    event.appName = AppInfo.appName
    event.appVersion = AppInfo.appVersion

    event.dataSourceId = context.config.dataSourceId
    event.urlScheme = context.config.urlScheme
    event.latitude = Math.abs(AnalyticsCore.location.latitude) > 0 ? AnalyticsCore.location.latitude : undefined
    event.longitude = Math.abs(AnalyticsCore.location.longitude) > 0 ? AnalyticsCore.location.longitude : undefined

    let user = UserIdentifier.getUser(context)!
    let userId = user.userId
    event.userId = userId.length > 0 ? userId : undefined
    if (context.config.idMappingEnabled) {
      let userKey = user.userKey
      event.userKey = userKey.length > 0 ? userKey : undefined
    } else {
      event.userKey = undefined
    }

    let attributes = GrowingGeneralProps.getGeneralProps()
    if (event.attributes) {
      attributes = Util.concatObject(attributes, event.attributes)
    }
    event.attributes = Util.serializableAttributes(attributes)

    EventBuilder.updateEventSequenceId()
    event.eventSequenceId = EventBuilder._eventSequenceId
    return event
  }

  private static updateEventSequenceId() {
    EventBuilder._eventSequenceId = EventBuilder._eventSequenceId + 1
    SharedPreferences.put(PREFERENCE_EVENT_SEQUENCE_ID, EventBuilder._eventSequenceId)
  }
}