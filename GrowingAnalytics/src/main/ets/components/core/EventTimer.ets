import systemUptime from '@ohos.systemDateTime'
import util from '@ohos.util'

import AnalyticsCore from './AnalyticsCore'
import CustomEvent from '../event/CustomEvent'
import EventSender from '../event/EventSender'
import { AttributesType, Event_DURATION } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'

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
    LogUtil.info('Track timer start, eventName: ' + eventName + ', timerId: ' + timerId)
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
    LogUtil.info('Track timer pause, timerId is ' + timerId)
  }

  static async trackTimerResume(timerId: string) {
    let currentTime = await systemUptime.getRealTime(false)
    let timer = this.timers[timerId]
    if (!timer || !timer.isPaused()) {
      return
    }
    timer.startTime = currentTime
    LogUtil.info('Track timer resume, timerId is ' + timerId)
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
    let e = CustomEvent.create(eventName, attributes)
    EventSender.sendEvent(e)
    delete this.timers[timerId]
    LogUtil.info('Track timer end, eventName: ' + eventName + ', timerId: ' + timerId + ', attributes: '
    + JSON.stringify(attributes))
  }

  static removeTimer(timerId: string) {
    LogUtil.info('Track timer remove, timerId is ' + timerId)
    delete this.timers[timerId]
  }

  static clearTrackTimer() {
    LogUtil.info('Track timer all delete')
    this.timers = {}
  }

  static async handleAllTimersPause() {
    LogUtil.info('Track timer all pause with appState is background')
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
    LogUtil.info('Track timer all resume with appState is foreground')
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