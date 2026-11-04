import UIAbility from '@ohos.app.ability.UIAbility'
import hilog from '@ohos.hilog'
import window from '@ohos.window'
import Want from '@ohos.app.ability.Want'
import AbilityConstant from '@ohos.app.ability.AbilityConstant'

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'growingWear', '%{public}s', 'Ability onCreate')
  }

  onDestroy(): void {
    hilog.info(0x0000, 'growingWear', '%{public}s', 'Ability onDestroy')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'growingWear', '%{public}s', 'Ability onWindowStageCreate')

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'growingWear', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '')
        return
      }
      hilog.info(0x0000, 'growingWear', 'Succeeded in loading the content.')

      // 手表端不采集无埋点，因此刻意不调用：
      //   GrowingAnalytics.onWindowStageCreate(this, windowStage)
      //
      // 该方法是无埋点 UI 监听的唯一注册入口，内部会挂上 4 个 UIObserver 回调
      // （willClick / navDestinationUpdate / navDestinationSwitch / routerPageUpdate）。
      // 不调用即零注册，每次点击与路由跳转都不会进入 SDK 回调。
      //
      // 手动埋点、会话、设备信息、事件入库与上报均不依赖此方法，功能不受影响。
    })
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'growingWear', '%{public}s', 'Ability onWindowStageDestroy')
  }

  onForeground(): void {
    hilog.info(0x0000, 'growingWear', '%{public}s', 'Ability onForeground')
  }

  onBackground(): void {
    hilog.info(0x0000, 'growingWear', '%{public}s', 'Ability onBackground')
  }
}
