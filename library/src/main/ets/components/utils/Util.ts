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
import buffer from '@ohos.buffer'
import snappy from 'snappyjs'

export default class Util {
  static mapToObject(map: Map<string, ValueType>): { [key: string]: ValueType } {
    const object: { [key: string]: ValueType } = {}
    map.forEach((value, key) => {
      object[key] = value
    })
    return object
  }

  static concatObject(objA: AttributesType, objB: AttributesType): AttributesType {
    return { ...objA, ...objB }
  }

  static removeKeysForObject(keys: string[], obj: AttributesType) {
    keys.forEach((key) => {
      delete obj[key]
    })
  }

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

  static compress(serialize: string): ArrayBuffer {
    if (typeof serialize != 'string') {
      throw new TypeError('[GrowingAnalytics] Argument compressed must be type of string')
    }

    let buf: ArrayBuffer = buffer.from(serialize, 'utf-8').buffer
    let compressed = snappy.compress(buf) as ArrayBuffer
    return compressed
  }

  static encrypt(serialize: string | ArrayBuffer, time: number): ArrayBuffer {
    let isString: boolean = false
    if (typeof serialize == 'string') {
      isString = true
    } else if (serialize instanceof ArrayBuffer) {
      isString = false
    } else {
      throw new TypeError('[GrowingAnalytics] Argument encrypted must be type of string or ArrayBuffer')
    }

    let buf: ArrayBuffer
    if (isString) {
      buf = buffer.from(serialize as string, 'utf-8').buffer
    } else {
      buf = serialize as ArrayBuffer
    }

    let hint = Util.getHintFromTime(time)
    let original = new Uint8Array(buf)
    let encrypted = new Uint8Array(buf.byteLength)
    for (let i = 0; i < original.length; i++) {
      encrypted[i] = original[i] ^ hint[i % hint.length]
    }

    return buffer.from(encrypted).buffer
  }
}