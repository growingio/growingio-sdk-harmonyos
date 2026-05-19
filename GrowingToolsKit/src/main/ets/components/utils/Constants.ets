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

/**
 * GrowingToolsKit 色彩 token。取值见 resources/{base,dark}/element/color.json，
 * ArkUI 自动随系统色彩模式切换。
 *
 * ⚠️ 命名沿用浅色模式：primaryBlack 在深色模式下是浅色，primaryWhite 反之。
 * ⚠️ primaryWhite 仅用作 .backgroundColor()；品牌色背景上的"白字"用 ArkUI 内置 Color.White。
 * ⚠️ transparentBackground 是 string 类型（其余为 Resource），用于 setWindowBackgroundColor 等只接受 string 的 API。
 */
interface GTKColorTokens {
  readonly primaryTheme: Resource
  readonly secondaryTheme: Resource
  readonly tertiaryTheme: Resource
  readonly primaryBlack: Resource
  readonly secondaryBlack: Resource
  readonly tertiaryBlack: Resource
  readonly primaryWhite: Resource
  readonly secondaryWhite: Resource
  readonly primaryLabel: Resource
  readonly secondaryLabel: Resource
  readonly primaryBackground: Resource
  readonly secondaryBackground: Resource
  readonly hybridTagLabel: Resource
  readonly flutterTagLabel: Resource
  readonly transparentBackground: string
}

export const GTKColor: GTKColorTokens = {
  primaryTheme:          $r('app.color.gtk_primaryTheme'),
  secondaryTheme:        $r('app.color.gtk_secondaryTheme'),
  tertiaryTheme:         $r('app.color.gtk_tertiaryTheme'),
  primaryBlack:          $r('app.color.gtk_primaryBlack'),
  secondaryBlack:        $r('app.color.gtk_secondaryBlack'),
  tertiaryBlack:         $r('app.color.gtk_tertiaryBlack'),
  primaryWhite:          $r('app.color.gtk_primaryWhite'),
  secondaryWhite:        $r('app.color.gtk_secondaryWhite'),
  primaryLabel:          $r('app.color.gtk_primaryLabel'),
  secondaryLabel:        $r('app.color.gtk_secondaryLabel'),
  primaryBackground:     $r('app.color.gtk_primaryBackground'),
  secondaryBackground:   $r('app.color.gtk_secondaryBackground'),
  hybridTagLabel:        $r('app.color.gtk_hybridTagLabel'),
  flutterTagLabel:       $r('app.color.gtk_flutterTagLabel'),
  transparentBackground: '#00000000',
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

// FPS 显示窗口尺寸常量
export const FPS_WINDOW_WIDTH = 160
export const FPS_WINDOW_HEIGHT = 80

// small icon 显示窗口尺寸常量
export const SMALL_ICON_WINDOW_SIDE_LENGTH = 56
