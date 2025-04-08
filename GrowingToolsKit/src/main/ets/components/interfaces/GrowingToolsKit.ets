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

import bundleManager from '@ohos.bundle.bundleManager'
import common from '@ohos.app.ability.common'
import UIAbility from '@ohos.app.ability.UIAbility'
import window from '@ohos.window'
import rcp from '@hms.collaboration.rcp'
import EventDatabase from '../event/EventDatabase'
import EventPersistence from '../event/EventPersistence'
import { routeName } from '../pages/EntryIcon'
import { SUB_WINDOW_NAME, ENTRY_PADDING, Position, GTKColor, PREFERENCE_ENTRY_POSITION,
  GTKConfig, GTKEventPersistence } from '../utils/Constants'
import RequestPersistence from '../network/RequestPersistence'
import TrackersInfo from '../core/TrackersInfo'
import SharedPreferences from '../utils/SharedPreferences'

interface GrowingToolsKitOptions {
  x?: number
  y?: number
  useInRelease?: boolean
}

export class GrowingToolsKit {
  static debug: boolean = false
  static mainWindowStage: window.WindowStage | undefined = undefined
  static sdkConfig: GTKConfig
  static sdkVersion: string
  static sdkStartTime: number = 0
  static sdkEndTime: number = 0
  static gioKitStartTime: number = 0
  private _position: Position = { x: 0, y: 0 }
  static autotrackStatusFetcher: () => boolean
  static deferStart: boolean = false

  constructor(options?: GrowingToolsKitOptions) {
    let x = options?.x ?? vp2px(ENTRY_PADDING)
    let y = options?.y ?? 400
    let useInRelease = options?.useInRelease ? true : false

    this._position.x = x
    this._position.y = y
    if (GrowingToolsKit.gioKitStartTime == 0) {
      GrowingToolsKit.gioKitStartTime = Date.now()
    }

    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags)
    let appInfo = bundleInfo.appInfo
    GrowingToolsKit.debug = (appInfo?.debug || useInRelease)
  }

  static show(): Promise<void> {
    try {
      let subWindow = GrowingToolsKit._findGioKitWindow()
      if (subWindow) {
        return subWindow.showWindow()
      } else {
        return Promise.resolve()
      }
    } catch (e) {
      return Promise.resolve()
    }
  }

  static minimize(): Promise<void> {
    try {
      let subWindow = GrowingToolsKit._findGioKitWindow()
      if (subWindow) {
        return subWindow.minimize()
      } else {
        return Promise.resolve()
      }
    } catch (e) {
      return Promise.resolve()
    }
  }

  private static _findGioKitWindow(): window.Window | undefined {
    try {
      let subWindow = window.findWindow(SUB_WINDOW_NAME)
      return subWindow
    } catch (e) {
      return undefined
    }
  }

  onSDKWillInitialize() {
    if (!GrowingToolsKit.debug) {
      return
    }

    GrowingToolsKit.sdkStartTime = Date.now()
  }

  onSDKDidInitialize(config: GTKConfig, version: string) {
    if (!GrowingToolsKit.debug) {
      return
    }

    GrowingToolsKit.sdkEndTime = Date.now()
    GrowingToolsKit.sdkConfig = config.copy()
    GrowingToolsKit.sdkVersion = version
  }

  onStartSubTracker(trackerId: string, config: GTKConfig) {
    if (!GrowingToolsKit.debug) {
      return
    }

    TrackersInfo.push(trackerId, config)
  }

  setAutotrackStatusFetcher(fetcher: () => boolean) {
    GrowingToolsKit.autotrackStatusFetcher = fetcher
  }

  onDeferStart() {
    GrowingToolsKit.deferStart = true
  }

  // 暂时保留，兼容旧版本SDK(指版本<=2.1.0)
  onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage) {
    this.afterWindowStageCreate(ability.context, windowStage)
  }

  afterWindowStageCreate(context: common.UIAbilityContext, windowStage: window.WindowStage) {
    if (!GrowingToolsKit.debug) {
      return
    }

    if (GrowingToolsKit.mainWindowStage != undefined) {
      return
    }

    GrowingToolsKit.mainWindowStage = windowStage
    SharedPreferences.initWithContext(context)
    windowStage.createSubWindow(SUB_WINDOW_NAME).then(subWindow => {
      let localStorage = new LocalStorage()
      localStorage.setOrCreate(PREFERENCE_ENTRY_POSITION, this._position)
      subWindow.loadContentByName(routeName, localStorage).then(() => {
        subWindow.setWindowBackgroundColor(GTKColor.blackAlpha)
      })
      subWindow.moveWindowTo(this._position.x, this._position.y)
      subWindow.resize(vp2px(56), vp2px(56))
      subWindow.showWindow()
      subWindow.setWindowLayoutFullScreen(true)

      subWindow.on("windowEvent", (windowEvent) => {
        if (windowEvent == window.WindowEventType.WINDOW_ACTIVE) {
          window.shiftAppWindowFocus(
            subWindow.getWindowProperties().id,
            windowStage.getMainWindowSync().getWindowProperties().id
          )
        }
      })
    })

    EventDatabase.initDatabase(context)
  }

  onEventWroteToDisk(event: GTKEventPersistence, eventScene: number) {
    if (!GrowingToolsKit.debug) {
      return
    }

    let e = EventPersistence.fromEvent(event, eventScene)
    EventDatabase.writeEvent(e)
  }

  onEventsRemoveFromDisk(events: string[]) {
    if (!GrowingToolsKit.debug) {
      return
    }

    EventDatabase.updateEventsDidSend(events)
  }

  onResponseReceive(response: rcp.Response) {
    if (!GrowingToolsKit.debug) {
      return
    }

    let r = RequestPersistence.fromResponse(response)
    EventDatabase.writeRequest(r)
  }
}