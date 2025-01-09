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
import { ConfigMode, GTKColor, NAV_PATH_PREFIX, SUB_WINDOW_NAME } from '../utils/Constants'
import { HAR_VERSION } from '../../../../../BuildProfile'
import SharedPreferences from '../utils/SharedPreferences'
import EventDatabase from '../event/EventDatabase'
import { GrowingToolsKit } from '../interfaces/GrowingToolsKit'

import { Preferences, AutotrackEvent, CircleModule } from '@growingio/tools_circle'
import promptAction from '@ohos.promptAction'

@ComponentV2
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
                let destination = new NavPathInfo(NAV_PATH_PREFIX + 'SdkInfo', '')
                this.pageStack.pushDestination(destination)
              }
            })
          ModuleButton({ name: '事件库', image: 'app.media.growingtk_eventsList' })
            .onTouch(event => {
              if (event.type ==  TouchType.Up) {
                let destination = new NavPathInfo(NAV_PATH_PREFIX + 'EventsList', '')
                this.pageStack.pushDestination(destination)
              }
            })
          // ModuleButton({ name: '实时事件', image: 'app.media.growingtk_realtime' })
          //   .onTouch(event => {
          //     if (event.type ==  TouchType.Up) {
          //       let destination = new NavPathInfo(NAV_PATH_PREFIX + 'Realtime', '')
          //       this.pageStack.pushDestination(destination)
          //     }
          //   })
          ModuleButton({ name: '网络记录', image: 'app.media.growingtk_netFlow' })
            .onTouch(event => {
              if (event.type ==  TouchType.Up) {
                let destination = new NavPathInfo(NAV_PATH_PREFIX + 'NetFlow', '')
                this.pageStack.pushDestination(destination)
              }
            })
          ModuleButton({ name: '圈选', image: 'app.media.growingtk_circle' })
            .onTouch(event => {
              if (event.type ==  TouchType.Up) {
                let config = GrowingToolsKit.sdkConfig
                if (config.mode != ConfigMode.NewSaaS) {
                  promptAction.showToast({ message: '圈选功能仅支持 NewSaaS 模式下' })
                  return
                }

                CircleModule.initModule({
                  dataSourceId: GrowingToolsKit.sdkConfig.dataSourceId,
                  preferences: SharedPreferences.shared as Preferences,
                  recentAutotrackEventsGetter: async (count: number) => {
                    let events = await EventDatabase.getEventsByCount(
                      count,
                      0,
                      GrowingToolsKit.sdkConfig.accountId,
                      GrowingToolsKit.sdkConfig.dataSourceId,
                      ['PAGE', 'VIEW_CLICK', 'VIEW_CHANGE']
                    )
                    let autotrackEvents: Array<AutotrackEvent> = []
                    for (let event of events) {
                      let e = event.getEvent()
                      autotrackEvents.push(e)
                    }
                    return autotrackEvents
                  }
                })

                if (CircleModule.isLogin()) {
                  let destination = new NavPathInfo(NAV_PATH_PREFIX + 'CircleList', '')
                  this.pageStack.pushDestination(destination)
                } else {
                  let destination = new NavPathInfo(NAV_PATH_PREFIX + 'Login', '')
                  this.pageStack.pushDestination(destination)
                }
              }
            })
        }
        Row() {
          Text('当前版本：' + HAR_VERSION)
        }
        .margin({top: 50})
        .justifyContent(FlexAlign.Center)
        .backgroundColor(GTKColor.tertiaryBlack)
        .width('100%')
        .height(40)
      }
    }
    .onBackPressed(() => {
      this.pageStack.pop('', false)
      return true
    })
  }
}