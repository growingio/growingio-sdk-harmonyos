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
import webview from '@ohos.web.webview'
import sendableContextManager from '@ohos.app.ability.sendableContextManager'
import collections from '@arkts.collections'

import { GrowingAnalyticsInterface } from '../interfaces/GrowingAnalytics'
import { ConfigMode, GrowingConfig } from '../interfaces/GrowingConfig'
import AppInfo from './AppInfo'
import GrowingContext from './Context'
import DeviceInfo from './DeviceInfo'
import EventTimer from './EventTimer'
import Hybrid from './Hybrid'
import Session from './Session'
import UserIdentifier from './UserIdentifier'
import Autotrack, { AutotrackStatusFetcher } from '../autotrack/Autotrack'
import CustomEvent from '../event/CustomEvent'
import Event, { EventScene, EventType } from '../event/Event'
import EventDatabase from '../event/EventDatabase'
import EventPersistence from '../event/EventPersistence'
import EventSender from '../event/EventSender'
import LoginUserAttributesEvent from '../event/LoginUserAttributesEvent'
import { SaaSEvarEvent, SaaSVisitorEvent } from '../event/saas/SaaSTrackEvent'
import Network from './Network'
import FakePageEvent from '../event/saas/FakePageEvent'
import { AttributesType, EMIT_EVENT_MAIN_TRACKER_INITIALIZE,
  GWindowStage,
  JavaScriptProxyType,
  SaaSJavaScriptConfigType,
  STORAGE_WINDOW_STAGE} from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'
import Util from '../utils/Util'
import DummyTracker from './DummyTracker'
import { HAR_VERSION } from '../../../../../BuildProfile'
import Plugins, { PluginsInterface } from '../plugins/Plugins'
import MobileDebugger from '../mobileDebugger/MobileDebugger'
import Circle from '../circle/Circle'
import { AppStorageV2 } from '@ohos.arkui.StateManagement'

"use shared"

@Sendable
class Location {
  latitude: number = 0
  longitude: number = 0
}

export const SDK_VERSION: string = HAR_VERSION

@Sendable
export default class AnalyticsCore implements GrowingAnalyticsInterface {
  static abContext: sendableContextManager.SendableContext
  static core: AnalyticsCore | DummyTracker = new DummyTracker()
  static trackers: collections.Array<AnalyticsCore> = new collections.Array<AnalyticsCore>()
  static dummyTracker: DummyTracker = new DummyTracker()
  static location: Location = new Location()
  context: GrowingContext
  private _isInitializedSuccessfully: boolean = false

  constructor(context: GrowingContext) {
    this.context = context
  }

  static startCore(context: Context, config: GrowingConfig) {
    let plugins: PluginsInterface[] = [...config.plugins]
    if (config.mode != ConfigMode.SaaS) {
      // 仅支持 NewSaaS 和 CDP
      plugins.push(new MobileDebugger())
    }
    if (config.mode == ConfigMode.NewSaaS && config.autotrackEnabled) {
      plugins.push(new Circle())
    }
    Plugins.registerPlugins(plugins)
    Plugins.onSDKWillInitialize()
    GrowingContext.setDefaultContext(config)
    let gContext = GrowingContext.getDefaultContext() as GrowingContext
    let core = new AnalyticsCore(gContext)
    AnalyticsCore.core = core
    AnalyticsCore.trackers.push(core)
    LogUtil.debugEnabled = config.debugEnabled
    Autotrack.initAutotrack(gContext)
    AnalyticsCore.setLifecycleCallback(context)
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
    Plugins.onSDKDidInitialize(config, SDK_VERSION)
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

    Plugins.onStartSubTracker(trackerId, config)
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

  static setLifecycleCallback(context: Context) {
    // 与Autotrack不同，插件的初始化需要保证在SDK的初始化之后
    // 而Autotrack的UI监听需要在应用启动之初，来保证page.path的正确性等
    if (AnalyticsCore.abContext != undefined) {
      return
    }

    let callback = (abilityContext: common.UIAbilityContext, windowStage: window.WindowStage) => {
      AnalyticsCore.abContext = sendableContextManager.convertFromContext(abilityContext)
      let prop = AppStorageV2.connect(GWindowStage, STORAGE_WINDOW_STAGE, () => new GWindowStage())
      if (prop != undefined) {
        prop.windowStage = windowStage
      }

      // 无法保证用户对SDK初始化和Autotrack的UI监听的执行顺序，因此使用匿名函数实时获取
      Plugins.setAutotrackStatusFetcher(AutotrackStatusFetcher)
      Plugins.afterWindowStageCreate(abilityContext, windowStage)
    }

    // 如果传入UIAbility实例，且已到达onWindowStageCreate生命周期，则直接获取windowStage，不用再监听abilityLifecycle
    if (Util.isUIAbilityContext(context)) {
      let abilityContext = context as common.UIAbilityContext
      let windowStage = abilityContext.windowStage
      if (windowStage) {
        // 可以断定为延迟初始化场景，即初始化时机在windowStage.loadContent之后
        Plugins.onDeferStart()
        callback(abilityContext, windowStage)
        return
      }
    }

    let abilityLifecycleCallback: AbilityLifecycleCallback = {
      onAbilityCreate(ability: UIAbility) {
      },
      onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage) {
        callback(ability.context, windowStage)
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
  }

  static setAppStateChangeCallback(context: Context) {
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

  static mainWindow(): window.Window | undefined {
    let prop = AppStorageV2.connect(GWindowStage, STORAGE_WINDOW_STAGE, () => new GWindowStage())
    let windowStage = prop?.windowStage
    if (windowStage) {
      return windowStage.getMainWindowSync()
    }
    return undefined
  }

  createHybridProxy(controller: webview.WebviewController): JavaScriptProxyType {
    return Hybrid.createHybridProxy(controller, this.context)
  }

  javaScriptOnDocumentStart(
    scriptRules?: Array<string>,
    saasJavaScriptConfig?: SaaSJavaScriptConfigType): Array<ScriptItem> {
    return Hybrid.javaScriptOnDocumentStart(this.context, scriptRules, saasJavaScriptConfig)
  }

  javaScriptOnDocumentEnd(scriptRules?: Array<string>): Array<ScriptItem> {
    return Hybrid.javaScriptOnDocumentEnd(this.context, scriptRules)
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
      if (tracker instanceof AnalyticsCore) {
        if (!tracker.context.config.dataCollectionEnabled) {
          return
        }
        let e = CustomEvent.create(eventName, Util.cloneObject(attributes), tracker.context)
        AnalyticsCore.writeEventToDisk(e, tracker.context)
        LogUtil.info(() => 'Send custom event to tracker(' + trackerId + ') with eventName: ' + eventName
          + ', attributes: ' + JSON.stringify(attributes))
      }
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
    Plugins.onEventWroteToDisk(pst, eventScene)
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

  setPeopleVariable(attributes: AttributesType) {
    if (this.context.config.mode != ConfigMode.SaaS) {
      LogUtil.info(() => 'Failed to set people variable, only support on SaaS mode')
      return
    }
    if (!this.context.config.dataCollectionEnabled) {
      LogUtil.info(() => 'Failed to set people variable, dataCollectionEnabled is false')
      return
    }
    this.setLoginUserAttributes(attributes)
  }

  setEvar(attributes: AttributesType) {
    if (this.context.config.mode != ConfigMode.SaaS) {
      LogUtil.info(() => 'Failed to set evar, only support on SaaS mode')
      return
    }
    if (!this.context.config.dataCollectionEnabled) {
      LogUtil.info(() => 'Failed to set evar, dataCollectionEnabled is false')
      return
    }

    let e = SaaSEvarEvent.create(Util.cloneObject(attributes), this.context)
    AnalyticsCore.writeEventToDisk(e, this.context)
    LogUtil.info(() => 'Set evar: ' + JSON.stringify(attributes))
  }

  setVisitor(attributes: AttributesType) {
    if (this.context.config.mode != ConfigMode.SaaS) {
      LogUtil.info(() => 'Failed to set visitor, only support on SaaS mode')
      return
    }
    if (!this.context.config.dataCollectionEnabled) {
      LogUtil.info(() => 'Failed to set visitor, dataCollectionEnabled is false')
      return
    }

    let e = SaaSVisitorEvent.create(Util.cloneObject(attributes), this.context)
    AnalyticsCore.writeEventToDisk(e, this.context)
    LogUtil.info(() => 'Set visitor: ' + JSON.stringify(attributes))
  }

  static handleOpenURL(uri: string): boolean {
    return Plugins.handleOpenURL(uri)
  }
}