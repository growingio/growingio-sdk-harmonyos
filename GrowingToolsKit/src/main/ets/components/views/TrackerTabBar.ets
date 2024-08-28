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

import TrackersInfo, { _TrackersInfo } from '../core/TrackersInfo'
import { GTKColor, MAIN_TRACKER_ID } from '../utils/Constants'

@ComponentV2
export default struct TrackerTabBar {
  @Consumer() trackerId: string = ''
  @Local subTrackerId: string = '子实例'

  build() {
    Row() {
      this.button('全部',
        () => this.trackerId == '' ? GTKColor.primaryTheme : GTKColor.secondaryTheme,
        () => {
        this.trackerId = ''

      })
      if (TrackersInfo.info.length > 0) {
        this.button('主实例',
          () => this.trackerId == MAIN_TRACKER_ID ? GTKColor.primaryTheme : GTKColor.secondaryTheme,
          () => {
          this.trackerId = MAIN_TRACKER_ID
        })
        Button(this.subTrackerId)
          .fontSize(14)
          .fontColor(GTKColor.primaryWhite)
          .backgroundColor(this.trackerId != '' && this.trackerId != MAIN_TRACKER_ID
            ? GTKColor.primaryTheme
            : GTKColor.secondaryTheme)
          .margin({ right: 5, top: 5, bottom: 5 })
          .bindMenu(this.menu)
      }
    }
    .justifyContent(FlexAlign.Start)
    .width('100%')
    .height(40)
    .padding({ left: 8, right: 8 })
  }

  @Builder
  menu() {
    Menu() {
      ForEach(TrackersInfo.info, (info: _TrackersInfo) => {
        MenuItem({ content: info.trackerId })
          .onClick(() => {
            this.trackerId = info.trackerId
            this.subTrackerId = info.trackerId
          })
      })
    }
  }

  @Builder
  button(title: string, color: () => ResourceColor, onClick: () => void) {
    Button(title)
      .fontSize(14)
      .fontColor(GTKColor.primaryWhite)
      .backgroundColor(color())
      .margin({ right: 5, top: 5, bottom: 5 })
      .onClick(onClick)
  }
}