import utilTests from './utils/Util.test'
import niceTryTests from './utils/NiceTry.test'
import configTests from './interfaces/GrowingConfig.test'
import eventTimerTests from './core/EventTimer.test'
import sessionTests from './core/Session.test'
import generalPropsTests from './core/GeneralProps.test'
import contextTests from './core/Context.test'
import userIdentifierTests from './core/UserIdentifier.test'
import networkTests from './core/Network.test'
import eventBuilderTests from './event/EventBuilder.test'
import pageEventTests from './event/PageEvent.test'
import customEventTests from './event/CustomEvent.test'
import viewElementEventTests from './event/ViewElementEvent.test'
import eventPersistenceTests from './event/EventPersistence.test'
import eventSendCycleTests from './event/EventSendCycle.test'

export default function testsuite() {
  // Phase 1 · 纯函数层
  utilTests()
  niceTryTests()
  configTests()

  // Phase 2 · 有状态业务逻辑层
  eventTimerTests()
  sessionTests()
  generalPropsTests()
  contextTests()
  userIdentifierTests()

  // Phase 3 · 数据管道层
  eventBuilderTests()
  pageEventTests()
  customEventTests()
  viewElementEventTests()
  eventPersistenceTests()
  eventSendCycleTests()

  // Phase 4 · 网络层（URL / Header 生成）
  networkTests()
}
