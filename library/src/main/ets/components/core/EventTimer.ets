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

import systemDatetime from '@ohos.systemDateTime'
import util from '@ohos.util'

import AnalyticsCore from './AnalyticsCore'
import GrowingContext from './Context'
import CustomEvent from '../event/CustomEvent'
import { AttributesType, Event_DURATION } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import FakePageEvent from '../event/saas/FakePageEvent'
import { ConfigMode } from '../interfaces/GrowingConfig'

export default class EventTimer {
  static timers: Map<string, EventTimer> = new Map()
  eventName: string
  startTime: number
  duration: number
  trackerId: string

  constructor(
    eventName: string,
    startTime: number,
    duration: number,
    trackerId: string
  ) {
    this.eventName = eventName
    this.startTime = startTime
    this.duration = duration
    this.trackerId = trackerId
  }

  static trackTimerStart(
    eventName: string,
    context: GrowingContext
  ): string {
    if (!context.config.dataCollectionEnabled) {
      return ''
    }

    let currentTime = systemDatetime.getUptime(systemDatetime.TimeType.STARTUP, false)
    let timer = new EventTimer(eventName, currentTime, 0, context.trackerId)
    let timerId = eventName + '_' + util.generateRandomUUID(false)

    EventTimer.timers.set(timerId, timer)
    LogUtil.info(() => 'Track timer start, eventName: ' + eventName + ', timerId: ' + timerId)
    return timerId
  }

  static trackTimerPause(timerId: string) {
    let timer: EventTimer | undefined = EventTimer.timers.get(timerId)
    if (!timer || timer.isPaused()) {
      return
    }
    let startTime = timer.startTime
    timer.startTime = 0
    let currentTime = systemDatetime.getUptime(systemDatetime.TimeType.STARTUP, false)
    timer.duration = EventTimer.durationFrom(startTime, currentTime)
    LogUtil.info(() => 'Track timer pause, timerId is ' + timerId)
  }

  static trackTimerResume(timerId: string) {
    let timer: EventTimer | undefined = EventTimer.timers.get(timerId)
    if (!timer || !timer.isPaused()) {
      return
    }
    let currentTime = systemDatetime.getUptime(systemDatetime.TimeType.STARTUP, false)
    timer.startTime = currentTime
    LogUtil.info(() => 'Track timer resume, timerId is ' + timerId)
  }

  static trackTimerEnd(
    timerId: string,
    attributes: AttributesType = {},
    context: GrowingContext,
    sendTo?: string[]
  ) {
    if (!context.config.dataCollectionEnabled) {
      return
    }

    let timer: EventTimer | undefined = EventTimer.timers.get(timerId)
    if (!timer) {
      return
    }
    if (timer.trackerId != context.trackerId) {
      const message = "Track timer end failed, this timer's trackerId (" + timer.trackerId
        + ") is not equal to current tracker's trackerId(" + context.trackerId + ")"
      LogUtil.warn(() => message)
      return
    }
    let eventName = timer.eventName
    let startTime = timer.startTime
    let duration = timer.duration
    EventTimer.timers.delete(timerId)

    let currentTime = systemDatetime.getUptime(systemDatetime.TimeType.STARTUP, false)
    duration = EventTimer.durationFrom(startTime, currentTime) + duration
    attributes[Event_DURATION] = (duration / 1000.0).toFixed(3) + ''
    if (context.config.mode == ConfigMode.SaaS) {
      let p = FakePageEvent.create(context)
      AnalyticsCore.writeEventToDisk(p, context)
      let e = CustomEvent.create(eventName, attributes, context, p)
      AnalyticsCore.writeEventToDisk(e, context)
    } else {
      let e = CustomEvent.create(eventName, attributes, context)
      AnalyticsCore.writeEventToDisk(e, context)
    }
    LogUtil.info(() => 'Track timer end, eventName: ' + eventName + ', timerId: ' + timerId + ', attributes: '
      + JSON.stringify(attributes))

    if (sendTo && sendTo.length > 0) {
      AnalyticsCore.sendTo(context.trackerId, sendTo, eventName, attributes)
    }
  }

  static removeTimer(timerId: string) {
    LogUtil.info(() => 'Track timer remove, timerId is ' + timerId)
    EventTimer.timers.delete(timerId)
  }

  static clearTrackTimer(context: GrowingContext) {
    LogUtil.info(() => 'Track timer all delete')
    let timersToDelete: string[] = []
    EventTimer.timers.forEach((timer, timerId) => {
      if (timer.trackerId == context.trackerId) {
        timersToDelete.push(timerId)
      }
    })
    for (let timerId of timersToDelete) {
      EventTimer.timers.delete(timerId)
    }
  }

  static handleAllTimersPause() {
    LogUtil.info(() => 'Track timer all pause with appState is background')
    for (let timer of EventTimer.timers.values()) {
      if (timer.isPaused()) {
        return
      }
      let currentTime = systemDatetime.getUptime(systemDatetime.TimeType.STARTUP, false)
      timer.duration = EventTimer.durationFrom(timer.startTime, currentTime)
      timer.startTime = currentTime
    }
  }

  static handleAllTimersResume() {
    LogUtil.info(() => 'Track timer all resume with appState is foreground')
    for (let timer of EventTimer.timers.values()) {
      if (timer.isPaused()) {
        return
      }
      let currentTime = systemDatetime.getUptime(systemDatetime.TimeType.STARTUP, false)
      timer.startTime = currentTime
    }
  }

  isPaused(): boolean {
    return this.startTime == 0
  }

  static durationFrom(startTime: number, endTime: number) {
    if (startTime <= 0) {
      return 0
    }
    let duration = endTime - startTime
    return (duration > 0 && duration < 24 * 60 * 60 * 1000) ? duration : 0
  }
}