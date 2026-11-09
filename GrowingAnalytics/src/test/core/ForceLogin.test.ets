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

import { describe, beforeEach, afterEach, it, expect } from '@ohos/hypium'
import ForceLogin from '../../main/ets/components/core/ForceLogin'
import GrowingContext from '../../main/ets/components/core/Context'
import { ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'
import { FORCE_LOGIN_PENDING_DEVICE_ID } from '../../main/ets/components/utils/Constants'
import { buildFakeContext } from '../helpers/TestBuilders'

function makeContext(mode: ConfigMode = ConfigMode.NewSaaS, forceLogin: boolean = true): GrowingContext {
  let context = buildFakeContext(mode)
  context.config.forceLogin = forceLogin
  return context
}

// 强制登录由主 Tracker（defaultContext）配置决定
function makeMainContext(mode: ConfigMode = ConfigMode.NewSaaS, forceLogin: boolean = true): GrowingContext {
  let context = makeContext(mode, forceLogin)
  GrowingContext.defaultContext = context
  return context
}

export default function forceLoginTests() {
  describe('ForceLogin', () => {
    beforeEach(() => {
      ForceLogin._reset()
      GrowingContext._reset()
    })

    afterEach(() => {
      ForceLogin._reset()
      GrowingContext._reset()
    })

    it('default_and_non_new_saas_should_allow_send', 0, () => {
      expect(ForceLogin.canSend(makeContext(ConfigMode.NewSaaS, false))).assertTrue()
      expect(ForceLogin.canSend(makeMainContext(ConfigMode.NewSaaS, false))).assertTrue()
      makeMainContext()
      expect(ForceLogin.canSend(makeContext(ConfigMode.SaaS, true))).assertTrue()
      expect(ForceLogin.canSend(makeContext(ConfigMode.CDP, true))).assertTrue()
    })

    it('new_saas_force_login_should_block_before_identify', 0, () => {
      expect(ForceLogin.canSend(makeMainContext())).assertFalse()
    })

    it('first_valid_identify_should_keep_raw_id_like_web_and_unlock', 0, () => {
      let context = makeMainContext()
      expect(ForceLogin.identify('  visitor-001  ', context)).assertTrue()
      expect(ForceLogin.canSend(context)).assertTrue()
      expect(ForceLogin.getDeviceId(context, 'generated-id')).assertEqual('  visitor-001  ')
      expect(ForceLogin.getPendingReplacement(context, 'generated-id')).assertEqual('  visitor-001  ')
    })

    it('empty_id_should_stay_blocked', 0, () => {
      let context = makeMainContext()
      expect(ForceLogin.identify('', context)).assertFalse()
      expect(ForceLogin.canSend(context)).assertFalse()
    })

    it('whitespace_id_should_be_accepted_like_web', 0, () => {
      let context = makeMainContext()
      expect(ForceLogin.identify('   ', context)).assertTrue()
      expect(ForceLogin.canSend(context)).assertTrue()
      expect(ForceLogin.getDeviceId(context, 'generated-id')).assertEqual('   ')
    })

    it('overlong_id_should_be_truncated_to_1000_and_unlock', 0, () => {
      let context = makeMainContext()
      expect(ForceLogin.identify('x'.repeat(1000) + 'y', context)).assertTrue()
      expect(ForceLogin.canSend(context)).assertTrue()
      expect(ForceLogin.getDeviceId(context, 'generated-id')).assertEqual('x'.repeat(1000))
    })

    it('identify_should_require_new_saas_and_force_login', 0, () => {
      expect(ForceLogin.identify('visitor', makeContext(ConfigMode.NewSaaS, false))).assertFalse()
      expect(ForceLogin.identify('visitor', makeContext(ConfigMode.SaaS, true))).assertFalse()
      expect(ForceLogin.identify('visitor', makeContext(ConfigMode.CDP, true))).assertFalse()
      expect(ForceLogin.identify('visitor', undefined)).assertFalse()
    })

    it('repeated_identify_should_keep_first_id', 0, () => {
      let context = makeMainContext()
      ForceLogin.identify('first', context)
      expect(ForceLogin.identify('second', context)).assertFalse()
      expect(ForceLogin.getDeviceId(context, 'generated-id')).assertEqual('first')
    })

    it('init_should_relock_for_a_new_process', 0, () => {
      let context = makeMainContext()
      ForceLogin.identify('visitor', context)
      ForceLogin.init()
      expect(ForceLogin.canSend(context)).assertFalse()
    })

    it('identified_id_should_only_override_new_saas', 0, () => {
      let context = makeMainContext()
      ForceLogin.identify('visitor', context)
      expect(ForceLogin.getDeviceId(makeContext(ConfigMode.SaaS, false), 'generated-id')).assertEqual('generated-id')
      expect(ForceLogin.getDeviceId(makeContext(ConfigMode.CDP, false), 'generated-id')).assertEqual('generated-id')
      expect(ForceLogin.getPendingReplacement(makeContext(ConfigMode.SaaS, false), 'generated-id')).assertEqual('')
      expect(ForceLogin.getPendingReplacement(makeContext(ConfigMode.CDP, false), 'generated-id')).assertEqual('')
    })

    it('all_new_saas_trackers_should_share_the_first_unlock', 0, () => {
      let main = makeMainContext()
      let sub = makeContext()
      ForceLogin.identify('visitor', main)
      expect(ForceLogin.canSend(main)).assertTrue()
      expect(ForceLogin.canSend(sub)).assertTrue()
      expect(ForceLogin.getDeviceId(sub, 'generated-id')).assertEqual('visitor')
    })

    it('sub_tracker_should_follow_main_force_login_when_main_enabled', 0, () => {
      makeMainContext(ConfigMode.NewSaaS, true)
      let sub = makeContext(ConfigMode.NewSaaS, false)
      expect(ForceLogin.isEnabled()).assertTrue()
      expect(ForceLogin.canSend(sub)).assertFalse()
    })

    it('sub_tracker_force_login_should_be_ignored_when_main_disabled', 0, () => {
      let main = makeMainContext(ConfigMode.NewSaaS, false)
      let sub = makeContext(ConfigMode.NewSaaS, true)
      expect(ForceLogin.isEnabled()).assertFalse()
      expect(ForceLogin.canSend(sub)).assertTrue()
      expect(ForceLogin.identify('visitor', main)).assertFalse()
    })

    it('force_login_should_be_disabled_when_main_is_not_new_saas', 0, () => {
      makeMainContext(ConfigMode.CDP, true)
      expect(ForceLogin.isEnabled()).assertFalse()
      expect(ForceLogin.canSend(makeContext(ConfigMode.NewSaaS, true))).assertTrue()
    })

    it('locked_new_saas_events_should_use_pending_marker', 0, () => {
      let main = makeMainContext()
      let sub = makeContext(ConfigMode.NewSaaS, false)
      expect(ForceLogin.getEventDeviceId(main, 'generated-id')).assertEqual(FORCE_LOGIN_PENDING_DEVICE_ID)
      expect(ForceLogin.getEventDeviceId(sub, 'generated-id')).assertEqual(FORCE_LOGIN_PENDING_DEVICE_ID)
      // 公开 getDeviceId 不暴露标记
      expect(ForceLogin.getDeviceId(main, 'generated-id')).assertEqual('generated-id')
    })

    it('unlocked_or_disabled_events_should_use_effective_device_id', 0, () => {
      let main = makeMainContext()
      ForceLogin.identify('visitor', main)
      expect(ForceLogin.getEventDeviceId(main, 'generated-id')).assertEqual('visitor')

      ForceLogin._reset()
      let disabled = makeMainContext(ConfigMode.NewSaaS, false)
      expect(ForceLogin.getEventDeviceId(disabled, 'generated-id')).assertEqual('generated-id')
    })

    it('saas_and_cdp_events_should_never_use_pending_marker', 0, () => {
      makeMainContext()
      expect(ForceLogin.getEventDeviceId(makeContext(ConfigMode.SaaS, true), 'generated-id')).assertEqual('generated-id')
      expect(ForceLogin.getEventDeviceId(makeContext(ConfigMode.CDP, true), 'generated-id')).assertEqual('generated-id')
    })

    it('pending_marker_should_not_be_accepted_as_identify_id', 0, () => {
      let context = makeMainContext()
      expect(ForceLogin.identify(FORCE_LOGIN_PENDING_DEVICE_ID, context)).assertFalse()
      expect(ForceLogin.canSend(context)).assertFalse()
    })

    it('pending_replacement_should_fall_back_to_generated_id_without_identify', 0, () => {
      let context = makeMainContext(ConfigMode.NewSaaS, false)
      expect(ForceLogin.getPendingReplacement(context, 'generated-id')).assertEqual('generated-id')
    })
  })
}
