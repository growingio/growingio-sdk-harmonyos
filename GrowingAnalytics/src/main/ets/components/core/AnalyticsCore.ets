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

export default class AnalyticsCore {
  static core: AnalyticsCore | undefined = undefined

  config: GrowingConfig
  location: Location

  constructor(config: GrowingConfig) {
    this.config = config
    this.location = new Location()
  }

  static async startCore(context: Context, config: GrowingConfig) {
    let core = new AnalyticsCore(config)
    AnalyticsCore.core = core
    LogUtil.debugEnabled = config.debugEnabled
    AnalyticsCore.setAbilityLifecycleCallback(context)
    await SharedPreferences.initWithContext(context)
    await Promise.all<Promise<void>>([
      AppInfo.initAppInfo(),
      DeviceInfo.initDeviceInfo(),
      UserIdentifier.initUser(),
      EventBuilder.initEventBuilder(),
      EventDatabase.initDatabase(context)
    ])

    LogUtil.info('Thank you very much for using GrowingIO. We will do our best to provide you with the best service. '
    + 'GrowingIO version: ' + SDK_VERSION)

    let delay = config.dataUploadInterval * 1000
    setInterval(() => {
      EventSender.sendEvent()
    }, delay)
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
    let config = this.config
    if (config.dataCollectionEnabled == enabled) {
      return
    }
    LogUtil.info('Set dataCollectionEnabled: ' + enabled)
    config.dataCollectionEnabled = enabled
    if (enabled) {
      Session.refreshSession()
    }
  }

  setLoginUserId(
    userId: string,
    userKey: string = ''
  ) {
    UserIdentifier.setLoginUserId(userId, userKey)
  }

  setLocation(
    latitude: number,
    longitude: number
  ) {
    this.location.latitude = latitude
    this.location.longitude = longitude
  }

  setLoginUserAttributes(
    attributes: AttributesType
  ) {
    let e = LoginUserAttributesEvent.create(attributes)
    this.writeEventToDisk(e)
    LogUtil.info('Set loginUserAttributes: ' + JSON.stringify(attributes))
  }

  getDeviceId() {
    return DeviceInfo.deviceId
  }

  track(
    eventName: string,
    attributes: AttributesType = {}
  ) {
    let generalProps = GeneralProps.getGeneralProps()
    let e = CustomEvent.create(eventName, Util.concatObject(generalProps, attributes))
    this.writeEventToDisk(e)
    LogUtil.info('Track custom event with eventName: ' + eventName + ', attributes: ' + JSON.stringify(attributes)
    + ', current generalProps: ' + JSON.stringify(generalProps))
  }

  async trackTimerStart(eventName: string): Promise<string> {
    return await EventTimer.trackTimerStart(eventName)
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
    await EventTimer.trackTimerEnd(timerId, attributes)
  }

  removeTimer(timerId: string) {
    EventTimer.removeTimer(timerId)
  }

  clearTrackTimer() {
    EventTimer.clearTrackTimer()
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

  async writeEventToDisk<T extends Event>(event: T) {
    if (!this.config.dataCollectionEnabled) {
      return
    }
    let pst = EventPersistence.fromEvent(event)
    await EventDatabase.writeEvent(pst)
    if (pst.eventType == EventType.Visit) {
      await EventSender.sendEvent()
    }
  }
}

class Location {
  latitude: number = 0
  longitude: number = 0
}