import AbilityStage from '@ohos.app.ability.AbilityStage'
import type Want from '@ohos.app.ability.Want'
import { GrowingAnalytics, GrowingConfig } from '@growingio/analytics'

export default class EntryAbilityStage extends AbilityStage {
  onCreate(): void {
    // 初始化 SDK
    this.setupAnalytics()

    // 确保终端已授权个人隐私信息合规收集和处理后，开启 SDK 数据采集
    this.startAnalytics()
  }

  onAcceptWant(want: Want): string {
    return 'EntryAbilityStage'
  }

  setupAnalytics() {
    let config = new GrowingConfig().NewSaaS(
      '0a1b4118dd954ec3bcc69da5138bdb96',
      '8eeb910e0db7a73b',
      'growing.84ff920737d56b1d'
    )
    config.debugEnabled = true
    config.sessionInterval = 30

    // 手表端建议放宽上报间隔：屏幕小、会话短，频繁唤醒网络对续航不友好
    config.dataUploadInterval = 60

    config.idMappingEnabled = true
    config.requestOptions.connectTimeout = 10
    config.requestOptions.transferTimeout = 10

    // 手表端不采集无埋点。
    // autotrackEnabled 默认即为 false，此处显式写出以表明是有意为之；
    // 真正决定是否注册 UI 监听的是 EntryAbility 里有没有调用
    // GrowingAnalytics.onWindowStageCreate —— 不调用则一个 UIObserver 都不会注册。
    config.autotrackEnabled = false
    config.autotrackAllPages = false

    // 手表端无 WebView 场景，关闭 Hybrid 无埋点
    config.hybridAutotrackEnabled = false

    // GrowingToolsKit 是悬浮窗形态的调试工具，手表屏幕放不下，故不挂载

    GrowingAnalytics.configure(config)

    AppStorage.setOrCreate('sdkMode', config.mode)
  }

  startAnalytics() {
    GrowingAnalytics.startAnalytics(this.context)
  }
}
