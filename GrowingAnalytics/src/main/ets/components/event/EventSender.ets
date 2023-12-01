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

    let serialize = event.toSerialize()
    let request = http.createHttp()
    let url = EventSender.url()

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
    let config = GrowingAnalytics.core.config
    let serverHost = config.dataCollectionServerHost
    let accountId = config.accountId
    return serverHost + '/v3/projects/' + accountId + '/collect?stm=' + Date.now()
  }
}