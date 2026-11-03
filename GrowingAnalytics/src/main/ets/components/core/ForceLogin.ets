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

export default class ForceLogin {
  private static identifiedDeviceId: string = ''
  private static unlocked: boolean = false

  static init() {
    ForceLogin.identifiedDeviceId = SharedPreferences.getValue(PREFERENCE_IDENTIFY_DEVICE_ID, '') as string
    ForceLogin.unlocked = false
  }

  static identify(deviceId: string, context: GrowingContext | undefined): boolean {
    if (!context || context.config.mode != ConfigMode.NewSaaS || !context.config.forceLogin || ForceLogin.unlocked) {
      LogUtil.info(() => 'Failed to identify, only available once when NewSaaS forceLogin is enabled')
      return false
    }
    if (!deviceId) {
      LogUtil.info(() => 'Failed to identify, deviceId is empty')
      return false
    }

    let identifiedDeviceId = deviceId.trim()
    if (identifiedDeviceId.length == 0 || identifiedDeviceId.length > 1000) {
      LogUtil.info(() => 'Failed to identify, deviceId must contain 1 to 1000 non-whitespace characters')
      return false
    }

    ForceLogin.identifiedDeviceId = identifiedDeviceId
    ForceLogin.unlocked = true
    SharedPreferences.put(PREFERENCE_IDENTIFY_DEVICE_ID, identifiedDeviceId)
    LogUtil.info(() => 'Identify deviceId for all NewSaaS trackers')
    return true
  }

  static canSend(context: GrowingContext): boolean {
    return context.config.mode != ConfigMode.NewSaaS || !context.config.forceLogin || ForceLogin.unlocked
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
