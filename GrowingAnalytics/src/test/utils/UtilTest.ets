import { describe, it, expect } from '@ohos/hypium'
import Util from '../../main/ets/components/utils/Util'

export default function utilTests() {

  // ─── serializableAttributes ───────────────────────────────────────────────

  describe('Util - serializableAttributes', () => {

    it('数组值应被转换为 || 分隔字符串', 0, () => {
      let result = Util.serializableAttributes({ tags: ['a', 'b', 'c'] })
      expect(result!['tags']).assertEqual('a||b||c')
    })

    it('空数组应被转换为空字符串', 0, () => {
      let result = Util.serializableAttributes({ empty: [] })
      expect(result!['empty']).assertEqual('')
    })

    it('数字值应被转换为字符串', 0, () => {
      let result = Util.serializableAttributes({ score: 99 })
      expect(result!['score']).assertEqual('99')
    })

    it('布尔值应被转换为字符串', 0, () => {
      let result = Util.serializableAttributes({ active: true })
      expect(result!['active']).assertEqual('true')
    })

    it('字符串值应原样保留（String 幂等）', 0, () => {
      let result = Util.serializableAttributes({ name: 'GrowingIO' })
      expect(result!['name']).assertEqual('GrowingIO')
    })

    it('空对象应返回 undefined', 0, () => {
      let result = Util.serializableAttributes({})
      expect(result).assertUndefined()
    })

    it('混合类型的 object 应全部转为字符串', 0, () => {
      let result = Util.serializableAttributes({ a: 1, b: true, c: 'x', d: [1, 2] })
      expect(result!['a']).assertEqual('1')
      expect(result!['b']).assertEqual('true')
      expect(result!['c']).assertEqual('x')
      expect(result!['d']).assertEqual('1||2')
    })
  })

  // ─── mapToObject ──────────────────────────────────────────────────────────

  describe('Util - mapToObject', () => {

    it('Map 转换后键值对应正确', 0, () => {
      let map: Map<string, string> = new Map([['k1', 'v1'], ['k2', 'v2']])
      let obj = Util.mapToObject(map)
      expect(obj['k1']).assertEqual('v1')
      expect(obj['k2']).assertEqual('v2')
    })

    it('空 Map 应返回空对象', 0, () => {
      let obj = Util.mapToObject(new Map())
      expect(Object.keys(obj).length).assertEqual(0)
    })
  })

  // ─── concatObject ─────────────────────────────────────────────────────────

  describe('Util - concatObject', () => {

    it('后者字段覆盖前者同名字段', 0, () => {
      let result = Util.concatObject({ x: '1', y: '2' }, { y: '99', z: '3' })
      expect(result['x']).assertEqual('1')
      expect(result['y']).assertEqual('99')
      expect(result['z']).assertEqual('3')
    })

    it('两个空对象合并仍为空对象', 0, () => {
      let result = Util.concatObject({}, {})
      expect(Object.keys(result).length).assertEqual(0)
    })
  })

  // ─── removeKeysForObject ──────────────────────────────────────────────────

  describe('Util - removeKeysForObject', () => {

    it('指定的 key 应被删除', 0, () => {
      let obj: Record<string, string> = { a: '1', b: '2', c: '3' }
      Util.removeKeysForObject(['a', 'c'], obj)
      expect(obj['a']).assertUndefined()
      expect(obj['c']).assertUndefined()
    })

    it('未指定的 key 应保留', 0, () => {
      let obj: Record<string, string> = { a: '1', b: '2' }
      Util.removeKeysForObject(['a'], obj)
      expect(obj['b']).assertEqual('2')
    })

    it('删除不存在的 key 不应抛出异常', 0, () => {
      let obj: Record<string, string> = { a: '1' }
      Util.removeKeysForObject(['nonexistent'], obj)
      expect(obj['a']).assertEqual('1')
    })
  })

  // ─── sizeOfEventString ────────────────────────────────────────────────────

  describe('Util - sizeOfEventString', () => {

    it('纯 ASCII 字符串：字节数等于字符数', 0, () => {
      expect(Util.sizeOfEventString('hello')).assertEqual(5)
    })

    it('中文字符：UTF-8 每字符 3 字节', 0, () => {
      expect(Util.sizeOfEventString('你好')).assertEqual(6)
    })

    it('空字符串：字节数为 0', 0, () => {
      expect(Util.sizeOfEventString('')).assertEqual(0)
    })

    it('混合 ASCII 和中文', 0, () => {
      // 'a' = 1 byte, '中' = 3 bytes → 共 4 bytes
      expect(Util.sizeOfEventString('a中')).assertEqual(4)
    })
  })

  // ─── getHintFromTime ──────────────────────────────────────────────────────

  describe('Util - getHintFromTime', () => {

    it('应提取时间戳十六进制的最低字节', 0, () => {
      // 0xFF 最低字节 = 0xFF = 255
      expect(Util.getHintFromTime(0xFF)[0]).assertEqual(255)
    })

    it('0xABCD 最低字节应为 0xCD = 205', 0, () => {
      expect(Util.getHintFromTime(0xABCD)[0]).assertEqual(0xCD)
    })

    it('时间戳为 0 时 hint 为 0', 0, () => {
      expect(Util.getHintFromTime(0)[0]).assertEqual(0)
    })
  })

  // ─── encrypt ──────────────────────────────────────────────────────────────

  describe('Util - encrypt', () => {

    it('XOR 自反性：加密两次应还原原文', 0, () => {
      let buf = new ArrayBuffer(5)
      let view = new Uint8Array(buf)
      view.set([0xDE, 0xAD, 0xBE, 0xEF, 0x42])

      let time = 1700000000255 // 末字节 0xFF
      let encrypted = Util.encrypt(buf, time)
      let decrypted = Util.encrypt(encrypted, time)

      let result = new Uint8Array(decrypted)
      expect(result[0]).assertEqual(0xDE)
      expect(result[1]).assertEqual(0xAD)
      expect(result[2]).assertEqual(0xBE)
      expect(result[3]).assertEqual(0xEF)
      expect(result[4]).assertEqual(0x42)
    })

    it('hint 为 0 时数据不变（XOR 0 恒等）', 0, () => {
      let buf = new ArrayBuffer(3)
      let view = new Uint8Array(buf)
      view.set([0x01, 0x02, 0x03])

      let encrypted = Util.encrypt(buf, 0x100) // 末字节 0x00，hint=0
      let result = new Uint8Array(encrypted)
      expect(result[0]).assertEqual(0x01)
      expect(result[1]).assertEqual(0x02)
      expect(result[2]).assertEqual(0x03)
    })

    it('加密结果长度与原始数据长度相同', 0, () => {
      let buf = new ArrayBuffer(10)
      let encrypted = Util.encrypt(buf, Date.now())
      expect(encrypted.byteLength).assertEqual(10)
    })
  })

  // ─── validateEventSize ────────────────────────────────────────────────────

  describe('Util - validateEventSize', () => {

    it('小事件（远小于 1.8MB）应通过校验', 0, () => {
      let event = { eventType: 'CUSTOM', eventName: 'btn_click', attributes: { key: 'value' } }
      let result = Util.validateEventSize(event)
      expect(result.isValid).assertTrue()
    })

    it('超过 1.8MB 的事件应返回 isValid=false', 0, () => {
      let bigValue = 'x'.repeat(2 * 1024 * 1024)
      let event = { eventType: 'CUSTOM', attributes: { key: bigValue } }
      let result = Util.validateEventSize(event)
      expect(result.isValid).assertFalse()
    })

    it('超大事件的 attributes 应包含 growing_error_msg', 0, () => {
      let bigValue = 'x'.repeat(2 * 1024 * 1024)
      let event = { eventType: 'CUSTOM', attributes: { key: bigValue } }
      let result = Util.validateEventSize(event)
      let errMsg = result.attributes['growing_error_msg'] as string
      expect(errMsg.indexOf('exceeds maximum limit')).assertLarger(-1)
    })
  })

  // ─── toSerializeByMeasurementProtocolV2 ──────────────────────────────────

  describe('Util - toSerializeByMeasurementProtocolV2 - CUSTOM', () => {

    function makeBase(): Record<string, object> {
      return {
        eventType: 'CUSTOM',
        eventSequenceId: 7,
        deviceId: 'device-abc',
        sessionId: 'session-xyz',
        domain: 'com.example.app',
        timestamp: 1700000000000,
        userId: 'user-001',
        eventName: 'btn_click',
        attributes: { source: 'home' },
        path: '/home',
        pageShowTimestamp: 1699999990000
      }
    }

    it('t 字段应为 cstm', 0, () => {
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(makeBase(), 'WIFI'))
      expect(json['t']).assertEqual('cstm')
    })

    it('n 字段应等于 eventName', 0, () => {
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(makeBase(), 'WIFI'))
      expect(json['n']).assertEqual('btn_click')
    })

    it('esid 和 gesid 应等于 eventSequenceId', 0, () => {
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(makeBase(), 'WIFI'))
      expect(json['esid']).assertEqual(7)
      expect(json['gesid']).assertEqual(7)
    })

    it('u 字段应等于 deviceId', 0, () => {
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(makeBase(), 'WIFI'))
      expect(json['u']).assertEqual('device-abc')
    })

    it('s 字段应等于 sessionId', 0, () => {
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(makeBase(), 'WIFI'))
      expect(json['s']).assertEqual('session-xyz')
    })

    it('cs1 字段在有 userId 时应有值', 0, () => {
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(makeBase(), 'WIFI'))
      expect(json['cs1']).assertEqual('user-001')
    })

    it('cs1 字段在 userId 为 undefined 时应为 undefined', 0, () => {
      let base = makeBase()
      base['userId'] = undefined as unknown as object
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(base, 'WIFI'))
      expect(json['cs1']).assertUndefined()
    })
  })

  describe('Util - toSerializeByMeasurementProtocolV2 - 网络状态映射', () => {

    function makePageEvent(): Record<string, object> {
      return {
        eventType: 'PAGE',
        eventSequenceId: 1,
        deviceId: 'd',
        sessionId: 's',
        domain: 'com.x',
        timestamp: 0,
        userId: undefined,
        path: '/page',
        query: '',
        title: 'Home',
        referralPage: '',
        attributes: undefined
      }
    }

    it('networkState=WIFI → r=WIFI', 0, () => {
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(makePageEvent(), 'WIFI'))
      expect(json['r']).assertEqual('WIFI')
    })

    it('networkState=5G → r=CELL', 0, () => {
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(makePageEvent(), '5G'))
      expect(json['r']).assertEqual('CELL')
    })

    it('networkState=4G → r=CELL', 0, () => {
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(makePageEvent(), '4G'))
      expect(json['r']).assertEqual('CELL')
    })

    it('networkState=UNKNOWN → r=UNKNOWN', 0, () => {
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(makePageEvent(), 'UNKNOWN'))
      expect(json['r']).assertEqual('UNKNOWN')
    })

    it('networkState=空字符串 → r=NONE', 0, () => {
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(makePageEvent(), ''))
      expect(json['r']).assertEqual('NONE')
    })
  })

  describe('Util - toSerializeByMeasurementProtocolV2 - PAGE', () => {

    it('t 字段应为 page', 0, () => {
      let event: Record<string, object> = {
        eventType: 'PAGE',
        eventSequenceId: 2,
        deviceId: 'd',
        sessionId: 's',
        domain: 'com.x',
        timestamp: 0,
        userId: undefined,
        path: '/detail',
        query: 'id=1',
        title: 'Detail',
        referralPage: '/home',
        attributes: undefined
      }
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(event, 'WIFI'))
      expect(json['t']).assertEqual('page')
      expect(json['p']).assertEqual('/detail')
      expect(json['tl']).assertEqual('Detail')
    })
  })

  describe('Util - toSerializeByMeasurementProtocolV2 - VISIT', () => {

    it('t 字段应为 vst，且包含设备信息字段', 0, () => {
      let event: Record<string, object> = {
        eventType: 'VISIT',
        eventSequenceId: 1,
        deviceId: 'd',
        sessionId: 's',
        domain: 'com.x',
        timestamp: 0,
        userId: undefined,
        sdkVersion: '2.8.0',
        screenHeight: 1920,
        screenWidth: 1080,
        deviceBrand: 'HUAWEI',
        deviceModel: 'Mate60',
        platform: 'HarmonyOS',
        platformVersion: '5.0',
        appVersion: '1.0.0',
        appName: 'Demo',
        urlScheme: 'growing.xxx',
        language: 'zh',
        latitude: undefined,
        longitude: undefined
      }
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(event, 'WIFI'))
      expect(json['t']).assertEqual('vst')
      expect(json['db']).assertEqual('HUAWEI')
      expect(json['dm']).assertEqual('Mate60')
      expect(json['sh']).assertEqual(1920)
      expect(json['sw']).assertEqual(1080)
      expect(json['os']).assertEqual('HarmonyOS')
      expect(json['cv']).assertEqual('1.0.0')
    })
  })

  describe('Util - toSerializeByMeasurementProtocolV2 - APP_CLOSED', () => {

    it('t 字段应为 cls', 0, () => {
      let event: Record<string, object> = {
        eventType: 'APP_CLOSED',
        eventSequenceId: 5,
        deviceId: 'd',
        sessionId: 's',
        domain: 'com.x',
        timestamp: 0,
        userId: undefined,
        path: '/home'
      }
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV2(event, 'WIFI'))
      expect(json['t']).assertEqual('cls')
      expect(json['p']).assertEqual('/home')
    })
  })

  // ─── toSerializeByMeasurementProtocolV3 ──────────────────────────────────

  describe('Util - toSerializeByMeasurementProtocolV3', () => {

    it('序列化结果不含 timezoneOffset 字段', 0, () => {
      let event: Record<string, object> = {
        eventType: 'CUSTOM',
        eventName: 'test',
        timezoneOffset: '+08:00'
      }
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV3(event))
      expect(json['timezoneOffset']).assertUndefined()
    })

    it('序列化结果不含 xcontent 字段（当 xcontent 存在时）', 0, () => {
      let event: Record<string, object> = {
        eventType: 'VIEW_CLICK',
        xpath: '/Button[0]',
        xcontent: '/Button[0]/Image[0]'
      }
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV3(event))
      expect(json['xcontent']).assertUndefined()
      expect(json['xpath']).assertEqual('/Button[0]')
    })

    it('xcontent 为 null 时仍应被移除', 0, () => {
      let event: Record<string, object> = {
        eventType: 'VIEW_CLICK',
        xcontent: null as unknown as object
      }
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV3(event))
      expect(json['xcontent']).assertUndefined()
    })

    it('其余字段应原样保留', 0, () => {
      let event: Record<string, object> = {
        eventType: 'CUSTOM',
        eventName: 'purchase',
        eventSequenceId: 42
      }
      let json = JSON.parse(Util.toSerializeByMeasurementProtocolV3(event))
      expect(json['eventType']).assertEqual('CUSTOM')
      expect(json['eventName']).assertEqual('purchase')
      expect(json['eventSequenceId']).assertEqual(42)
    })
  })
}
