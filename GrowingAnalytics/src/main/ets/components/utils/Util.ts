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

import { ValueType, AttributesType } from '../utils/Constants'
import { event_pb } from './protobuf/event_pb'
import buffer from '@ohos.buffer'
import snappy from 'snappyjs'

export default class Util {
  static cloneObject(obj: AttributesType): AttributesType {
    return { ...obj }
  }

  static serializableAttributes(attr: AttributesType): AttributesType | undefined {
    let result: AttributesType = {}
    Object.keys(attr).forEach(key => {
      let value = attr[key] as ValueType
      if (Array.isArray(value)) {
        let stringValue = value.map(String).join('||')
        result[key] = stringValue
      } else {
        result[key] = String(value)
      }
    })
    return Object.keys(result).length > 0 ? result : undefined
  }

  static getHintFromTime(time: number): Uint8Array {
    let hexString: string = time.toString(16)
    let lastByteHex: string = hexString.slice(-2)
    let lastByte: number = parseInt(lastByteHex, 16)
    return new Uint8Array([lastByte])
  }

  static sizeOfEventString(serialize: string): number {
    let buf: ArrayBuffer = buffer.from(serialize, 'utf-8').buffer
    return buf.byteLength
  }

  static toSerialize(isProtobuf: boolean, events: any[]): ArrayBuffer {
    if (isProtobuf) {
      let values: event_pb.EventV3Dto[] = []
      events.forEach(e => {
        let event = JSON.parse(e.data)
        let dto = event_pb.EventV3Dto.fromObject(event)
        values.push(dto)
      })
      let list = event_pb.EventV3List.create({values: values})
      let arrayBuffer: Uint8Array = event_pb.EventV3List.encode(list).finish()
      return buffer.from(arrayBuffer).buffer
    } else {
      let json = '[' + events.map(event => String(event.data)).join(',') + ']'
      return buffer.from(json, 'utf-8').buffer
    }
  }

  static compress(serialize: ArrayBuffer): ArrayBuffer {
    let compressed = snappy.compress(serialize) as ArrayBuffer
    return compressed
  }

  static encrypt(serialize: ArrayBuffer, time: number): ArrayBuffer {
    let buf: ArrayBuffer = serialize
    let hint = Util.getHintFromTime(time)
    let original = new Uint8Array(buf)
    let encrypted = new Uint8Array(buf.byteLength)
    for (let i = 0; i < original.length; i++) {
      encrypted[i] = original[i] ^ hint[i % hint.length]
    }

    return buffer.from(encrypted).buffer
  }
}