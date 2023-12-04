import AnalyticsCore from './AnalyticsCore'
import Session from './Session'
import { PREFERENCE_USER_ID, PREFERENCE_USER_KEY } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'

export default class UserIdentifier {
  curUserId: string
  curUserKey: string
  private latestNonnullUserId: string

  static instance: UserIdentifier = null
  constructor(
    curUserId: string,
    curUserKey: string,
  ) {
    this.curUserId = curUserId
    this.curUserKey = curUserKey
    this.latestNonnullUserId = curUserId
  }

  static async sharedInstance(): Promise<UserIdentifier> {
    if (this.instance == null) {
      let curUserId = await this.getUserId()
      let curUserKey = await this.getUserKey()
      LogUtil.info('UserId from preferences is ' + curUserId + ', userKey from preferences is ' + curUserKey)
      this.instance = new UserIdentifier(curUserId, curUserKey)
    }
    return this.instance
  }

  static async getUserId(): Promise<string> {
    return SharedPreferences.getValue(PREFERENCE_USER_ID) as Promise<string>
  }

  static async getUserKey(): Promise<string> {
    return SharedPreferences.getValue(PREFERENCE_USER_KEY) as Promise<string>
  }

  setLoginUserId(userId: string, userKey: string = '') {
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
      SharedPreferences.put(PREFERENCE_USER_ID, '')
      SharedPreferences.put(PREFERENCE_USER_KEY, '')
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
    SharedPreferences.put(PREFERENCE_USER_ID, userId)
    SharedPreferences.put(PREFERENCE_USER_KEY, userKey)

    this.userIdDidChanged(userId)
  }

  userIdDidChanged(userId: string) {
    let oldUserId = this.latestNonnullUserId
    if (oldUserId.length == 0) {
      return
    }
    this.latestNonnullUserId = userId

    // A=>B
    if (oldUserId != userId) {
      Session.refreshSession()
    }
  }
}