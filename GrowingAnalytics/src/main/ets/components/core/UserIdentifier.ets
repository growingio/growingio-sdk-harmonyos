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
import Util from '../utils/Util'

export default class UserIdentifier {
  static curUserId: string
  static curUserKey: string
  private static latestNonnullUserId: string

  static async initUser() {
    let userInfoString = await SharedPreferences.getValue(PREFERENCE_USER_IDENTIFIER, '{}') as string
    let userInfo = JSON.parse(userInfoString) as object
    UserIdentifier.curUserId = userInfo[PREFERENCE_USER_ID] ?? ''
    UserIdentifier.curUserKey = userInfo[PREFERENCE_USER_KEY] ?? ''
    UserIdentifier.latestNonnullUserId = UserIdentifier.curUserId
    LogUtil.info('UserId from preferences is ' + UserIdentifier.curUserId + ', userKey from preferences is ' + UserIdentifier.curUserKey)
  }

  static setLoginUserId(userId: string, userKey: string = '') {
    let core = AnalyticsCore.core as AnalyticsCore
    if (core.config.idMappingEnabled == false) {
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
      UserIdentifier.curUserId = ''
      UserIdentifier.curUserKey = ''
      UserIdentifier.saveToPreferences()
      return
    }
    if (userId === UserIdentifier.curUserId && userKey === UserIdentifier.curUserKey) {
      return
    }

    LogUtil.info('LoginUserId did changed, userId from '
    + ((UserIdentifier.curUserId == null || UserIdentifier.curUserId.length == 0) ? 'undefined' : UserIdentifier.curUserId)
    + ' to ' + userId + ', userKey from '
    + ((UserIdentifier.curUserKey == null || UserIdentifier.curUserKey.length == 0) ? 'undefined' : UserIdentifier.curUserKey)
    + ' to ' + userKey)

    UserIdentifier.curUserId = userId
    UserIdentifier.curUserKey = userKey
    UserIdentifier.saveToPreferences()
    UserIdentifier.userIdDidChanged(userId)
  }

  static saveToPreferences() {
    let u = new Map<string, string>()
    u.set(PREFERENCE_USER_ID, String(UserIdentifier.curUserId))
    u.set(PREFERENCE_USER_KEY, String(UserIdentifier.curUserKey))
    SharedPreferences.put(PREFERENCE_USER_IDENTIFIER, JSON.stringify(Util.mapToObject(u)))
  }

  static userIdDidChanged(userId: string) {
    let oldUserId = UserIdentifier.latestNonnullUserId
    UserIdentifier.latestNonnullUserId = userId
    // A=>B
    if (oldUserId && oldUserId.length > 0 && oldUserId != userId) {
      Session.refreshSession()
    }
  }
}