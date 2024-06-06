import { GrowingAnalyticsInterface } from '../interfaces/GrowingAnalytics'
import { AttributesType } from '../utils/Constants'

export default class DummyTracker implements GrowingAnalyticsInterface {
  constructor() {}

  isInitializedSuccessfully(): boolean { return false }
  setDataCollectionEnabled(enabled: boolean): void {}
  setLoginUserId(userId: string, userKey?: string): void {}
  cleanLoginUserId(): void {}

  setLoginUserAttributes(attributes: AttributesType): void {}
  track(eventName: string, attributes: AttributesType, sendTo?: string[]): void {}
  trackTimerStart(eventName: string): Promise<string> { return Promise.resolve('') }
  trackTimerPause(timerId: string): void {}
  trackTimerResume(timerId: string): void {}
  trackTimerEnd(timerId: string, attributes: AttributesType, sendTo?: string[]): void {}
  removeTimer(timerId: string): void {}
  clearTrackTimer(): void {}
}