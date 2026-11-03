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

function makeEvent(): EventPersistence {
  let data: SerializedEvent = {
    deviceId: 'old-device',
    eventType: 'CUSTOM',
    eventName: 'purchase',
    eventSequenceId: 7
  }
  return EventPersistence.fromDatabase('uuid-1', JSON.stringify(data), 'CUSTOM', '2.8.0', 'account', 'datasource')
}

function decodeJson(data: ArrayBuffer): SerializedEvent {
  let json = buffer.from(data).toString()
  let events = JSON.parse(json) as SerializedEvent[]
  return events[0]
}

export default function concurrentTests() {
  describe('processEvents_force_login_device_id', () => {
    it('json_should_replace_device_id_and_preserve_source', 0, () => {
      let event = makeEvent()
      let source = event.data
      let result = processEvents([event], false, false, false, 'new-device')
      let decoded = decodeJson(result.serialize)
      let sentEvent = JSON.parse(result.events[0].data) as SerializedEvent
      expect(decoded.deviceId).assertEqual('new-device')
      expect(decoded.eventName).assertEqual('purchase')
      expect(decoded.eventSequenceId).assertEqual(7)
      expect(sentEvent.deviceId).assertEqual('new-device')
      expect(result.events[0].uuid).assertEqual(event.uuid)
      expect(event.data).assertEqual(source)
    })

    it('json_without_override_should_keep_device_id', 0, () => {
      let result = processEvents([makeEvent()], false, false)
      expect(decodeJson(result.serialize).deviceId).assertEqual('old-device')
    })

    it('protobuf_should_replace_device_id_and_preserve_source', 0, () => {
      let event = makeEvent()
      let source = event.data
      let result = processEvents([event], true, false, false, 'new-device')
      let decoded = event_pb.EventV3List.decode(new Uint8Array(result.serialize))
      let sentEvent = JSON.parse(result.events[0].data) as SerializedEvent
      expect(decoded.values.length).assertEqual(1)
      expect(decoded.values[0].deviceId).assertEqual('new-device')
      expect(decoded.values[0].eventName).assertEqual('purchase')
      expect(decoded.values[0].eventSequenceId).assertEqual(7)
      expect(sentEvent.deviceId).assertEqual('new-device')
      expect(result.events[0].uuid).assertEqual(event.uuid)
      expect(event.data).assertEqual(source)
    })

    it('compressed_json_should_replace_device_id', 0, () => {
      let result = processEvents([makeEvent()], false, true, false, 'new-device')
      let uncompressed = snappy.uncompress(result.serialize) as ArrayBuffer
      expect(decodeJson(uncompressed).deviceId).assertEqual('new-device')
    })
  })
}
