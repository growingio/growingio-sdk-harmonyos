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

import { afterEach, beforeEach, describe, expect, it } from '@ohos/hypium'
import AnalyticsCore from '../../main/ets/components/core/AnalyticsCore'
import GrowingContext from '../../main/ets/components/core/Context'
import DummyTracker from '../../main/ets/components/core/DummyTracker'
import ForceLogin from '../../main/ets/components/core/ForceLogin'
import Session from '../../main/ets/components/core/Session'
import UserIdentifier from '../../main/ets/components/core/UserIdentifier'
import { GrowingAnalytics } from '../../main/ets/components/interfaces/GrowingAnalytics'
import { GrowingConfig, IgnoreFieldsAll } from '../../main/ets/components/interfaces/GrowingConfig'
import Plugins, { PluginsInterface } from '../../main/ets/components/plugins/Plugins'

class TestApplicationContext {
  on(_event: string, _callback: object): void {}
}

class TestContext {
  getApplicationContext(): TestApplicationContext {
    return new TestApplicationContext()
  }
}

class IdentifyOnInitializePlugin implements PluginsInterface {
  initializedInWillCallback: boolean = false
  initializedInDidCallback: boolean = false
  deviceIdInWillCallback: string = ''

  onSDKWillInitialize(): void {
    this.initializedInWillCallback = GrowingAnalytics.isInitializedSuccessfully()
    GrowingAnalytics.identify('before-initialize')
    this.deviceIdInWillCallback = GrowingAnalytics.getDeviceId()
  }

  onSDKDidInitialize(_config: GrowingConfig, _version: string): void {
    this.initializedInDidCallback = GrowingAnalytics.isInitializedSuccessfully()
    let context = GrowingContext.getDefaultContext()!
    context.eventSender = []
    GrowingAnalytics.identify('  visitor-from-callback  ')
  }
}

export default function analyticsCoreTests() {
  describe('AnalyticsCore_initialization', () => {
    beforeEach(() => {
      AnalyticsCore.core = new DummyTracker()
      AnalyticsCore.trackers = []
      GrowingContext._reset()
      ForceLogin._reset()
      Session._reset()
      UserIdentifier._reset()
      Plugins.plugins = []
      Plugins.deferDeepLink = undefined
    })

    afterEach(() => {
      AnalyticsCore.core = new DummyTracker()
      AnalyticsCore.trackers = []
      GrowingContext._reset()
      ForceLogin._reset()
      Session._reset()
      UserIdentifier._reset()
      Plugins.plugins = []
      Plugins.deferDeepLink = undefined
    })

    it('初始化完成回调中 identify 应解锁，初始化前调用仍应忽略', 0, () => {
      let plugin = new IdentifyOnInitializePlugin()
      let config = new GrowingConfig().NewSaaS('account', 'datasource', 'growing.test')
      config.forceLogin = true
      config.dataCollectionEnabled = false
      config.ignoreField = IgnoreFieldsAll
      config.plugins = [plugin]

      GrowingAnalytics.start(new TestContext() as ESObject as Context, config)

      expect(plugin.initializedInWillCallback).assertFalse()
      expect(plugin.deviceIdInWillCallback).assertEqual('')
      expect(plugin.initializedInDidCallback).assertTrue()
      expect(GrowingAnalytics.getDeviceId()).assertEqual('visitor-from-callback')
      expect(ForceLogin.canSend(GrowingContext.getDefaultContext()!)).assertTrue()
    })
  })
}
