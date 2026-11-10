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

import buffer from '@ohos.buffer'
import { describe, it, expect } from '@ohos/hypium'
import snappy from 'snappyjs'
import EventPersistence from '../../main/ets/components/event/EventPersistence'
import { processEvents } from '../../main/ets/components/utils/Concurrent'
import { event_pb } from '../../main/ets/components/utils/protobuf/event_pb'

interface SerializedEvent {
  deviceId: string
  eventType: string
  eventName: string
  eventSequenceId: number
}

function makeEvent(
  deviceId: string = 'generated-device',
  uuid: string = 'uuid-1',
  forceLoginPending: boolean = true
): EventPersistence {
  let data: SerializedEvent = {
    deviceId: deviceId,
    eventType: 'CUSTOM',
    eventName: 'purchase',
    eventSequenceId: 7
  }
  return EventPersistence.fromDatabase(
    uuid, JSON.stringify(data), 'CUSTOM', '2.8.0', 'account', 'datasource', forceLoginPending
  )
}

function decodeJsonList(data: ArrayBuffer): SerializedEvent[] {
  let json = buffer.from(data).toString()
  return JSON.parse(json) as SerializedEvent[]
}

function decodeJson(data: ArrayBuffer): SerializedEvent {
  return decodeJsonList(data)[0]
}

export default function concurrentTests() {
  describe('processEvents_force_login_device_id', () => {
    it('json_should_replace_pending_event_and_preserve_source', 0, () => {
      let event = makeEvent()
      let source = event.data
      let result = processEvents([event], false, false, false, 'new-device')
      let decoded = decodeJson(result.serialize)
      let sentEvent = JSON.parse(result.sentEvents[0].data) as SerializedEvent
      expect(decoded.deviceId).assertEqual('new-device')
      expect(decoded.eventName).assertEqual('purchase')
      expect(decoded.eventSequenceId).assertEqual(7)
      expect(sentEvent.deviceId).assertEqual('new-device')
      expect(result.sentEvents[0].uuid).assertEqual(event.uuid)
      expect(event.data).assertEqual(source)
    })

    it('protobuf_should_replace_pending_event_and_preserve_source', 0, () => {
      let event = makeEvent()
      let source = event.data
      let result = processEvents([event], true, false, false, 'new-device')
      let decoded = event_pb.EventV3List.decode(new Uint8Array(result.serialize))
      let sentEvent = JSON.parse(result.sentEvents[0].data) as SerializedEvent
      expect(decoded.values.length).assertEqual(1)
      expect(decoded.values[0].deviceId).assertEqual('new-device')
      expect(decoded.values[0].eventName).assertEqual('purchase')
      expect(decoded.values[0].eventSequenceId).assertEqual(7)
      expect(sentEvent.deviceId).assertEqual('new-device')
      expect(result.sentEvents[0].uuid).assertEqual(event.uuid)
      expect(event.data).assertEqual(source)
    })

    it('json_should_keep_real_device_ids_and_reuse_events', 0, () => {
      // 未带待替换标志的事件（老版本遗留、上次启动已确认身份）均不改写
      let legacy = makeEvent('generated-device', 'uuid-legacy', false)
      let confirmed = makeEvent('previous-visitor', 'uuid-confirmed', false)
      let result = processEvents([legacy, confirmed], false, false, false, 'new-device')
      let decoded = decodeJsonList(result.serialize)
      expect(result.sentEvents[0] === legacy).assertTrue()
      expect(result.sentEvents[1] === confirmed).assertTrue()
      expect(decoded[0].deviceId).assertEqual('generated-device')
      expect(decoded[1].deviceId).assertEqual('previous-visitor')
    })

    it('protobuf_should_keep_real_device_ids_and_reuse_events', 0, () => {
      let legacy = makeEvent('generated-device', 'uuid-legacy', false)
      let confirmed = makeEvent('previous-visitor', 'uuid-confirmed', false)
      let result = processEvents([legacy, confirmed], true, false, false, 'new-device')
      let decoded = event_pb.EventV3List.decode(new Uint8Array(result.serialize))
      expect(result.sentEvents[0] === legacy).assertTrue()
      expect(result.sentEvents[1] === confirmed).assertTrue()
      expect(decoded.values.length).assertEqual(2)
      expect(decoded.values[0].deviceId).assertEqual('generated-device')
      expect(decoded.values[1].deviceId).assertEqual('previous-visitor')
    })

    it('mixed_batch_should_only_replace_pending_events', 0, () => {
      // 两条事件的 deviceId 相同，只按待替换标志区分
      let pending = makeEvent('generated-device', 'uuid-pending', true)
      let legacy = makeEvent('generated-device', 'uuid-legacy', false)
      let result = processEvents([pending, legacy], false, false, false, 'new-device')
      let decoded = decodeJsonList(result.serialize)
      expect(result.sentEvents.length).assertEqual(2)
      expect(result.sentEvents[0].forceLoginPending).assertFalse()
      expect(result.sentEvents[1] === legacy).assertTrue()
      expect(decoded[0].deviceId).assertEqual('new-device')
      expect(decoded[1].deviceId).assertEqual('generated-device')

      let pbResult = processEvents([pending, legacy], true, false, false, 'new-device')
      let pbDecoded = event_pb.EventV3List.decode(new Uint8Array(pbResult.serialize))
      expect(pbDecoded.values[0].deviceId).assertEqual('new-device')
      expect(pbDecoded.values[1].deviceId).assertEqual('generated-device')
    })

    it('without_replacement_should_keep_events_untouched', 0, () => {
      // SaaS/CDP 或未开启强制登录时不传替换值，带标志的事件也保持原样
      let event = makeEvent('generated-device')
      let result = processEvents([event], false, false)
      expect(result.sentEvents[0] === event).assertTrue()
      expect(decodeJson(result.serialize).deviceId).assertEqual('generated-device')
    })

    it('compressed_json_should_replace_pending_event', 0, () => {
      let result = processEvents([makeEvent()], false, true, false, 'new-device')
      let uncompressed = snappy.uncompress(result.serialize) as ArrayBuffer
      expect(decodeJson(uncompressed).deviceId).assertEqual('new-device')
    })
  })
}
