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
import ViewElementEvent from '../../main/ets/components/event/ViewElementEvent'
import { EventType } from '../../main/ets/components/event/Event'
import EventBuilder from '../../main/ets/components/event/EventBuilder'
import Session from '../../main/ets/components/core/Session'
import UserIdentifier from '../../main/ets/components/core/UserIdentifier'
import GrowingContext from '../../main/ets/components/core/Context'
import { ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'

// ─── 测试 context 工厂 ────────────────────────────────────────────────────────

interface MinimalViewConfig {
  accountId: string
  dataSourceId: string
  urlScheme: string
  mode: ConfigMode
  idMappingEnabled: boolean
  dataCollectionEnabled: boolean
}

interface MinimalViewContext {
  trackerId: string
  config: MinimalViewConfig
}

function makeCtx(
  trackerId: string = 'tracker-1',
  mode: ConfigMode = ConfigMode.NewSaaS
): GrowingContext {
  let config: MinimalViewConfig = {
    accountId: 'acct-1',
    dataSourceId: 'ds-1',
    urlScheme: 'growing.test',
    mode: mode,
    idMappingEnabled: false,
    dataCollectionEnabled: false
  }
  let ctx: MinimalViewContext = { trackerId: trackerId, config: config }
  return ctx as ESObject as GrowingContext
}

function seedContext(ctx: GrowingContext) {
  Session.sessions.push(new Session('sid', ctx.trackerId))
  UserIdentifier.users.set(ctx.trackerId, new UserIdentifier('', ''))
}

function resetAll() {
  EventBuilder._reset()
  Session._reset()
  UserIdentifier._reset()
}

/** 便捷工厂：create() 参数较多，提供默认值减少测试样板 */
function createViewClick(
  ctx: GrowingContext,
  path: string = '/page',
  pageShowTimestamp: number = 0,
  textValue: string = 'Click Me',
  xpath: string = '/Page/Button[0]',
  xcontent: string = '',
  index: number = 0
): ViewElementEvent {
  return ViewElementEvent.create(path, pageShowTimestamp, textValue, xpath, xcontent, index, {}, EventType.ViewClick, ctx)
}

function createViewChange(
  ctx: GrowingContext,
  textValue: string = 'changed',
  index: number = 0
): ViewElementEvent {
  return ViewElementEvent.create('/page', 0, textValue, '/Page/Input[0]', '', index, {}, EventType.ViewChange, ctx)
}

/**
 * ViewElementEvent 测试策略说明：
 *
 * ViewElementEvent.create() 的分支逻辑：
 *   1. path：String(path ?? '') 保证非 null
 *   2. pageShowTimestamp：CDP 和 SaaS 模式写入，>0 用原值，=0 用 Date.now()
 *   3. textValue：仅 eventType = ViewClick 时写入，且非空才写（否则 undefined）
 *   4. index：> 0 时写入，否则 undefined（过滤掉 0 和负数）
 *   5. xcontent / xpath / attributes：直接透传
 *   6. eventType：直接透传（ViewClick / ViewChange）
 *   7. query / hyperlink：不在 create() 参数内，由调用方在 create() 后直接赋值
 */
export default function viewElementEventTests() {

  // ─── eventType 透传 ───────────────────────────────────────────────────────

  describe('ViewElementEvent_eventType', () => {

    beforeEach(() => { resetAll() })

    it('ViewClick eventType = VIEW_CLICK', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = createViewClick(ctx)
      expect(e.eventType).assertEqual('VIEW_CLICK')
    })

    it('ViewChange eventType = VIEW_CHANGE', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = createViewChange(ctx)
      expect(e.eventType).assertEqual('VIEW_CHANGE')
    })
  })

  // ─── path ─────────────────────────────────────────────────────────────────

  describe('ViewElementEvent_path', () => {

    beforeEach(() => { resetAll() })

    it('正常 path 字符串透传', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = ViewElementEvent.create('/home/detail', 0, '', '/Page', '', 0, {}, EventType.ViewClick, ctx)
      expect(e.path).assertEqual('/home/detail')
    })

    it('path 为空字符串 → 仍为空字符串', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = ViewElementEvent.create('', 0, '', '/Page', '', 0, {}, EventType.ViewClick, ctx)
      expect(e.path).assertEqual('')
    })
  })

  // ─── pageShowTimestamp（仅 CDP）───────────────────────────────────────────

  describe('ViewElementEvent_pageShowTimestamp', () => {

    beforeEach(() => { resetAll() })

    it('CDP 模式 + pageShowTimestamp > 0 → 使用原值', 0, () => {
      let ctx = makeCtx('t', ConfigMode.CDP)
      seedContext(ctx)
      let e = ViewElementEvent.create('/p', 1700000000000, '', '/X', '', 0, {}, EventType.ViewClick, ctx)
      expect(e.pageShowTimestamp).assertEqual(1700000000000)
    })

    it('CDP 模式 + pageShowTimestamp = 0 → 替换为 Date.now()', 0, () => {
      let ctx = makeCtx('t', ConfigMode.CDP)
      seedContext(ctx)
      let before = Date.now()
      let e = ViewElementEvent.create('/p', 0, '', '/X', '', 0, {}, EventType.ViewClick, ctx)
      let after = Date.now()
      expect(e.pageShowTimestamp !== undefined).assertTrue()
      expect((e.pageShowTimestamp as number) >= before).assertTrue()
      expect((e.pageShowTimestamp as number) <= after).assertTrue()
    })

    it('非 CDP 模式：pageShowTimestamp 为 undefined', 0, () => {
      let ctx = makeCtx('t', ConfigMode.NewSaaS)
      seedContext(ctx)
      let e = ViewElementEvent.create('/p', 1700000000000, '', '/X', '', 0, {}, EventType.ViewClick, ctx)
      expect(e.pageShowTimestamp === undefined).assertTrue()
    })

    it('SaaS 模式：pageShowTimestamp 有值', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      let e = ViewElementEvent.create('/p', 1700000000000, '', '/X', '', 0, {}, EventType.ViewClick, ctx)
      expect(e.pageShowTimestamp !== undefined).assertTrue()
      expect(e.pageShowTimestamp).assertEqual(1700000000000)
    })
  })

  // ─── textValue（仅 ViewClick）─────────────────────────────────────────────

  describe('ViewElementEvent_textValue', () => {

    beforeEach(() => { resetAll() })

    it('ViewClick + 非空 textValue → 写入', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = createViewClick(ctx, '/p', 0, 'Submit')
      expect(e.textValue).assertEqual('Submit')
    })

    it('ViewClick + 空字符串 textValue → undefined', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = createViewClick(ctx, '/p', 0, '')
      expect(e.textValue === undefined).assertTrue()
    })

    it('ViewChange：textValue 始终为 undefined（无论传入何值）', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = createViewChange(ctx, 'some text')
      expect(e.textValue === undefined).assertTrue()
    })
  })

  // ─── index 过滤 ───────────────────────────────────────────────────────────

  describe('ViewElementEvent_index', () => {

    beforeEach(() => { resetAll() })

    it('index > 0 → 写入', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = ViewElementEvent.create('/p', 0, '', '/X', '', 3, {}, EventType.ViewClick, ctx)
      expect(e.index).assertEqual(3)
    })

    it('index = 0 → undefined', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = ViewElementEvent.create('/p', 0, '', '/X', '', 0, {}, EventType.ViewClick, ctx)
      expect(e.index === undefined).assertTrue()
    })

    it('index < 0 → undefined', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = ViewElementEvent.create('/p', 0, '', '/X', '', -1, {}, EventType.ViewClick, ctx)
      expect(e.index === undefined).assertTrue()
    })
  })

  // ─── xpath / xcontent 透传 ────────────────────────────────────────────────

  describe('ViewElementEvent_xpathXcontent', () => {

    beforeEach(() => { resetAll() })

    it('xpath 透传', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = ViewElementEvent.create('/p', 0, '', '/Page/List[0]/Button[1]', '', 0, {}, EventType.ViewClick, ctx)
      expect(e.xpath).assertEqual('/Page/List[0]/Button[1]')
    })

    it('xcontent 透传', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = ViewElementEvent.create('/p', 0, '', '/X', 'content-id-123', 0, {}, EventType.ViewClick, ctx)
      expect(e.xcontent).assertEqual('content-id-123')
    })
  })

  // ─── query / hyperlink（SaaS hybrid autotrack 赋值路径）───────────────────

  describe('ViewElementEvent_queryHyperlink', () => {

    beforeEach(() => { resetAll() })

    it('create() 后赋值 query，字段应可读取', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      let e = createViewClick(ctx)
      e.query = 'tab=1'
      expect(e.query).assertEqual('tab=1')
    })

    it('create() 后赋值 hyperlink，字段应可读取', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      let e = createViewClick(ctx)
      e.hyperlink = 'https://example.com/page'
      expect(e.hyperlink).assertEqual('https://example.com/page')
    })

    it('未赋值时 query 默认为 undefined', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      let e = createViewClick(ctx)
      expect(e.query === undefined).assertTrue()
    })

    it('未赋值时 hyperlink 默认为 undefined', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      let e = createViewClick(ctx)
      expect(e.hyperlink === undefined).assertTrue()
    })
  })
}
