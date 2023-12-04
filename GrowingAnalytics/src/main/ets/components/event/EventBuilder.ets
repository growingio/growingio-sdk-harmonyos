import Event from './Event'
import AnalyticsCore from '../core/AnalyticsCore'
import AppInfo from '../core/AppInfo'
import DeviceInfo from '../core/DeviceInfo'
import Session, { SessionState } from '../core/Session'
import UserIdentifier from '../core/UserIdentifier'
import { SDK_VERSION, PREFERENCE_EVENT_SEQUENCE_ID } from '../utils/Constants'
import SharedPreferences from '../utils/SharedPreferences'

export default class EventBuilder {
  static async build<T extends Event>(event: T): Promise<T> {
    event.sessionId = Session.sessionId
    event.appState = Session.sessionState === SessionState.Foreground ? 'FOREGROUND' : 'BACKGROUND'
    event.eventSequenceId = await EventBuilder.updateEventSequenceId()
    event.networkState = 'WiFi' // TODO
    event.timestamp = Date.now()
    event.sdkVersion = SDK_VERSION

    let deviceInfo = await DeviceInfo.sharedInstance()
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

    let appInfo = await AppInfo.sharedInstance()
    event.domain = appInfo.domain
    event.appChannel = appInfo.appChannel
    event.appName = appInfo.appName
    event.appVersion = appInfo.appVersion

    let core = AnalyticsCore.core
    event.dataSourceId = core.config.dataSourceId
    event.urlScheme = core.config.urlScheme
    event.latitude = Math.abs(core.location.latitude) > 0 ? core.location.latitude : undefined
    event.longitude = Math.abs(core.location.longitude) > 0 ? core.location.longitude : undefined

    let userIdentifier = await UserIdentifier.sharedInstance()
    let userId = userIdentifier.curUserId
    event.userId = userId.length > 0 ? userId : undefined
    let userKey = userIdentifier.curUserKey
    event.userKey = userKey.length > 0 ? userKey : undefined

    return event
  }

  static async updateEventSequenceId(): Promise<number> {
    let se = await SharedPreferences.getValue(PREFERENCE_EVENT_SEQUENCE_ID) as number
    if (!se || se == 0 || se == NaN) {
      se = 0
    }
    SharedPreferences.put(PREFERENCE_EVENT_SEQUENCE_ID, se + 1)
    return se
  }
}