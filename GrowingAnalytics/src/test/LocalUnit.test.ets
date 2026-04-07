import utilTests from './utils/UtilTest'
import niceTryTests from './utils/NiceTryTest'
import configTests from './interfaces/GrowingConfigTest'
import eventTimerTests from './core/EventTimerTest'
import sessionTests from './core/SessionTest'
import networkTests from './core/NetworkTest'
import eventPersistenceTests from './event/EventPersistenceTest'
import eventSenderTests from './event/EventSenderTest'

export default function localUnitTest() {
  // Phase 1 · 纯函数层
  utilTests()
  niceTryTests()
  configTests()

  // Phase 2 · 有状态业务逻辑层
  eventTimerTests()
  sessionTests()

  // Phase 3 · 数据管道层
  eventPersistenceTests()
  eventSenderTests()

  // Phase 4 · 网络层（URL / Header 生成）
  networkTests()
}
