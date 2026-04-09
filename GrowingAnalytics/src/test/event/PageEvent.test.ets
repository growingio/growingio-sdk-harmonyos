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
import PageEvent, { Page } from '../../main/ets/components/event/PageEvent'
import EventBuilder from '../../main/ets/components/event/EventBuilder'
import Session from '../../main/ets/components/core/Session'
import UserIdentifier from '../../main/ets/components/core/UserIdentifier'
import GrowingContext from '../../main/ets/components/core/Context'
import { ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'

// ─── 测试 context 工厂 ────────────────────────────────────────────────────────

interface MinimalPageConfig {
  accountId: string
  dataSourceId: string
  urlScheme: string
  mode: ConfigMode
  idMappingEnabled: boolean
  dataCollectionEnabled: boolean
}

interface MinimalPageContext {
  trackerId: string
  config: MinimalPageConfig
}

function makeCtx(
  trackerId: string = 'tracker-1',
  mode: ConfigMode = ConfigMode.NewSaaS
): GrowingContext {
  let config: MinimalPageConfig = {
    accountId: 'acct-1',
    dataSourceId: 'ds-1',
    urlScheme: 'growing.test',
    mode: mode,
    idMappingEnabled: false,
    dataCollectionEnabled: false
  }
  let ctx: MinimalPageContext = { trackerId: trackerId, config: config }
  return ctx as ESObject as GrowingContext
}

function seedContext(ctx: GrowingContext) {
  Session.sessions.push(new Session('sid', ctx.trackerId))
  UserIdentifier.users.set(ctx.trackerId, new UserIdentifier('', ''))
}

function resetAll() {
  PageEvent._reset()
  EventBuilder._reset()
  Session._reset()
  UserIdentifier._reset()
}

/**
 * PageEvent 测试策略说明：
 *
 * PageEvent.create() 的核心逻辑：
 *   1. path / title / orientation 字段填充
 *   2. SaaS / NewSaaS 模式下：读取 lastPage 作为 referralPage，并更新 lastPage
 *   3. CDP 模式下：不读写 lastPage，不设 referralPage
 *
 * lastPage 是每个 trackerId 独立的静态状态（Record<string, Page>），
 * 也提供了 getLastPage / setLastPage 公开方法供外部直接操作。
 *
 * 测试分两层：
 *   1. getLastPage / setLastPage 作为状态机的纯存取测试
 *   2. create() 的完整场景测试（需要 Session + UserIdentifier 支撑 EventBuilder.build）
 */
export default function pageEventTests() {

  // ─── getLastPage / setLastPage ────────────────────────────────────────────

  describe('PageEvent_lastPageState', () => {

    beforeEach(() => { resetAll() })

    it('初始状态下 getLastPage 返回 undefined', 0, () => {
      let ctx = makeCtx()
      expect(PageEvent.getLastPage(ctx) === undefined).assertTrue()
    })

    it('setLastPage 后 getLastPage 能取回相同对象', 0, () => {
      let ctx = makeCtx()
      let page: Page = {
        path: '/home',
        title: 'Home',
        timestamp: 1700000000000,
        attributes: undefined,
        referralPage: undefined
      }
      PageEvent.setLastPage(page, ctx)
      let result = PageEvent.getLastPage(ctx)
      expect(result !== undefined).assertTrue()
      expect(result?.path).assertEqual('/home')
      expect(result?.title).assertEqual('Home')
      expect(result?.timestamp).assertEqual(1700000000000)
    })

    it('不同 trackerId 的 lastPage 相互独立', 0, () => {
      let ctx1 = makeCtx('t1')
      let ctx2 = makeCtx('t2')
      let page1: Page = { path: '/a', title: 'A', timestamp: 1000, attributes: undefined, referralPage: undefined }
      let page2: Page = { path: '/b', title: 'B', timestamp: 2000, attributes: undefined, referralPage: undefined }
      PageEvent.setLastPage(page1, ctx1)
      PageEvent.setLastPage(page2, ctx2)
      expect(PageEvent.getLastPage(ctx1)?.path).assertEqual('/a')
      expect(PageEvent.getLastPage(ctx2)?.path).assertEqual('/b')
    })

    it('重复 setLastPage 覆盖旧值', 0, () => {
      let ctx = makeCtx()
      let page1: Page = { path: '/old', title: 'Old', timestamp: 1000, attributes: undefined, referralPage: undefined }
      let page2: Page = { path: '/new', title: 'New', timestamp: 2000, attributes: undefined, referralPage: undefined }
      PageEvent.setLastPage(page1, ctx)
      PageEvent.setLastPage(page2, ctx)
      expect(PageEvent.getLastPage(ctx)?.path).assertEqual('/new')
    })

    it('_reset 后 getLastPage 返回 undefined', 0, () => {
      let ctx = makeCtx()
      let page: Page = { path: '/p', title: 'P', timestamp: 1000, attributes: undefined, referralPage: undefined }
      PageEvent.setLastPage(page, ctx)
      PageEvent._reset()
      expect(PageEvent.getLastPage(ctx) === undefined).assertTrue()
    })
  })

  // ─── create() 字段填充 ────────────────────────────────────────────────────

  describe('PageEvent_create_fields', () => {

    beforeEach(() => { resetAll() })

    it('path 来自参数', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = PageEvent.create('/detail', 'Detail', {}, Date.now(), ctx)
      expect(e.path).assertEqual('/detail')
    })

    it('title 来自参数', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = PageEvent.create('/p', 'My Title', {}, Date.now(), ctx)
      expect(e.title).assertEqual('My Title')
    })

    it('eventType = PAGE', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let e = PageEvent.create('/p', 'T', {}, Date.now(), ctx)
      expect(e.eventType).assertEqual('PAGE')
    })

    it('timestamp 来自参数', 0, () => {
      let ctx = makeCtx()
      seedContext(ctx)
      let ts = 1700000000000
      let e = PageEvent.create('/p', 'T', {}, ts, ctx)
      expect(e.timestamp).assertEqual(ts)
    })
  })

  // ─── referralPage（SaaS / NewSaaS）──────────────────────────────────────

  describe('PageEvent_create_referralPage_SaaS', () => {

    beforeEach(() => { resetAll() })

    it('SaaS 首页：无 referralPage，并将自身写入 lastPage', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      let e = PageEvent.create('/first', 'First', {}, 1000, ctx)
      expect(e.referralPage === undefined).assertTrue()
      expect(PageEvent.getLastPage(ctx)?.path).assertEqual('/first')
    })

    it('SaaS 第二页：referralPage = 上一页 path', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      PageEvent.create('/first', 'First', {}, 1000, ctx)
      let e2 = PageEvent.create('/second', 'Second', {}, 2000, ctx)
      expect(e2.referralPage).assertEqual('/first')
    })

    it('SaaS 第三页：referralPage = 第二页 path', 0, () => {
      let ctx = makeCtx('t', ConfigMode.SaaS)
      seedContext(ctx)
      PageEvent.create('/p1', 'P1', {}, 1000, ctx)
      PageEvent.create('/p2', 'P2', {}, 2000, ctx)
      let e3 = PageEvent.create('/p3', 'P3', {}, 3000, ctx)
      expect(e3.referralPage).assertEqual('/p2')
    })

    it('NewSaaS：referralPage 逻辑与 SaaS 相同', 0, () => {
      let ctx = makeCtx('t', ConfigMode.NewSaaS)
      seedContext(ctx)
      PageEvent.create('/p1', 'P1', {}, 1000, ctx)
      let e2 = PageEvent.create('/p2', 'P2', {}, 2000, ctx)
      expect(e2.referralPage).assertEqual('/p1')
    })

    it('SaaS：不同 trackerId 的 referralPage 相互独立', 0, () => {
      let ctx1 = makeCtx('t1', ConfigMode.SaaS)
      let ctx2 = makeCtx('t2', ConfigMode.SaaS)
      seedContext(ctx1)
      seedContext(ctx2)
      // t1: 两页
      PageEvent.create('/t1-p1', 'T1P1', {}, 1000, ctx1)
      let t1e2 = PageEvent.create('/t1-p2', 'T1P2', {}, 2000, ctx1)
      // t2: 一页（无 referral）
      let t2e1 = PageEvent.create('/t2-p1', 'T2P1', {}, 3000, ctx2)
      expect(t1e2.referralPage).assertEqual('/t1-p1')
      expect(t2e1.referralPage === undefined).assertTrue()
    })
  })

  // ─── CDP 模式：无 referralPage，不更新 lastPage ──────────────────────────

  describe('PageEvent_create_CDP', () => {

    beforeEach(() => { resetAll() })

    it('CDP 模式：referralPage = undefined', 0, () => {
      let ctx = makeCtx('t', ConfigMode.CDP)
      seedContext(ctx)
      let e = PageEvent.create('/p', 'P', {}, 1000, ctx)
      expect(e.referralPage === undefined).assertTrue()
    })

    it('CDP 模式：不更新 lastPage（多次调用后 getLastPage 仍为 undefined）', 0, () => {
      let ctx = makeCtx('t', ConfigMode.CDP)
      seedContext(ctx)
      PageEvent.create('/p1', 'P1', {}, 1000, ctx)
      PageEvent.create('/p2', 'P2', {}, 2000, ctx)
      expect(PageEvent.getLastPage(ctx) === undefined).assertTrue()
    })

    it('CDP 模式连续两页：第二页也无 referralPage', 0, () => {
      let ctx = makeCtx('t', ConfigMode.CDP)
      seedContext(ctx)
      PageEvent.create('/p1', 'P1', {}, 1000, ctx)
      let e2 = PageEvent.create('/p2', 'P2', {}, 2000, ctx)
      expect(e2.referralPage === undefined).assertTrue()
    })
  })
}
