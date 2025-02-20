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

import image from '@ohos.multimedia.image'
import buffer from '@ohos.buffer'
import { BusinessError } from '@ohos.base'

import AnalyticsCore from "../core/AnalyticsCore"

export class SnapshotProvider {
  sendSnapshot: (screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) => void
  observer?: DidLayoutObserver
  timer?: number
  snapshotKey: number = 0

  constructor(sendSnapshot: (screenWidth: number, screenHeight: number, snapshotKey: number, snapshot: string) => void) {
    this.sendSnapshot = sendSnapshot
  }

  startObserver() {
    if (this.observer) {
      return
    }

    this.observer = new DidLayoutObserver(() => {
      if (this.timer) {
        clearTimeout(this.timer)
        this.timer = undefined
      }
      this.timer = setTimeout(() => {
        this.needRefreshSnapshot()
      }, 300)
    })
    this.observer.on()
    this.needRefreshSnapshot()
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

  needRefreshSnapshot() {
    AnalyticsCore.mainWindow.snapshot((error: BusinessError, pixmap: image.PixelMap) => {
      let errCode = error.code
      if (errCode) {
        return
      }
      let size = pixmap.getImageInfoSync().size
      this.pixmapToBase64(pixmap).then(snapshot => {
        pixmap.release()
        if (!this.timer) {
          return
        }
        this.timer = undefined
        this.snapshotKey += 1
        this.sendSnapshot(px2vp(size.width), px2vp(size.height), this.snapshotKey, snapshot)
      })
    })
  }

  pixmapToBase64(pixmap: image.PixelMap): Promise<string> {
    let packOpts: image.PackingOption = { format: 'image/jpeg', quality: 98 }
    let imagePackerApi = image.createImagePacker()
    return imagePackerApi.packToData(pixmap, packOpts).then((data: ArrayBuffer) => {
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

  constructor(didLayoutCallback: () => void) {
    this.didLayoutCallback = didLayoutCallback
  }

  on() {
    AnalyticsCore.uiContent.getUIObserver().on('didLayout', this.didLayoutCallback)
  }

  off() {
    AnalyticsCore.uiContent.getUIObserver().off('didLayout', this.didLayoutCallback)
  }
}