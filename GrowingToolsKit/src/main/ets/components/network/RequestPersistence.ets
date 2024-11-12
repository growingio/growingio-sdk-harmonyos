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

import rcp from '@hms.collaboration.rcp'
import buffer from '@ohos.buffer'
import util from '@ohos.util'

class RequestPersistenceInfo {
  url: string = ''
  method: string = ''
  requestHeader: string = ''
  responseHeader: string = ''
  statusCode: number = 0
  totalDuration: number = 0
  startTimestamp: number = 0

  static fromResponse(response: rcp.Response): RequestPersistenceInfo {
    let info = new RequestPersistenceInfo()
    info.url = response.request.url.toString()
    info.method = response.request.method
    info.requestHeader = JSON.stringify(response.request.headers)
    info.responseHeader = JSON.stringify(response.headers)
    info.statusCode = response.statusCode
    info.totalDuration = response.timeInfo!.totalTimeMs
    info.startTimestamp = Math.floor(Date.now() - info.totalDuration)
    return info
  }

  static fromJsonString(jsonString: string): RequestPersistenceInfo {
    let json = JSON.parse(jsonString) as RequestPersistenceInfo
    let info = new RequestPersistenceInfo()
    info.url = json.url
    info.method = json.method
    info.requestHeader = json.requestHeader
    info.responseHeader = json.responseHeader
    info.statusCode = json.statusCode
    info.totalDuration = json.totalDuration
    info.startTimestamp = json.startTimestamp
    return info
  }

  get status(): string {
    let status = ''
    switch (this.statusCode) {
      case 200:
        status = 'OK'
        break
      case 201:
        status = 'Created'
        break
      case 202:
        status = 'Accepted'
        break
      case 204:
        status = 'No Content'
        break
      case 300:
        status = 'Multiple Choices'
        break
      case 301:
        status = 'Moved Permanently'
        break
      case 302:
        status = 'Found'
        break
      case 303:
        status = 'See Other'
        break
      case 304:
        status = 'Not Modified'
        break
      case 307:
        status = 'Temporary Redirect'
        break
      case 400:
        status = 'Bad Request'
        break
      case 401:
        status = 'Unauthorized'
        break
      case 403:
        status = 'Forbidden'
        break
      case 404:
        status = 'Not Found'
        break
      case 405:
        status = 'Method Not Allowed'
        break
      case 409:
        status = 'Conflict'
        break
      case 412:
        status = 'Precondition Failed'
        break
      case 422:
        status = 'UnProcessable Entity'
        break
      case 500:
        status = 'Server Error'
        break
      case 502:
        status = 'Bad Gateway'
        break
      case 503:
        status = 'Service Unavailable'
        break
      default:
        status = 'Unknown'
        break
    }
    return status
  }

  get time(): string {
    let date = new Date(this.startTimestamp)
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    const seconds = date.getSeconds().toString().padStart(2, '0')
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
  }

  get day(): string {
    let date = new Date(this.startTimestamp)
    return date.toISOString().split('T')[0]
  }
}

export default class RequestPersistence {
  info: RequestPersistenceInfo
  uuid: string = ''
  requestBody: ArrayBuffer = new ArrayBuffer(0)
  responseBody?: ArrayBuffer

  constructor(info: RequestPersistenceInfo) {
    this.info = info
  }

  static fromResponse(response: rcp.Response): RequestPersistence {
    let info = RequestPersistenceInfo.fromResponse(response)
    let r = new RequestPersistence(info)
    r.uuid = util.generateRandomUUID(false)
    let requestBody = response.request.content as string | ArrayBuffer
    // 兼容旧版本，可能使用 string 对象作为 requestBody
    if (typeof requestBody == 'string') {
      requestBody = buffer.from(requestBody, 'utf-8').buffer
    }
    r.requestBody = requestBody
    r.responseBody = response.body
    return r
  }

  static fromDatabase(
    infoByJsonString: string,
    uuid: string,
    requestBody: string | ArrayBuffer,
    responseBody?: ArrayBuffer
  ): RequestPersistence {
    let info = RequestPersistenceInfo.fromJsonString(infoByJsonString)
    let r = new RequestPersistence(info)
    r.uuid = uuid
    // 兼容旧版本，可能使用 string 对象作为 requestBody
    if (typeof requestBody == 'string') {
      requestBody = buffer.from(requestBody, 'utf-8').buffer
    }
    r.requestBody = requestBody
    r.responseBody = responseBody
    return r
  }

  get requestBodyLength(): number {
    if (this.requestBody) {
      if (typeof this.requestBody == 'string') {
        return (this.requestBody as string).length
      } else {
        return (this.requestBody as ArrayBuffer).byteLength
      }
    }
    return 0
  }

  get uploadFlow(): number {
    return this.requestBodyLength + this.info.requestHeader.length
  }

  get downFlow(): number {
    return this.responseBodyLength + this.info.responseHeader.length
  }

  get responseBodyLength(): number {
    if (this.responseBody) {
      return this.responseBody.byteLength
    }
    return 0
  }
}