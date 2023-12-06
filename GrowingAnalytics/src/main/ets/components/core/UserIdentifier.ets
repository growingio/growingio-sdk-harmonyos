import AnalyticsCore from './AnalyticsCore'
import Session from './Session'
import { PREFERENCE_USER_ID, PREFERENCE_USER_KEY } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'

export default class UserIdentifier {
  static curUserId: string
  static curUserKey: string
  private static latestNonnullUserId: string

  static async initUser() {
    this.curUserId = await SharedPreferences.getValue(PREFERENCE_USER_ID) as string
    this.curUserKey = await SharedPreferences.getValue(PREFERENCE_USER_KEY) as string
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

  static userIdDidChanged(userId: string) {
    let oldUserId = this.latestNonnullUserId
    this.latestNonnullUserId = userId
    // A=>B
    if (oldUserId.length > 0 && oldUserId != userId) {
      Session.refreshSession()
    }
  }
}