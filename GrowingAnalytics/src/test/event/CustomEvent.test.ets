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
import CustomEvent from '../../main/ets/components/event/CustomEvent'
import AppClosedEvent from '../../main/ets/components/event/AppClosedEvent'
import PageEvent, { Page } from '../../main/ets/components/event/PageEvent'
import EventBuilder from '../../main/ets/components/event/EventBuilder'
import Session from '../../main/ets/components/core/Session'
import UserIdentifier from '../../main/ets/components/core/UserIdentifier'
import GrowingContext from '../../main/ets/components/core/Context'
import { ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'

// ─── 测试 context 工厂 ────────────────────────────────────────────────────────

interface MinimalCustomConfig {
  accountId: string
  dataSourceId: string
  urlScheme: string
  mode: ConfigMode
  idMappingEnabled: boolean
  dataCollectionEnabled: boolean
}

interface MinimalCustomContext {
  trackerId: string
  config: MinimalCustomConfig
}

function makeCtx(
  trackerId: string = 'tracker-1',
  mode: ConfigMode = ConfigMode.NewSaaS
): GrowingContext {
  let config: MinimalCustomConfig = {
    accountId: 'acct-1',
    dataSourceId: 'ds-1',
    urlScheme: 'growing.test',
    mode: mode,
    idMappingEnabled: false,
    dataCollectionEnabled: false
  }
  let ctx: MinimalCustomContext = { trackerId: trackerId, config: config }
  return ctx as ESObject as GrowingContext
}

function seedContext(ctx: GrowingContext) {
  Session.sessions.push(new Session('sid', ctx.trackerId))
  UserIdentifier.users.set(ctx.trackerId, new UserIdentifier('', ''))
}

/** 直接写 PageEvent.lastPage，绕过 create() 副作用 */
function seedLastPage(ctx: GrowingContext, path: string = '/last-page', ts: number = 1700000000000) {
  let page: Page = {
    path: path,
    title: 'Last Page',
    timestamp: ts,
    attributes: undefined,
    referralPage: undefined
  }
  PageEvent.setLastPage(page, ctx)
}

function resetAll() {
  PageEvent._reset()
  EventBuilder._reset()
  Session._reset()
  UserIdentifier._reset()
}

/**
 * CustomEvent & AppClosedEvent 测试策略说明：
 *
 * 两个事件类在 SaaS 模式下都读取 PageEvent.lastPage：
 *   - CustomEvent：填充 event.path + event.pageShowTimestamp
 *   - AppClosedEvent：填充 event.path
 *
 * 共同测试点：
 *   SaaS + lastPage 存在 → 字段填充
 *   SaaS + lastPage 不存在 → 字段为 undefined
 *   NewSaaS / CDP → 字段为 undefined（不读 lastPage）
 *
 * seedLastPage() 直接调用 PageEvent.setLastPage() 构造前驱状态，
 * 不依赖 PageEvent.create() 触发完整副作用链。
 */
export default function customEventTests() {

  // ─── CustomEvent 基础字段 ─────────────────────────────────────────────────

  describe('CustomEvent_basicFields', () => {

    beforeEach(() => { resetAll() })

    it('eventName 来自参数', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = CustomEvent.create('btn_click', {}, ctx)
      expect(e.eventName).assertEqual('btn_click')
    })

    it('eventType = CUSTOM', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = CustomEvent.create('test', {}, ctx)
      expect(e.eventType).assertEqual('CUSTOM')
    })

    it('attributes 来自参数', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = CustomEvent.create('purchase', { 'price': '99' }, ctx)
      expect(e.attributes?.['price']).assertEqual('99')
    })
  })

  // ─── CustomEvent SaaS 模式 lastPage 注入 ──────────────────────────────────

  describe('CustomEvent_SaaS_lastPage', () => {

    beforeEach(() => { resetAll() })

    it('SaaS + lastPage 存在：path 和 pageShowTimestamp 被填充', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      seedLastPage(ctx, '/product/detail', 1700000000000)
      let e = CustomEvent.create('add_cart', {}, ctx)
      expect(e.path).assertEqual('/product/detail')
      expect(e.pageShowTimestamp).assertEqual(1700000000000)
    })

    it('SaaS + 无 lastPage：path 和 pageShowTimestamp 为 undefined', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      // 不调用 seedLastPage
      let e = CustomEvent.create('add_cart', {}, ctx)
      expect(e.path === undefined).assertTrue()
      expect(e.pageShowTimestamp === undefined).assertTrue()
    })

    it('SaaS lastPage.path 为 undefined 时 event.path = 空字符串', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      let page: Page = { path: undefined, title: 'T', timestamp: 1000, attributes: undefined, referralPage: undefined }
      PageEvent.setLastPage(page, ctx)
      let e = CustomEvent.create('test', {}, ctx)
      expect(e.path).assertEqual('')
    })
  })

  // ─── CustomEvent 非 SaaS 模式不注入 lastPage ─────────────────────────────

  describe('CustomEvent_nonSaaS', () => {

    beforeEach(() => { resetAll() })

    it('NewSaaS：path 和 pageShowTimestamp 为 undefined（即使 lastPage 存在）', 0, () => {
      let ctx = makeCtx('t', ConfigMode.NewSaaS)
      seedContext(ctx)
      seedLastPage(ctx)
      let e = CustomEvent.create('test', {}, ctx)
      expect(e.path === undefined).assertTrue()
      expect(e.pageShowTimestamp === undefined).assertTrue()
    })

    it('CDP：path 和 pageShowTimestamp 为 undefined', 0, () => {
      let ctx = makeCtx('t', ConfigMode.CDP)
      seedContext(ctx)
      seedLastPage(ctx)
      let e = CustomEvent.create('test', {}, ctx)
      expect(e.path === undefined).assertTrue()
      expect(e.pageShowTimestamp === undefined).assertTrue()
    })
  })

  // ─── AppClosedEvent SaaS 模式 lastPage 注入 ──────────────────────────────

  describe('AppClosedEvent_SaaS_lastPage', () => {

    beforeEach(() => { resetAll() })

    it('SaaS + lastPage 存在：event.path 被填充', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      seedLastPage(ctx, '/checkout', 0)
      let e = AppClosedEvent.create(ctx)
      expect(e.path).assertEqual('/checkout')
    })

    it('SaaS + 无 lastPage：event.path = undefined', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      let e = AppClosedEvent.create(ctx)
      expect(e.path === undefined).assertTrue()
    })

    it('NewSaaS：event.path = undefined（即使 lastPage 存在）', 0, () => {
      let ctx = makeCtx('t', ConfigMode.NewSaaS)
      seedContext(ctx)
      seedLastPage(ctx)
      let e = AppClosedEvent.create(ctx)
      expect(e.path === undefined).assertTrue()
    })

    it('CDP：event.path = undefined', 0, () => {
      let ctx = makeCtx('t', ConfigMode.CDP)
      seedContext(ctx)
      seedLastPage(ctx)
      let e = AppClosedEvent.create(ctx)
      expect(e.path === undefined).assertTrue()
    })

    it('eventType = APP_CLOSED', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = AppClosedEvent.create(ctx)
      expect(e.eventType).assertEqual('APP_CLOSED')
    })
  })
}
