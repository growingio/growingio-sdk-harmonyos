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

import AnalyticsCore from '../core/AnalyticsCore'
import EventPersistence from '../event/EventPersistence'

export interface PluginsInterface {
  handleOpenURL?(uri: string): boolean
  onEventsDidSend?(events: EventPersistence[], url: string): void
}

export default class Plugins {
  static plugins: Array<PluginsInterface> = []
  static deferDeepLink: string | undefined = undefined

  static registerPlugin(plugin: PluginsInterface) {
    Plugins.plugins.push(plugin)
  }

  static registerPlugins(plugins: PluginsInterface[]) {
    plugins.forEach(plugin => {
      Plugins.registerPlugin(plugin)
    })
  }

  static onSDKDidInitialize() {
    // 延迟初始化场景下，待SDK初始化后再处理DeepLink
    if (Plugins.deferDeepLink) {
      let uri = Plugins.deferDeepLink
      Plugins.deferDeepLink = undefined
      Plugins.handleOpenURL(uri)
    }
  }

  static handleOpenURL(uri: string): boolean {
    let isHandle = false
    for (let plugin of Plugins.plugins) {
      if (plugin.handleOpenURL) {
        isHandle = plugin.handleOpenURL(uri)
        if (isHandle) {
          break
        }
      }
    }

    if (!isHandle && !AnalyticsCore.core.isInitializedSuccessfully() && uri.startsWith('growing.')) {
      Plugins.deferDeepLink = uri
    }

    return isHandle
  }

  static onEventsDidSend(events: EventPersistence[], url: string) {
    Plugins.plugins.forEach(plugin => {
      if (plugin.onEventsDidSend) {
        plugin.onEventsDidSend(events, url)
      }
    })
  }

}
