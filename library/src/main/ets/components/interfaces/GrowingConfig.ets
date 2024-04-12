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

export class GrowingConfig {
  accountId: string
  dataSourceId: string
  dataCollectionServerHost: string
  urlScheme: string

  debugEnabled: boolean = false
  sessionInterval: number = 30
  dataUploadInterval: number = 15
  dataCollectionEnabled: boolean = true
  idMappingEnabled: boolean = true
  encryptEnabled: boolean = false
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
    config.trackerId = this.trackerId

    return config
  }
}