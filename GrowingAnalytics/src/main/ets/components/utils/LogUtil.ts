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

export class LogUtil {
  static debugEnabled: boolean = false
  static logDebugger: ((type: string, message: string) => void) | undefined = undefined

  static info(message: () => string) {
    let m = '[GrowingAnalytics] ' + message()
    if (LogUtil.debugEnabled) {
      console.info(m)
    }
    if (LogUtil.logDebugger) {
      LogUtil.logDebugger('DEBUG', m)
    }
  }

  static error(message: () => string) {
    let m = '[GrowingAnalytics] ' + message()
    console.error(m)

    if (LogUtil.logDebugger) {
      LogUtil.logDebugger('ERROR', m)
    }
  }

  static warn(message: () => string) {
    let m = '[GrowingAnalytics] ' + message()
    console.warn(m)

    if (LogUtil.logDebugger) {
      LogUtil.logDebugger('WARN', m)
    }
  }
}