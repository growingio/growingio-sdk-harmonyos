/**
 * @license
 * Copyright (C) 2026 Beijing Yishu Technology Co., Ltd.
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
import HybridCustomEvent from '../../main/ets/components/event/hybrid/HybridCustomEvent'
import EventBuilder from '../../main/ets/components/event/EventBuilder'
import Session from '../../main/ets/components/core/Session'
import UserIdentifier from '../../main/ets/components/core/UserIdentifier'
import GrowingContext from '../../main/ets/components/core/Context'
import { ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'
import { buildFakeContext } from '../helpers/TestBuilders'

function makeEvent(
  context: GrowingContext,
  path: string,
  referralPage: string | undefined
): HybridCustomEvent {
  return HybridCustomEvent.create(
    'add_cart',
    {},
    path,
    'from=hybrid',
    1700000000000,
    'example.com',
    referralPage,
    context
  )
}

function seedContext(context: GrowingContext) {
  Session.sessions.push(new Session('sid', context.trackerId))
  UserIdentifier.users.set(context.trackerId, new UserIdentifier('', ''))
}

function resetAll() {
  EventBuilder._reset()
  Session._reset()
  UserIdentifier._reset()
}

export default function hybridCustomEventTests() {
  describe('HybridCustomEvent_NewSaaS_pageInfo', () => {
    beforeEach(() => { resetAll() })

    it('默认无条件携带 H5 消息中的 path 和 referralPage', 0, () => {
      let context = buildFakeContext(ConfigMode.NewSaaS)
      seedContext(context)
      let event = makeEvent(context, '/current', '/previous')
      expect(event.path).assertEqual('/current')
      expect(event.referralPage).assertEqual('/previous')
      expect(event.toSerialize(context)).assertContain('"path":"/current"')
      expect(event.toSerialize(context)).assertContain('"referralPage":"/previous"')
    })

    it('两个初始化开关开启也不改变 Hybrid 页面字段行为', 0, () => {
      let context = buildFakeContext(ConfigMode.NewSaaS)
      context.config.customEventWithPath = true
      context.config.customEventWithReferralPath = true
      seedContext(context)
      let event = makeEvent(context, '/current', '/previous')
      expect(event.path).assertEqual('/current')
      expect(event.referralPage).assertEqual('/previous')
    })

    it('无上一页：仍携带 path，referralPage 为 undefined', 0, () => {
      let context = buildFakeContext(ConfigMode.NewSaaS)
      seedContext(context)
      let event = makeEvent(context, '/first', undefined)
      expect(event.path).assertEqual('/first')
      expect(event.referralPage === undefined).assertTrue()
    })

    it('referralPage 为空字符串：仍携带 path，不携带空 referralPage', 0, () => {
      let context = buildFakeContext(ConfigMode.NewSaaS)
      seedContext(context)
      let event = makeEvent(context, '/current', '')
      expect(event.path).assertEqual('/current')
      expect(event.referralPage === undefined).assertTrue()
    })
  })

  describe('HybridCustomEvent_nonNewSaaS_pageInfo', () => {
    beforeEach(() => { resetAll() })

    it('SaaS：保持原有 path 行为，两个开关不注入 referralPage', 0, () => {
      let context = buildFakeContext(ConfigMode.SaaS)
      context.config.customEventWithPath = true
      context.config.customEventWithReferralPath = true
      seedContext(context)
      let event = makeEvent(context, '/current', '/previous')
      expect(event.path).assertEqual('/current')
      expect(event.referralPage === undefined).assertTrue()
    })

    it('CDP：保持原有 path 行为，两个开关不注入 referralPage', 0, () => {
      let context = buildFakeContext(ConfigMode.CDP)
      context.config.customEventWithPath = true
      context.config.customEventWithReferralPath = true
      seedContext(context)
      let event = makeEvent(context, '/current', '/previous')
      expect(event.path).assertEqual('/current')
      expect(event.referralPage === undefined).assertTrue()
    })
  })
}
