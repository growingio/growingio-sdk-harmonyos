import Event from './Event'
import UserIdentifier from '../core/UserIdentifier'
import DeviceInfo from '../core/DeviceInfo'
import AppInfo from '../core/AppInfo'
import { SessionState } from '../core/Session'
import { GrowingAnalytics } from '../interfaces/GrowingAnalytics'
import { SDK_VERSION, PREFERENCE_EVENT_SEQUENCE_ID } from '../utils/Constants'

export default class EventBuilder {
  static async build<T extends Event>(event: T): Promise<T> {
    event.eventSequenceId = await EventBuilder.updateEventSequenceId()
    event.networkState = 'WiFi' // TODO
    event.timestamp = Date.now()
    event.sdkVersion = SDK_VERSION

    var deviceInfo = await DeviceInfo.sharedInstance()
    event.deviceId = deviceInfo.deviceId
    event.platform = deviceInfo.platform
    event.platformVersion = deviceInfo.platformVersion
    event.screenHeight = deviceInfo.screenHeight
    event.screenWidth = deviceInfo.screenWidth
    event.deviceBrand = deviceInfo.deviceBrand
    event.deviceModel = deviceInfo.deviceModel
    event.deviceType = deviceInfo.deviceType
    event.language = deviceInfo.language
    event.timezoneOffset = deviceInfo.timezoneOffset

    var appInfo = await AppInfo.sharedInstance()
    event.domain = appInfo.domain
    event.appChannel = appInfo.appChannel
    event.appName = appInfo.appName
    event.appVersion = appInfo.appVersion

    var core = GrowingAnalytics.core
    event.dataSourceId = core.config.dataSourceId
    event.urlScheme = core.config.urlScheme
    event.sessionId = core.session.sessionId
    event.appState = core.session.sessionState === SessionState.Foreground ? 'FOREGROUND' : 'BACKGROUND'
    event.latitude = Math.abs(core.location.latitude) > 0 ? core.location.latitude : undefined
    event.longitude = Math.abs(core.location.longitude) > 0 ? core.location.longitude : undefined

    var userIdentifier = UserIdentifier.sharedInstance()
    var userId = await userIdentifier.userId()
    event.userId = userId.length > 0 ? userId : undefined
    var userKey = await userIdentifier.userKey()
    event.userKey = userKey.length > 0 ? userKey : undefined

    return event
  }

  static async updateEventSequenceId(): Promise<number> {
    var se = await GrowingAnalytics.core.preferences.getValue(PREFERENCE_EVENT_SEQUENCE_ID) as number
    if (!se || se == 0 || se == NaN) {
      se = 0
    }
    GrowingAnalytics.core.preferences.put(se + 1, PREFERENCE_EVENT_SEQUENCE_ID)
    return se
  }
}