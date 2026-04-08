import { describe, it, expect } from '@ohos/hypium'
import { GrowingConfig, ConfigMode, IgnoreFields, IgnoreFieldsAll } from '../../main/ets/components/interfaces/GrowingConfig'

export default function configTests() {

  // ─── 默认值 ───────────────────────────────────────────────────────────────

  describe('GrowingConfig - 默认值', () => {

    it('默认 mode 为 NewSaaS', 0, () => {
      let config = new GrowingConfig()
      expect(config.mode).assertEqual(ConfigMode.NewSaaS)
    })

    it('默认 sessionInterval 为 30 秒', 0, () => {
      let config = new GrowingConfig()
      expect(config.sessionInterval).assertEqual(30)
      expect(config._sessionInterval).assertEqual(30000)
    })

    it('默认 dataUploadInterval 为 15 秒', 0, () => {
      let config = new GrowingConfig()
      expect(config.dataUploadInterval).assertEqual(15)
      expect(config._dataUploadInterval).assertEqual(15000)
    })

    it('默认 dataValidityPeriod 为 7 天', 0, () => {
      let config = new GrowingConfig()
      expect(config.dataValidityPeriod).assertEqual(7)
    })

    it('默认 encryptEnabled 为 true', 0, () => {
      let config = new GrowingConfig()
      expect(config.encryptEnabled).assertTrue()
    })

    it('默认 compressEnabled 为 true', 0, () => {
      let config = new GrowingConfig()
      expect(config.compressEnabled).assertTrue()
    })

    it('默认 dataCollectionEnabled 为 true', 0, () => {
      let config = new GrowingConfig()
      expect(config.dataCollectionEnabled).assertTrue()
    })

    it('默认 autotrackEnabled 为 false', 0, () => {
      let config = new GrowingConfig()
      expect(config.autotrackEnabled).assertFalse()
    })

    it('默认 idMappingEnabled 为 false', 0, () => {
      let config = new GrowingConfig()
      expect(config.idMappingEnabled).assertFalse()
    })

    it('默认 useProtobuf 为 true', 0, () => {
      let config = new GrowingConfig()
      expect(config.useProtobuf).assertTrue()
    })

    it('默认 ignoreField 为 0（不忽略任何字段）', 0, () => {
      let config = new GrowingConfig()
      expect(config.ignoreField).assertEqual(0)
    })
  })

  // ─── 模式工厂方法 ─────────────────────────────────────────────────────────

  describe('GrowingConfig - NewSaaS()', () => {

    it('mode 应为 NewSaaS', 0, () => {
      let config = new GrowingConfig().NewSaaS('acct-001', 'ds-001', 'growing.xxx')
      expect(config.mode).assertEqual(ConfigMode.NewSaaS)
    })

    it('accountId / dataSourceId / urlScheme 应正确赋值', 0, () => {
      let config = new GrowingConfig().NewSaaS('acct-001', 'ds-001', 'growing.xxx')
      expect(config.accountId).assertEqual('acct-001')
      expect(config.dataSourceId).assertEqual('ds-001')
      expect(config.urlScheme).assertEqual('growing.xxx')
    })

    it('省略 dataCollectionServerHost 时应使用默认值', 0, () => {
      let config = new GrowingConfig().NewSaaS('a', 'b', 'c')
      expect(config.dataCollectionServerHost).assertEqual('https://napi.growingio.com')
    })

    it('显式传入 dataCollectionServerHost 时应覆盖默认值', 0, () => {
      let config = new GrowingConfig().NewSaaS('a', 'b', 'c', 'https://custom.example.com')
      expect(config.dataCollectionServerHost).assertEqual('https://custom.example.com')
    })

    it('useProtobuf 应保持默认值 true', 0, () => {
      let config = new GrowingConfig().NewSaaS('a', 'b', 'c')
      expect(config.useProtobuf).assertTrue()
    })
  })

  describe('GrowingConfig - SaaS()', () => {

    it('mode 应为 SaaS', 0, () => {
      let config = new GrowingConfig().SaaS('saas-acct', 'growing.saas')
      expect(config.mode).assertEqual(ConfigMode.SaaS)
    })

    it('accountId / urlScheme 应正确赋值', 0, () => {
      let config = new GrowingConfig().SaaS('saas-acct', 'growing.saas')
      expect(config.accountId).assertEqual('saas-acct')
      expect(config.urlScheme).assertEqual('growing.saas')
    })

    it('省略 dataCollectionServerHost 时应使用 SaaS 默认值', 0, () => {
      let config = new GrowingConfig().SaaS('a', 'b')
      expect(config.dataCollectionServerHost).assertEqual('https://api.growingio.com')
    })

    it('SaaS 模式下 useProtobuf 应保持默认值（不自动关闭，copy 前由外部控制）', 0, () => {
      // SaaS 模式在上报时强制走 V2 协议，useProtobuf 字段由 Network.generateRequest 忽略
      // 此处验证工厂方法不主动修改 useProtobuf
      let config = new GrowingConfig().SaaS('a', 'b')
      expect(config.useProtobuf).assertTrue()
    })
  })

  describe('GrowingConfig - CDP()', () => {

    it('mode 应为 CDP', 0, () => {
      let config = new GrowingConfig().CDP('cdp-acct', 'cdp-ds', 'growing.cdp', 'https://cdp.example.com')
      expect(config.mode).assertEqual(ConfigMode.CDP)
    })

    it('4 个参数应全部正确赋值', 0, () => {
      let config = new GrowingConfig().CDP('cdp-acct', 'cdp-ds', 'growing.cdp', 'https://cdp.example.com')
      expect(config.accountId).assertEqual('cdp-acct')
      expect(config.dataSourceId).assertEqual('cdp-ds')
      expect(config.urlScheme).assertEqual('growing.cdp')
      expect(config.dataCollectionServerHost).assertEqual('https://cdp.example.com')
    })
  })

  // ─── setter / getter 边界值 ────────────────────────────────────────────────

  describe('GrowingConfig - sessionInterval setter/getter', () => {

    it('设置正数应正确转为毫秒存储', 0, () => {
      let config = new GrowingConfig()
      config.sessionInterval = 60
      expect(config._sessionInterval).assertEqual(60000)
      expect(config.sessionInterval).assertEqual(60)
    })

    it('设置 0 应被忽略，保持默认值', 0, () => {
      let config = new GrowingConfig()
      config.sessionInterval = 0
      expect(config._sessionInterval).assertEqual(30000)
    })

    it('设置负数应被忽略，保持默认值', 0, () => {
      let config = new GrowingConfig()
      config.sessionInterval = -10
      expect(config._sessionInterval).assertEqual(30000)
    })
  })

  describe('GrowingConfig - dataUploadInterval setter/getter', () => {

    it('设置正数应正确转为毫秒存储', 0, () => {
      let config = new GrowingConfig()
      config.dataUploadInterval = 30
      expect(config._dataUploadInterval).assertEqual(30000)
      expect(config.dataUploadInterval).assertEqual(30)
    })

    it('设置 0 应被忽略，保持默认值', 0, () => {
      let config = new GrowingConfig()
      config.dataUploadInterval = 0
      expect(config._dataUploadInterval).assertEqual(15000)
    })
  })

  describe('GrowingConfig - dataValidityPeriod setter/getter', () => {

    it('设置 7 天应正确存储', 0, () => {
      let config = new GrowingConfig()
      config.dataValidityPeriod = 7
      expect(config.dataValidityPeriod).assertEqual(7)
    })

    it('设置超过 30 天应被限制为 30 天', 0, () => {
      let config = new GrowingConfig()
      config.dataValidityPeriod = 100
      expect(config.dataValidityPeriod).assertEqual(30)
    })

    it('设置少于 3 天应被限制为 3 天', 0, () => {
      let config = new GrowingConfig()
      config.dataValidityPeriod = 1
      expect(config.dataValidityPeriod).assertEqual(3)
    })
  })

  // ─── IgnoreFields bitmask ────────────────────────────────────────────────

  describe('GrowingConfig - IgnoreFields bitmask', () => {

    it('各字段位应互相独立（单独设置不影响其他位）', 0, () => {
      expect(IgnoreFields.NetworkState & IgnoreFields.ScreenSize).assertEqual(0)
      expect(IgnoreFields.NetworkState & IgnoreFields.DeviceBrand).assertEqual(0)
      expect(IgnoreFields.DeviceModel & IgnoreFields.SystemLanguage).assertEqual(0)
      expect(IgnoreFields.TimezoneOffset & IgnoreFields.PlatformVersion).assertEqual(0)
    })

    it('IgnoreFieldsAll 应包含所有 8 个字段位', 0, () => {
      expect(IgnoreFieldsAll & IgnoreFields.NetworkState).assertLarger(0)
      expect(IgnoreFieldsAll & IgnoreFields.ScreenSize).assertLarger(0)
      expect(IgnoreFieldsAll & IgnoreFields.DeviceBrand).assertLarger(0)
      expect(IgnoreFieldsAll & IgnoreFields.DeviceModel).assertLarger(0)
      expect(IgnoreFieldsAll & IgnoreFields.DeviceType).assertLarger(0)
      expect(IgnoreFieldsAll & IgnoreFields.SystemLanguage).assertLarger(0)
      expect(IgnoreFieldsAll & IgnoreFields.TimezoneOffset).assertLarger(0)
      expect(IgnoreFieldsAll & IgnoreFields.PlatformVersion).assertLarger(0)
    })

    it('位与运算可正确检测单字段是否被忽略', 0, () => {
      let mask = IgnoreFields.NetworkState | IgnoreFields.DeviceBrand
      expect((mask & IgnoreFields.NetworkState) !== 0).assertTrue()
      expect((mask & IgnoreFields.DeviceBrand) !== 0).assertTrue()
      expect((mask & IgnoreFields.ScreenSize) !== 0).assertFalse()
    })
  })

  // ─── copy() 校验 ─────────────────────────────────────────────────────────

  describe('GrowingConfig - copy() 校验', () => {

    it('accountId 为空时 copy() 应抛出错误', 0, () => {
      let config = new GrowingConfig()
      config.urlScheme = 'growing.xxx'
      config.dataCollectionServerHost = 'https://napi.growingio.com'
      // accountId 为默认空字符串

      let threw = false
      try {
        config.copy()
      } catch (e) {
        threw = true
        expect((e as Error).message).assertContain('accountId')
      }
      expect(threw).assertTrue()
    })

    it('NewSaaS 模式下 dataSourceId 为空时 copy() 应抛出错误', 0, () => {
      let config = new GrowingConfig()
      config.accountId = 'acct-001'
      config.urlScheme = 'growing.xxx'
      config.dataCollectionServerHost = 'https://napi.growingio.com'
      // mode=NewSaaS（默认），dataSourceId 为空

      let threw = false
      try {
        config.copy()
      } catch (e) {
        threw = true
        expect((e as Error).message).assertContain('dataSourceId')
      }
      expect(threw).assertTrue()
    })

    it('SaaS 模式下省略 dataSourceId 时 copy() 不应抛出错误', 0, () => {
      let config = new GrowingConfig().SaaS('acct-001', 'growing.saas')

      let threw = false
      try {
        config.copy()
      } catch (e) {
        threw = true
      }
      expect(threw).assertFalse()
    })

    it('dataCollectionServerHost 格式非法时 copy() 应抛出错误', 0, () => {
      let config = new GrowingConfig().NewSaaS('a', 'b', 'c')
      config.dataCollectionServerHost = 'not-a-valid-url'

      let threw = false
      try {
        config.copy()
      } catch (e) {
        threw = true
        expect((e as Error).message).assertContain('dataCollectionServerHost')
      }
      expect(threw).assertTrue()
    })

    it('合法配置 copy() 后所有字段应正确传递', 0, () => {
      let original = new GrowingConfig().NewSaaS('acct', 'ds', 'growing.x', 'https://api.example.com')
      original.debugEnabled = true
      original.encryptEnabled = false
      original.sessionInterval = 60

      let copied = original.copy()
      expect(copied.accountId).assertEqual('acct')
      expect(copied.dataSourceId).assertEqual('ds')
      expect(copied.debugEnabled).assertTrue()
      expect(copied.encryptEnabled).assertFalse()
      expect(copied._sessionInterval).assertEqual(60000)
    })

    it('copy() 应返回新对象（深拷贝），修改副本不影响原始配置', 0, () => {
      let original = new GrowingConfig().NewSaaS('acct', 'ds', 'growing.x', 'https://api.example.com')
      let copied = original.copy()
      copied.debugEnabled = true

      expect(original.debugEnabled).assertFalse()
    })
  })
}
