import { GrowingAnalytics } from '@growingio/analytics'
import AppContext from '@ohos.app.ability.common'
import router from '@ohos.router'

@Entry
@Component
struct TrackTimer {
  @State trackerId: string = ''
  @State timerIds: string[] = []
  @State curTimerId: string = ''

  onPageShow() {
    if (!this.trackerId) {
      let trackTimerAbilityWant = globalThis.trackTimerAbilityWant
      let trackerId = trackTimerAbilityWant?.parameters?.trackerId
      this.trackerId = trackerId
    }
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text('trackerId = ' + this.trackerId)
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
          // router.back()
        }).margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
  }

  async trackTimerStart() {
    if (this.trackerId) {
      return await GrowingAnalytics.tracker(this.trackerId).trackTimerStart("timer")
    } else {
      return await GrowingAnalytics.trackTimerStart("timer")
    }
  }

  trackTimerPause() {
    if (this.trackerId) {
      GrowingAnalytics.tracker(this.trackerId).trackTimerPause(this.curTimerId)
    } else {
      GrowingAnalytics.trackTimerPause(this.curTimerId)
    }
  }

  trackTimerResume() {
    if (this.trackerId) {
      GrowingAnalytics.tracker(this.trackerId).trackTimerResume(this.curTimerId)
    } else {
      GrowingAnalytics.trackTimerResume(this.curTimerId)
    }
  }

  trackTimerEnd() {
    if (this.trackerId) {
      GrowingAnalytics.tracker(this.trackerId).trackTimerEnd(this.curTimerId, {"key": "value"})
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
    if (this.trackerId) {
      GrowingAnalytics.tracker(this.trackerId).removeTimer(this.curTimerId)
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
    if (this.trackerId) {
      GrowingAnalytics.tracker(this.trackerId).clearTrackTimer()
    } else {
      GrowingAnalytics.clearTrackTimer()
    }
    this.timerIds = []
    this.curTimerId = ''
  }
}