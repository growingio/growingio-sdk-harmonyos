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

import AnalyticsCore from './AnalyticsCore'
import Session from './Session'
import { PREFERENCE_USER_ID, PREFERENCE_USER_IDENTIFIER, PREFERENCE_USER_KEY } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'

export default class UserIdentifier {
  static curUserId: string
  static curUserKey: string
  private static latestNonnullUserId: string

  static async initUser() {
    let userInfoString = await SharedPreferences.getValue(PREFERENCE_USER_IDENTIFIER) as string
    let userInfo = JSON.parse(userInfoString)
    this.curUserId = userInfo[PREFERENCE_USER_ID]
    this.curUserKey = userInfo[PREFERENCE_USER_KEY]
    this.latestNonnullUserId = this.curUserId
    LogUtil.info('UserId from preferences is ' + this.curUserId + ', userKey from preferences is ' + this.curUserKey)
  }

  static setLoginUserId(userId: string, userKey: string = '') {
    if (AnalyticsCore.core.config.idMappingEnabled == false) {
      userKey = ''
    }
    if (userId && userId.length > 1000) {
      return
    }
    if (userKey && userKey.length > 1000) {
      return
    }
    if (userId == null || userId.length == 0) {
      LogUtil.info('Clear loginUserId')
      this.curUserId = ''
      this.curUserKey = ''
      this.saveToPreferences()
      return
    }
    if (userId === this.curUserId && userKey === this.curUserKey) {
      return
    }

    LogUtil.info('LoginUserId did changed, userId from '
    + ((this.curUserId == null || this.curUserId.length == 0) ? 'undefined' : this.curUserId) + ' to ' + userId
    + ', userKey from ' + ((this.curUserKey == null || this.curUserKey.length == 0) ? 'undefined' : this.curUserKey)
    + ' to ' + userKey)
    this.curUserId = userId
    this.curUserKey = userKey
    this.saveToPreferences()
    this.userIdDidChanged(userId)
  }

  static saveToPreferences() {
    let userIdentifier = {
      PREFERENCE_USER_ID: this.curUserId,
      PREFERENCE_USER_KEY: this.curUserKey
    }
    SharedPreferences.put(PREFERENCE_USER_IDENTIFIER, JSON.stringify(userIdentifier))
  }

  static userIdDidChanged(userId: string) {
    let oldUserId = this.latestNonnullUserId
    this.latestNonnullUserId = userId
    // A=>B
    if (oldUserId.length > 0 && oldUserId != userId) {
      Session.refreshSession()
    }
  }
}