import { GrowingAnalytics } from '@growingio/analytics'
import AppContext from '@ohos.app.ability.common'
import Want from '@ohos.app.ability.Want'
import router from '@ohos.router'

@Entry
@Component
struct SubTracker {
  @State trackerId: string = ''

  onPageShow() {
    if (!this.trackerId) {
      let subTrackerAbilityWant = globalThis.subTrackerAbilityWant
      let trackerId = subTrackerAbilityWant?.parameters?.trackerId
      this.trackerId = trackerId
    }
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text('trackerId = ' + this.trackerId)
      Toggle({ type: ToggleType.Button, isOn: true }) {
        Text('setDataCollectionEnabled')
          .fontColor('#182431')
          .fontSize(16)
      }.height(40).selectedColor(Color.Green)
      .onChange((isOn: boolean) => {
        this.setDataCollectionEnabled(isOn)
      }).margin({ top: 15 })
      Button('setLoginUserId')
        .onClick(() => {
          this.setLoginUserId()
        }).margin({ top: 15 })
      Button('cleanLoginUserId')
        .onClick(() => {
          this.cleanLoginUserId()
        }).margin({ top: 15 })
      Button('track')
        .onClick(() => {
          this.track()
        }).margin({ top: 15 })
      Button('loginUserAttributes')
        .onClick(() => {
          this.loginUserAttributes()
        }).margin({ top: 15 })
      Button('trackTimer')
        .onClick(() => {
          let context = getContext(this) as AppContext.UIAbilityContext
          const want: Want = {
            bundleName: getContext(context).applicationInfo.name,
            abilityName: 'TrackTimerAbility',
            parameters: {
              trackerId: this.trackerId,
            },
          };
          try {
            context.startAbility(want)
          } catch (error) {
          }
          // router.pushUrl({url: 'pages/TrackTimer'})
        }).margin({ top: 15 })
      Button('Back')
        .onClick(() => {
          let context = getContext(this) as AppContext.UIAbilityContext
          // context.terminateSelf()
          router.back()
        }).margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
  }

  setDataCollectionEnabled(enabled: boolean) {
    let tracker = GrowingAnalytics.tracker(this.trackerId)
    if (tracker) {
      tracker.setDataCollectionEnabled(enabled)
    }
  }

  setLoginUserId() {
    const characters = 'abcdefghijklmnopqrstuvwxyz0123456789'
    let userId = ''

    for (let i = 0; i < 10; i++) {
      const randomIndex = Math.floor(Math.random() * characters.length)
      userId += characters.charAt(randomIndex)
    }
    GrowingAnalytics.tracker(this.trackerId).setLoginUserId(userId, 'harmony')
  }

  cleanLoginUserId() {
    GrowingAnalytics.tracker(this.trackerId).cleanLoginUserId()
  }

  track() {
    GrowingAnalytics.tracker(this.trackerId).track('buyProduct', {
      'name': 'apple',
      'money': 1000,
      'num': 100,
      'from': ['sichuan', 'guizhou', 'hunan']
    })
  }

  loginUserAttributes() {
    GrowingAnalytics.tracker(this.trackerId).setLoginUserAttributes({
      'name': 'ben',
      'age': 30
    })
  }
}