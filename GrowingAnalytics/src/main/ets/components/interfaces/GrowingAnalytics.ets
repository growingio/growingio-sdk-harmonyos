import { GrowingConfig } from './GrowingConfig'
import CustomEvent from '../event/CustomEvent'
import EventSender from '../event/EventSender'

export class GrowingAnalytics {
  static start = (
    context: Context,
    accountId: string,
    dataSourceId: string,
    dataCollectionServerHost: string = 'https://napi.growingio.com'
  ) => {
    var config = new GrowingConfig()
    config.accountId = accountId
    config.dataSourceId = dataSourceId
    config.dataCollectionServerHost = dataCollectionServerHost
  }

  static track = (
  eventName: string,
  attributes: object
  ) => {
    var e = CustomEvent.create(eventName, attributes)
    EventSender.sendEvent(e)
  }
}