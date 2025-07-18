import { GrowingAnalytics, GrowingConfig, GrowingAnalyticsInterface } from '@growingio/analytics'
import AppContext from '@ohos.app.ability.common'
import router from '@ohos.router'
import Util from '../Util'

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
          if (trackerId.length > 0) {
            this.curTrackerId = trackerId
            if (this.trackerIds.includes(trackerId)) {
              return
            }
            this.trackerIds = [trackerId, ...this.trackerIds]
          }
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
          if (this.curTrackerId.length == 0) {
            return
          }
          Util.startAbility(getContext(this), 'TrackAbility', 'pages/Track', {'trackerId': this.curTrackerId})
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
          // let context = getContext(this) as AppContext.UIAbilityContext
          // context.terminateSelf()
          router.back()
        }).margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
  }

  createSubTracker(): string {
    let trackerId = Util.getRandomString()
    let config = new GrowingConfig().NewSaaS(
      '1111111111111',
      trackerId,
      'growing.33333333333',
      "https://www.baidu.com"
    )
    config.debugEnabled = true
    config.sessionInterval = 30
    config.dataUploadInterval = 15
    config.idMappingEnabled = true
    GrowingAnalytics.startSubTracker(trackerId, config)
    return GrowingAnalytics.tracker(trackerId).isInitializedSuccessfully() ? trackerId : ''
  }

  setDataCollectionEnabled(enabled: boolean) {
    this.subTracker().setDataCollectionEnabled(enabled)
  }

  setLoginUserId() {
    let userId = Util.getRandomString()
    this.subTracker().setLoginUserId(userId, 'harmony')
  }

  cleanLoginUserId() {
    this.subTracker().cleanLoginUserId()
  }

  subTracker(): GrowingAnalyticsInterface {
    return GrowingAnalytics.tracker(this.curTrackerId) as GrowingAnalyticsInterface
  }
}
