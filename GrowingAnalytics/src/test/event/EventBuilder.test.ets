/**
 * @license
 * Copyright (C) 2024 Beijing Yishu Technology Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { describe, it, expect, beforeEach } from '@ohos/hypium'
import EventBuilder from '../../main/ets/components/event/EventBuilder'
import VisitEvent from '../../main/ets/components/event/VisitEvent'
import Session, { SessionState } from '../../main/ets/components/core/Session'
import UserIdentifier from '../../main/ets/components/core/UserIdentifier'
import GrowingContext from '../../main/ets/components/core/Context'
import GeneralProps from '../../main/ets/components/core/GeneralProps'
import AppInfo from '../../main/ets/components/core/AppInfo'
import AnalyticsCore, { SDK_VERSION } from '../../main/ets/components/core/AnalyticsCore'
import { ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'
import { AttributesType } from '../../main/ets/components/utils/Constants'
import { JsonParser } from '../helpers/JsonParser'

/**
 * 构造测试用最小 GrowingContext 替身
 *
 * EventBuilder.build() 使用的字段：
 *   - trackerId
 *   - config.accountId / dataSourceId  → eventSequenceId 隔离键
 *   - config.urlScheme
 *   - config.mode
 *   - config.idMappingEnabled          → userKey 控制
 *   - config.dataCollectionEnabled     → Session.generateVisit 短路保护
 */
interface MinimalBuilderConfig {
  accountId: string
  dataSourceId: string
  urlScheme: string
  mode: ConfigMode
  idMappingEnabled: boolean
  dataCollectionEnabled: boolean
}

interface MinimalBuilderContext {
  trackerId: string
  config: MinimalBuilderConfig
}

function makeCtx(
  trackerId: string = 'tracker-1',
  accountId: string = 'acct-1',
  dataSourceId: string = 'ds-1',
  idMappingEnabled: boolean = false,
  mode: ConfigMode = ConfigMode.NewSaaS
): GrowingContext {
  let config: MinimalBuilderConfig = {
    accountId: accountId,
    dataSourceId: dataSourceId,
    urlScheme: 'growing.test',
    mode: mode,
    idMappingEnabled: idMappingEnabled,
    dataCollectionEnabled: false
  }
  let ctx: MinimalBuilderContext = { trackerId: trackerId, config: config }
  return ctx as ESObject as GrowingContext
}

/**
 * 为测试上下文注入最小运行态：Session 条目 + UserIdentifier 条目
 *
 * - EventBuilder.build() 调用 Session.getSessionId() 读 Session.sessions
 * - EventBuilder.build() 调用 UserIdentifier.getUser()!  若 undefined 则 crash
 */
function seedContext(
  ctx: GrowingContext,
  sessionId: string = 'sid-default',
  userId: string = '',
  userKey: string = ''
) {
  Session.sessions.push(new Session(sessionId, ctx.trackerId))
  UserIdentifier.users.set(ctx.trackerId, new UserIdentifier(userId, userKey))
}

/** beforeEach 全局重置，保证用例隔离 */
function resetAll() {
  EventBuilder._reset()
  Session._reset()
  UserIdentifier._reset()
  GeneralProps._reset()
  AnalyticsCore.location.latitude = 0
  AnalyticsCore.location.longitude = 0
  AppInfo.domain = ''
  AppInfo.appName = ''
  AppInfo.appVersion = ''
  AppInfo.appChannel = undefined
}

/**
 * EventBuilder 测试策略说明：
 *
 * EventBuilder.build() 是一个纯赋值函数，不触发 IO / 网络，
 * 仅在 updateEventSequenceId 内做 SharedPreferences.put()（无 context 时静默跳过）。
 *
 * 测试策略：
 *   - makeCtx() 构造最小 ESObject fake context（无真实 GrowingContext 副作用）
 *   - seedContext() 直接写 Session.sessions / UserIdentifier.users 绕过初始化
 *   - resetAll() 在 beforeEach 清理所有静态状态
 *
 * 本套测试覆盖：
 *   1. eventSequenceId：首次从 1 开始、自增、accountId+dataSourceId 隔离、_reset
 *   2. timestamp：event.timestamp ≤ 0 时回退 Date.now()，> 0 时保留
 *   3. appState：来自 Session.sessionState 枚举
 *   4. sessionId：来自 Session.sessions 对应 trackerId 条目
 *   5. userId/userKey：空值→ undefined，idMappingEnabled 开关
 *   6. location：abs > 0 才写入，否则 undefined
 *   7. attributes：generalProps 与 event.attributes 合并（event 覆盖 gp），
 *                  数组值→ '||' 拼接，数值→字符串，空→ undefined
 *   8. config 字段透传：dataSourceId、urlScheme、domain 回退
 *   9. sdkVersion：等于 SDK_VERSION 常量
 */
export default function eventBuilderTests() {

  // ─── eventSequenceId ──────────────────────────────────────────────────────

  describe('EventBuilder_eventSequenceId', () => {

    beforeEach(() => { resetAll() })

    it('第一次 build 序列号为 1', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.eventSequenceId).assertEqual(1)
    })

    it('连续两次 build 序列号依次自增', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e1 = new VisitEvent()
      let e2 = new VisitEvent()
      EventBuilder.build(e1, ctx)
      EventBuilder.build(e2, ctx)
      expect(e1.eventSequenceId).assertEqual(1)
      expect(e2.eventSequenceId).assertEqual(2)
    })

    it('不同 accountId+dataSourceId 序列号相互独立', 0, () => {
      let ctx1 = makeCtx('t1', 'acct-A', 'ds-A')
      let ctx2 = makeCtx('t2', 'acct-B', 'ds-B')
      seedContext(ctx1)
      seedContext(ctx2)
      let e1 = new VisitEvent()
      let e2 = new VisitEvent()
      EventBuilder.build(e1, ctx1)
      EventBuilder.build(e2, ctx2)
      expect(e1.eventSequenceId).assertEqual(1)
      expect(e2.eventSequenceId).assertEqual(1)
    })

    it('相同 accountId+dataSourceId 不同 trackerId 共享序列号', 0, () => {
      let ctx1 = makeCtx('t1', 'acct-1', 'ds-1')
      let ctx2 = makeCtx('t2', 'acct-1', 'ds-1')
      seedContext(ctx1)
      seedContext(ctx2)
      let e1 = new VisitEvent()
      let e2 = new VisitEvent()
      EventBuilder.build(e1, ctx1)
      EventBuilder.build(e2, ctx2)
      expect(e1.eventSequenceId).assertEqual(1)
      expect(e2.eventSequenceId).assertEqual(2)
    })

    it('_reset 后序列号重置为 1', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e1 = new VisitEvent()
      EventBuilder.build(e1, ctx)
      expect(e1.eventSequenceId).assertEqual(1)

      EventBuilder._reset()

      let e2 = new VisitEvent()
      EventBuilder.build(e2, ctx)
      expect(e2.eventSequenceId).assertEqual(1)
    })
  })

  // ─── timestamp ────────────────────────────────────────────────────────────

  describe('EventBuilder_timestamp', () => {

    beforeEach(() => { resetAll() })

    it('event.timestamp 默认为 0 时替换为 Date.now()', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let before = Date.now()
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      let after = Date.now()
      expect(e.timestamp >= before).assertTrue()
      expect(e.timestamp <= after).assertTrue()
    })

    it('event.timestamp > 0 时保留原值', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = new VisitEvent()
      e.timestamp = 1700000000000
      EventBuilder.build(e, ctx)
      expect(e.timestamp).assertEqual(1700000000000)
    })

    it('event.timestamp < 0 时替换为 Date.now()', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let before = Date.now()
      let e = new VisitEvent()
      e.timestamp = -1
      EventBuilder.build(e, ctx)
      let after = Date.now()
      expect(e.timestamp >= before).assertTrue()
      expect(e.timestamp <= after).assertTrue()
    })
  })

  // ─── appState ─────────────────────────────────────────────────────────────

  describe('EventBuilder_appState', () => {

    beforeEach(() => { resetAll() })

    it('sessionState = Foreground → appState = FOREGROUND', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      Session.sessionState = SessionState.Foreground
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.appState).assertEqual('FOREGROUND')
    })

    it('sessionState = Background → appState = BACKGROUND', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      Session.sessionState = SessionState.Background
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.appState).assertEqual('BACKGROUND')
    })
  })

  // ─── sessionId ────────────────────────────────────────────────────────────

  describe('EventBuilder_sessionId', () => {

    beforeEach(() => { resetAll() })

    it('sessionId 来自 Session.sessions 对应 trackerId 条目', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx, 'expected-session-id')
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.sessionId).assertEqual('expected-session-id')
    })

    it('多个 trackerId 各自使用独立 sessionId', 0, () => {
      let ctx1 = makeCtx('t1')
      let ctx2 = makeCtx('t2')
      seedContext(ctx1, 'session-for-t1')
      seedContext(ctx2, 'session-for-t2')
      let e1 = new VisitEvent()
      let e2 = new VisitEvent()
      EventBuilder.build(e1, ctx1)
      EventBuilder.build(e2, ctx2)
      expect(e1.sessionId).assertEqual('session-for-t1')
      expect(e2.sessionId).assertEqual('session-for-t2')
    })
  })

  // ─── userId / userKey ─────────────────────────────────────────────────────

  describe('EventBuilder_userId', () => {

    beforeEach(() => { resetAll() })

    it('userId 为空时 event.userId = undefined', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx, 'sid', '')
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.userId === undefined).assertTrue()
    })

    it('userId 非空时写入 event.userId', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx, 'sid', 'user-123')
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.userId).assertEqual('user-123')
    })

    it('idMappingEnabled=false 时 event.userKey 始终为 undefined', 0, () => {
      let ctx = makeCtx('t', 'a', 'd', false)
      seedContext(ctx, 'sid', 'user-123', 'key-abc')
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.userKey === undefined).assertTrue()
    })

    it('idMappingEnabled=true、userKey 为空时 event.userKey = undefined', 0, () => {
      let ctx = makeCtx('t', 'a', 'd', true)
      seedContext(ctx, 'sid', 'user-123', '')
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.userKey === undefined).assertTrue()
    })

    it('idMappingEnabled=true、userKey 非空时写入 event.userKey', 0, () => {
      let ctx = makeCtx('t', 'a', 'd', true)
      seedContext(ctx, 'sid', 'user-123', 'key-456')
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.userKey).assertEqual('key-456')
    })
  })

  // ─── location ─────────────────────────────────────────────────────────────

  describe('EventBuilder_location', () => {

    beforeEach(() => { resetAll() })

    it('lat=0 lng=0 → event.latitude/longitude = undefined', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.latitude === undefined).assertTrue()
      expect(e.longitude === undefined).assertTrue()
    })

    it('非零正坐标 → 写入 event.latitude/longitude', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      AnalyticsCore.location.latitude = 39.9
      AnalyticsCore.location.longitude = 116.4
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.latitude).assertEqual(39.9)
      expect(e.longitude).assertEqual(116.4)
    })

    it('负值坐标（abs > 0）→ 写入 event.latitude/longitude', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      AnalyticsCore.location.latitude = -33.8
      AnalyticsCore.location.longitude = 151.2
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.latitude).assertEqual(-33.8)
      expect(e.longitude).assertEqual(151.2)
    })

    it('仅 latitude 非零 → longitude = undefined', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      AnalyticsCore.location.latitude = 39.9
      AnalyticsCore.location.longitude = 0
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.latitude).assertEqual(39.9)
      expect(e.longitude === undefined).assertTrue()
    })
  })

  // ─── attributes / generalProps 合并 ───────────────────────────────────────

  describe('EventBuilder_attributes', () => {

    beforeEach(() => { resetAll() })

    it('无 generalProps 无 event.attributes → event.attributes = undefined', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.attributes === undefined).assertTrue()
    })

    it('只有 generalProps → 写入 event.attributes', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      GeneralProps.setGeneralProps({ 'gp_key': 'gp_value' })
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.attributes !== undefined).assertTrue()
      expect((e.attributes as AttributesType)['gp_key']).assertEqual('gp_value')
    })

    it('只有 event.attributes → 保留 event.attributes', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = new VisitEvent()
      e.attributes = { 'e_key': 'e_value' }
      EventBuilder.build(e, ctx)
      expect((e.attributes as AttributesType)['e_key']).assertEqual('e_value')
    })

    it('generalProps 与 event.attributes 合并，event 覆盖同名 gp', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      GeneralProps.setGeneralProps({ 'shared': 'gp_value', 'gp_only': 'from_gp' })
      let e = new VisitEvent()
      e.attributes = { 'shared': 'event_value', 'ev_only': 'from_event' }
      EventBuilder.build(e, ctx)
      let attrs = e.attributes as AttributesType
      expect(attrs['shared']).assertEqual('event_value')
      expect(attrs['gp_only']).assertEqual('from_gp')
      expect(attrs['ev_only']).assertEqual('from_event')
    })

    it('数组 value → 以 || 拼接为字符串', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = new VisitEvent()
      e.attributes = { 'tags': ['a', 'b', 'c'] }
      EventBuilder.build(e, ctx)
      expect((e.attributes as AttributesType)['tags']).assertEqual('a||b||c')
    })

    it('数值 value → 转为字符串', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = new VisitEvent()
      e.attributes = { 'price': 99 }
      EventBuilder.build(e, ctx)
      expect((e.attributes as AttributesType)['price']).assertEqual('99')
    })

    it('bool value → 转为字符串', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = new VisitEvent()
      e.attributes = { 'active': true }
      EventBuilder.build(e, ctx)
      expect((e.attributes as AttributesType)['active']).assertEqual('true')
    })
  })

  // ─── config 字段透传 ───────────────────────────────────────────────────────

  describe('EventBuilder_configFields', () => {

    beforeEach(() => { resetAll() })

    it('dataSourceId 来自 context.config.dataSourceId', 0, () => {
      let ctx = makeCtx('t', 'acct', 'my-datasource')
      seedContext(ctx)
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.dataSourceId).assertEqual('my-datasource')
    })

    it('urlScheme 来自 context.config.urlScheme', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.urlScheme).assertEqual('growing.test')
    })

    it('event.domain 为空时回退到 AppInfo.domain', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      AppInfo.domain = 'com.example.test'
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.domain).assertEqual('com.example.test')
    })

    it('event.domain 非空时不被 AppInfo.domain 覆盖', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      AppInfo.domain = 'com.example.test'
      let e = new VisitEvent()
      e.domain = 'custom.domain'
      EventBuilder.build(e, ctx)
      expect(e.domain).assertEqual('custom.domain')
    })
  })

  // ─── sdkVersion ───────────────────────────────────────────────────────────

  describe('EventBuilder_sdkVersion', () => {

    beforeEach(() => { resetAll() })

    it('event.sdkVersion = SDK_VERSION 常量', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = new VisitEvent()
      EventBuilder.build(e, ctx)
      expect(e.sdkVersion).assertEqual(SDK_VERSION)
    })
  })

  // ─── Event.toSerialize() 模式分发 ─────────────────────────────────────────
  //
  // toSerialize() 是三路分发：
  //   SaaS    → Util.toSerializeByMeasurementProtocolV2  （eventType 重命名为 "t"）
  //   CDP     → Util.toSerializeByMeasurementProtocolV3  （timezoneOffset 字段被剔除）
  //   NewSaaS → JSON.stringify                            （保留所有原始字段名）
  //
  // 使用 timezoneOffset 字段作为 CDP vs NewSaaS 的区分符：
  //   V3 明确删除该字段，JSON.stringify 原样保留。

  describe('Event_toSerialize', () => {

    beforeEach(() => { resetAll() })

    it('SaaS 模式 → V2 协议：eventType 被映射为 "t"，原始 eventType 键不存在', 0, () => {
      let ctx = makeCtx('t', 'acct', 'ds', false, ConfigMode.SaaS)
      let e = new VisitEvent()
      e.timezoneOffset = '+08:00'
      let json = new JsonParser(e.toSerialize(ctx))
      expect(json.hasKey('t')).assertTrue()
      expect(json.hasKey('eventType')).assertFalse()
    })

    it('CDP 模式 → V3 协议：保留 "eventType" 键，timezoneOffset 被剔除', 0, () => {
      let ctx = makeCtx('t', 'acct', 'ds', false, ConfigMode.CDP)
      let e = new VisitEvent()
      e.timezoneOffset = '+08:00'
      let json = new JsonParser(e.toSerialize(ctx))
      expect(json.hasKey('eventType')).assertTrue()
      expect(json.hasKey('timezoneOffset')).assertFalse()
    })

    it('NewSaaS 模式 → JSON.stringify：保留 "eventType" 和 "timezoneOffset" 原始键', 0, () => {
      let ctx = makeCtx('t', 'acct', 'ds', false, ConfigMode.NewSaaS)
      let e = new VisitEvent()
      e.timezoneOffset = '+08:00'
      let json = new JsonParser(e.toSerialize(ctx))
      expect(json.hasKey('eventType')).assertTrue()
      expect(json.hasKey('timezoneOffset')).assertTrue()
    })
  })
}
