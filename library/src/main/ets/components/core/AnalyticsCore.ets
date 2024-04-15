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

import { GrowingAnalyticsInterface } from '../interfaces/GrowingAnalytics'
import { GrowingConfig } from '../interfaces/GrowingConfig'
import AppInfo from './AppInfo'
import DeviceInfo from './DeviceInfo'
import EventTimer from './EventTimer'
import GeneralProps from './GeneralProps'
import Session from './Session'
import UserIdentifier from './UserIdentifier'
import CustomEvent from '../event/CustomEvent'
import Event, { EventType } from '../event/Event'
import EventBuilder from '../event/EventBuilder'
import EventDatabase from '../event/EventDatabase'
import EventPersistence from '../event/EventPersistence'
import EventSender from '../event/EventSender'
import LoginUserAttributesEvent from '../event/LoginUserAttributesEvent'
import { AttributesType, SDK_VERSION } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'
import Util from '../utils/Util'
import GrowingContext from './Context'

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
    let gContext = GrowingContext.getDefaultContext()
    let core = new AnalyticsCore(gContext)
    AnalyticsCore.core = core
    LogUtil.debugEnabled = config.debugEnabled
    AnalyticsCore.location = new Location()
    AnalyticsCore.setAbilityLifecycleCallback(context)
    await SharedPreferences.initWithContext(context)
    await Promise.all<Promise<void>>([
      AppInfo.initAppInfo(),
      DeviceInfo.initDeviceInfo(),
      UserIdentifier.initUser(gContext),
      EventBuilder.initEventBuilder(),
      EventDatabase.initDatabase(context)
    ])

    LogUtil.info('Thank you very much for using GrowingIO. We will do our best to provide you with the best service. '
    + 'GrowingIO version: ' + SDK_VERSION)

    let delay = config.dataUploadInterval * 1000
    setInterval(() => {
      EventSender.sendEvent(gContext)
    }, delay)
  }

  static startMultiTracker(trackerId: string, config: GrowingConfig): boolean {
    if (GrowingContext.getContext(trackerId)) {
      return false
    }

    GrowingContext.setContext(trackerId, config)
    let context = GrowingContext.getContext(trackerId)
    let core = new AnalyticsCore(context)
    AnalyticsCore.trackers.push(core)

    UserIdentifier.initMultiUser(context)

    let delay = config.dataUploadInterval * 1000
    setInterval(() => {
      EventSender.sendEvent(context)
    }, delay)

    return true
  }

  static tracker(trackerId: string): AnalyticsCore | undefined {
    AnalyticsCore.trackers.forEach(function (tracker) {
      if (tracker.context.trackerId == trackerId) {
        return tracker
      }
    })

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

  setDataCollectionEnabled(enabled: boolean) {
    let config = this.context.config
    if (config.dataCollectionEnabled == enabled) {
      return
    }
    LogUtil.info('Set dataCollectionEnabled: ' + enabled)
    config.dataCollectionEnabled = enabled
    if (enabled) {
      Session.refreshSession(this.context)
    } else {
      EventTimer.clearTrackTimer(this.context)
    }
  }

  setLoginUserId(
    userId: string,
    userKey: string = ''
  ) {
    UserIdentifier.setLoginUserId(userId, userKey, this.context)
  }

  cleanLoginUserId() {
    UserIdentifier.setLoginUserId('', '', this.context)
  }

  setLoginUserAttributes(attributes: AttributesType) {
    let e = LoginUserAttributesEvent.create(attributes, this.context)
    AnalyticsCore.writeEventToDisk(e, this.context)
    LogUtil.info('Set loginUserAttributes: ' + JSON.stringify(attributes))
  }

  getDeviceId(): string {
    return DeviceInfo.deviceId
  }

  track(
    eventName: string,
    attributes: AttributesType = {},
    sendTo?: string[]
  ) {
    let generalProps = GeneralProps.getGeneralProps()
    let finalAttributes = Util.concatObject(generalProps, attributes)
    let e = CustomEvent.create(eventName, finalAttributes, this.context)
    AnalyticsCore.writeEventToDisk(e, this.context)
    LogUtil.info('Track custom event with eventName: ' + eventName + ', attributes: ' + JSON.stringify(attributes)
    + ', current generalProps: ' + JSON.stringify(generalProps))

    if (sendTo && sendTo.length > 0) {
      AnalyticsCore.sendTo(sendTo, eventName, finalAttributes)
    }
  }

  static sendTo(
    trackers: string[],
    eventName: string,
    attributes: AttributesType = {}
  ) {
    trackers.forEach(function (trackerId) {
      let tracker = AnalyticsCore.tracker(trackerId)
      if (tracker) {
        let e = CustomEvent.create(eventName, attributes, tracker.context)
        AnalyticsCore.writeEventToDisk(e, tracker.context)
        LogUtil.info('Send custom event to tracker(' + trackerId + ') with eventName: ' + eventName
        + ', attributes: ' + JSON.stringify(attributes))
      }
    })
  }

  async trackTimerStart(eventName: string): Promise<string> {
    return await EventTimer.trackTimerStart(eventName, this.context)
  }

  async trackTimerPause(timerId: string) {
    await EventTimer.trackTimerPause(timerId)
  }

  async trackTimerResume(timerId: string) {
    await EventTimer.trackTimerResume(timerId)
  }

  async trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {}
  ) {
    await EventTimer.trackTimerEnd(timerId, attributes, this.context)
  }

  removeTimer(timerId: string) {
    EventTimer.removeTimer(timerId)
  }

  clearTrackTimer() {
    EventTimer.clearTrackTimer(this.context)
  }

  setGeneralProps(props: AttributesType) {
    GeneralProps.setGeneralProps(props)
  }

  removeGeneralProps(keys: string[]) {
    GeneralProps.removeGeneralProps(keys)
  }

  clearGeneralProps() {
    GeneralProps.clearGeneralProps()
  }

  static async writeEventToDisk<T extends Event>(event: T, context: GrowingContext) {
    if (!context.config.dataCollectionEnabled) {
      return
    }
    let pst = EventPersistence.fromEvent(event, context)
    await EventDatabase.writeEvent(pst)
    if (pst.eventType == EventType.Visit) {
      await EventSender.sendEvent(context)
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

class Location {
  latitude: number = 0
  longitude: number = 0
}