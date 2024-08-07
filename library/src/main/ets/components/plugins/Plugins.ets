import UIAbility from '@ohos.app.ability.UIAbility'
import window from '@ohos.window'

export interface PluginsInterface {
  onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage): void
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

  static onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage) {
    Plugins.plugins.forEach(plugin => {
      plugin.onWindowStageCreate(ability, windowStage)
    })
  }
}