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
  GTKColor,
  FPS_WINDOW_WIDTH,
  FPS_WINDOW_HEIGHT,
  SMALL_ICON_WINDOW_SIDE_LENGTH} from '../utils/Constants'
import Home from './Home'
import SdkInfo from './SdkInfo'
import EventsList from './EventsList'
import Realtime from './Realtime'
import NetFlow from './NetFlow'
import FPSCanvas from './FPSCanvas'
import NavStackManager from '../core/NavStackManager'
import { GrowingToolsKit } from '../interfaces/GrowingToolsKit'

export const routeName: string = "EntryIcon"

export class EntryIconManager {
  private static instance: EntryIconManager
  private entryIconInstance: EntryIcon | null = null

  static getInstance(): EntryIconManager {
    if (!EntryIconManager.instance) {
      EntryIconManager.instance = new EntryIconManager()
    }
    return EntryIconManager.instance
  }

  setEntryIconInstance(instance: EntryIcon) {
    this.entryIconInstance = instance
  }

  enableFPSMode() {
    if (this.entryIconInstance) {
      this.entryIconInstance.enableFPSMode()
    }
  }

  disableFPSMode() {
    if (this.entryIconInstance) {
      this.entryIconInstance.disableFPSMode()
    }
  }

  isFPSEnabled(): boolean {
    if (this.entryIconInstance) {
      return this.entryIconInstance.isFPSMode
    }
    return false
  }
}

@Entry({ routeName: routeName, storage: LocalStorage.getShared() })
@Component
struct EntryIcon {
  pageStack: NavPathStack = NavStackManager.pageStack
  @LocalStorageProp(PREFERENCE_ENTRY_POSITION) windowPosition: Position = { x: 0, y: 0 }
  @State isFPSMode: boolean = false

  aboutToAppear() {
    EntryIconManager.getInstance().setEntryIconInstance(this)
  }

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

  enableFPSMode() {
    this.isFPSMode = true
  }

  disableFPSMode() {
    this.isFPSMode = false
  }

  private handleClick() {
    let subWindow = this.subWindow()
    let screenWidth = display.getDefaultDisplaySync().width
    let screenHeight = display.getDefaultDisplaySync().height
    let avoidArea = this.mainWindow().getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    let avoidTop = Math.max(avoidArea.topRect.height, 126)

    subWindow.moveWindowTo(0, avoidTop)
    subWindow.resize(screenWidth, screenHeight - avoidTop).then(() => {
      let destination = new NavPathInfo(NAV_PATH_PREFIX + 'Home', '', popInfo => {
        if (EntryIconManager.getInstance().isFPSEnabled()) {
          this.windowPosition.x = 20
          this.windowPosition.y = avoidTop + 20

          // FPS was enabled in Home, need to resize to large window
          subWindow.resize(vp2px(FPS_WINDOW_WIDTH), vp2px(FPS_WINDOW_HEIGHT))
        } else {
          // FPS not enabled, restore small icon
          subWindow.resize(vp2px(SMALL_ICON_WINDOW_SIDE_LENGTH), vp2px(SMALL_ICON_WINDOW_SIDE_LENGTH))
        }
        subWindow.moveWindowTo(this.windowPosition.x, this.windowPosition.y)
      })
      this.pageStack.pushDestination(destination, false)
    })
  }

  private onPanActionUpdate(event: GestureEvent) {
    this.windowPosition.x += event.offsetX
    this.windowPosition.y += event.offsetY
    this.subWindow().moveWindowTo(this.windowPosition.x, this.windowPosition.y)
  }

  private onPanActionEnd(event: GestureEvent) {
    let subWindow = this.subWindow()
    let screenWidth = display.getDefaultDisplaySync().width
    let screenHeight = display.getDefaultDisplaySync().height
    let entryWidth = subWindow.getWindowProperties().windowRect.width
    let entryHeight = subWindow.getWindowProperties().windowRect.height
    let padding = vp2px(ENTRY_PADDING)
    let avoidArea = this.mainWindow().getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    let avoidTop = Math.max(avoidArea.topRect.height, 126)
    let avoidBottom = Math.max(avoidArea.bottomRect.height, 100)

    let minY = avoidTop + padding
    let maxY = screenHeight - avoidBottom - entryHeight - padding
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
      if (this.isFPSMode) {
        // FPS display mode
        FPSCanvas()
        .onClick(() => {
          this.handleClick()
        })
        .gesture(PanGesture(new PanGestureOptions({ direction: PanDirection.All }))
          .onActionStart((e) => {
          })
          .onActionUpdate((e) => {
            this.onPanActionUpdate(e)
          })
          .onActionEnd((e) => {
            this.onPanActionEnd(e)
          })
          .onActionCancel(() => {
          }))
      } else {
        // Normal entry icon mode
        Button() {
          Image($r('app.media.growingtk_logo'))
            .backgroundColor(GTKColor.secondaryTheme)
            .borderRadius(SMALL_ICON_WINDOW_SIDE_LENGTH / 2 - ENTRY_MARGIN)
            .width(SMALL_ICON_WINDOW_SIDE_LENGTH - ENTRY_MARGIN * 2)
            .height(SMALL_ICON_WINDOW_SIDE_LENGTH - ENTRY_MARGIN * 2)
        }
        .backgroundColor(GTKColor.primaryTheme)
        .borderRadius(SMALL_ICON_WINDOW_SIDE_LENGTH / 2)
        .width(SMALL_ICON_WINDOW_SIDE_LENGTH)
        .height(SMALL_ICON_WINDOW_SIDE_LENGTH)
        .onClick(() => {
          this.handleClick()
        })
        .gesture(PanGesture(new PanGestureOptions({ direction: PanDirection.All }))
          .onActionStart((e) => {
          })
          .onActionUpdate((e) => {
            this.onPanActionUpdate(e)
          })
          .onActionEnd((e) => {
            this.onPanActionEnd(e)
          })
          .onActionCancel(() => {
          }))
      }
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.pagesMap)
  }
}
