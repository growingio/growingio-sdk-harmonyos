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

import { GTKColor } from '../utils/Constants'

@ComponentV2
export struct NavTitle {
  @Require @Param title: string
  @Param isPopup: boolean = false
  @Param message: string = ''
  @Param confirm: string = ''
  @Event confirmHandler: () => void = () => {}
  @Local handlePopup: boolean = false

  build() {
    if (this.isPopup) {
      Text(this.title)
        .fontSize(20)
        .fontColor(GTKColor.primaryLabel)
        .fontWeight(FontWeight.Bold)
        .height('100%')
        .margin({left: 10})
        .gesture(
          LongPressGesture()
            .onAction((event: GestureEvent | undefined) => {
              if(event){
                this.handlePopup = !this.handlePopup
              }
            })
            .onActionEnd(() => {
            })
        )
        .bindPopup(this.handlePopup, {
          message: this.message,
          primaryButton: {
            value: this.confirm,
            action: () => {
              this.handlePopup = !this.handlePopup
              this.confirmHandler()
            }
          },
          onStateChange: (e) => {
            if (!e.isVisible) {
              this.handlePopup = false
            }
          }
        })
    } else {
      Text(this.title)
        .fontSize(20)
        .fontColor(GTKColor.primaryLabel)
        .fontWeight(FontWeight.Bold)
        .height('100%')
        .margin({left: 10})
    }
  }
}