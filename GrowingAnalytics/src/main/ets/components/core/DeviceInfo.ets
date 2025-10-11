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

import deviceInfo from '@ohos.deviceInfo'
import display from '@ohos.display'
import I18n from '@ohos.i18n'
import connection from '@ohos.net.connection'
import util from '@ohos.util'
// import radio from '@ohos.telephony.radio'

import { PREFERENCE_DEVICE_ID } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'
import { niceTry } from '../utils/Util'

export const SDK_PLATFORM: string = 'HarmonyOS'

export default class DeviceInfo {
  static deviceId: string = ''
  static platform: string = ''
  static platformVersion: string = ''
  static screenHeight: number = 0
  static screenWidth: number = 0
  static orientation: string = 'PORTRAIT'
  static deviceBrand: string = ''
  static deviceModel: string = ''
  static deviceType: string = ''
  static language: string = ''
  static timezoneOffset: string = ''
  static networkState: string = ''
  static netConnection = connection.createNetConnection()

  static initDeviceInfo() {
    DeviceInfo.platform = SDK_PLATFORM
    DeviceInfo.platformVersion = deviceInfo.displayVersion

    let displayInfo = niceTry(() => display.getDefaultDisplaySync())
    if (displayInfo) {
      DeviceInfo.screenHeight = displayInfo.height
      DeviceInfo.screenWidth = displayInfo.width
      if (displayInfo.orientation != undefined) {
        let isPortrait = displayInfo.orientation == 0 || displayInfo.orientation == 2
        DeviceInfo.orientation = isPortrait ? 'PORTRAIT' : 'LANDSCAPE'
      }
    }

    DeviceInfo.deviceBrand = deviceInfo.brand
    DeviceInfo.deviceModel = deviceInfo.productModel
    DeviceInfo.deviceType = deviceInfo.deviceType
    DeviceInfo.language = I18n.System.getSystemLanguage()
    DeviceInfo.timezoneOffset = new Date().getTimezoneOffset() + ''

    DeviceInfo.networkState = 'UNKNOWN'
    DeviceInfo.netConnection.register((e) => {
      if (e) {
        LogUtil.info(() => 'NetCapability listener register failed.')
        DeviceInfo.networkState = 'WIFI'
      }
    })
    DeviceInfo.netConnection.on("netLost", (data) => {
      LogUtil.info(() => 'NetCapability change to NotReachable')
      DeviceInfo.networkState = 'UNKNOWN'
    })
    DeviceInfo.netConnection.on("netUnavailable", (data) => {
      LogUtil.info(() => 'NetCapability change to NotReachable')
      DeviceInfo.networkState = 'UNKNOWN'
    })
    DeviceInfo.netConnection.on("netCapabilitiesChange", (data) => {
      if (!data.netCap) {
        return
      }
      if (!data.netCap.bearerTypes) {
        return
      }
      if (data.netCap.bearerTypes.length == 0) {
        return
      }
      if (data.netCap.bearerTypes[0] == connection.NetBearType.BEARER_CELLULAR) {
        LogUtil.info(() => 'NetCapability change to 5G')
        DeviceInfo.networkState = '5G'
        // radio.getPrimarySlotId().then((slotId) => {
        //   let infos: Array<radio.SignalInformation> = radio.getSignalInformationSync(slotId)
        //   if (infos.length > 0) {
        //     let signalInfo = infos[0]
        //     let networkType = signalInfo.signalType
        //     if (networkType == radio.NetworkType.NETWORK_TYPE_UNKNOWN) {
        //       DeviceInfo.networkState = 'UNKNOWN'
        //     } else if (networkType == radio.NetworkType.NETWORK_TYPE_GSM ||
        //       networkType == radio.NetworkType.NETWORK_TYPE_CDMA) {
        //       DeviceInfo.networkState = '2G'
        //     } else if (networkType == radio.NetworkType.NETWORK_TYPE_WCDMA ||
        //       networkType == radio.NetworkType.NETWORK_TYPE_TDSCDMA) {
        //       DeviceInfo.networkState = '3G'
        //     } else if (networkType == radio.NetworkType.NETWORK_TYPE_LTE) {
        //       DeviceInfo.networkState = '4G'
        //     } else if (networkType == radio.NetworkType.NETWORK_TYPE_NR) {
        //       DeviceInfo.networkState = '5G'
        //     }
        //   }
        // })
      } else if (data.netCap.bearerTypes[0] == connection.NetBearType.BEARER_WIFI) {
        LogUtil.info(() => 'NetCapability change to WiFi')
        DeviceInfo.networkState = 'WIFI'
      } else if (data.netCap.bearerTypes[0] == connection.NetBearType.BEARER_ETHERNET) {
        LogUtil.info(() => 'NetCapability change to Ethernet')
        DeviceInfo.networkState = 'WIFI' //Ethernet
      }
    })

    let deviceId = SharedPreferences.getValue(PREFERENCE_DEVICE_ID) as string
    LogUtil.info(() => 'DeviceId from preferences is ' + deviceId)
    if (deviceId == '') {
      deviceId = util.generateRandomUUID(false)
      SharedPreferences.put(PREFERENCE_DEVICE_ID, deviceId)
    }
    DeviceInfo.deviceId = deviceId
  }
}