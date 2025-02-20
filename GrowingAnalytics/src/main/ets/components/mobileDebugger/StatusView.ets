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

import { ComponentContent } from '@ohos.arkui.node'
import display from '@ohos.display'
import { OverlayManager } from '@ohos.arkui.UIContext'
import window from '@ohos.window'
import promptAction from "@ohos.promptAction"

import AnalyticsCore from "../core/AnalyticsCore"

export class StatusView {
  overlayNode?: OverlayManager
  componentContent?: ComponentContent<Params>
  params?: Params

  constructor(text: string, onClick: () => void) {
    if (!AnalyticsCore.uiContent) {
      return
    }
    this.params = new Params(
      text,
      () => {
        this._update()
      },
      () => {
        onClick()
      })
    this.overlayNode = AnalyticsCore.uiContent.getOverlayManager()
    this.componentContent = new ComponentContent(
      AnalyticsCore.uiContent,
      wrapBuilder<[Params]>(builderStatusView),
      this.params
    )
    this.overlayNode.addComponentContent(this.componentContent)
  }

  static showDialog(options: promptAction.ShowDialogOptions): Promise<promptAction.ShowDialogSuccessResponse> {
    if (!AnalyticsCore.uiContent) {
      return Promise.reject(new Error('AnalyticsCore.uiContent is not available'))
    }
    try {
      let promptAction = AnalyticsCore.uiContent.getPromptAction()
      return promptAction.showDialog(options)
    } catch (error) {
      return Promise.reject(error)
    }
  }

  show() {
    this.overlayNode?.showComponentContent(this.componentContent)
  }

  hide() {
    this.overlayNode?.hideComponentContent(this.componentContent)
  }

  private _update() {
    this.componentContent?.update(this.params)
  }
}

class Params {
  text: string
  positionY: number
  offsetY: number
  updateComponent: () => void
  onClick: () => void

  constructor(text: string, updateComponent: () => void, onClick: () => void) {
    let screenHeight = display.getDefaultDisplaySync().height
    let avoidArea = AnalyticsCore.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    let avoidTop = Math.max(avoidArea.topRect.height, 150)
    let minY = px2vp(avoidTop - screenHeight / 2)

    this.positionY = minY
    this.offsetY = minY
    this.text = text
    this.updateComponent = updateComponent
    this.onClick = onClick
  }
}

@Builder
function builderStatusView(params: Params) {
  Column() {
    Text(params.text)
      .fontSize(15)
      .fontColor(Color.White)
  }
  .backgroundColor('#ff0c90c1')
  .width('100%')
  .offset({x: 0, y: params.offsetY})
  .gesture(
    PanGesture(new PanGestureOptions({ direction: PanDirection.Vertical }))
      .onActionStart(event => {
      })
      .onActionUpdate(event => {
        params.offsetY = params.positionY + event.offsetY
        params.updateComponent()
      })
      .onActionEnd(event => {
        let screenHeight = display.getDefaultDisplaySync().height
        let avoidArea = AnalyticsCore.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
        let avoidTop = Math.max(avoidArea.topRect.height, 150)
        let avoidBottom = Math.max(avoidArea.bottomRect.height, 150)

        let minY = px2vp(avoidTop - screenHeight / 2)
        let maxY = px2vp(screenHeight / 2 - avoidBottom - 15)
        if (params.offsetY > maxY) {
          params.offsetY = maxY
        } else if (params.offsetY < minY) {
          params.offsetY = minY
        }
        params.positionY = params.offsetY
        params.updateComponent()
      })
      .onActionCancel(() => {

      })
  )
  .onClick(() => {
    params.onClick()
  })
}