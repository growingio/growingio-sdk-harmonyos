import preferences from '@ohos.data.preferences'

import { PREFERENCE_NAME } from './Constants'
import { LogUtil } from './LogUtil'

export default class SharedPreferences {
  private static preferences: preferences.Preferences = null

  static async initWithContext(context: Context) {
    let appContext = context.getApplicationContext()
    try {
      let promise = preferences.getPreferences(appContext, PREFERENCE_NAME)
      await promise.then((p) => {
        this.preferences = p
      }).catch ((e) => {
        LogUtil.error("Failed to get preferences. code =" + e.code + ", message =" + e.message)
      })
    } catch (e) {
      LogUtil.error("Failed to get preferences. code =" + e.code + ", message =" + e.message)
    }
  }

  static async put(key: string, value: preferences.ValueType) {
    if (!this.preferences) {
      return
    }
    await this.preferences.put(key, value)
    await this.preferences.flush()
  }

  static async getValue(key: string, defValue: preferences.ValueType = ''): Promise<preferences.ValueType> {
    if (!this.preferences) {
      return null
    }
    let value: preferences.ValueType
    try {
      let result = await this.preferences.get(key, defValue)
      value = result as preferences.ValueType
    } catch (e) {
      LogUtil.error("Failed to get value of " + key + ". code =" + e.code + ", message =" + e.message)
    }
    return value
  }
}