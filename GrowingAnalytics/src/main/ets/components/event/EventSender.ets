import http from '@ohos.net.http'

import Event from './Event'
import AnalyticsCore from '../core/AnalyticsCore'
import { LogUtil } from '../utils/LogUtil'

export default class EventSender {
  static sendEvent = <T extends Event>(
  event: T
  ) => {
    if (!AnalyticsCore.core.config.dataCollectionEnabled) {
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
    let config = AnalyticsCore.core.config
    let serverHost = config.dataCollectionServerHost
    let accountId = config.accountId
    return serverHost + '/v3/projects/' + accountId + '/collect?stm=' + Date.now()
  }
}