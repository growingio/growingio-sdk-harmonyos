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

import systemUptime from '@ohos.systemDateTime'
import util from '@ohos.util'

import AnalyticsCore from './AnalyticsCore'
import CustomEvent from '../event/CustomEvent'
import { AttributesType, Event_DURATION } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'

export default class EventTimer {
  static timers: Map<string, EventTimer> = new Map()

  eventName: string
  startTime: number
  duration: number

  constructor(
    eventName: string,
    startTime: number,
    duration: number
  ) {
    this.eventName = eventName
    this.startTime = startTime
    this.duration = duration
  }

  static async trackTimerStart(eventName: string): Promise<string> {
    let config = (AnalyticsCore.core as AnalyticsCore).config
    if (!config.dataCollectionEnabled) {
      return ''
    }

    let currentTime = await systemUptime.getRealTime(false)
    let timer = new EventTimer(eventName, currentTime, 0)
    let timerId = eventName + '_' + util.generateRandomUUID(false)

    EventTimer.timers.set(timerId, timer)
    LogUtil.info('Track timer start, eventName: ' + eventName + ', timerId: ' + timerId)
    return timerId
  }

  static async trackTimerPause(timerId: string) {
    let timer: EventTimer | undefined = EventTimer.timers.get(timerId)
    if (!timer || timer.isPaused()) {
      return
    }
    let startTime = timer.startTime
    timer.startTime = 0
    let currentTime = await systemUptime.getRealTime(false)
    timer.duration = EventTimer.durationFrom(startTime, currentTime)
    LogUtil.info('Track timer pause, timerId is ' + timerId)
  }

  static async trackTimerResume(timerId: string) {
    let timer: EventTimer | undefined = EventTimer.timers.get(timerId)
    if (!timer || !timer.isPaused()) {
      return
    }
    let currentTime = await systemUptime.getRealTime(false)
    timer.startTime = currentTime
    LogUtil.info('Track timer resume, timerId is ' + timerId)
  }

  static async trackTimerEnd(timerId: string, attributes: AttributesType = {}) {
    let timer: EventTimer | undefined = EventTimer.timers.get(timerId)
    if (!timer) {
      return
    }
    let eventName = timer.eventName
    let startTime = timer.startTime
    let duration = timer.duration
    EventTimer.timers.delete(timerId)

    let currentTime = await systemUptime.getRealTime(false)
    duration = EventTimer.durationFrom(startTime, currentTime) + duration
    attributes[Event_DURATION] = (duration / 1000.0).toFixed(3) + ''
    let e = CustomEvent.create(eventName, attributes)
    let core = AnalyticsCore.core as AnalyticsCore
    core.writeEventToDisk(e)
    LogUtil.info('Track timer end, eventName: ' + eventName + ', timerId: ' + timerId + ', attributes: '
    + JSON.stringify(attributes))
  }

  static removeTimer(timerId: string) {
    LogUtil.info('Track timer remove, timerId is ' + timerId)
    EventTimer.timers.delete(timerId)
  }

  static clearTrackTimer() {
    LogUtil.info('Track timer all delete')
    EventTimer.timers.clear()
  }

  static async handleAllTimersPause() {
    LogUtil.info('Track timer all pause with appState is background')
    for (let timer of EventTimer.timers.values()) {
      if (timer.isPaused()) {
        return
      }
      let currentTime = await systemUptime.getRealTime(false)
      timer.duration = EventTimer.durationFrom(timer.startTime, currentTime)
      timer.startTime = currentTime
    }
  }

  static async handleAllTimersResume() {
    LogUtil.info('Track timer all resume with appState is foreground')
    for (let timer of EventTimer.timers.values()) {
      if (timer.isPaused()) {
        return
      }
      let currentTime = await systemUptime.getRealTime(false)
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