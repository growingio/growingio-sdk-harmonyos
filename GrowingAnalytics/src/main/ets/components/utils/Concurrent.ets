/**
 * @license
 * Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.
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

import EventPersistence from "../event/EventPersistence"
import { LogUtil } from './LogUtil'
import snappy from 'snappyjs'
import { event_pb } from './protobuf/event_pb'

@Concurrent
export function processEvents(events: EventPersistence[], useProtobuf: boolean, compressEnabled: boolean): ArrayBuffer {
  let serialize: ArrayBuffer = new ArrayBuffer(0)
  if (useProtobuf) {
    let values: event_pb.EventV3Dto[] = []
    events.forEach(e => {
      try {
        let event = JSON.parse(e.data) as object
        let dto = event_pb.EventV3Dto.fromObject(event)
        values.push(dto)
      } catch (error) {
        LogUtil.error(() => 'Failed to parse event data: ' + error)
      }
    })
    try {
      let list = event_pb.EventV3List.create({values: values})
      let arrayBuffer: Uint8Array = event_pb.EventV3List.encode(list).finish()
      serialize = buffer.from(arrayBuffer).buffer
    } catch (error) {
      LogUtil.error(() => 'Failed to create protobuf: ' + error)
    }
  } else {
    try {
      let json = '[' + events.map(event => String(event.data)).join(',') + ']'
      serialize = buffer.from(json, 'utf-8').buffer
    } catch (error) {
      LogUtil.error(() => 'Failed to create JSON buffer: ' + error)
    }
  }

  if (compressEnabled) {
    try {
      serialize = snappy.compress(serialize) as ArrayBuffer
    } catch (error) {
      LogUtil.error(() => 'Failed to compress data: ' + error)
    }
  }

  return serialize
}