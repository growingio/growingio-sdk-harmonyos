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

import preferences from '@ohos.data.preferences'

import { PREFERENCE_NAME } from './Constants'
import { LogUtil } from './LogUtil'

export default class SharedPreferences {
  private static preferences: preferences.Preferences

  static async initWithContext(context: Context) {
    let appContext = context.getApplicationContext()
    try {
      SharedPreferences.preferences = await preferences.getPreferences(appContext, PREFERENCE_NAME)
    } catch (e) {
      LogUtil.error("Failed to get preferences. code = " + e.code + ", message = " + e.message)
    }
  }

  static async put(key: string, value: preferences.ValueType) {
    if (!SharedPreferences.preferences) {
      return
    }
    await SharedPreferences.preferences.put(key, value)
    await SharedPreferences.preferences.flush()
  }

  static async getValue(key: string, defValue: preferences.ValueType = ''): Promise<preferences.ValueType> {
    let value: preferences.ValueType = defValue
    if (!SharedPreferences.preferences) {
      return value
    }
    try {
      let result = await SharedPreferences.preferences.get(key, defValue)
      value = result as preferences.ValueType
    } catch (e) {
      LogUtil.error("Failed to get value of " + key + ". code = " + e.code + ", message = " + e.message)
    }
    return value
  }
}