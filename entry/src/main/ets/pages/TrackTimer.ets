import { GrowingAnalytics } from '@growingio/analytics'
import router from '@ohos.router'

@Entry
@Component
struct TrackTimer {
  @State timerIds: string[] = []
  @State curTimerId: string = undefined

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
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
        ForEach(this.timerIds, timerId => {
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
      Button('routerBack')
        .onClick(() => {
          router.back()
        }).margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
  }

  async trackTimerStart() {
    return await GrowingAnalytics.trackTimerStart("timer")
  }

  trackTimerPause() {
    GrowingAnalytics.trackTimerPause(this.curTimerId)
  }

  trackTimerResume() {
    GrowingAnalytics.trackTimerResume(this.curTimerId)
  }

  trackTimerEnd() {
    GrowingAnalytics.trackTimerEnd(this.curTimerId, {"key": "value"})
    this.timerIds = this.timerIds.filter((timerId) => timerId !== this.curTimerId)
    if (this.timerIds.length > 0) {
      this.curTimerId = this.timerIds[0]
    } else {
      this.curTimerId = undefined
    }
  }

  removeTimer() {
    GrowingAnalytics.removeTimer(this.curTimerId)
    this.timerIds = this.timerIds.filter((timerId) => timerId !== this.curTimerId)
    if (this.timerIds.length > 0) {
      this.curTimerId = this.timerIds[0]
    } else {
      this.curTimerId = undefined
    }
  }

  clearTrackTimer() {
    GrowingAnalytics.clearTrackTimer()
    this.timerIds = []
    this.curTimerId = undefined
  }
}