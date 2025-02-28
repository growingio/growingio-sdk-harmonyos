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

export const ENTRY_PADDING = 5
export const ENTRY_MARGIN = 8
export const SUB_WINDOW_NAME = 'GrowingToolsKit'
export const NAV_PATH_PREFIX = '__GTK_'

export const PREFERENCE_NAME = 'growing_tools_sp'

export const DATABASE_NAME = 'growing_tools_enc_database'
export const MAIN_TRACKER_ID = '__GrowingAnalyticsCore'

export enum GTKColor {
  primaryTheme = '#FC5F3A',
  secondaryTheme = '#FF9167',
  tertiaryTheme = '#C22A0D',
  blackAlpha = '#00000000',
  primaryBlack = '#333333',
  secondaryBlack = '#666666',
  tertiaryBlack = '#DDDDDD',
  primaryWhite = '#FFFFFF',
  secondaryWhite = '#FFF2F2F7',
  primaryLabel = '#FF000000',
  secondaryLabel = '#993C3C43',
  primaryBackground = '#FFFFFF',
  secondaryBackground = '#F4F5F6',
  hybridTagLabel = '#FF5733',
  flutterTagLabel = '#027DFD',
}

export enum ConfigMode {
  NewSaaS = 0,
  SaaS,
  CDP
}

export interface RequestOptions {
  _connectTimeout: number
  _transferTimeout: number
}

export interface GTKConfig {
  mode: ConfigMode
  accountId: string
  dataSourceId: string
  dataCollectionServerHost: string
  urlScheme: string
  debugEnabled: boolean
  _sessionInterval: number
  _dataUploadInterval: number
  dataCollectionEnabled: boolean
  idMappingEnabled: boolean
  encryptEnabled: boolean
  compressEnabled: boolean
  requestOptions: RequestOptions
  _dataValidityPeriod: number
  autotrackEnabled: boolean
  autotrackAllPages: boolean
  useProtobuf: boolean
  copy(): GTKConfig
}

export interface GTKEventPersistence {
  uuid: string
  data: string
  eventType: string
  sdkVersion: string
  accountId: string
  dataSourceId: string
}

export enum EventScene {
  Native = 0,
  Hybrid,
  Flutter
}

export interface Position {
  x: number
  y: number
}
export const PREFERENCE_ENTRY_POSITION = 'growingtk_entry_position'
