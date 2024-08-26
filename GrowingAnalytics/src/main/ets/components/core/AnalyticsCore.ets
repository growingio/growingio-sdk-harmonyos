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
import UIAbility from '@ohos.app.ability.UIAbility'
import emitter from '@ohos.events.emitter'
import window from '@ohos.window'
import webview from '@ohos.web.webview'

import { GrowingAnalyticsInterface } from '../interfaces/GrowingAnalytics'
import { ConfigMode, GrowingConfig } from '../interfaces/GrowingConfig'
import AppInfo from './AppInfo'
import GrowingContext from './Context'
import DeviceInfo from './DeviceInfo'
import EventTimer from './EventTimer'
import Hybrid from './Hybrid'
import Session from './Session'
import UserIdentifier from './UserIdentifier'
import AutotrackPage from '../autotrack/AutotrackPage'
import CustomEvent from '../event/CustomEvent'
import Event, { EventScene, EventType } from '../event/Event'
import EventBuilder from '../event/EventBuilder'
import EventDatabase from '../event/EventDatabase'
import EventPersistence from '../event/EventPersistence'
import EventSender from '../event/EventSender'
import LoginUserAttributesEvent from '../event/LoginUserAttributesEvent'
import Network from './Network'
import FakePageEvent from '../event/saas/FakePageEvent'
import { AttributesType, EMIT_EVENT_MAIN_TRACKER_INITIALIZE, JavaScriptProxyType } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'
import Util from '../utils/Util'
import DummyTracker from './DummyTracker'
import { HAR_VERSION } from '../../../../../BuildProfile'
import Plugins from '../plugins/Plugins'

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
  private static _mainWindowStage: window.WindowStage | undefined = undefined

  constructor(context: GrowingContext) {
    this.context = context
  }

  static startCore(context: Context, config: GrowingConfig) {
    Plugins.registerPlugins(config.plugins)
    Plugins.onSDKWillInitialize()
    GrowingContext.setDefaultContext(config)
    let gContext = GrowingContext.getDefaultContext() as GrowingContext
    let core = new AnalyticsCore(gContext)
    AnalyticsCore.core = core
    AnalyticsCore.trackers.push(core)
    LogUtil.debugEnabled = config.debugEnabled
    AnalyticsCore.setLifecycleCallback(context)
    SharedPreferences.initWithContext(context)
    AppInfo.initAppInfo(context)
    DeviceInfo.initDeviceInfo()
    UserIdentifier.initUser(gContext)
    EventBuilder.initEventBuilder()
    EventDatabase.initDatabase(context)
    Network.initNetwork(gContext)
    Session.refreshSession(gContext)

    let delay = config._dataUploadInterval
    setInterval(() => {
      EventSender.sendEvent(gContext)
    }, delay)

    emitter.emit({
      eventId: EMIT_EVENT_MAIN_TRACKER_INITIALIZE
    })
    LogUtil.info(() => 'Thank you very much for using GrowingIO. We will do our best to provide you with the best service. '
      + 'GrowingIO version: ' + SDK_VERSION)
    Plugins.onSDKDidInitialize(config, SDK_VERSION)
    core._isInitializedSuccessfully = true
  }

  static startSubTracker(trackerId: string, config: GrowingConfig): boolean {
    if (GrowingContext.hasSimilarContext(trackerId, config)) {
      return false
    }

    GrowingContext.setContext(trackerId, config)
    let context = GrowingContext.getContext(trackerId) as GrowingContext
    let core = new AnalyticsCore(context)
    AnalyticsCore.trackers.push(core)
    UserIdentifier.initMultiUser(context)
    Session.refreshSession(context)

    let delay = config._dataUploadInterval
    setInterval(() => {
      EventSender.sendEvent(context)
    }, delay)

    core._isInitializedSuccessfully = true
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

  static setLifecycleCallback(context: Context) {
    let gContext = GrowingContext.getDefaultContext() as GrowingContext
    let abilityLifecycleCallback: AbilityLifecycleCallback = {
      onAbilityCreate(ability: UIAbility) {
      },
      onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage) {
        if (AnalyticsCore._mainWindowStage != undefined) {
          return
        }

        AnalyticsCore._mainWindowStage = windowStage

        if (gContext.config.autotrackEnabled) {
          windowStage.getMainWindow().then(window => {
            AutotrackPage.initAutotrackPage(window.getUIContext())
          })
        }

        Plugins.onWindowStageCreate(ability, windowStage)
      },
      onWindowStageActive(ability: UIAbility, windowStage: window.WindowStage) {
      },
      onWindowStageInactive(ability: UIAbility, windowStage: window.WindowStage) {
      },
      onWindowStageDestroy(ability: UIAbility, windowStage: window.WindowStage) {
      },
      onAbilityDestroy(ability: UIAbility) {
      },
      onAbilityForeground(ability: UIAbility) {
      },
      onAbilityBackground(ability: UIAbility) {
      },
      onAbilityContinue(ability: UIAbility) {
      }
    }
    context.getApplicationContext().on('abilityLifecycle', abilityLifecycleCallback)

    let applicationStateChangeCallback: ApplicationStateChangeCallback = {
      onApplicationForeground() {
        Session.onForeground()
        EventTimer.handleAllTimersResume()
      },
      onApplicationBackground() {
        Session.onBackground()
        EventTimer.handleAllTimersPause()
      }
    }

    context.getApplicationContext().on('applicationStateChange', applicationStateChangeCallback)
  }

  createHybridProxy(controller: webview.WebviewController): JavaScriptProxyType {
    return Hybrid.createHybridProxy(controller, this.context)
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
      if (config.mode == ConfigMode.CDP) {
        Session.generateVisit(this.context)
      } else {
        Session.refreshSession(this.context)
      }
    } else {
      EventTimer.clearTrackTimer(this.context)
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

  setLoginUserAttributes(attributes: AttributesType) {
    if (!this.context.config.dataCollectionEnabled) {
      LogUtil.info(() => 'Failed to set login user attributes, dataCollectionEnabled is false')
      return
    }

    let e = LoginUserAttributesEvent.create(Util.cloneObject(attributes), this.context)
    AnalyticsCore.writeEventToDisk(e, this.context)
    LogUtil.info(() => 'Set loginUserAttributes: ' + JSON.stringify(attributes))
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
    if (config.mode == ConfigMode.SaaS) {
      FakePageEvent.sendFakePageIfNeeded(this.context)
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

  trackTimerStart(eventName: string): string {
    return EventTimer.trackTimerStart(eventName, this.context)
  }

  trackTimerPause(timerId: string) {
    EventTimer.trackTimerPause(timerId)
  }

  trackTimerResume(timerId: string) {
    EventTimer.trackTimerResume(timerId)
  }

  trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {},
    sendTo?: string[]
  ) {
    EventTimer.trackTimerEnd(timerId, Util.cloneObject(attributes), this.context, sendTo)
  }

  removeTimer(timerId: string) {
    EventTimer.removeTimer(timerId)
  }

  clearTrackTimer() {
    EventTimer.clearTrackTimer(this.context)
  }

  static async writeEventToDisk<T extends Event>(
    event: T,
    context: GrowingContext,
    eventScene: EventScene = EventScene.Native
  ) {
    if (!context.config.dataCollectionEnabled) {
      // 所有event在生成之前都应该做此判断，此处实现是防呆设计
      return
    }

    let pst = EventPersistence.fromEvent(event, context)
    await EventDatabase.writeEvent(pst)
    Plugins.onEventWroteToDisk(pst.uuid, pst.data, pst.eventType, eventScene)
    if (pst.eventType == EventType.Visit) {
      EventSender.sendEvent(context)
    }
  }

  static setLocation(
    latitude: number,
    longitude: number
  ) {
    // mode CDP
    let needSendVisit: boolean = false
    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (context) {
      if (context.config.mode == ConfigMode.CDP) {
        if ((AnalyticsCore.location.latitude == 0 && Math.abs(latitude) > 0)
          || (AnalyticsCore.location.longitude == 0 && Math.abs(longitude) > 0)) {
          needSendVisit = true
        }
      }
    }

    AnalyticsCore.location.latitude = latitude
    AnalyticsCore.location.longitude = longitude

    // mode CDP
    if (needSendVisit) {
      Session.generateVisit(context)
    }
  }

  static cleanLocation() {
    AnalyticsCore.location.latitude = 0
    AnalyticsCore.location.longitude = 0
  }
}