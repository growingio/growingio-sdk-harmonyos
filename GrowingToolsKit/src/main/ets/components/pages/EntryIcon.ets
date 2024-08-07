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

import window from '@ohos.window'
import display from '@ohos.display'
import { ENTRY_MARGIN, ENTRY_PADDING, Position } from '../utils/Constants'

export const routeName: string = "EntryIcon"
@Entry({ routeName: routeName, storage: LocalStorage.getShared() })
@Component
struct EntryIcon {
  @LocalStorageProp('position') windowPosition: Position = { x: 0, y: 0 }
  window: window.Window = window.findWindow('GrowingToolsKit')
  _entrySideLength: number = 0
  entrySideLength(): number {
    if (this._entrySideLength > 0) {
      return this._entrySideLength
    }
    return px2vp(this.window.getWindowProperties().windowRect.width)
  }

  build() {
    Button() {
        Image($r('app.media.growingtk_logo'))
          .backgroundColor('#FF9167')
          .borderRadius(this.entrySideLength() / 2 - ENTRY_MARGIN)
          .width(this.entrySideLength() - ENTRY_MARGIN * 2)
          .height(this.entrySideLength() - ENTRY_MARGIN * 2)
    }
    .backgroundColor('#FC5F3A')
    .borderRadius(this.entrySideLength() / 2)
    .width(this.entrySideLength())
    .height(this.entrySideLength())
    .onClick(event => {

    })
    .gesture(
      PanGesture(new PanGestureOptions({ direction: PanDirection.All }))
        .onActionStart(event => {
        })
        .onActionUpdate(event => {
          this.windowPosition.x += event.offsetX
          this.windowPosition.y += event.offsetY

          this.window.moveWindowTo(this.windowPosition.x, this.windowPosition.y)
        })
        .onActionEnd(event => {
          let screenWidth = display.getDefaultDisplaySync().width
          let screenHeight = display.getDefaultDisplaySync().height
          let entryWidth = this.window.getWindowProperties().windowRect.width
          let padding = vp2px(ENTRY_PADDING)

          let windowStage = AppStorage.get<window.WindowStage>('windowStage')
          let mainWindow = windowStage!.getMainWindowSync()
          let avoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
          let avoidTop = Math.max(avoidArea.topRect.height, 126)
          let avoidBottom = Math.max(avoidArea.bottomRect.height, 100)

          let minY = avoidTop + padding
          let maxY = screenHeight - avoidBottom - entryWidth - padding
          if (this.windowPosition.y > maxY) {
            this.windowPosition.y = maxY
          } else if (this.windowPosition.y < minY) {
            this.windowPosition.y = minY
          }

          let minX = padding
          let maxX = screenWidth - entryWidth - padding
          if (this.windowPosition.x > screenWidth / 2) {
            this.windowPosition.x = maxX
          } else {
            this.windowPosition.x = minX
          }

          if (this.window) {
            this.window.moveWindowTo(this.windowPosition.x, this.windowPosition.y)
          }
        })
        .onActionCancel(() => {

        })
    )
  }
}
