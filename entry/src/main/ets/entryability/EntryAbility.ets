import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { GrowingAnalytics, GrowingConfig } from '@growingio/analytics';

export default class EntryAbility extends UIAbility {
  async startAnalytics() {
    // let count = 0
    // GrowingAnalytics.setDynamicGeneralProps(() => {
    //   count++
    //   return { 'count' : count}
    // })

    let config = new GrowingConfig(
      '0a1b4118dd954ec3bcc69da5138bdb96', 'ab555003531e0fd1', 'growing.bf30ad277eaae1aa'
    )
    config.debugEnabled = true
    config.sessionInterval = 30
    config.dataUploadInterval = 15
    config.idMappingEnabled = true
    await GrowingAnalytics.start(this.context, config)
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');

    this.startAnalytics()
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
