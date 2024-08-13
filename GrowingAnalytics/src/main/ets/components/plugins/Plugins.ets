import UIAbility from '@ohos.app.ability.UIAbility'
import window from '@ohos.window'
import { GrowingConfig } from '../interfaces/GrowingConfig'

export interface PluginsInterface {
  onSDKWillInitialize(): void
  onSDKDidInitialize(config: GrowingConfig, version: string): void
  onUserIdChange(before: string, after: string): void
  onSessionChange(before: string, after: string): void
  onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage): void
  onEventWroteToDisk(uuid: string, data: string, eventType: string, eventScene: number): void
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
}