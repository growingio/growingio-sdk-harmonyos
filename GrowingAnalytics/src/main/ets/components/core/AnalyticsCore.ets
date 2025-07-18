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

import AbilityLifecycleCallback from '@ohos.app.ability.AbilityLifecycleCallback'
import ApplicationStateChangeCallback from '@ohos.app.ability.ApplicationStateChangeCallback'
import common from '@ohos.app.ability.common'
import UIAbility from '@ohos.app.ability.UIAbility'
import emitter from '@ohos.events.emitter'
import window from '@ohos.window'

import { GrowingAnalyticsInterface } from '../interfaces/GrowingAnalytics'
import { GrowingConfig } from '../interfaces/GrowingConfig'
import AppInfo from './AppInfo'
import GrowingContext from './Context'
import DeviceInfo from './DeviceInfo'
import Session from './Session'
import UserIdentifier from './UserIdentifier'
import CustomEvent from '../event/CustomEvent'
import Event, { EventType } from '../event/Event'
import EventDatabase from '../event/EventDatabase'
import EventPersistence from '../event/EventPersistence'
import EventSender from '../event/EventSender'
import Network from './Network'
import { AttributesType, EMIT_EVENT_MAIN_TRACKER_INITIALIZE } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'
import Util from '../utils/Util'
import DummyTracker from './DummyTracker'
import { HAR_VERSION } from '../../../../../BuildProfile'

class Location {
  latitude: number = 0
  longitude: number = 0
}

export const SDK_VERSION: string = HAR_VERSION

export default class AnalyticsCore implements GrowingAnalyticsInterface {
  static core: AnalyticsCore | DummyTracker = new DummyTracker()
  static trackers: Array<AnalyticsCore> = []
  static dummyTracker: DummyTracker = new DummyTracker()
  static location: Location = new Location()
  context: GrowingContext
  private _isInitializedSuccessfully: boolean = false

  constructor(context: GrowingContext) {
    this.context = context
  }

  static startCore(context: Context, config: GrowingConfig) {
    GrowingContext.setDefaultContext(config)
    let gContext = GrowingContext.getDefaultContext() as GrowingContext
    let core = new AnalyticsCore(gContext)
    AnalyticsCore.core = core
    AnalyticsCore.trackers.push(core)
    LogUtil.debugEnabled = config.debugEnabled
    AnalyticsCore.setAppStateChangeCallback(context)
    SharedPreferences.initWithContext(context)
    AppInfo.initAppInfo(context)
    DeviceInfo.initDeviceInfo()
    UserIdentifier.initUser(gContext)
    EventDatabase.initDatabase(context)
    Network.initNetwork(gContext)
    Session.refreshSession(gContext)

    let delay = config.debugEnabled && AppInfo.debug ? 1000 : config._dataUploadInterval
    setInterval(() => {
      EventSender.sendEvent(gContext)
    }, delay)

    emitter.emit(EMIT_EVENT_MAIN_TRACKER_INITIALIZE)
    LogUtil.info(() => 'Thank you very much for using GrowingIO. We will do our best to provide you with the best service. '
      + 'GrowingIO version: ' + SDK_VERSION)
    core._isInitializedSuccessfully = true
  }

  static startSubTracker(trackerId: string, config: GrowingConfig): boolean {
    if (GrowingContext.hasSimilarContext(trackerId, config)) {
      return false
    }

    GrowingContext.setContext(trackerId, config)
    let context = GrowingContext.getContext(trackerId) as GrowingContext
    let subTracker = new AnalyticsCore(context)
    AnalyticsCore.trackers.push(subTracker)
    UserIdentifier.initMultiUser(context)
    Session.refreshSession(context)

    let delay = config.debugEnabled && AppInfo.debug ? 1000 : config._dataUploadInterval
    setInterval(() => {
      EventSender.sendEvent(context)
    }, delay)

    subTracker._isInitializedSuccessfully = true
    return true
  }

  static tracker(trackerId: string): AnalyticsCore | DummyTracker {
    for (let tracker of AnalyticsCore.trackers) {
      if (tracker.context.trackerId == trackerId) {
        return tracker
      }
    }
    return AnalyticsCore.dummyTracker
  }

  static setAppStateChangeCallback(context: Context) {
    let applicationStateChangeCallback: ApplicationStateChangeCallback = {
      onApplicationForeground() {
        Session.onForeground()
      },
      onApplicationBackground() {
        Session.onBackground()
      }
    }

    context.getApplicationContext().on('applicationStateChange', applicationStateChangeCallback)
  }

  isInitializedSuccessfully(): boolean {
    return this._isInitializedSuccessfully
  }

  setDataCollectionEnabled(enabled: boolean) {
    let config = this.context.config
    if (config.dataCollectionEnabled == enabled) {
      return
    }
    LogUtil.info(() => 'Set dataCollectionEnabled: ' + enabled)
    config.dataCollectionEnabled = enabled
    if (enabled) {
      Session.refreshSession(this.context)
    }
  }

  setLoginUserId(
    userId: string,
    userKey?: string
  ) {
    if (!userKey) {
      userKey = ''
    }
    UserIdentifier.setLoginUserId(userId, userKey, this.context)
  }

  cleanLoginUserId() {
    UserIdentifier.setLoginUserId('', '', this.context)
  }

  getDeviceId(): string {
    return DeviceInfo.deviceId
  }

  track(
    eventName: string,
    attributes: AttributesType = {},
    sendTo?: string[]
  ) {
    let config = this.context.config
    if (!config.dataCollectionEnabled) {
      LogUtil.info(() => 'Failed to track event with name ' + eventName + ', dataCollectionEnabled is false')
      return
    }
    let e = CustomEvent.create(eventName, Util.cloneObject(attributes), this.context)
    AnalyticsCore.writeEventToDisk(e, this.context)
    LogUtil.info(() => 'Track custom event with eventName: ' + eventName + ', attributes: ' +
    JSON.stringify(attributes))

    if (sendTo && sendTo.length > 0) {
      AnalyticsCore.sendTo(this.context.trackerId, sendTo, eventName, attributes)
    }
  }

  static sendTo(
    curTrackerId: string,
    trackers: string[],
    eventName: string,
    attributes: AttributesType = {}
  ) {
    trackers = trackers.filter( trackerId => trackerId != curTrackerId )
    trackers = Array.from(new Set(trackers))
    trackers.forEach(trackerId => {
      let tracker = AnalyticsCore.tracker(trackerId)
      if (!tracker.isInitializedSuccessfully()) {
        return
      }
      if (!(tracker as AnalyticsCore).context.config.dataCollectionEnabled) {
        return
      }
      let e = CustomEvent.create(eventName, Util.cloneObject(attributes), (tracker as AnalyticsCore).context)
      AnalyticsCore.writeEventToDisk(e, (tracker as AnalyticsCore).context)
      LogUtil.info(() => 'Send custom event to tracker(' + trackerId + ') with eventName: ' + eventName
        + ', attributes: ' + JSON.stringify(attributes))
    })
  }

  static async writeEventToDisk<T extends Event>(
    event: T,
    context: GrowingContext
  ) {
    if (!context.config.dataCollectionEnabled) {
      // 所有event在生成之前都应该做此判断，此处实现是防呆设计
      return
    }

    let pst = EventPersistence.fromEvent(event, context)
    await EventDatabase.writeEvent(pst)
    if (pst.eventType == EventType.Visit) {
      EventSender.sendEvent(context)
    }
  }

  static setLocation(
    latitude: number,
    longitude: number
  ) {
    AnalyticsCore.location.latitude = latitude
    AnalyticsCore.location.longitude = longitude
  }

  static cleanLocation() {
    AnalyticsCore.location.latitude = 0
    AnalyticsCore.location.longitude = 0
  }
}