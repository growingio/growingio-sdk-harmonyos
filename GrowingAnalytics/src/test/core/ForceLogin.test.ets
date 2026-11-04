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

import { describe, beforeEach, it, expect } from '@ohos/hypium'
import ForceLogin from '../../main/ets/components/core/ForceLogin'
import GrowingContext from '../../main/ets/components/core/Context'
import { ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'
import { buildFakeContext } from '../helpers/TestBuilders'

function makeContext(mode: ConfigMode = ConfigMode.NewSaaS, forceLogin: boolean = true): GrowingContext {
  let context = buildFakeContext(mode)
  context.config.forceLogin = forceLogin
  return context
}

export default function forceLoginTests() {
  describe('ForceLogin', () => {
    beforeEach(() => {
      ForceLogin._reset()
    })

    it('default_and_non_new_saas_should_allow_send', 0, () => {
      expect(ForceLogin.canSend(makeContext(ConfigMode.NewSaaS, false))).assertTrue()
      expect(ForceLogin.canSend(makeContext(ConfigMode.SaaS, true))).assertTrue()
      expect(ForceLogin.canSend(makeContext(ConfigMode.CDP, true))).assertTrue()
    })

    it('new_saas_force_login_should_block_before_identify', 0, () => {
      expect(ForceLogin.canSend(makeContext())).assertFalse()
    })

    it('first_valid_identify_should_trim_id_and_unlock', 0, () => {
      let context = makeContext()
      expect(ForceLogin.identify('  visitor-001  ', context)).assertTrue()
      expect(ForceLogin.canSend(context)).assertTrue()
      expect(ForceLogin.getDeviceId(context, 'generated-id')).assertEqual('visitor-001')
      expect(ForceLogin.getOverrideDeviceId(context)).assertEqual('visitor-001')
    })

    it('blank_and_overlong_id_should_stay_blocked', 0, () => {
      let context = makeContext()
      expect(ForceLogin.identify('   ', context)).assertFalse()
      expect(ForceLogin.identify('x'.repeat(1001), context)).assertFalse()
      expect(ForceLogin.canSend(context)).assertFalse()
    })

    it('identify_should_require_new_saas_and_force_login', 0, () => {
      expect(ForceLogin.identify('visitor', makeContext(ConfigMode.NewSaaS, false))).assertFalse()
      expect(ForceLogin.identify('visitor', makeContext(ConfigMode.SaaS, true))).assertFalse()
      expect(ForceLogin.identify('visitor', makeContext(ConfigMode.CDP, true))).assertFalse()
      expect(ForceLogin.identify('visitor', undefined)).assertFalse()
    })

    it('repeated_identify_should_keep_first_id', 0, () => {
      let context = makeContext()
      ForceLogin.identify('first', context)
      expect(ForceLogin.identify('second', context)).assertFalse()
      expect(ForceLogin.getDeviceId(context, 'generated-id')).assertEqual('first')
    })

    it('init_should_relock_for_a_new_process', 0, () => {
      let context = makeContext()
      ForceLogin.identify('visitor', context)
      ForceLogin.init()
      expect(ForceLogin.canSend(context)).assertFalse()
    })

    it('identified_id_should_only_override_new_saas', 0, () => {
      let context = makeContext()
      ForceLogin.identify('visitor', context)
      expect(ForceLogin.getDeviceId(makeContext(ConfigMode.SaaS, false), 'generated-id')).assertEqual('generated-id')
      expect(ForceLogin.getDeviceId(makeContext(ConfigMode.CDP, false), 'generated-id')).assertEqual('generated-id')
      expect(ForceLogin.getOverrideDeviceId(makeContext(ConfigMode.SaaS, false))).assertEqual('')
      expect(ForceLogin.getOverrideDeviceId(makeContext(ConfigMode.CDP, false))).assertEqual('')
    })

    it('all_new_saas_trackers_should_share_the_first_unlock', 0, () => {
      let main = makeContext()
      let sub = makeContext()
      ForceLogin.identify('visitor', main)
      expect(ForceLogin.canSend(main)).assertTrue()
      expect(ForceLogin.canSend(sub)).assertTrue()
      expect(ForceLogin.getDeviceId(sub, 'generated-id')).assertEqual('visitor')
    })
  })
}
