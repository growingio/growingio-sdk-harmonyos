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

export enum ConfigMode {
  NewSaaS = 0,
  SaaS,
  CDP
}

export class GrowingConfig {
  mode: ConfigMode = ConfigMode.NewSaaS
  accountId: string = ''
  dataSourceId: string = ''
  dataCollectionServerHost: string = ''
  urlScheme: string = ''
  debugEnabled: boolean = false
  _sessionInterval: number = 30 * 1000
  _dataUploadInterval: number = 15 * 1000
  dataCollectionEnabled: boolean = true
  idMappingEnabled: boolean = false
  encryptEnabled: boolean = true
  compressEnabled: boolean = true
  requestOptions: RequestOptions = new RequestOptions()
  _dataValidityPeriod: number = 7 * 86400000
  trackerId: string = ''
  autotrackAllPages: boolean = false

  constructor() {}

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

  SaaS(
    accountId: string,
    urlScheme: string,
    dataCollectionServerHost: string = 'https://api.growingio.com'
  ): GrowingConfig {
    this.mode = ConfigMode.SaaS
    this.accountId = accountId
    this.urlScheme = urlScheme
    this.dataCollectionServerHost = dataCollectionServerHost
    return this
  }

  NewSaaS(
    accountId: string,
    dataSourceId: string,
    urlScheme: string,
    dataCollectionServerHost: string = 'https://napi.growingio.com'
  ): GrowingConfig {
    this.mode = ConfigMode.NewSaaS
    this.accountId = accountId
    this.dataSourceId = dataSourceId
    this.urlScheme = urlScheme
    this.dataCollectionServerHost = dataCollectionServerHost
    return this
  }

  CDP(
    accountId: string,
    dataSourceId: string,
    urlScheme: string,
    dataCollectionServerHost: string
  ): GrowingConfig {
    this.mode = ConfigMode.CDP
    this.accountId = accountId
    this.dataSourceId = dataSourceId
    this.urlScheme = urlScheme
    this.dataCollectionServerHost = dataCollectionServerHost
    return this
  }

  copy(): GrowingConfig {
    if (!(typeof this.accountId === 'string') || this.accountId.trim() === '') {
      throw new Error('[GrowingAnalytics] 请在初始化配置中传入 accountId')
    }

    if (this.mode === ConfigMode.NewSaaS || this.mode === ConfigMode.CDP) {
      if (!(typeof this.dataSourceId === 'string') || this.dataSourceId.trim() === '') {
        throw new Error('[GrowingAnalytics] 请在初始化配置中传入 dataSourceId')
      }
    }

    if (!(typeof this.urlScheme === 'string') || this.urlScheme.trim() === '') {
      throw new Error('[GrowingAnalytics] 请在初始化配置中传入 urlScheme')
    }

    if (!(typeof this.dataCollectionServerHost === 'string') || this.dataCollectionServerHost.trim() === '') {
      throw new Error('[GrowingAnalytics] 请在初始化配置中传入 dataCollectionServerHost')
    }

    let pattern = /^(https?:\/\/)((([a-zA-Z0-9\-]+\.)+[a-zA-Z]{2,})|(\d{1,3}\.){3}\d{1,3})(:\d+)?(\/[^\s]*)?$/
    if (!pattern.test(this.dataCollectionServerHost)) {
      throw new Error('[GrowingAnalytics] 请在初始化配置中传入正确的 dataCollectionServerHost')
    }

    let config = new GrowingConfig()
    config.mode = this.mode
    config.accountId = this.accountId
    config.dataSourceId = this.dataSourceId
    config.urlScheme = this.urlScheme
    config.dataCollectionServerHost = this.dataCollectionServerHost
    config.debugEnabled = this.debugEnabled
    config._sessionInterval = this._sessionInterval
    config._dataUploadInterval = this._dataUploadInterval
    config.dataCollectionEnabled = this.dataCollectionEnabled
    config.idMappingEnabled = this.idMappingEnabled
    config.encryptEnabled = this.encryptEnabled
    config.compressEnabled = this.compressEnabled
    config.requestOptions = this.requestOptions.copy()
    config._dataValidityPeriod = this._dataValidityPeriod
    config.trackerId = this.trackerId
    config.autotrackAllPages = this.autotrackAllPages

    return config
  }
}