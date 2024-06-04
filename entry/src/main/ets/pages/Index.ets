import {
  GrowingAnalytics,
  GrowingAttrType,
  GrowingEventType,
  GrowingPropPlugin,
  GrowingPropPluginEventFilter } from '@growingio/analytics'
import Util from '../Util'
import Util_TS from '../Util_TS'

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
        Button('setPropertyPlugin1')
          .onClick(() => {
            this.setPropertyPlugin1()
          }).margin({ top: 15 })
        Button('setPropertyPlugin2')
          .onClick(() => {
            this.setPropertyPlugin2()
          }).margin({ top: 15 })
      }
      Button('loginUserAttributes')
        .onClick(() => {
          this.loginUserAttributes()
        }).margin({ top: 15 })
      Button('track')
        .onClick(() => {
          Util.startAbility(getContext(this), 'TrackAbility', 'pages/Track')
        }).margin({ top: 15 })
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

  setPropertyPlugin1() {
    GrowingAnalytics.setEventPropertyPlugin(new PropertyPlugin1())
  }

  setPropertyPlugin2() {
    GrowingAnalytics.setEventPropertyPlugin(new PropertyPlugin2())
  }

  loginUserAttributes() {
    GrowingAnalytics.setLoginUserAttributes({
      'name': 'ben',
      'age': 30
    })
  }
}

class PropertyPlugin1 implements GrowingPropPlugin {
  attributes(attributes: GrowingAttrType | undefined): GrowingAttrType | undefined {
    if (attributes) {
      attributes['pluginKey'] = '11111'
    }
    return attributes
  }

  priority(): number {
    return 1
  }

  isMatchedWithFilter(filter: GrowingPropPluginEventFilter): boolean {
    // 不处理 eventName 为 impossible 的 CUSTOM 事件
    if (filter.name() == 'impossible') {
      return false
    }

    // 不处理 VISIT 事件
    if (filter.type() == GrowingEventType.Visit) {
      return false
    }

    // 不处理儿童节触发的事件
    let date = new Date(filter.time())
    if (date.getUTCMonth() == 5 && date.getUTCDate() == 1) {
      return false
    }

    // 不处理来自 hybrid 的事件
    if (filter.isFromHybrid()) {
      return false
    }

    // 不处理来自子实例 subTracker_01 的事件
    if (filter.trackerId() == 'subTracker_01') {
      return false
    }

    return true
  }
}

class PropertyPlugin2 implements GrowingPropPlugin {
  attributes(attributes: GrowingAttrType | undefined): GrowingAttrType | undefined {
    if (attributes) {
      attributes['pluginKey'] = '22222'
    }
    return attributes
  }

  priority(): number {
    return 2
  }

  isMatchedWithFilter(filter: GrowingPropPluginEventFilter): boolean {
    return true
  }
}