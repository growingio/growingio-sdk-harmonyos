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

import Session from './Session'
import { PREFERENCE_USER_ID, PREFERENCE_USER_IDENTIFIER, PREFERENCE_USER_KEY } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'
import GrowingContext from './Context'

export default class UserIdentifier {
  userId: string
  userKey: string
  private latestNonnullUserId: string

  static users: Map<string, UserIdentifier> = new Map()
  static userInfo: object

  constructor(
    userId: string,
    userKey: string,
  ) {
    this.userId = userId
    this.userKey = userKey
    this.latestNonnullUserId = userId
  }

  static async initUser(context: GrowingContext) {
    let userInfoString = await SharedPreferences.getValue(PREFERENCE_USER_IDENTIFIER, '{}') as string
    let userInfo = JSON.parse(userInfoString) as object
    UserIdentifier.userInfo = userInfo

    let userId = (userInfo[PREFERENCE_USER_ID] as string | undefined) ?? ''
    let userKey = (userInfo[PREFERENCE_USER_KEY] as string | undefined) ?? ''
    let user = new UserIdentifier(userId, userKey)
    UserIdentifier.users.set(context.trackerId, user)
    LogUtil.info('UserId from preferences is ' + userId + ', userKey from preferences is ' + userKey)
  }

  static initMultiUser(context: GrowingContext) {
    let userInfo = UserIdentifier.userInfo

    let userId = (userInfo[PREFERENCE_USER_ID + '_' + context.trackerId] as string | undefined) ?? ''
    let userKey = (userInfo[PREFERENCE_USER_KEY + '_' + context.trackerId] as string | undefined) ?? ''
    let user = new UserIdentifier(userId, userKey)
    UserIdentifier.users.set(context.trackerId, user)
    LogUtil.info('UserId from preferences is ' + userId + ', userKey from preferences is ' + userKey)
  }

  static getUser(context: GrowingContext) {
    return UserIdentifier.users.get(context.trackerId)
  }

  static setLoginUserId(userId: string, userKey: string = '', context: GrowingContext) {
    if (context.config.idMappingEnabled == false) {
      userKey = ''
    }
    if (userId && userId.length > 1000) {
      return
    }
    if (userKey && userKey.length > 1000) {
      return
    }

    let user = UserIdentifier.users.get(context.trackerId)
    if (user) {
      if (userId == null || userId.length == 0) {
        LogUtil.info('Clear loginUserId')
        user.userId = ''
        user.userKey = ''
        user.saveToPreferences(context)
        return
      }
      if (userId === user.userId && userKey === user.userKey) {
        return
      }

      LogUtil.info('LoginUserId did changed, userId from '
      + ((user.userId == null || user.userId.length == 0) ? 'undefined' : user.userId)
      + ' to ' + userId + ', userKey from '
      + ((user.userKey == null || user.userKey.length == 0) ? 'undefined' : user.userKey)
      + ' to ' + userKey)

      user.userId = userId
      user.userKey = userKey
      user.saveToPreferences(context)
      user.userIdDidChanged(userId, context)
    }
  }

  async saveToPreferences(context: GrowingContext) {
    let userInfo = UserIdentifier.userInfo
    if (GrowingContext.isDefaultContext(context)) {
      userInfo[PREFERENCE_USER_ID] = String(this.userId)
      userInfo[PREFERENCE_USER_KEY] = String(this.userKey)
    } else {
      userInfo[PREFERENCE_USER_ID + '_' + context.trackerId] = String(this.userId)
      userInfo[PREFERENCE_USER_KEY + '_' + context.trackerId] = String(this.userKey)
    }
    SharedPreferences.put(PREFERENCE_USER_IDENTIFIER, JSON.stringify(userInfo))
  }

  userIdDidChanged(userId: string, context: GrowingContext) {
    let oldUserId = this.latestNonnullUserId
    this.latestNonnullUserId = userId
    // A=>B
    if (oldUserId && oldUserId.length > 0 && oldUserId != userId) {
      Session.refreshSession(context)
    }
  }
}