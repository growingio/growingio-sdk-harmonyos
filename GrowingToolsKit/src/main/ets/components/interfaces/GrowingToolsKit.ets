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

import UIAbility from '@ohos.app.ability.UIAbility'
import window from '@ohos.window'
import { routeName } from '../pages/EntryIcon'
import { SUB_WINDOW_NAME, ENTRY_PADDING, Position } from '../utils/Constants'

export class GrowingToolsKit {
  static mainWindowStage: window.WindowStage | undefined = undefined
  private _position: Position = { x: 0, y: 0 }

  constructor(x: number = vp2px(ENTRY_PADDING), y: number = 400) {
    this._position.x = x
    this._position.y = y
  }

  onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage) {
    if (GrowingToolsKit.mainWindowStage != undefined) {
      return
    }

    GrowingToolsKit.mainWindowStage = windowStage
    windowStage.createSubWindow(SUB_WINDOW_NAME).then(window => {
      let localStorage = new LocalStorage()
      localStorage.setOrCreate('position', this._position)
      window.loadContentByName(routeName, localStorage).then(() => {
        window.setWindowBackgroundColor('#00000000')
      })
      window.moveWindowTo(this._position.x, this._position.y)
      window.resize(vp2px(56), vp2px(56))
      window.showWindow()
      window.setWindowLayoutFullScreen(true)
    })
  }
}