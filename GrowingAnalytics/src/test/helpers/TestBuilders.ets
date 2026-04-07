import { GrowingConfig, ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'
import GrowingContext from '../../main/ets/components/core/Context'
import EventSender from '../../main/ets/components/event/EventSender'
import EventPersistence from '../../main/ets/components/event/EventPersistence'

/**
 * buildFakeContext 的可选覆盖参数
 */
export interface FakeContextOptions {
  accountId?: string
  dataSourceId?: string
  urlScheme?: string
  dataCollectionServerHost?: string
}

/** 用于构造最小 GrowingContext 替身的中间结构 */
interface MinimalContext {
  trackerId: string
  config: GrowingConfig
  eventSender: EventSender[]
}

/**
 * 构造最小可用的 GrowingContext 替身
 *
 * 用于 EventSender / EventPersistence 等需要 context.config 的测试。
 * 不涉及任何平台 API，全部字段手动赋值。
 */
export function buildFakeContext(
  mode: ConfigMode = ConfigMode.NewSaaS,
  overrides?: FakeContextOptions
): GrowingContext {
  let config = new GrowingConfig()
  config.mode = mode
  config.accountId = overrides?.accountId ?? 'test-account-id'
  config.dataSourceId = overrides?.dataSourceId ?? 'test-datasource-id'
  config.urlScheme = overrides?.urlScheme ?? 'growing.test'
  config.dataCollectionServerHost = overrides?.dataCollectionServerHost ?? 'https://napi.growingio.com'

  let eventSender: EventSender[] = []
  let ctx: MinimalContext = { trackerId: 'default', config: config, eventSender: eventSender }
  return ctx as ESObject as GrowingContext
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
    JSON.stringify({ eventType: eventType, eventName: 'test_event', eventSequenceId: 1 }),
    eventType,
    '2.8.0',
    accountId,
    dataSourceId
  )
}
