/**
 * @license
 * Copyright (C) 2024 Beijing Yishu Technology Co., Ltd.
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

import { GrowingAnalyticsInterface } from '../interfaces/GrowingAnalytics'
import { AttributesType, JavaScriptProxyType, SaaSJavaScriptConfigType } from '../utils/Constants'
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
  trackTimerStart(eventName: string): string { return '' }
  trackTimerPause(timerId: string): void {}
  trackTimerResume(timerId: string): void {}
  trackTimerEnd(timerId: string, attributes: AttributesType, sendTo?: string[]): void {}
  removeTimer(timerId: string): void {}
  clearTrackTimer(): void {}

  createHybridProxy(controller: webview.WebviewController): JavaScriptProxyType | undefined {
    return undefined
  }
  javaScriptOnDocumentStart(
    scriptRules?: Array<string>,
    saasJavaScriptConfig?: SaaSJavaScriptConfigType): Array<ScriptItem> {
    return []
  }
  javaScriptOnDocumentEnd(scriptRules?: Array<string>): Array<ScriptItem> {
    return []
  }

  // Main tracker only
  getDeviceId(): string { return '' }
}