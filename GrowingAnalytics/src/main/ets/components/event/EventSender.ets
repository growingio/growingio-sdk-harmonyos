import { LogUtil } from '../utils/LogUtil'
import Event from './Event'
import http from '@ohos.net.http'
import { GrowingAnalytics } from '../interfaces/GrowingAnalytics'

export default class EventSender {
  static sendEvent = <T extends Event>(
  event: T
  ) => {
    if (!GrowingAnalytics.core.config.dataCollectionEnabled) {
      return
    }

    if (!GrowingAnalytics.core.session.sentVisitAfterRefreshSession) {
      GrowingAnalytics.core.session.generateVisit()
    }

    var serialize = event.toSerialize()
    var request = http.createHttp()
    var url = EventSender.url()

    request.request(url, {
      method: http.RequestMethod.POST,
      connectTimeout: 30000,
      readTimeout: 30000,
      extraData: '[' + serialize + ']',
      header: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Timestamp": Date.now() + ''
      }
    }, (e, v) => {
      if (e) {
        LogUtil.info('Request Failure, error: ' + JSON.stringify(e))
      } else {
        LogUtil.info('Request Success, Url = ' + url + ', Send event = ' + serialize)
      }
      request.destroy()
    })
  }

  static url() {
    var config = GrowingAnalytics.core.config
    var serverHost = config.dataCollectionServerHost
    var accountId = config.accountId
    return serverHost + '/v3/projects/' + accountId + '/collect?stm=' + Date.now()
  }
}