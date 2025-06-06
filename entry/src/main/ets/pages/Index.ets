import { GrowingAnalytics, GrowingAttrType } from '@growingio/analytics'
import Util from '../Util'

@Entry
@Component
struct Index {
  @State deviceId: string = '请点击下方按钮获取'

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text('DeviceId = ' + this.deviceId)
      Button('getDeviceId')
        .onClick(() => {
          this.getDeviceId()
        }).margin({ top: 15 })
      Toggle({ type: ToggleType.Button, isOn: true }) {
        Text('setDataCollectionEnabled')
          .fontColor('#182431')
          .fontSize(16)
      }.height(40).selectedColor('rgba(0, 125, 255, 0.20)')
      .onChange((isOn: boolean) => {
        this.setDataCollectionEnabled(isOn)
      }).margin({ top: 15 })
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Button('setLoginUserId')
          .onClick(() => {
            this.setLoginUserId()
          }).margin({ top: 15 })
        Button('cleanLoginUserId')
          .onClick(() => {
            this.cleanLoginUserId()
          }).margin({ top: 15 })
      }
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Button('setLocation')
          .onClick(() => {
            this.setLocation()
          }).margin({ top: 15 })
        Button('cleanLocation')
          .onClick(() => {
            this.cleanLocation()
          }).margin({ top: 15 })
      }
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Button('loginUserAttributes')
          .onClick(() => {
            this.loginUserAttributes()
          }).margin({ top: 15 })
        Button('setEvar(SaaS)')
          .onClick(() => {
            this.setEvar()
          }).margin({ top: 15 })
        Button('setVisitor(SaaS)')
          .onClick(() => {
            this.setVisitor()
          }).margin({ top: 15 })
      }
      Button('track')
        .onClick(() => {
          Util.startAbility(getContext(this), 'TrackAbility', 'pages/Track', {
            "growing_attributes": {
              "name": "kk",
              "age": 21
            } as Record<string, Object>
          })
        }).margin({ top: 15 })
        .customProperty("growing_attributes", {
          "action": "click",
          "timestamp": Date.now(),
          "where": "index_track_button"
        })
      Button('generalProps')
        .onClick(() => {
          Util.startAbility(getContext(this), 'GeneralPropsAbility', 'pages/GeneralProps')
        }).margin({ top: 15 })
      Button('trackTimer')
        .onClick(() => {
          Util.startAbility(getContext(this), 'TrackTimerAbility', 'pages/TrackTimer')
        }).margin({ top: 15 })
      Button('subTracker')
        .onClick(() => {
          Util.startAbility(getContext(this), 'SubTrackerAbility', 'pages/SubTracker')
        }).margin({ top: 15 })
      Button('hybrid')
        .onClick(() => {
          Util.startAbility(getContext(this), 'HybridAbility', 'pages/Hybrid')
        }).margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
  }

  async getDeviceId() {
    this.deviceId = GrowingAnalytics.getDeviceId()
  }

  setDataCollectionEnabled(enabled: boolean) {
    GrowingAnalytics.setDataCollectionEnabled(enabled)
  }

  setLoginUserId() {
    let userId = Util.getRandomString()
    GrowingAnalytics.setLoginUserId(userId, 'harmony')
  }

  cleanLoginUserId() {
    GrowingAnalytics.cleanLoginUserId()
  }

  setLocation() {
    const latitude: number = 30.0
    const longitude: number = 120.0
    GrowingAnalytics.setLocation(latitude, longitude)
  }

  cleanLocation() {
    GrowingAnalytics.cleanLocation()
  }

  loginUserAttributes() {
    GrowingAnalytics.setLoginUserAttributes({
      'name': 'ben',
      'age': 30
    })
  }

  setEvar() {
    GrowingAnalytics.setEvar({
      'product': 'apple',
      'age': 30
    })
  }

  setVisitor() {
    GrowingAnalytics.setVisitor({
      'visitor': 'david',
      'age': 30
    })
  }
}