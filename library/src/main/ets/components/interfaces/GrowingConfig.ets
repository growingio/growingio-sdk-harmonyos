/**
 * @license
 * Copyright (C) 2023 Beijing Yishu Technology Co., Ltd.
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

class RequestOptions {
  _connectTimeout: number = 30000
  _readTimeout: number = 30000

  set connectTimeout(timeout: number) {
    timeout = Math.max(1, Math.min(timeout, 60)) * 1000
    this._connectTimeout = timeout
  }

  get connectTimeout(): number {
    return this._connectTimeout / 1000
  }

  set readTimeout(timeout: number) {
    timeout = Math.max(1, Math.min(timeout, 60)) * 1000
    this._readTimeout = timeout
  }

  get readTimeout(): number {
    return this._readTimeout / 1000
  }

  copy(): RequestOptions {
    let options = new RequestOptions()
    options.connectTimeout = this.connectTimeout
    options.readTimeout = this.readTimeout
    return options
  }
}

export class GrowingConfig {
  accountId: string
  dataSourceId: string
  dataCollectionServerHost: string
  urlScheme: string
  debugEnabled: boolean = false
  _sessionInterval: number = 30000
  _dataUploadInterval: number = 15000
  dataCollectionEnabled: boolean = true
  idMappingEnabled: boolean = false
  encryptEnabled: boolean = false
  requestOptions: RequestOptions = new RequestOptions()
  trackerId: string = ''

  constructor(
    accountId: string,
    dataSourceId: string,
    urlScheme: string,
    dataCollectionServerHost: string = 'https://napi.growingio.com'
  ) {
    this.accountId = accountId
    this.dataSourceId = dataSourceId
    this.urlScheme = urlScheme
    this.dataCollectionServerHost = dataCollectionServerHost
  }

  set sessionInterval(interval: number) {
    if (interval <= 0) {
      return
    }
    this._sessionInterval = interval * 1000
  }

  get sessionInterval(): number {
    return this._sessionInterval / 1000
  }

  set dataUploadInterval(interval: number) {
    if (interval <= 0) {
      return
    }
    this._dataUploadInterval = interval * 1000
  }

  get dataUploadInterval(): number {
    return this._dataUploadInterval / 1000
  }

  copy(): GrowingConfig {
    let config = new GrowingConfig(
      this.accountId,
      this.dataSourceId,
      this.urlScheme,
      this.dataCollectionServerHost)

    config.debugEnabled = this.debugEnabled
    config.sessionInterval = this.sessionInterval
    config.dataUploadInterval = this.dataUploadInterval
    config.dataCollectionEnabled = this.dataCollectionEnabled
    config.idMappingEnabled = this.idMappingEnabled
    config.encryptEnabled = this.encryptEnabled
    config.requestOptions = this.requestOptions.copy()
    config.trackerId = this.trackerId

    return config
  }
}