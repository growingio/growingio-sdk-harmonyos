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

import common from '@ohos.app.ability.common'
import window from '@ohos.window'
import rcp from '@hms.collaboration.rcp'

import AnalyticsCore from '../core/AnalyticsCore'
import EventPersistence from '../event/EventPersistence'
import { GrowingConfig } from '../interfaces/GrowingConfig'

export interface PluginsInterface {
  onSDKWillInitialize?(): void
  onSDKDidInitialize?(config: GrowingConfig, version: string): void
  onStartSubTracker?(trackerId: string, config: GrowingConfig): void
  setAutotrackStatusFetcher?(fetcher: () => boolean): void
  onDeferStart?(): void
  afterWindowStageCreate?(abilityContext: common.UIAbilityContext, windowStage: window.WindowStage): void
  handleOpenURL?(uri: string): boolean
  onEventWroteToDisk?(event: EventPersistence, eventScene: number): void
  onEventsRemoveFromDisk?(events: string[]): void
  onResponseReceive?(response: rcp.Response): void
  onEventsDidSend?(events: EventPersistence[], request: rcp.Request): void
  onWebViewDomTreeChanged?(): void
}

export default class Plugins {
  static plugins: Array<PluginsInterface> = []
  static deferDeepLink: string | undefined = undefined

  static registerPlugins(plugins: PluginsInterface[]) {
    plugins.forEach(plugin => {
      Plugins.registerPlugin(plugin)
    })
  }

  static registerPlugin(plugin: PluginsInterface) {
    Plugins.plugins.push(plugin)
  }

  static onSDKWillInitialize() {
    Plugins.plugins.forEach(plugin => {
      if (plugin.onSDKWillInitialize) {
        plugin.onSDKWillInitialize()
      }
    })
  }

  static onSDKDidInitialize(config: GrowingConfig, version: string) {
    Plugins.plugins.forEach(plugin => {
      if (plugin.onSDKDidInitialize) {
        plugin.onSDKDidInitialize(config, version)
      }
    })

    // 延迟初始化场景下，待SDK初始化后再处理DeepLink
    if (Plugins.deferDeepLink) {
      let uri = Plugins.deferDeepLink
      Plugins.deferDeepLink = undefined
      Plugins.handleOpenURL(uri)
    }
  }

  static onStartSubTracker(trackerId: string, config: GrowingConfig) {
    Plugins.plugins.forEach(plugin => {
      if (plugin.onStartSubTracker) {
        plugin.onStartSubTracker(trackerId, config)
      }
    })
  }

  static setAutotrackStatusFetcher(fetcher: () => boolean) {
    Plugins.plugins.forEach(plugin => {
      if (plugin.setAutotrackStatusFetcher) {
        plugin.setAutotrackStatusFetcher(fetcher)
      }
    })
  }

  static onDeferStart() {
    Plugins.plugins.forEach(plugin => {
      if (plugin.onDeferStart) {
        plugin.onDeferStart()
      }
    })
  }

  static afterWindowStageCreate(abilityContext: common.UIAbilityContext, windowStage: window.WindowStage) {
    Plugins.plugins.forEach(plugin => {
      if (plugin.afterWindowStageCreate) {
        plugin.afterWindowStageCreate(abilityContext, windowStage)
      }
    })
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
      // 延迟初始化场景下，待SDK初始化后再处理DeepLink
      Plugins.deferDeepLink = uri
    }

    return isHandle
  }

  static onEventWroteToDisk(event: EventPersistence, eventScene: number) {
    Plugins.plugins.forEach(plugin => {
      if (plugin.onEventWroteToDisk) {
        plugin.onEventWroteToDisk(event, eventScene)
      }
    })
  }

  static onEventsRemoveFromDisk(events: string[]) {
    Plugins.plugins.forEach(plugin => {
      if (plugin.onEventsRemoveFromDisk) {
        plugin.onEventsRemoveFromDisk(events)
      }
    })
  }

  static onResponseReceive(response: rcp.Response) {
    Plugins.plugins.forEach(plugin => {
      if (plugin.onResponseReceive) {
        plugin.onResponseReceive(response)
      }
    })
  }

  static onEventsDidSend(events: EventPersistence[], request: rcp.Request) {
    Plugins.plugins.forEach(plugin => {
      if (plugin.onEventsDidSend) {
        plugin.onEventsDidSend(events, request)
      }
    })
  }

  static onWebViewDomTreeChanged() {
    Plugins.plugins.forEach(plugin => {
      if (plugin.onWebViewDomTreeChanged) {
        plugin.onWebViewDomTreeChanged()
      }
    })
  }
}