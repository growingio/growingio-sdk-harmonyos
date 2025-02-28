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

import preferences from '@ohos.data.preferences'

import { PREFERENCE_NAME } from './Constants'
import { LogUtil } from './LogUtil'

export default class SharedPreferences {
  static shared: SharedPreferences
  preferences: preferences.Preferences

  constructor(preferences: preferences.Preferences) {
    this.preferences = preferences
  }

  static initWithContext(context: Context) {
    if (SharedPreferences.shared) {
      return
    }

    let appContext = context.getApplicationContext()
    try {
      let p = preferences.getPreferencesSync(appContext, { name: PREFERENCE_NAME })
      SharedPreferences.shared = new SharedPreferences(p)
    } catch (e) {
      LogUtil.error(() => "Failed to get preferences. code = " + e.code + ", message = " + e.message)
    }
  }

  async put(key: string, value: preferences.ValueType) {
    if (!this.preferences) {
      return
    }
    this.preferences.putSync(key, value)
    await this.preferences.flush()
  }

  getValue(key: string, defValue: preferences.ValueType = ''): preferences.ValueType {
    let value: preferences.ValueType = defValue
    if (!this.preferences) {
      return value
    }
    try {
      let result = this.preferences.getSync(key, defValue)
      value = result as preferences.ValueType
    } catch (e) {
      LogUtil.error(() => "Failed to get value of " + key + ". code = " + e.code + ", message = " + e.message)
    }
    return value
  }
}