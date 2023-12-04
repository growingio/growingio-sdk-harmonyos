import systemUptime from '@ohos.systemDateTime'
import util from '@ohos.util'

import AnalyticsCore from './AnalyticsCore'
import CustomEvent from '../event/CustomEvent'
import EventSender from '../event/EventSender'
import { AttributesType, Event_DURATION } from '../utils/Constants'

export default class EventTimer {
  static timers: { [key: string]: EventTimer } = {}

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
    let config = AnalyticsCore.core.config
    if (!config.dataCollectionEnabled) {
      return
    }

    let currentTime = await systemUptime.getRealTime(false)
    let timer = new EventTimer(eventName, currentTime, 0)
    let timerId = eventName + '_' + util.generateRandomUUID(false)

    this.timers[timerId] = timer
    return timerId
  }

  static async trackTimerPause(timerId: string) {
    let currentTime = await systemUptime.getRealTime(false)
    let timer = this.timers[timerId]
    if (!timer || timer.isPaused()) {
      return
    }
    timer.duration = this.durationFrom(timer.startTime, currentTime)
    timer.startTime = 0
  }

  static async trackTimerResume(timerId: string) {
    let currentTime = await systemUptime.getRealTime(false)
    let timer = this.timers[timerId]
    if (!timer || !timer.isPaused()) {
      return
    }
    timer.startTime = currentTime
  }

  static async trackTimerEnd(timerId: string, attributes: AttributesType = {}) {
    let currentTime = await systemUptime.getRealTime(false)
    let timer = this.timers[timerId]
    if (!timer) {
      return
    }
    let eventName = timer.eventName
    let duration = this.durationFrom(timer.startTime, currentTime) + timer.duration
    attributes[Event_DURATION] = (duration / 1000.0).toFixed(3) + ''
    let e = await CustomEvent.create(eventName, attributes)
    EventSender.sendEvent(e)
    delete this.timers[timerId]
  }

  static removeTimer(timerId: string) {
    delete this.timers[timerId]
  }

  static clearTrackTimer() {
    this.timers = {}
  }

  static async handleAllTimersPause() {
    let currentTime = await systemUptime.getRealTime(false)
    Object.keys(this.timers).forEach(timerId => {
      let timer = this.timers[timerId]
      if (timer.isPaused()) {
        return
      }
      timer.duration = this.durationFrom(timer.startTime, currentTime)
      timer.startTime = currentTime
    })
  }

  static async handleAllTimersResume() {
    let currentTime = await systemUptime.getRealTime(false)
    Object.keys(this.timers).forEach(timerId => {
      let timer = this.timers[timerId]
      if (timer.isPaused()) {
        return
      }
      timer.startTime = currentTime
    })
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