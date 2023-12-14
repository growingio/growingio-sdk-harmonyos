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
import util from '@ohos.util'

import { PREFERENCE_DEVICE_ID } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'

export default class DeviceInfo {
  static deviceId: string = ''
  static platform: string = ''
  static platformVersion: string = ''
  static screenHeight: number = 0
  static screenWidth: number = 0
  static deviceBrand: string = ''
  static deviceModel: string = ''
  static deviceType: string = ''
  static language: string = ''
  static timezoneOffset: string = ''
  static networkState: string = ''

  static async initDeviceInfo() {
    DeviceInfo.platform = 'HarmonyOS'
    DeviceInfo.platformVersion = deviceInfo.displayVersion

    let displayInfo = display.getDefaultDisplaySync()
    DeviceInfo.screenHeight = displayInfo.height
    DeviceInfo.screenWidth = displayInfo.width

    DeviceInfo.deviceBrand = deviceInfo.brand
    DeviceInfo.deviceModel = deviceInfo.productModel
    DeviceInfo.deviceType = deviceInfo.deviceType
    DeviceInfo.language = I18n.System.getSystemLanguage()
    DeviceInfo.timezoneOffset = new Date().getTimezoneOffset() + ''
    DeviceInfo.networkState = 'WIFI' //TODO

    let deviceId = await SharedPreferences.getValue(PREFERENCE_DEVICE_ID) as string
    LogUtil.info('DeviceId from preferences is ' + deviceId)
    if (deviceId == '') {
      deviceId = util.generateRandomUUID(false)
      await SharedPreferences.put(PREFERENCE_DEVICE_ID, deviceId)
    }
    DeviceInfo.deviceId = deviceId
  }
}