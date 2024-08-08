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
import ModuleButton from '../views/ModuleButton'
import NavStackManager from '../core/NavStackManager'
import { SUB_WINDOW_NAME } from '../utils/Constants'

@Component
export default struct Home {
  pageStack: NavPathStack = NavStackManager.pageStack
  window: window.Window = window.findWindow(SUB_WINDOW_NAME)

  build() {
    NavDestination() {
      Column() {
        Blank(10)
        Flex({justifyContent: FlexAlign.SpaceEvenly}) {
          ModuleButton({ name: 'SDK信息', image: 'app.media.growingtk_sdkInfo' })
            .onTouch(event => {
              if (event.type ==  TouchType.Up) {
                let destination = new NavPathInfo('SdkInfo', '')
                this.pageStack.pushDestination(destination)
              }
            })
          ModuleButton({ name: '事件库', image: 'app.media.growingtk_eventsList' })
            .onTouch(event => {
              if (event.type ==  TouchType.Up) {
                let destination = new NavPathInfo('EventsList', '')
                this.pageStack.pushDestination(destination)
              }
            })
          ModuleButton({ name: '实时事件', image: 'app.media.growingtk_realtime' })
            .onTouch(event => {
              if (event.type ==  TouchType.Up) {
                let destination = new NavPathInfo('Realtime', '')
                this.pageStack.pushDestination(destination)
              }
            })
          ModuleButton({ name: '网络记录', image: 'app.media.growingtk_netFlow' })
            .onTouch(event => {
              if (event.type ==  TouchType.Up) {
                let destination = new NavPathInfo('NetFlow', '')
                this.pageStack.pushDestination(destination)
              }
            })
        }
      }
    }
    .onBackPressed(() => {
      this.pageStack.pop('', false)
      return true
    })
  }
}