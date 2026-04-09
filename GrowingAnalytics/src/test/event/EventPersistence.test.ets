import { describe, it, expect } from '@ohos/hypium'
import EventPersistence from '../../main/ets/components/event/EventPersistence'
import Util from '../../main/ets/components/utils/Util'
import { AttributesType } from '../../main/ets/components/utils/Constants'
import { JsonParser } from '../helpers/JsonParser'

// ─── 测试用事件数据接口（模块顶层声明，符合 ArkTS arkts-no-untyped-obj-literals 规则）

interface NormalEventData {
  eventType: string
  eventName: string
  attributes: AttributesType
}

interface BigEventData {
  eventType: string
  attributes: AttributesType
}

interface BorderEventData {
  eventType: string
  key: string
}

interface V3CustomEventData {
  eventType: string
  eventName: string
  eventSequenceId: number
  deviceId: string
  sessionId: string
  domain: string
  timestamp: number
  userId: string | undefined
}

interface V2CustomEventData {
  eventType: string
  eventName: string
  eventSequenceId: number
  deviceId: string
  sessionId: string
  domain: string
  timestamp: number
  userId: string
  path: string
  pageShowTimestamp: number
}

interface V2VisitEventData {
  eventType: string
  eventSequenceId: number
  deviceId: string
  sessionId: string
  domain: string
  timestamp: number
  userId: string | undefined
  sdkVersion: string
  screenHeight: number
  screenWidth: number
  deviceBrand: string
  deviceModel: string
  platform: string
  platformVersion: string
  appVersion: string
  appName: string
  urlScheme: string
  language: string
}

interface V3PageEventData {
  eventType: string
  path: string
  timezoneOffset: string
}

export default function eventPersistenceTests() {

  // ─── fromDatabase ─────────────────────────────────────────────────────────

  describe('EventPersistence_fromDatabase', () => {

    it('6 个字段应全部正确保留', 0, () => {
      let e = EventPersistence.fromDatabase(
        'uuid-001',
        '{"eventType":"CUSTOM","eventName":"btn_click"}',
        'CUSTOM',
        '2.8.0',
        'account-001',
        'ds-001'
      )
      expect(e.uuid).assertEqual('uuid-001')
      expect(e.data).assertEqual('{"eventType":"CUSTOM","eventName":"btn_click"}')
      expect(e.eventType).assertEqual('CUSTOM')
      expect(e.sdkVersion).assertEqual('2.8.0')
      expect(e.accountId).assertEqual('account-001')
      expect(e.dataSourceId).assertEqual('ds-001')
    })

    it('不同 eventType 应正确保留', 0, () => {
      let visit = EventPersistence.fromDatabase('u', '{}', 'VISIT', '2.8.0', 'a', 'd')
      expect(visit.eventType).assertEqual('VISIT')

      let page = EventPersistence.fromDatabase('u', '{}', 'PAGE', '2.8.0', 'a', 'd')
      expect(page.eventType).assertEqual('PAGE')
    })
  })

  // ─── validateEventSize（通过 Util 直接测试，EventPersistence 调用该逻辑）──

  describe('EventPersistence_largeEvent_degradation', () => {

    it('正常大小事件应通过校验，isValid=true', 0, () => {
      let attrs: AttributesType = { price: '99.9', item: 'book' }
      let normalEvent: NormalEventData = {
        eventType: 'CUSTOM',
        eventName: 'purchase',
        attributes: attrs
      }
      let result = Util.validateEventSize(normalEvent)
      expect(result.isValid).assertTrue()
    })

    it('超过 1.8MB 的事件 isValid=false，并携带 growing_error_msg', 0, () => {
      let attrs: AttributesType = { key: 'x'.repeat(2 * 1024 * 1024) }
      let bigEvent: BigEventData = {
        eventType: 'CUSTOM',
        attributes: attrs
      }
      let result = Util.validateEventSize(bigEvent)
      expect(result.isValid).assertFalse()
      expect(result.attributes['growing_error_msg'] as string).assertContain('exceeds maximum limit')
    })

    it('1.8MB 边界值：刚好超过 1.8MB 时应返回错误', 0, () => {
      // 1.8 * 1024 * 1024 = 1887436.8 bytes，加 1 确保超过阈值
      let borderEvent: BorderEventData = {
        eventType: 'CUSTOM',
        key: 'x'.repeat(Math.floor(1.8 * 1024 * 1024) + 1)
      }
      let result = Util.validateEventSize(borderEvent)
      expect(result.isValid).assertFalse()
    })
  })

  // ─── EventPersistence.fromDatabase + 序列化格式验证 ──────────────────────

  describe('EventPersistence_serialization_format', () => {

    it('NewSaaS 序列化（V3）结果应为合法 JSON', 0, () => {
      let eventObj: V3CustomEventData = {
        eventType: 'CUSTOM',
        eventName: 'test',
        eventSequenceId: 1,
        deviceId: 'dev',
        sessionId: 'sess',
        domain: 'com.test',
        timestamp: 1700000000000,
        userId: undefined
      }
      let json = new JsonParser(Util.toSerializeByMeasurementProtocolV3(eventObj))
      expect(json.getString('eventType')).assertEqual('CUSTOM')
      expect(json.getString('eventName')).assertEqual('test')
    })

    it('SaaS 序列化（V2）CUSTOM 事件 t 字段应为 cstm', 0, () => {
      let eventObj: V2CustomEventData = {
        eventType: 'CUSTOM',
        eventName: 'checkout',
        eventSequenceId: 3,
        deviceId: 'dev',
        sessionId: 'sess',
        domain: 'com.test',
        timestamp: 1700000000000,
        userId: 'user1',
        path: '/cart',
        pageShowTimestamp: 0
      }
      let json = new JsonParser(Util.toSerializeByMeasurementProtocolV2(eventObj, 'WIFI'))
      expect(json.getString('t')).assertEqual('cstm')
    })

    it('SaaS 序列化（V2）VISIT 事件 t 字段应为 vst', 0, () => {
      let eventObj: V2VisitEventData = {
        eventType: 'VISIT',
        eventSequenceId: 1,
        deviceId: 'dev',
        sessionId: 'sess',
        domain: 'com.test',
        timestamp: 1700000000000,
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
        urlScheme: 'growing.x',
        language: 'zh'
      }
      let json = new JsonParser(Util.toSerializeByMeasurementProtocolV2(eventObj, 'WIFI'))
      expect(json.getString('t')).assertEqual('vst')
    })

    it('V3 序列化应过滤 timezoneOffset 字段', 0, () => {
      let eventObj: V3PageEventData = {
        eventType: 'PAGE',
        path: '/home',
        timezoneOffset: '+08:00'
      }
      let json = new JsonParser(Util.toSerializeByMeasurementProtocolV3(eventObj))
      expect(json.hasKey('timezoneOffset')).assertFalse()
      expect(json.getString('path')).assertEqual('/home')
    })
  })

  // ─── fromDatabase 保障：uuid 唯一性（业务约定）────────────────────────────

  describe('EventPersistence_uuid', () => {

    it('相同参数构造的两个实例 uuid 应相同（fromDatabase 不生成新 uuid）', 0, () => {
      let e1 = EventPersistence.fromDatabase('fixed-uuid', '{}', 'CUSTOM', '2.8.0', 'a', 'b')
      let e2 = EventPersistence.fromDatabase('fixed-uuid', '{}', 'CUSTOM', '2.8.0', 'a', 'b')
      expect(e1.uuid).assertEqual(e2.uuid)
      expect(e1.uuid).assertEqual('fixed-uuid')
    })
  })
}
