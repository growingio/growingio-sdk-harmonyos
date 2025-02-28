import { GrowingAnalytics, GrowingAnalyticsInterface, GrowingAttrType } from '@growingio/analytics'
import AppContext from '@ohos.app.ability.common'
import Util from '../Util'
import router from '@ohos.router'

type ValueType = string | number | boolean | string[] | number[] | boolean[]
let storage: LocalStorage = LocalStorage.getShared()

@Entry(storage)
@Component
struct Track {
  @LocalStorageProp('trackerId') trackerIdFromStorage: string = ''
  @State trackerIdFromRouterParams: string = router.getParams()
    ? ((router.getParams() as Record<string, Object>)['trackerId'] as string)
    : ''
  @State eventName: string = Util.getRandomString()
  @State attributesK: string[] = []
  @State attributesV: ValueType[] = []

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      if (this.getTrackerId().length > 0) {
        Text('trackerId = ' + this.getTrackerId())
      }
      TextInput({placeholder: 'enter eventName please', text: this.eventName})
        .onChange(v => {
          this.eventName = v
        })
      Button('add')
        .onClick(() => {
          this.attributesK = [Util.getRandomString(), ...this.attributesK]
          this.attributesV = [Util.getRandomString(), ...this.attributesV]
        }).margin({ top: 15 })
        .customProperty("growing_attributes", {
          "action": "click",
          "timestamp": Date.now(),
          "where": "track_add_button"
        })
      List({space: 15}) {
        ForEach(this.attributesK, (k: string, i: number) => {
          ListItem() {
            Row() {
              TextInput({placeholder: 'enter key please', text: String(k)})
                .width('50%')
                .onChange(v => {
                  this.attributesK[i] = v
                })
              TextInput({placeholder: 'enter value please', text: String(this.attributesV[i])})
                .width('50%')
                .onChange(v => {
                  this.attributesV[i] = v
                })
            }
          }
        })
      }
      .width('100%')
      .height('50%')
      Button('track')
        .onClick(() => {
          this.track()
        }).margin({ top: 15 })
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

  track() {
    let attributes: GrowingAttrType = {}
    this.attributesK.forEach((k, i) => {
      if (k.length == 0) {
        return
      }
      let value = this.attributesV[i] as string
      if (value.length == 0) {
        return
      }
      attributes[k] = value
    })

    let trackerId = this.getTrackerId()
    if (trackerId && trackerId.length > 0) {
      this.subTracker().track(this.eventName, attributes)
    } else {
      GrowingAnalytics.track(this.eventName, attributes)
    }

    // GrowingAnalytics.track('buyProduct1')
    //
    // GrowingAnalytics.track('buyProduct2', {
    //   'name': 'apple',
    //   'money': 1000,
    //   'num': 100,
    //   'from': ['sichuan', 'guizhou', 'hunan']
    // })
  }

  subTracker(): GrowingAnalyticsInterface {
    return GrowingAnalytics.tracker(this.getTrackerId()) as GrowingAnalyticsInterface
  }
}