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
import UIAbility from '@ohos.app.ability.UIAbility'
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
import CustomEvent from '../event/CustomEvent'
import Event, { EventScene, EventType } from '../event/Event'
import EventBuilder from '../event/EventBuilder'
import EventDatabase from '../event/EventDatabase'
import EventPersistence from '../event/EventPersistence'
import EventSender from '../event/EventSender'
import LoginUserAttributesEvent from '../event/LoginUserAttributesEvent'
import CustomEventSender from '../event/saas/SaaSCSTMEventSender'
import PVEventSender from '../event/saas/SaaSPVEventSender'
import FakePageEvent from '../event/saas/FakePageEvent'
import { AttributesType, JavaScriptProxyType, SDK_VERSION } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'
import Util from '../utils/Util'

export default class AnalyticsCore implements GrowingAnalyticsInterface {
  static core: AnalyticsCore | undefined = undefined
  static trackers: Array<AnalyticsCore> = []
  static location: Location
  context: GrowingContext

  constructor(context: GrowingContext) {
    this.context = context
  }

  static async startCore(context: Context, config: GrowingConfig) {
    GrowingContext.setDefaultContext(config)
    let gContext = GrowingContext.getDefaultContext() as GrowingContext
    let core = new AnalyticsCore(gContext)
    AnalyticsCore.core = core
    AnalyticsCore.trackers.push(core)
    LogUtil.debugEnabled = config.debugEnabled
    AnalyticsCore.location = new Location()
    AnalyticsCore.setAbilityLifecycleCallback(context)
    await SharedPreferences.initWithContext(context)
    await Promise.all<Promise<void>>([
      AppInfo.initAppInfo(context),
      DeviceInfo.initDeviceInfo(),
      UserIdentifier.initUser(gContext),
      EventBuilder.initEventBuilder(),
      EventDatabase.initDatabase(context)
    ])

    LogUtil.info(() => 'Thank you very much for using GrowingIO. We will do our best to provide you with the best service. '
      + 'GrowingIO version: ' + SDK_VERSION)

    let delay = config._dataUploadInterval
    let runner = config.mode == ConfigMode.SaaS ? () => {
      CustomEventSender.sendEvent(gContext)
      PVEventSender.sendEvent(gContext)
    } : () => {
      EventSender.sendEvent(gContext)
    }
    setInterval(runner, delay)
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

    let delay = config._dataUploadInterval
    let runner = config.mode == ConfigMode.SaaS ? () => {
      CustomEventSender.sendEvent(context)
      PVEventSender.sendEvent(context)
    } : () => {
      EventSender.sendEvent(context)
    }
    setInterval(runner, delay)

    return true
  }

  static tracker(trackerId: string): AnalyticsCore | undefined {
    for (let tracker of AnalyticsCore.trackers) {
      if (tracker.context.trackerId == trackerId) {
        return tracker
      }
    }
    return undefined
  }

  static setAbilityLifecycleCallback(context: Context) {
    let abilityLifecycleCallback: AbilityLifecycleCallback = {
      onAbilityCreate(ability: UIAbility) {
      },
      onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage) {
      },
      onWindowStageActive(ability: UIAbility, windowStage: window.WindowStage) {
        Session.onForeground()
        EventTimer.handleAllTimersResume()
      },
      onWindowStageInactive(ability: UIAbility, windowStage: window.WindowStage) {
        Session.onBackground()
        EventTimer.handleAllTimersPause()
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

  createHybridProxy(controller: webview.WebviewController): JavaScriptProxyType {
    try {
      return Hybrid.createHybridProxy(controller, this.context)
    } catch (e) {
      LogUtil.error(() => "Failed to call createHybridProxy. code = " + e.code + ", message = " + e.message)
      return {
        object: this,
        name: '',
        methodList: [],
        controller: controller
      }
    }
  }

  setDataCollectionEnabled(enabled: boolean) {
    try {
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
    } catch (e) {
      LogUtil.error(() => "Failed to call setDataCollectionEnabled. code = " + e.code + ", message = " + e.message)
    }
  }

  setLoginUserId(
    userId: string,
    userKey?: string
  ) {
    try {
      if (!userKey) {
        userKey = ''
      }
      UserIdentifier.setLoginUserId(userId, userKey, this.context)
    } catch (e) {
      LogUtil.error(() => "Failed to call setLoginUserId. code = " + e.code + ", message = " + e.message)
    }
  }

  cleanLoginUserId() {
    try {
      UserIdentifier.setLoginUserId('', '', this.context)
    } catch (e) {
      LogUtil.error(() => "Failed to call cleanLoginUserId. code = " + e.code + ", message = " + e.message)
    }
  }

  setLoginUserAttributes(attributes: AttributesType) {
    try {
      let e = LoginUserAttributesEvent.create(Util.cloneObject(attributes), this.context)
      AnalyticsCore.writeEventToDisk(e, this.context)
      LogUtil.info(() => 'Set loginUserAttributes: ' + JSON.stringify(attributes))
    } catch (e) {
      LogUtil.error(() => "Failed to call setLoginUserAttributes. code = " + e.code + ", message = " + e.message)
    }
  }

  getDeviceId(): string {
    try {
      return DeviceInfo.deviceId
    } catch (e) {
      LogUtil.error(() => "Failed to call getDeviceId. code = " + e.code + ", message = " + e.message)
      return ''
    }
  }

  track(
    eventName: string,
    attributes: AttributesType = {},
    sendTo?: string[]
  ) {
    try {
      if (this.context.config.mode == ConfigMode.SaaS) {
        let p = FakePageEvent.create(this.context)
        AnalyticsCore.writeEventToDisk(p, this.context)
        let e = CustomEvent.create(eventName, Util.cloneObject(attributes), this.context, p)
        AnalyticsCore.writeEventToDisk(e, this.context)
      } else {
        let e = CustomEvent.create(eventName, Util.cloneObject(attributes), this.context)
        AnalyticsCore.writeEventToDisk(e, this.context)
      }
      LogUtil.info(() => 'Track custom event with eventName: ' + eventName + ', attributes: ' +
      JSON.stringify(attributes))

      if (sendTo && sendTo.length > 0) {
        AnalyticsCore.sendTo(sendTo, eventName, attributes)
      }
    } catch (e) {
      LogUtil.error(() => "Failed to call track. code = " + e.code + ", message = " + e.message)
    }
  }

  static sendTo(
    trackers: string[],
    eventName: string,
    attributes: AttributesType = {}
  ) {
    try {
      trackers.forEach(trackerId => {
        let tracker = AnalyticsCore.tracker(trackerId)
        if (tracker) {
          let e = CustomEvent.create(eventName, Util.cloneObject(attributes), tracker.context)
          AnalyticsCore.writeEventToDisk(e, tracker.context)
          LogUtil.info(() => 'Send custom event to tracker(' + trackerId + ') with eventName: ' + eventName
            + ', attributes: ' + JSON.stringify(attributes))
        }
      })
    } catch (e) {
      LogUtil.error(() => "Failed to call sendTo. code = " + e.code + ", message = " + e.message)
    }
  }

  async trackTimerStart(eventName: string): Promise<string> {
    try {
      return await EventTimer.trackTimerStart(eventName, this.context)
    } catch (e) {
      LogUtil.error(() => "Failed to call trackTimerStart. code = " + e.code + ", message = " + e.message)
      return ''
    }
  }

  async trackTimerPause(timerId: string) {
    try {
      await EventTimer.trackTimerPause(timerId)
    } catch (e) {
      LogUtil.error(() => "Failed to call trackTimerPause. code = " + e.code + ", message = " + e.message)
    }
  }

  async trackTimerResume(timerId: string) {
    try {
      await EventTimer.trackTimerResume(timerId)
    } catch (e) {
      LogUtil.error(() => "Failed to call trackTimerResume. code = " + e.code + ", message = " + e.message)
    }
  }

  async trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {}
  ) {
    try {
      await EventTimer.trackTimerEnd(timerId, Util.cloneObject(attributes), this.context)
    } catch (e) {
      LogUtil.error(() => "Failed to call trackTimerEnd. code = " + e.code + ", message = " + e.message)
    }
  }

  removeTimer(timerId: string) {
    try {
      EventTimer.removeTimer(timerId)
    } catch (e) {
      LogUtil.error(() => "Failed to call removeTimer. code = " + e.code + ", message = " + e.message)
    }
  }

  clearTrackTimer() {
    try {
      EventTimer.clearTrackTimer(this.context)
    } catch (e) {
      LogUtil.error(() => "Failed to call clearTrackTimer. code = " + e.code + ", message = " + e.message)
    }
  }

  static async writeEventToDisk<T extends Event>(
    event: T,
    context: GrowingContext,
    eventScene: EventScene = EventScene.Native
  ) {
    try {
      if (!context.config.dataCollectionEnabled) {
        return
      }

      let pst = EventPersistence.fromEvent(event, context)
      await EventDatabase.writeEvent(pst)
      if (pst.eventType == EventType.Visit) {
        if (context.config.mode == ConfigMode.SaaS) {
          await PVEventSender.sendEvent(context)
        } else {
          await EventSender.sendEvent(context)
        }
      }
    } catch (e) {
      LogUtil.error(() => "Failed to call writeEventToDisk. code = " + e.code + ", message = " + e.message)
    }
  }

  static setLocation(
    latitude: number,
    longitude: number
  ) {
    try {
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
    } catch (e) {
      LogUtil.error(() => "Failed to call setLocation. code = " + e.code + ", message = " + e.message)
    }
  }

  static cleanLocation() {
    try {
      AnalyticsCore.location.latitude = 0
      AnalyticsCore.location.longitude = 0
    } catch (e) {
      LogUtil.error(() => "Failed to call cleanLocation. code = " + e.code + ", message = " + e.message)
    }
  }
}

class Location {
  latitude: number = 0
  longitude: number = 0
}