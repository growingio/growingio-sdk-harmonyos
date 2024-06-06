import { GrowingAnalyticsInterface } from '../interfaces/GrowingAnalytics'
import { AttributesType, JavaScriptProxyType } from '../utils/Constants'
import webview from '@ohos.web.webview'

export default class DummyTracker implements GrowingAnalyticsInterface {
  constructor() {}

  // Sub tracker (GrowingAnalyticsInterface)
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

  // Main tracker only
  createHybridProxy(controller: webview.WebviewController): JavaScriptProxyType | undefined {
    return undefined
  }
  getDeviceId(): string { return '' }
}