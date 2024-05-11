import { GrowingAnalytics, GrowingAnalyticsInterface } from '@growingio/analytics'
import AppContext from '@ohos.app.ability.common'

let storage: LocalStorage = LocalStorage.getShared()

@Entry(storage)
@Component
struct TrackTimer {
  @LocalStorageProp('trackerId') trackerId: string = ''
  @State timerIds: string[] = []
  @State curTimerId: string = ''

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      if (this.trackerId && this.trackerId.length > 0) {
        Text('trackerId = ' + this.trackerId)
      }
      Button('trackTimerStart')
        .onClick(async () => {
          let timerId = await this.trackTimerStart()
          this.curTimerId = timerId
          this.timerIds = [timerId, ...this.timerIds]
        }).margin({ top: 15 })
      Button('trackTimerPause')
        .onClick(() => {
          this.trackTimerPause()
        }).margin({ top: 15 })
      Button('trackTimerResume')
        .onClick(() => {
          this.trackTimerResume()
        }).margin({ top: 15 })
      Button('trackTimerEnd')
        .onClick(() => {
          this.trackTimerEnd()
        }).margin({ top: 15 })
      Button('removeTimer')
        .onClick(() => {
          this.removeTimer()
        }).margin({ top: 15 })
      Button('clearTrackTimer')
        .onClick(() => {
          this.clearTrackTimer()
        }).margin({ top: 15 })
      List({space: 15}) {
        ForEach(this.timerIds, (timerId: string) => {
          ListItem() {
            Row() {
              Radio({ value: timerId, group: 'timerIds' }).checked(this.curTimerId == timerId)
                .height(25)
                .width(25)
                .onChange((isChecked: boolean) => {
                  if(isChecked) {
                    this.curTimerId = timerId
                  }
                })
              Text(timerId)
            }
          }
        })
      }
      .width('100%')
      .height('50%')
      Button('Back')
        .onClick(() => {
          let context = getContext(this) as AppContext.UIAbilityContext
          context.terminateSelf()
        }).margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
  }

  async trackTimerStart() {
    if (this.trackerId && this.trackerId.length > 0) {
      return await (GrowingAnalytics.tracker(this.trackerId) as GrowingAnalyticsInterface).trackTimerStart("timer")
    } else {
      return await GrowingAnalytics.trackTimerStart("timer")
    }
  }

  trackTimerPause() {
    if (this.trackerId && this.trackerId.length > 0) {
      (GrowingAnalytics.tracker(this.trackerId) as GrowingAnalyticsInterface).trackTimerPause(this.curTimerId)
    } else {
      GrowingAnalytics.trackTimerPause(this.curTimerId)
    }
  }

  trackTimerResume() {
    if (this.trackerId && this.trackerId.length > 0) {
      (GrowingAnalytics.tracker(this.trackerId) as GrowingAnalyticsInterface).trackTimerResume(this.curTimerId)
    } else {
      GrowingAnalytics.trackTimerResume(this.curTimerId)
    }
  }

  trackTimerEnd() {
    if (this.trackerId && this.trackerId.length > 0) {
      (GrowingAnalytics.tracker(this.trackerId) as GrowingAnalyticsInterface).trackTimerEnd(this.curTimerId, {"key": "value"})
    } else {
      GrowingAnalytics.trackTimerEnd(this.curTimerId, {"key": "value"})
    }
    this.timerIds = this.timerIds.filter((timerId) => timerId !== this.curTimerId)
    if (this.timerIds.length > 0) {
      this.curTimerId = this.timerIds[0]
    } else {
      this.curTimerId = ''
    }
  }

  removeTimer() {
    if (this.trackerId && this.trackerId.length > 0) {
      (GrowingAnalytics.tracker(this.trackerId) as GrowingAnalyticsInterface).removeTimer(this.curTimerId)
    } else {
      GrowingAnalytics.removeTimer(this.curTimerId)
    }
    this.timerIds = this.timerIds.filter((timerId) => timerId !== this.curTimerId)
    if (this.timerIds.length > 0) {
      this.curTimerId = this.timerIds[0]
    } else {
      this.curTimerId = ''
    }
  }

  clearTrackTimer() {
    if (this.trackerId && this.trackerId.length > 0) {
      (GrowingAnalytics.tracker(this.trackerId) as GrowingAnalyticsInterface).clearTrackTimer()
    } else {
      GrowingAnalytics.clearTrackTimer()
    }
    this.timerIds = []
    this.curTimerId = ''
  }
}