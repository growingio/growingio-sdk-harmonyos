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
 * GrowingToolsKit 色彩 token。深浅模式适配通过资源限定符
 * （resources/base/element/color.json + resources/dark/element/color.json）实现，
 * ArkUI 自动随系统颜色模式切换并重绘。
 *
 * 命名约定（历史保留，请按"语义/用途"而非"字面颜色"理解）：
 * - primaryBlack / secondaryBlack / tertiaryBlack：文字层级（主/次/占位与分隔），
 *   深色模式下值为浅色——名称仅源自浅色模式。
 * - primaryWhite / secondaryWhite：表面层（卡片/列表）背景，
 *   深色模式下值为深色（#232323 / #181818）——名称仅源自浅色模式。
 *   ⚠️ 仅用于 .backgroundColor()。品牌色背景上的"白字"请用 ArkUI 内置 Color.White（永远白），
 *   不要用 GTKColor.primaryWhite 作 .fontColor()——深色模式下会变成深字。
 * - primaryBackground / secondaryBackground：页面级背景。
 * - primaryLabel / secondaryLabel：对齐 iOS labelColor / secondaryLabelColor 系统色。
 * - primaryTheme / secondaryTheme / tertiaryTheme：品牌橙色（深浅模式相同）。
 * - hybridTagLabel / flutterTagLabel：事件类型标记色（深浅模式相同）。
 * - transparentBackground：完全透明（#00000000），非深浅色 token，
 *   用于 setWindowBackgroundColor 等只接受 string 的 API。
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
