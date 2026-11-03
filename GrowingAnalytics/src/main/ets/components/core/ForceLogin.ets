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
  private static identifiedUserId: string = ''
  private static unlocked: boolean = false

  static init() {
    ForceLogin.identifiedUserId = SharedPreferences.getValue(PREFERENCE_IDENTIFY_DEVICE_ID, '') as string
    ForceLogin.unlocked = false
  }

  static identify(userId: string, context: GrowingContext | undefined): boolean {
    if (!context || context.config.mode != ConfigMode.NewSaaS || !context.config.forceLogin || ForceLogin.unlocked) {
      LogUtil.info(() => 'Failed to identify, only available once when NewSaaS forceLogin is enabled')
      return false
    }
    if (!userId) {
      LogUtil.info(() => 'Failed to identify, userId is empty')
      return false
    }

    let identifiedUserId = userId.trim()
    if (identifiedUserId.length == 0 || identifiedUserId.length > 1000) {
      LogUtil.info(() => 'Failed to identify, userId must contain 1 to 1000 non-whitespace characters')
      return false
    }

    ForceLogin.identifiedUserId = identifiedUserId
    ForceLogin.unlocked = true
    SharedPreferences.put(PREFERENCE_IDENTIFY_DEVICE_ID, identifiedUserId)
    LogUtil.info(() => 'Identify deviceId for all NewSaaS trackers')
    return true
  }

  static canSend(context: GrowingContext): boolean {
    return context.config.mode != ConfigMode.NewSaaS || !context.config.forceLogin || ForceLogin.unlocked
  }

  static getDeviceId(context: GrowingContext, generatedDeviceId: string): string {
    if (context.config.mode == ConfigMode.NewSaaS && ForceLogin.identifiedUserId.length > 0) {
      return ForceLogin.identifiedUserId
    }
    return generatedDeviceId
  }

  static getOverrideDeviceId(context: GrowingContext): string {
    if (context.config.mode == ConfigMode.NewSaaS) {
      return ForceLogin.identifiedUserId
    }
    return ''
  }

  static _reset() {
    ForceLogin.identifiedUserId = ''
    ForceLogin.unlocked = false
  }
}
