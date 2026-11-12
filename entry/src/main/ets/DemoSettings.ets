import preferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'

const DEMO_PREFERENCES_NAME = 'growingio_demo_settings'
const KEY_FORCE_LOGIN = 'forceLogin'

// Demo 本地开关：forceLogin 只能在初始化时配置，因此在下次启动时读取生效
export default class DemoSettings {
  static isForceLoginEnabled(context: common.Context): boolean {
    try {
      let store = preferences.getPreferencesSync(context, { name: DEMO_PREFERENCES_NAME })
      return store.getSync(KEY_FORCE_LOGIN, false) as boolean
    } catch {
      return false
    }
  }

  static setForceLoginEnabled(context: common.Context, enabled: boolean) {
    try {
      let store = preferences.getPreferencesSync(context, { name: DEMO_PREFERENCES_NAME })
      store.putSync(KEY_FORCE_LOGIN, enabled)
      store.flush()
    } catch {
    }
  }
}
