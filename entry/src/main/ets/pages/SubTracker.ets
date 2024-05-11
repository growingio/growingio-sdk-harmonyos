import { GrowingAnalytics, GrowingConfig, GrowingAnalyticsInterface } from '@growingio/analytics'
import AppContext from '@ohos.app.ability.common'
import Want from '@ohos.app.ability.Want'
import router from '@ohos.router'

@Entry
@Component
struct SubTracker {
  @State trackerIds: string[] = []
  @State curTrackerId: string = ''

  aboutToAppear(): void {
    let trackerId = this.createSubTracker()
    this.curTrackerId = trackerId
    this.trackerIds = [trackerId, ...this.trackerIds]
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Button('createSubTracker')
        .onClick(() => {
          let trackerId = this.createSubTracker()
          this.curTrackerId = trackerId
          this.trackerIds = [trackerId, ...this.trackerIds]
        }).margin({ top: 15 })
      Toggle({ type: ToggleType.Button, isOn: true }) {
        Text('setDataCollectionEnabled')
          .fontColor('#182431')
          .fontSize(16)
      }.height(40).selectedColor('rgba(0, 125, 255, 0.20)')
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
          if (this.curTrackerId.length == 0) {
            return
          }
          let context = getContext(this) as AppContext.UIAbilityContext
          const want: Want = {
            bundleName: getContext(context).applicationInfo.name,
            abilityName: 'TrackTimerAbility',
            parameters: {
              trackerId: this.curTrackerId,
            },
          };
          try {
            context.startAbility(want)
          } catch (error) {
          }
          // router.pushUrl({url: 'pages/TrackTimer'})
        }).margin({ top: 15 })
      List({space: 15}) {
        ForEach(this.trackerIds, (trackerId: string) => {
          ListItem() {
            Row() {
              Radio({ value: trackerId, group: 'trackerIds' }).checked(this.curTrackerId == trackerId)
                .height(25)
                .width(25)
                .onChange((isChecked: boolean) => {
                  if(isChecked) {
                    this.curTrackerId = trackerId
                  }
                })
              Text(trackerId)
            }
          }
        })
      }
      .width('100%')
      .height('50%')
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

  getRandomString(): string {
    const characters = 'abcdefghijklmnopqrstuvwxyz0123456789'
    let random = ''

    for (let i = 0; i < 10; i++) {
      const randomIndex = Math.floor(Math.random() * characters.length)
      random += characters.charAt(randomIndex)
    }
    return random
  }

  createSubTracker(): string {
    let trackerId = this.getRandomString()
    let config = new GrowingConfig(
      '1111111111111', trackerId, 'growing.33333333333', "https://www.baidu.com"
    )
    config.debugEnabled = true
    config.sessionInterval = 30
    config.dataUploadInterval = 15
    config.idMappingEnabled = true
    GrowingAnalytics.startSubTracker(trackerId, config)
    return trackerId
  }

  setDataCollectionEnabled(enabled: boolean) {
    this.subTracker().setDataCollectionEnabled(enabled)
  }

  setLoginUserId() {
    const characters = 'abcdefghijklmnopqrstuvwxyz0123456789'
    let userId = ''

    for (let i = 0; i < 10; i++) {
      const randomIndex = Math.floor(Math.random() * characters.length)
      userId += characters.charAt(randomIndex)
    }
    this.subTracker().setLoginUserId(userId, 'harmony')
  }

  cleanLoginUserId() {
    this.subTracker().cleanLoginUserId()
  }

  track() {
    this.subTracker().track('buyProduct', {
      'name': 'apple',
      'money': 1000,
      'num': 100,
      'from': ['sichuan', 'guizhou', 'hunan']
    })
  }

  loginUserAttributes() {
    this.subTracker().setLoginUserAttributes({
      'name': 'ben',
      'age': 30
    })
  }

  subTracker(): GrowingAnalyticsInterface {
    return GrowingAnalytics.tracker(this.curTrackerId) as GrowingAnalyticsInterface;
  }
}
