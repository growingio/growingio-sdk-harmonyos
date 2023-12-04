import { GrowingAnalytics } from '@growingio/analytics'
import router from '@ohos.router'

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
      Button('setLocation')
        .onClick(() => {
          this.setLocation()
        }).margin({ top: 15 })
      Button('cleanLocation')
        .onClick(() => {
          this.cleanLocation()
        }).margin({ top: 15 })
      Button('track')
        .onClick(() => {
          this.track()
        }).margin({ top: 15 })
      Button('loginUserAttributes')
        .onClick(() => {
          this.loginUserAttributes()
        }).margin({ top: 15 })
      Button('setGeneralProps')
        .onClick(() => {
          this.setGeneralProps()
        }).margin({ top: 15 })
      Button('removeGeneralProps')
        .onClick(() => {
          this.removeGeneralProps()
        }).margin({ top: 15 })
      Button('clearGeneralProps')
        .onClick(() => {
          this.clearGeneralProps()
        }).margin({ top: 15 })
      Button('trackTimer')
        .onClick(() => {
          router.pushUrl({url: 'pages/TrackTimer'})
        }).margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
  }

  async getDeviceId() {
    this.deviceId = await GrowingAnalytics.getDeviceId()
  }

  setDataCollectionEnabled(enabled: boolean) {
    GrowingAnalytics.setDataCollectionEnabled(enabled)
  }

  setLoginUserId() {
    const characters = 'abcdefghijklmnopqrstuvwxyz0123456789'
    let userId = ''

    for (let i = 0; i < 10; i++) {
      const randomIndex = Math.floor(Math.random() * characters.length)
      userId += characters.charAt(randomIndex)
    }
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

  track() {
    GrowingAnalytics.track('buyProduct1')

    GrowingAnalytics.track('buyProduct2', {
      'name': 'apple',
      'money': 1000,
      'num': 100,
      'from': ['sichuan', 'guizhou', 'hunan']
    })
  }

  loginUserAttributes() {
    GrowingAnalytics.setLoginUserAttributes({
      'name': 'ben',
      'age': 30
    })
  }

  setGeneralProps() {
    GrowingAnalytics.setGeneralProps({
      'prop1': 10,
      'prop2': 'kkk',
      'prop3': [1, 2, 3],
      'prop4': ['a', 'b', 'c'],
      'name': 'banana'
    })
  }

  removeGeneralProps() {
    GrowingAnalytics.removeGeneralProps(['prop1', 'prop2', 'prop3'])
  }

  clearGeneralProps() {
    GrowingAnalytics.clearGeneralProps()
  }
}