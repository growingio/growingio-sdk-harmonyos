import { GrowingAnalytics, GrowingAnalyticsInterface } from '@growingio/analytics'
import AppContext from '@ohos.app.ability.common'
import router from '@ohos.router'

let storage: LocalStorage = LocalStorage.getShared()

@Entry(storage)
@Component
struct TrackTimer {
  @LocalStorageProp('trackerId') trackerIdFromStorage: string = ''
  @State trackerIdFromRouterParams: string = router.getParams()
    ? ((router.getParams() as Record<string, Object>)['trackerId'] as string)
    : ''
  @State timerIds: string[] = []
  @State curTimerId: string = ''

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      if (this.getTrackerId().length > 0) {
        Text('trackerId = ' + this.getTrackerId())
      }
      Button('trackTimerStart')
        .onClick(() => {
          let timerId = this.trackTimerStart()
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
          // let context = getContext(this) as AppContext.UIAbilityContext
          // context.terminateSelf()
          router.back()
        }).margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
  }

  getTrackerId(): string {
    if (this.trackerIdFromStorage && this.trackerIdFromStorage.length > 0) {
      return this.trackerIdFromStorage
    } else if (this.trackerIdFromRouterParams && this.trackerIdFromRouterParams.length > 0) {
      return this.trackerIdFromRouterParams
    }
    return ''
  }

  trackTimerStart() {
    let trackerId = this.getTrackerId()
    if (trackerId && trackerId.length > 0) {
      return this.subTracker().trackTimerStart("timer")
    } else {
      return GrowingAnalytics.trackTimerStart("timer")
    }
  }

  trackTimerPause() {
    let trackerId = this.getTrackerId()
    if (trackerId && trackerId.length > 0) {
      this.subTracker().trackTimerPause(this.curTimerId)
    } else {
      GrowingAnalytics.trackTimerPause(this.curTimerId)
    }
  }

  trackTimerResume() {
    let trackerId = this.getTrackerId()
    if (trackerId && trackerId.length > 0) {
      this.subTracker().trackTimerResume(this.curTimerId)
    } else {
      GrowingAnalytics.trackTimerResume(this.curTimerId)
    }
  }

  trackTimerEnd() {
    let trackerId = this.getTrackerId()
    if (trackerId && trackerId.length > 0) {
      this.subTracker().trackTimerEnd(this.curTimerId, {"key": "value"})
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
    let trackerId = this.getTrackerId()
    if (trackerId && trackerId.length > 0) {
      this.subTracker().removeTimer(this.curTimerId)
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
    let trackerId = this.getTrackerId()
    if (trackerId && trackerId.length > 0) {
      this.subTracker().clearTrackTimer()
    } else {
      GrowingAnalytics.clearTrackTimer()
    }
    this.timerIds = []
    this.curTimerId = ''
  }

  subTracker(): GrowingAnalyticsInterface {
    return GrowingAnalytics.tracker(this.getTrackerId()) as GrowingAnalyticsInterface
  }
}