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
import {
  SUB_WINDOW_NAME,
  ENTRY_MARGIN,
  ENTRY_PADDING,
  Position,
  NAV_PATH_PREFIX,
  PREFERENCE_ENTRY_POSITION,
  GTKColor} from '../utils/Constants'
import Home from './Home'
import SdkInfo from './SdkInfo'
import EventsList from './EventsList'
import Realtime from './Realtime'
import NetFlow from './NetFlow'
import NavStackManager from '../core/NavStackManager'
import { GrowingToolsKit } from '../interfaces/GrowingToolsKit'

export const routeName: string = "EntryIcon"
@Entry({ routeName: routeName, storage: LocalStorage.getShared() })
@Component
struct EntryIcon {
  pageStack: NavPathStack = NavStackManager.pageStack
  @LocalStorageProp(PREFERENCE_ENTRY_POSITION) windowPosition: Position = { x: 0, y: 0 }
  entrySideLength: number = 56

  _mainWindow: window.Window | undefined = undefined
  mainWindow(): window.Window {
    if (this._mainWindow == undefined) {
      let windowStage = GrowingToolsKit.mainWindowStage
      this._mainWindow = windowStage!.getMainWindowSync()
    }

    return this._mainWindow
  }

  _window: window.Window | undefined = undefined
  subWindow(): window.Window {
    if (this._window == undefined) {
      this._window = window.findWindow(SUB_WINDOW_NAME)
    }

    return this._window
  }


  removePrefixForPathIfExist(path: string): string {
    if (path.startsWith(NAV_PATH_PREFIX)) {
      return path.slice(NAV_PATH_PREFIX.length)
    }
    return path
  }

  @Builder
  pagesMap(name: string, param: object) {
    if (this.removePrefixForPathIfExist(name) == 'Home') {
      Home()
    } else if (this.removePrefixForPathIfExist(name) == 'SdkInfo') {
      SdkInfo()
    } else if (this.removePrefixForPathIfExist(name) == 'EventsList') {
      EventsList()
    } else if (this.removePrefixForPathIfExist(name) == 'Realtime') {
      Realtime()
    } else if (this.removePrefixForPathIfExist(name) == 'NetFlow') {
      NetFlow()
    }
  }

  build() {
    Navigation(this.pageStack) {
        Button() {
          Image($r('app.media.growingtk_logo'))
            .backgroundColor(GTKColor.secondaryTheme)
            .borderRadius(this.entrySideLength / 2 - ENTRY_MARGIN)
            .width(this.entrySideLength - ENTRY_MARGIN * 2)
            .height(this.entrySideLength - ENTRY_MARGIN * 2)
        }
        .backgroundColor(GTKColor.primaryTheme)
        .borderRadius(this.entrySideLength / 2)
        .width(this.entrySideLength)
        .height(this.entrySideLength)
        .onClick(event => {
          let subWindow = this.subWindow()
          if (canIUse('SystemCapability.Window.SessionManager')) {
            subWindow.minimize()
          }
          let screenWidth = display.getDefaultDisplaySync().width
          let screenHeight = display.getDefaultDisplaySync().height
          let avoidArea = this.mainWindow().getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
          let avoidTop = Math.max(avoidArea.topRect.height, 126)

          subWindow.moveWindowTo(0, avoidTop)
          let curSizeWidth = subWindow.getWindowProperties().windowRect.width
          let curSizeHeight = subWindow.getWindowProperties().windowRect.height
          subWindow.resize(screenWidth, screenHeight - avoidTop).then(() => {
            let destination = new NavPathInfo(NAV_PATH_PREFIX + 'Home', '', popInfo => {
              subWindow.moveWindowTo(this.windowPosition.x, this.windowPosition.y)
              subWindow.resize(curSizeWidth, curSizeHeight)
            })
            this.pageStack.pushDestination(destination, false).then(() => {
              subWindow.showWindow()
            })
          })
        })
        .gesture(
          PanGesture(new PanGestureOptions({ direction: PanDirection.All }))
            .onActionStart(event => {
            })
            .onActionUpdate(event => {
              this.windowPosition.x += event.offsetX
              this.windowPosition.y += event.offsetY

              this.subWindow().moveWindowTo(this.windowPosition.x, this.windowPosition.y)
            })
            .onActionEnd(event => {
              let subWindow = this.subWindow()
              let screenWidth = display.getDefaultDisplaySync().width
              let screenHeight = display.getDefaultDisplaySync().height
              let entryWidth = subWindow.getWindowProperties().windowRect.width
              let padding = vp2px(ENTRY_PADDING)
              let avoidArea = this.mainWindow().getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
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
              if (this.windowPosition.x > (screenWidth - entryWidth) / 2) {
                this.windowPosition.x = maxX
              } else {
                this.windowPosition.x = minX
              }

              subWindow.moveWindowTo(this.windowPosition.x, this.windowPosition.y)
            })
            .onActionCancel(() => {

            })
        )
      }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.pagesMap)
  }
}
