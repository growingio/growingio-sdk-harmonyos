/**
 * @license
 * Copyright (C) 2026 Beijing Yishu Technology Co., Ltd.
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

// @doc-impl UserIdentifier.md

import GrowingContext from './Context'
import { ConfigMode } from '../interfaces/GrowingConfig'
import { PREFERENCE_IDENTIFY_DEVICE_ID } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'

// 与 Web SDK identify 一致：超出部分截断而非拒绝
const IDENTIFY_DEVICE_ID_MAX_LENGTH = 1000

export default class ForceLogin {
  private static identifiedDeviceId: string = ''
  private static unlocked: boolean = false

  static init() {
    ForceLogin.identifiedDeviceId = SharedPreferences.getValue(PREFERENCE_IDENTIFY_DEVICE_ID, '') as string
    ForceLogin.unlocked = false
  }

  /**
   * 强制登录是否生效
   *
   * 与 Web SDK 一致，仅由主 Tracker 配置决定：主 Tracker 为 NewSaaS 且开启 forceLogin 时，
   * 所有 NewSaaS Tracker（含子 Tracker）统一阻塞并由主入口 identify 统一解锁；子 Tracker 自身的 forceLogin 不生效。
   */
  static isEnabled(): boolean {
    let main = GrowingContext.getDefaultContext()
    return main != undefined && main.config.mode == ConfigMode.NewSaaS && main.config.forceLogin
  }

  static identify(deviceId: string, context: GrowingContext | undefined): boolean {
    if (!context || context.config.mode != ConfigMode.NewSaaS || !context.config.forceLogin || ForceLogin.unlocked) {
      LogUtil.info(() => 'Failed to identify, only available once when NewSaaS forceLogin is enabled')
      return false
    }
    // 与 Web SDK 校验规则一致：非空字符串即有效，不去除首尾空白，超过 1000 字符截断
    if (!deviceId || deviceId.length == 0) {
      LogUtil.info(() => 'Failed to identify, deviceId is empty')
      return false
    }

    let identifiedDeviceId = deviceId.slice(0, IDENTIFY_DEVICE_ID_MAX_LENGTH)
    ForceLogin.identifiedDeviceId = identifiedDeviceId
    ForceLogin.unlocked = true
    SharedPreferences.put(PREFERENCE_IDENTIFY_DEVICE_ID, identifiedDeviceId)
    LogUtil.info(() => 'Identify deviceId for all NewSaaS trackers')
    return true
  }

  static canSend(context: GrowingContext): boolean {
    return context.config.mode != ConfigMode.NewSaaS || !ForceLogin.isEnabled() || ForceLogin.unlocked
  }

  static getDeviceId(context: GrowingContext, generatedDeviceId: string): string {
    if (context.config.mode == ConfigMode.NewSaaS && ForceLogin.identifiedDeviceId.length > 0) {
      return ForceLogin.identifiedDeviceId
    }
    return generatedDeviceId
  }

  static getOverrideDeviceId(context: GrowingContext): string {
    if (context.config.mode == ConfigMode.NewSaaS) {
      return ForceLogin.identifiedDeviceId
    }
    return ''
  }

  static _reset() {
    ForceLogin.identifiedDeviceId = ''
    ForceLogin.unlocked = false
  }
}
