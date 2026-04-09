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

import { describe, it, expect } from '@ohos/hypium'
import DeviceInfo from '../../main/ets/components/core/DeviceInfo'
import GrowingContext from '../../main/ets/components/core/Context'
import { ConfigMode, IgnoreFields, IgnoreFieldsAll } from '../../main/ets/components/interfaces/GrowingConfig'

// ─── 测试 context 工厂 ────────────────────────────────────────────────────────

interface MinimalDeviceConfig {
  mode: ConfigMode
  ignoreField: number
}

interface MinimalDeviceContext {
  trackerId: string
  config: MinimalDeviceConfig
}

function makeCtx(mode: ConfigMode, ignoreField: number = 0): GrowingContext {
  let config: MinimalDeviceConfig = { mode: mode, ignoreField: ignoreField }
  let ctx: MinimalDeviceContext = { trackerId: 'test', config: config }
  return ctx as ESObject as GrowingContext
}

/**
 * DeviceInfo.isNotIgnoreField() 测试策略说明：
 *
 * isNotIgnoreField() 是 ignoreField 隐私合规功能的运行时解释层：
 *   - GrowingConfig 测试已覆盖位掩码的定义和数值正确性
 *   - 本测试覆盖该方法将位掩码"解释为是否采集"的逻辑：
 *       1. 非 NewSaaS 模式（SaaS / CDP）：忽略 ignoreField，始终返回 true
 *       2. NewSaaS 模式 + 字段未被忽略：返回 true
 *       3. NewSaaS 模式 + 字段已被忽略：返回 false
 *       4. 多字段组合掩码：只影响对应位，不干扰其他字段
 *       5. IgnoreFieldsAll：全部字段均返回 false
 */
export default function deviceInfoTests() {

  // ─── 非 NewSaaS 模式：ignoreField 无效 ───────────────────────────────────

  describe('DeviceInfo_isNotIgnoreField_nonNewSaaS', () => {

    it('SaaS 模式：任意 ignoreField 均返回 true', 0, () => {
      let ctx = makeCtx(ConfigMode.SaaS, IgnoreFieldsAll)
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.NetworkState)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.DeviceBrand)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.ScreenSize)).assertTrue()
    })

    it('CDP 模式：任意 ignoreField 均返回 true', 0, () => {
      let ctx = makeCtx(ConfigMode.CDP, IgnoreFieldsAll)
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.NetworkState)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.TimezoneOffset)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.PlatformVersion)).assertTrue()
    })
  })

  // ─── NewSaaS 模式：ignoreField = 0（不忽略任何字段）────────────────────────

  describe('DeviceInfo_isNotIgnoreField_NewSaaS_noIgnore', () => {

    it('ignoreField=0：所有字段均返回 true', 0, () => {
      let ctx = makeCtx(ConfigMode.NewSaaS, 0)
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.NetworkState)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.ScreenSize)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.DeviceBrand)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.DeviceModel)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.DeviceType)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.SystemLanguage)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.TimezoneOffset)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.PlatformVersion)).assertTrue()
    })
  })

  // ─── NewSaaS 模式：单字段忽略 ────────────────────────────────────────────

  describe('DeviceInfo_isNotIgnoreField_NewSaaS_singleField', () => {

    it('忽略 NetworkState → NetworkState 返回 false，其余返回 true', 0, () => {
      let ctx = makeCtx(ConfigMode.NewSaaS, IgnoreFields.NetworkState)
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.NetworkState)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.ScreenSize)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.DeviceBrand)).assertTrue()
    })

    it('忽略 DeviceBrand → DeviceBrand 返回 false，其余返回 true', 0, () => {
      let ctx = makeCtx(ConfigMode.NewSaaS, IgnoreFields.DeviceBrand)
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.DeviceBrand)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.DeviceModel)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.NetworkState)).assertTrue()
    })

    it('忽略 TimezoneOffset → TimezoneOffset 返回 false，其余返回 true', 0, () => {
      let ctx = makeCtx(ConfigMode.NewSaaS, IgnoreFields.TimezoneOffset)
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.TimezoneOffset)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.PlatformVersion)).assertTrue()
    })
  })

  // ─── NewSaaS 模式：多字段组合掩码 ────────────────────────────────────────

  describe('DeviceInfo_isNotIgnoreField_NewSaaS_multiField', () => {

    it('忽略 NetworkState | ScreenSize → 两者均返回 false，其余不受影响', 0, () => {
      let mask = IgnoreFields.NetworkState | IgnoreFields.ScreenSize
      let ctx = makeCtx(ConfigMode.NewSaaS, mask)
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.NetworkState)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.ScreenSize)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.DeviceBrand)).assertTrue()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.SystemLanguage)).assertTrue()
    })

    it('IgnoreFieldsAll → 全部 8 个字段均返回 false', 0, () => {
      let ctx = makeCtx(ConfigMode.NewSaaS, IgnoreFieldsAll)
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.NetworkState)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.ScreenSize)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.DeviceBrand)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.DeviceModel)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.DeviceType)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.SystemLanguage)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.TimezoneOffset)).assertFalse()
      expect(DeviceInfo.isNotIgnoreField(ctx, IgnoreFields.PlatformVersion)).assertFalse()
    })
  })
}
