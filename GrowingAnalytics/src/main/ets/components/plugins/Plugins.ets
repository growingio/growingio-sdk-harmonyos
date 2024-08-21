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
import { rcp } from '@kit.RemoteCommunicationKit'
import { GrowingConfig } from '../interfaces/GrowingConfig'

export interface PluginsInterface {
  onSDKWillInitialize(): void
  onSDKDidInitialize(config: GrowingConfig, version: string): void
  onUserIdChange(before: string, after: string): void
  onSessionChange(before: string, after: string): void
  onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage): void
  onEventWroteToDisk(uuid: string, data: string, eventType: string, eventScene: number): void
  onEventsRemoveFromDisk(events: string[]): void
  onResponseReceive(response: rcp.Response): void
}

export default class Plugins {
  static plugins: Array<PluginsInterface> = []

  static registerPlugin(plugin: PluginsInterface) {
    let hasPlugin: boolean = false
    for (let i = 0; i < Plugins.plugins.length; i++) {
      if (typeof Plugins.plugins[i] == typeof plugin) {
        hasPlugin = true
        break
      }
    }
    if (hasPlugin) {
      return
    }
    Plugins.plugins.push(plugin)
  }

  static onSDKWillInitialize() {
    Plugins.plugins.forEach(plugin => {
      plugin.onSDKWillInitialize()
    })
  }

  static onSDKDidInitialize(config: GrowingConfig, version: string) {
    Plugins.plugins.forEach(plugin => {
      plugin.onSDKDidInitialize(config, version)
    })
  }

  static onUserIdChange(before: string, after: string) {
    Plugins.plugins.forEach(plugin => {
      plugin.onUserIdChange(before, after)
    })
  }

  static onSessionChange(before: string, after: string) {
    Plugins.plugins.forEach(plugin => {
      plugin.onSessionChange(before, after)
    })
  }

  static onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage) {
    Plugins.plugins.forEach(plugin => {
      plugin.onWindowStageCreate(ability, windowStage)
    })
  }

  static onEventWroteToDisk(uuid: string, data: string, eventType: string, eventScene: number) {
    Plugins.plugins.forEach(plugin => {
      plugin.onEventWroteToDisk(uuid, data, eventType, eventScene)
    })
  }

  static onEventsRemoveFromDisk(events: string[]) {
    Plugins.plugins.forEach(plugin => {
      plugin.onEventsRemoveFromDisk(events)
    })
  }

  static onResponseReceive(response: rcp.Response) {
    Plugins.plugins.forEach(plugin => {
      plugin.onResponseReceive(response)
    })
  }
}