import AbilityStage from '@ohos.app.ability.AbilityStage'
import type Want from '@ohos.app.ability.Want'
import { GrowingAnalytics, GrowingConfig } from '@growingio/analytics'
import { GrowingToolsKit } from '@growingio/tools'

export default class EntryAbilityStage extends AbilityStage {
  onCreate(): void {
    // 应用的HAP在首次加载的时，为该Module初始化操作
    this.startAnalytics()
  }
  onAcceptWant(want: Want): string {
    // 仅specified模式下触发
    return 'EntryAbilityStage'
  }

  startAnalytics() {
    // 在初始化 SDK 之前，可配置通用属性
    // GrowingAnalytics.setGeneralProps({ 'defaultProps':'good' })
    // let count = 0
    // GrowingAnalytics.setDynamicGeneralProps(() => {
    //   count++
    //   return { 'count' : count}
    // })
    // GrowingAnalytics.setDynamicGeneralProps(() => ({}))

    // ---------------- NewSaaS ----------------

    let config = new GrowingConfig().NewSaaS(
      '0a1b4118dd954ec3bcc69da5138bdb96',
      '8eeb910e0db7a73b',
      'growing.84ff920737d56b1d'
    )
    config.debugEnabled = true
    config.sessionInterval = 30
    config.dataUploadInterval = 15
    config.idMappingEnabled = true
    config.requestOptions.connectTimeout = 10
    config.requestOptions.transferTimeout = 10
    config.autotrackEnabled = true
    config.autotrackAllPages = true
    config.plugins = [new GrowingToolsKit()]
    GrowingAnalytics.start(this.context, config)

    // ---------------- CDP ----------------

    // let config = new GrowingConfig().CDP(
    //   '0a1b4118dd954ec3bcc69da5138bdb96',
    //   '8eeb910e0db7a73b',
    //   'growing.84ff920737d56b1d',
    //   'https://cdp-api.growing.com'
    // )
    // config.debugEnabled = true
    // config.sessionInterval = 30
    // config.dataUploadInterval = 15
    // config.idMappingEnabled = true
    // config.requestOptions.connectTimeout = 10
    // config.requestOptions.transferTimeout = 10
    // config.autotrackAllPages = true
    // config.plugins = [new GrowingToolsKit()]
    // GrowingAnalytics.start(this.context, config)

    // ---------------- SaaS ----------------

    // let config = new GrowingConfig().SaaS(
    //   '0a1b4118dd954ec3bcc69da5138bdb96',
    //   'growing.84ff920737d56b1d'
    // )
    // config.debugEnabled = true
    // config.sessionInterval = 30
    // config.dataUploadInterval = 15
    // config.requestOptions.connectTimeout = 10
    // config.requestOptions.transferTimeout = 10
    // config.autotrackAllPages = true
    // config.plugins = [new GrowingToolsKit()]
    // GrowingAnalytics.start(this.context, config)
  }
}