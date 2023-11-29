import { GrowingAnalytics } from '../interfaces/GrowingAnalytics'
import { PREFERENCE_USER_ID, PREFERENCE_USER_KEY } from '../utils/Constants'

export default class UserIdentifier {
  curUserId: string = ''
  curUserKey: string = ''
  private latestNonnullUserId: string = ''

  static instance: UserIdentifier = null
  constructor() { }

  static sharedInstance(): UserIdentifier {
    if (this.instance == null) {
      this.instance = new UserIdentifier()
    }
    return this.instance
  }

  async userId(): Promise<string> {
    return GrowingAnalytics.core.preferences.getValue(PREFERENCE_USER_ID) as Promise<string>
  }

  async userKey(): Promise<string> {
    return GrowingAnalytics.core.preferences.getValue(PREFERENCE_USER_KEY) as Promise<string>
  }

  setLoginUserId(userId: string, userKey: string) {
    if (userId && userId.length > 1000) {
      return
    }
    if (userKey && userKey.length > 1000) {
      return
    }
    if (userId == null || userId.length == 0) {
      this.curUserId = null
      this.curUserKey = null
      GrowingAnalytics.core.preferences.put('', PREFERENCE_USER_ID)
      GrowingAnalytics.core.preferences.put('', PREFERENCE_USER_KEY)
      return
    }
    if (userId === this.curUserId && userKey === this.curUserKey) {
      return
    }
    this.curUserId = userId
    this.curUserKey = userKey
    GrowingAnalytics.core.preferences.put(userId, PREFERENCE_USER_ID)
    GrowingAnalytics.core.preferences.put(userKey, PREFERENCE_USER_KEY)

    this.userIdDidChanged(userId)
  }

  userIdDidChanged(userId: string) {
    if (userId == null || userId.length == 0) {
      return
    }
    var oldUserId = this.latestNonnullUserId
    this.latestNonnullUserId = userId

    if (oldUserId == null || oldUserId.length == 0) {
      return
    }
    // A=>B
    if (oldUserId != userId) {
      GrowingAnalytics.core.session.refreshSession()
      GrowingAnalytics.core.session.generateVisit()
    }
  }
}