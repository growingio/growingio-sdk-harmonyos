import deviceInfo from '@ohos.deviceInfo'
import display from '@ohos.display'
import I18n from '@ohos.i18n'
import util from '@ohos.util'
import { GrowingAnalytics } from '../interfaces/GrowingAnalytics'
import { PREFERENCE_DEVICE_ID } from '../utils/Constants'

export default class DeviceInfo {
  deviceId: string = ''
  platform: string = ''
  platformVersion: string = ''
  screenHeight: number = 0
  screenWidth: number = 0
  deviceBrand: string = ''
  deviceModel: string = ''
  deviceType: string = ''
  language: string = ''
  timezoneOffset: string = ''

  static instance: DeviceInfo = null

  constructor() {
  }

  static sharedInstance(): DeviceInfo {
    if (this.instance == null) {
      this.instance = new DeviceInfo()
      this.instance.initDeviceInfo()
    }
    return this.instance
  }

  async initDeviceInfo() {
    this.platform = 'HarmonyOS'
    this.platformVersion = deviceInfo.displayVersion

    var displayInfo = display.getDefaultDisplaySync()
    this.screenHeight = displayInfo.height
    this.screenWidth = displayInfo.width

    this.deviceBrand = deviceInfo.brand
    this.deviceModel = deviceInfo.productModel
    this.deviceType = deviceInfo.deviceType
    this.language = I18n.System.getSystemLanguage()
    this.timezoneOffset = new Date().getTimezoneOffset() + ''

    var deviceId = await GrowingAnalytics.core.preferences.getValue(PREFERENCE_DEVICE_ID) as string
    if (deviceId == '') {
      let uuid = util.generateRandomUUID(false)
      GrowingAnalytics.core.preferences.put(PREFERENCE_DEVICE_ID, uuid)
      deviceId = uuid
    }
    this.deviceId = deviceId
  }
}