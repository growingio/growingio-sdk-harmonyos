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

import collections from '@arkts.collections'
import ArkTSUtils from '@arkts.utils'

import Session from './Session'
import { PREFERENCE_USER_ID, PREFERENCE_USER_IDENTIFIER, PREFERENCE_USER_KEY } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'
import GrowingContext from './Context'
import { ConfigMode } from '../interfaces/GrowingConfig'

"use shared"

@Sendable
export default class UserIdentifier {
  userId: string
  userKey: string
  private latestNonnullUserId: string
  static users: collections.Map<string, UserIdentifier> = new collections.Map()
  static userInfo: collections.Map<string, string> = new collections.Map()

  constructor(
    userId: string,
    userKey: string,
  ) {
    this.userId = userId
    this.userKey = userKey
    this.latestNonnullUserId = userId
  }

  static initUser(context: GrowingContext) {
    let userInfoString = SharedPreferences.getValue(PREFERENCE_USER_IDENTIFIER, '{}') as string
    let options: ArkTSUtils.ASON.ParseOptions = {
      bigIntMode: ArkTSUtils.ASON.BigIntMode.PARSE_AS_BIGINT,
      parseReturnType: ArkTSUtils.ASON.ParseReturnType.MAP,
    }
    let userInfo = (ArkTSUtils.ASON.parse(userInfoString, undefined, options) ?? new collections.Map()) as collections.Map<string, string>
    UserIdentifier.userInfo = userInfo

    let userId = (userInfo.get(PREFERENCE_USER_ID) as string | undefined) ?? ''
    let userKey = (userInfo.get(PREFERENCE_USER_KEY) as string | undefined) ?? ''
    let user = new UserIdentifier(userId, userKey)
    UserIdentifier.users.set(context.trackerId, user)

    let message = 'UserId from preferences is ' + userId
    if (context.config.mode == ConfigMode.NewSaaS || context.config.mode == ConfigMode.CDP) {
      if (context.config.idMappingEnabled == true) {
        message += ', userKey from preferences is ' + userKey
      }
    }
    LogUtil.info(() => message)
  }

  static initMultiUser(context: GrowingContext) {
    let userInfo = UserIdentifier.userInfo

    let suffix = '_' + context.config.accountId + '_' + context.config.dataSourceId
    let userId = (userInfo.get(PREFERENCE_USER_ID + suffix) as string | undefined) ?? ''
    let userKey = (userInfo.get(PREFERENCE_USER_KEY + suffix) as string | undefined) ?? ''
    let user = new UserIdentifier(userId, userKey)
    UserIdentifier.users.set(context.trackerId, user)

    let message = 'UserId for ' + context.trackerId + ' from preferences is ' + userId
    if (context.config.mode == ConfigMode.NewSaaS || context.config.mode == ConfigMode.CDP) {
      if (context.config.idMappingEnabled == true) {
        message += ', userKey from preferences is ' + userKey
      }
    }
    LogUtil.info(() => message)
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
        LogUtil.info(() => 'Clear loginUserId')
        user.userId = ''
        user.userKey = ''
        user.saveToPreferences(context)
        return
      }
      if (userId === user.userId && userKey === user.userKey) {
        return
      }

      let message = 'LoginUserId for ' + context.trackerId + ' did changed, userId from '
        + ((user.userId == null || user.userId.length == 0) ? 'undefined' : user.userId)
        + ' to ' + userId
      if (context.config.mode == ConfigMode.NewSaaS || context.config.mode == ConfigMode.CDP) {
        if (context.config.idMappingEnabled == true) {
          message += ', userKey from '
            + ((user.userKey == null || user.userKey.length == 0) ? 'undefined' : user.userKey)
            + ' to ' + userKey
        }
      }
      LogUtil.info(() => message)

      user.userId = userId
      user.userKey = userKey
      user.saveToPreferences(context)
      user.userIdDidChanged(userId, context)
    }
  }

  saveToPreferences(context: GrowingContext) {
    let userInfo = UserIdentifier.userInfo
    if (GrowingContext.isDefaultContext(context)) {
      userInfo.set(PREFERENCE_USER_ID, String(this.userId))
      userInfo.set(PREFERENCE_USER_KEY, String(this.userKey))
    } else {
      let suffix = '_' + context.config.accountId + '_' + context.config.dataSourceId
      userInfo.set(PREFERENCE_USER_ID + suffix, String(this.userId))
      userInfo.set(PREFERENCE_USER_KEY + suffix, String(this.userKey))
    }
    SharedPreferences.put(PREFERENCE_USER_IDENTIFIER, JSON.stringify(userInfo))
  }

  userIdDidChanged(userId: string, context: GrowingContext) {
    let oldUserId = this.latestNonnullUserId
    this.latestNonnullUserId = userId
    // A=>B
    if (oldUserId && oldUserId.length > 0 && oldUserId != userId) {
      Session.refreshSession(context)
    } else if (context.config.mode == ConfigMode.CDP) {
      if (oldUserId == null || oldUserId.length == 0) {
        Session.generateVisit(context)
      }
    }
  }
}