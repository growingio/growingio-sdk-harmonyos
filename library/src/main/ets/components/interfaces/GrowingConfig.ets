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
  _connectTimeout: number = 30 * 1000
  _readTimeout: number = 30 * 1000

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
    options._connectTimeout = this._connectTimeout
    options._readTimeout = this._readTimeout
    return options
  }
}

export class GrowingConfig {
  accountId: string
  dataSourceId: string
  dataCollectionServerHost: string
  urlScheme: string
  debugEnabled: boolean = false
  _sessionInterval: number = 30 * 1000
  _dataUploadInterval: number = 15 * 1000
  dataCollectionEnabled: boolean = true
  idMappingEnabled: boolean = false
  encryptEnabled: boolean = false
  requestOptions: RequestOptions = new RequestOptions()
  _dataValidityPeriod: number = 7 * 86400000
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

  set dataValidityPeriod(days: number) {
    days = Math.max(3, Math.min(days, 30))
    this._dataValidityPeriod = days * 86400000
  }

  get dataValidityPeriod(): number {
    return this._dataValidityPeriod / 86400000
  }

  copy(): GrowingConfig {
    let config = new GrowingConfig(
      this.accountId,
      this.dataSourceId,
      this.urlScheme,
      this.dataCollectionServerHost)

    config.debugEnabled = this.debugEnabled
    config._sessionInterval = this._sessionInterval
    config._dataUploadInterval = this._dataUploadInterval
    config.dataCollectionEnabled = this.dataCollectionEnabled
    config.idMappingEnabled = this.idMappingEnabled
    config.encryptEnabled = this.encryptEnabled
    config.requestOptions = this.requestOptions.copy()
    config._dataValidityPeriod = this._dataValidityPeriod
    config.trackerId = this.trackerId

    return config
  }
}