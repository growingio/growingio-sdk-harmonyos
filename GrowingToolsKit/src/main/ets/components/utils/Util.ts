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

import buffer from '@ohos.buffer'
import snappy from 'snappyjs'
import util from '@ohos.util'

export default class Util {
  static isRequestCompress(requestHeaders: string): boolean {
    let headers = JSON.parse(requestHeaders)
    return headers['X-Compress-Codec'] == '2'
  }

  static isRequestEncrypt(requestHeaders: string): boolean {
    let headers = JSON.parse(requestHeaders)
    return headers['X-Crypt-Codec'] == '1'
  }

  static getTimestamp(requestHeaders: string): number {
    let headers = JSON.parse(requestHeaders)
    return Number(headers['X-Timestamp'])
  }

  static getRequestBodyText(requestHeaders: string, requestBody: string | ArrayBuffer): string {
    try {
      let result = requestBody
      if (typeof result != 'string') {
        if (Util.isRequestEncrypt(requestHeaders)) {
          result = Util.decrypt(requestHeaders, result, Util.getTimestamp(requestHeaders))
        }

        if (Util.isRequestCompress(requestHeaders)) {
          result = Util.decompress(result as ArrayBuffer)
        }
      }
      return JSON.stringify(JSON.parse(result as string), null, 4)
    } catch (e) {
      return ''
    }
  }

  static decompress(serialize: ArrayBuffer): string {
    if (!(serialize instanceof ArrayBuffer)) {
      throw new TypeError('[GrowingToolsKit] Argument decompressed must be type of ArrayBuffer')
    }

    let decompressed = new Uint8Array(snappy.uncompress(serialize))
    return new util.TextDecoder().decodeWithStream(decompressed)
  }

  static decrypt(requestHeaders: string, serialize: ArrayBuffer, time: number): string | ArrayBuffer {
    let isString: boolean = false
    if (!Util.isRequestCompress(requestHeaders)) {
      isString = true
    }

    let buf: ArrayBuffer = serialize
    let hint = Util.getHintFromTime(time)
    let original = new Uint8Array(buf)
    let decrypted = new Uint8Array(buf.byteLength)
    for (let i = 0; i < original.length; i++) {
      decrypted[i] = original[i] ^ hint[i % hint.length]
    }

    if (isString) {
      return new util.TextDecoder().decodeWithStream(decrypted)
    } else {
      return buffer.from(decrypted).buffer
    }
  }

  static getHintFromTime(time: number): Uint8Array {
    let hexString: string = time.toString(16)
    let lastByteHex: string = hexString.slice(-2)
    let lastByte: number = parseInt(lastByteHex, 16)
    return new Uint8Array([lastByte])
  }
}