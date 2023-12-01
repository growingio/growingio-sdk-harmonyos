import preferences from '@ohos.data.preferences'
import { PREFERENCE_NAME } from './Constants'
import { LogUtil } from './LogUtil'

export default class SharedPreferences {
  private preferences: preferences.Preferences = null
  private context: Context

  constructor(context: Context) {
    this.context = context
  }

  async getPreferences() {
    if (this.preferences) {
      return
    }

    try {
      let promise = preferences.getPreferences(this.context, PREFERENCE_NAME)
      await promise.then((p) => {
        this.preferences = p
      }).catch ((e) => {
        LogUtil.error("Failed to get preferences. code =" + e.code + ", message =" + e.message)
      })
    } catch (e) {
      LogUtil.error("Failed to get preferences. code =" + e.code + ", message =" + e.message)
    }
  }

  async put(value: preferences.ValueType, key: string) {
    await this.getPreferences()
    await this.preferences.put(key, value)
    await this.preferences.flush()
  }

  async getValue(key: string): Promise<preferences.ValueType> {
    await this.getPreferences()
    let value: preferences.ValueType
    try {
      let result = await this.preferences.get(key, '')
      value = result as preferences.ValueType
    } catch (e) {
      LogUtil.error("Failed to get value of " + key + ". code =" + e.code + ", message =" + e.message)
    }
    return value
  }
}