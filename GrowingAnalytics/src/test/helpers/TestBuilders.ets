import { GrowingConfig, ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'
import GrowingContext from '../../main/ets/components/core/Context'
import EventPersistence from '../../main/ets/components/event/EventPersistence'

/**
 * 构造最小可用的 GrowingContext 替身
 *
 * 用于 EventSender / EventPersistence 等需要 context.config 的测试。
 * 不涉及任何平台 API，全部字段手动赋值。
 */
export function buildFakeContext(
  mode: ConfigMode = ConfigMode.NewSaaS,
  overrides?: {
    accountId?: string
    dataSourceId?: string
    urlScheme?: string
    dataCollectionServerHost?: string
  }
): GrowingContext {
  let config = new GrowingConfig()
  config.mode = mode
  config.accountId = overrides?.accountId ?? 'test-account-id'
  config.dataSourceId = overrides?.dataSourceId ?? 'test-datasource-id'
  config.urlScheme = overrides?.urlScheme ?? 'growing.test'
  config.dataCollectionServerHost = overrides?.dataCollectionServerHost ?? 'https://napi.growingio.com'

  return {
    trackerId: 'default',
    config,
    eventSender: []
  } as unknown as GrowingContext
}

/**
 * 构造用于测试的最小 EventPersistence 实例
 *
 * 用于 EventSender / InMemoryEventStore 的测试数据填充。
 */
export function makeFakePersistence(
  uuid: string,
  eventType: string = 'CUSTOM',
  accountId: string = 'test-account-id',
  dataSourceId: string = 'test-datasource-id'
): EventPersistence {
  return EventPersistence.fromDatabase(
    uuid,
    JSON.stringify({ eventType, eventName: 'test_event', eventSequenceId: 1 }),
    eventType,
    '2.8.0',
    accountId,
    dataSourceId
  )
}
