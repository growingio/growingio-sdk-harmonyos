import { GrowingAnalytics } from '../interfaces/GrowingAnalytics'
import systemUptime from '@ohos.systemDateTime'
import util from '@ohos.util'
import { AttributesType, Event_DURATION } from '../utils/Constants'
import CustomEvent from '../event/CustomEvent'
import EventSender from '../event/EventSender'

export default class EventTimer {
  static timers: { string: EventTimer }

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
    var config = GrowingAnalytics.core.config
    if (!config.dataCollectionEnabled) {
      return
    }

    var currentTime = await systemUptime.getRealTime(false)
    var timer = new EventTimer(eventName, currentTime, 0)
    var timerId = eventName + util.generateRandomUUID(false)

    this.timers[timerId] = timer
    return timerId
  }

  static async trackTimerPause(timerId: string) {
    var currentTime = await systemUptime.getRealTime(false)
    var timer = this.timers[timerId]
    if (!timer || timer.isPaused()) {
      return
    }
    timer.duration = this.durationFrom(timer.startTime, currentTime)
    timer.startTime = 0
  }

  static async trackTimerResume(timerId: string) {
    var currentTime = await systemUptime.getRealTime(false)
    var timer = this.timers[timerId]
    if (!timer || !timer.isPaused()) {
      return
    }
    timer.startTime = currentTime
  }

  static async trackTimerEnd(timerId: string, attributes: AttributesType = {}) {
    var currentTime = await systemUptime.getRealTime(false)
    var timer = this.timers[timerId]
    if (!timer) {
      return
    }
    var eventName = timer.eventName
    var duration = this.durationFrom(timer.startTime, currentTime) + timer.duration
    attributes[Event_DURATION] = (duration / 1000.0).toFixed(3) + ''
    var e = await CustomEvent.create(eventName, attributes)
    EventSender.sendEvent(e)
    delete this.timers[timerId]
  }

  static removeTimer(timerId: string) {
    delete this.timers[timerId]
  }

  static clearAllTimers() {
    this.timers = {} as { string: EventTimer }
  }

  static async handleAllTimersPause() {
    var currentTime = await systemUptime.getRealTime(false)
    Object.keys(this.timers).forEach(timerId => {
      var timer = this.timers[timerId]
      if (timer.isPaused()) {
        return
      }
      timer.duration = this.durationFrom(timer.startTime, currentTime)
      timer.startTime = currentTime
    })
  }

  static async handleAllTimersResume() {
    var currentTime = await systemUptime.getRealTime(false)
    Object.keys(this.timers).forEach(timerId => {
      var timer = this.timers[timerId]
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
    var duration = endTime - startTime
    return (duration > 0 && duration < 24 * 60 * 60 * 1000) ? duration : 0
  }
}