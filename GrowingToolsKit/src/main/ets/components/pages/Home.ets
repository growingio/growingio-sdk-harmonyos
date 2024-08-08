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
import emitter from '@ohos.events.emitter'
import ModuleButton from '../views/ModuleButton'
import { EMIT_EVENT_MODULE_BUTTON_ON_CLICK, SUB_WINDOW_NAME } from '../utils/Constants'

enum ModuleType {
  sdkInfo,
  eventsList,
  realtime,
  netFlow
}

@Component
export default struct Home {
  @Consume('pathStack') pathStack: NavPathStack
  window: window.Window = window.findWindow(SUB_WINDOW_NAME)

  aboutToAppear(): void {
    emitter.on({eventId: EMIT_EVENT_MODULE_BUTTON_ON_CLICK}, this.moduleOnClick)
  }

  aboutToDisappear(): void {
    emitter.off(EMIT_EVENT_MODULE_BUTTON_ON_CLICK)
  }

  build() {
    NavDestination() {
      Column() {
        Blank(10)
        Flex({justifyContent: FlexAlign.SpaceEvenly}) {
          ModuleButton({ name: 'SDK信息', image: 'app.media.growingtk_sdkInfo', type: ModuleType.sdkInfo })
          ModuleButton({ name: '事件库', image: 'app.media.growingtk_eventsList', type: ModuleType.eventsList })
          ModuleButton({ name: '实时事件', image: 'app.media.growingtk_realtime', type: ModuleType.realtime })
          ModuleButton({ name: '网络记录', image: 'app.media.growingtk_netFlow', type: ModuleType.netFlow })
        }
      }
    }
    .onBackPressed(() => {
      this.pathStack.pop('', false)
      return true
    })
  }

  moduleOnClick = (eventData: emitter.EventData) => {
    let data = eventData.data!
    let type = data['type'] as ModuleType
    switch (type) {
      case ModuleType.sdkInfo: {
        let destination = new NavPathInfo('SdkInfo', '')
        this.pathStack.pushDestination(destination)
      }
      break
      case ModuleType.eventsList: {
        let destination = new NavPathInfo('EventsList', '')
        this.pathStack.pushDestination(destination)
      }
        break
      case ModuleType.realtime: {
        let destination = new NavPathInfo('Realtime', '')
        this.pathStack.pushDestination(destination)
      }
        break
      case ModuleType.netFlow: {
        let destination = new NavPathInfo('NetFlow', '')
        this.pathStack.pushDestination(destination)
      }
        break
      default:
        break
    }
  }
}