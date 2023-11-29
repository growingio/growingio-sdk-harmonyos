import { GrowingConfig } from './GrowingConfig'
import CustomEvent from '../event/CustomEvent'
import EventSender from '../event/EventSender'
import AnalyticsCore from '../core/AnalyticsCore'

export class GrowingAnalytics {
  static core: AnalyticsCore = null

  static start = (
    context: Context,
    accountId: string,
    dataSourceId: string,
    urlScheme: string,
    dataCollectionServerHost: string = 'https://napi.growingio.com'
  ) => {
    var config = new GrowingConfig()
    config.accountId = accountId
    config.dataSourceId = dataSourceId
    config.dataCollectionServerHost = dataCollectionServerHost
    config.urlScheme = urlScheme
    GrowingAnalytics.core = new AnalyticsCore(context, config)
  }

  static track = async (
  eventName: string,
  attributes: object
  ) => {
    var e = await CustomEvent.create(eventName, attributes)
    EventSender.sendEvent(e)
  }

  static onForeground = () => {
    GrowingAnalytics.core.session.onForeground()
  }

  static onBackground = () => {
    GrowingAnalytics.core.session.onBackground()
  }
}