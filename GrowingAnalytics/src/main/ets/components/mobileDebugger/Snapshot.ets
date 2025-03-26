/**
 * @license
 * Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.
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

import uiObserver from '@ohos.arkui.observer'
import image from '@ohos.multimedia.image'
import buffer from '@ohos.buffer'
import { BusinessError } from '@ohos.base'

import AnalyticsCore from "../core/AnalyticsCore"

export class SnapshotProvider {
  sendSnapshot: (screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) => void
  observer?: DidLayoutObserver
  timer?: number
  lastRefreshTime: number = 0
  snapshotKey: number = 0
  onScroll: boolean = false

  constructor(sendSnapshot: (screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) => void) {
    this.sendSnapshot = sendSnapshot
  }

  startObserver() {
    if (this.observer) {
      return
    }

    let didLayoutCallback = () => {
      this.refreshSnapshotIfNeeded()
    }
    let onScrollEventCallback = (info: uiObserver.ScrollEventInfo) => {
      this.onScroll = info.scrollEvent == uiObserver.ScrollEventType.SCROLL_START
    }

    this.observer = new DidLayoutObserver(didLayoutCallback, onScrollEventCallback)
    this.observer.on()
    this.refreshSnapshotIfNeeded()
  }

  stopObserver() {
    if (this.observer) {
      this.observer.off()
      this.observer = undefined
    }

    if (this.timer) {
      clearTimeout(this.timer)
      this.timer = undefined
    }
  }

  refreshSnapshotIfNeeded() {
    if (!this.observer) {
      return
    }

    if (this.timer) {
      clearTimeout(this.timer)
      this.timer = undefined
    }

    let separateTime = 1000
    if (Date.now() - this.lastRefreshTime > separateTime) {
      this.lastRefreshTime = Date.now()
      this.refreshSnapshot()
    } else {
      this.timer = setTimeout(() => {
        // clearTimeout 实测会可能性失效，此处加上保护性判断
        if (Date.now() - this.lastRefreshTime < separateTime) {
          return
        }

        this.lastRefreshTime = Date.now()
        this.refreshSnapshot()
      }, separateTime)
    }
  }

  onDomChanged() {
    this.refreshSnapshotIfNeeded()
  }

  refreshSnapshot() {
    if (this.onScroll) {
      return
    }
    AnalyticsCore.mainWindow.snapshot((error: BusinessError, pixmap: image.PixelMap) => {
      let errCode = error.code
      if (errCode) {
        return
      }
      let size = pixmap.getImageInfoSync().size
      this.pixmapToBase64(pixmap).then(snapshot => {
        pixmap.release()
        this.snapshotKey += 1
        this.sendSnapshot(px2vp(size.width), px2vp(size.height), this.snapshotKey, snapshot)
      })
    })
  }

  pixmapToBase64(pixmap: image.PixelMap): Promise<string> {
    let packOpts: image.PackingOption = { format: 'image/jpeg', quality: 50 }
    let imagePackerApi = image.createImagePacker()
    return imagePackerApi.packing(pixmap, packOpts).then((data: ArrayBuffer) => {
      let result = buffer.from(data).toString('base64')
      result = 'data:image/jpeg;base64,' + result
      return result
    }).catch((e: Error) => {
      throw e
    });
  }
}

class DidLayoutObserver {
  didLayoutCallback: () => void
  onScrollEventCallback: (info: uiObserver.ScrollEventInfo) => void

  constructor(didLayoutCallback: () => void, onScrollEventCallback: (info: uiObserver.ScrollEventInfo) => void) {
    this.didLayoutCallback = didLayoutCallback
    this.onScrollEventCallback = onScrollEventCallback
  }

  on() {
    AnalyticsCore.uiContent.getUIObserver().on('didLayout', this.didLayoutCallback)
    AnalyticsCore.uiContent.getUIObserver().on('scrollEvent', this.onScrollEventCallback)
  }

  off() {
    AnalyticsCore.uiContent.getUIObserver().off('didLayout', this.didLayoutCallback)
    AnalyticsCore.uiContent.getUIObserver().off('scrollEvent', this.onScrollEventCallback)
  }
}