import deviceInfo from '@ohos.deviceInfo'
import { GrowingAnalytics, GrowingAttrType } from '@growingio/analytics'

/**
 * 手表端 demo 首页。
 *
 * 与 entry（手机）demo 的关键差异：本模块不开启无埋点，因此不产生 PAGE 与
 * VIEW_CLICK 事件，下面的事件全部来自手动埋点 API。
 * 圆形屏幕下所有可点区域集中在中心竖列，四角不放内容。
 */
@Entry
@Component
struct Index {
  @State status: string = '等待操作'
  @State collectionEnabled: boolean = true
  @State timerId: string = ''

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('GrowingIO Wearable')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)

        Text(`deviceType: ${deviceInfo.deviceType}`)
          .fontSize(12)
          .fontColor($r('sys.color.font_secondary'))

        Text(this.status)
          .fontSize(12)
          .fontColor($r('sys.color.font_secondary'))
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('80%')

        Button('自定义事件')
          .wearableButton()
          .onClick(() => {
            GrowingAnalytics.track('wear_button_click')
            this.status = 'track: wear_button_click'
          })

        Button('带属性事件')
          .wearableButton()
          .onClick(() => {
            let attrs: GrowingAttrType = {
              'source': 'wearable',
              'battery_saver': true,
              'timestamp': Date.now()
            }
            GrowingAnalytics.track('wear_workout_finish', attrs)
            this.status = 'track: wear_workout_finish'
          })

        Button(this.timerId.length > 0 ? '结束计时' : '开始计时')
          .wearableButton()
          .onClick(() => {
            this.toggleTimer()
          })

        Button('登录用户')
          .wearableButton()
          .onClick(() => {
            GrowingAnalytics.setLoginUserId('wear_user_001')
            this.status = 'setLoginUserId: wear_user_001'
          })

        Button('登出')
          .wearableButton()
          .onClick(() => {
            GrowingAnalytics.cleanLoginUserId()
            this.status = 'cleanLoginUserId'
          })

        Button(this.collectionEnabled ? '关闭采集' : '开启采集')
          .wearableButton()
          .onClick(() => {
            this.collectionEnabled = !this.collectionEnabled
            GrowingAnalytics.setDataCollectionEnabled(this.collectionEnabled)
            this.status = `dataCollectionEnabled = ${this.collectionEnabled}`
          })

        Text(`deviceId: ${GrowingAnalytics.getDeviceId()}`)
          .fontSize(10)
          .fontColor($r('sys.color.font_tertiary'))
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('80%')
      }
      .width('100%')
      .padding({ top: 40, bottom: 40, left: 16, right: 16 })
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
  }

  private toggleTimer() {
    if (this.timerId.length > 0) {
      GrowingAnalytics.trackTimerEnd(this.timerId)
      this.status = `trackTimerEnd: ${this.timerId}`
      this.timerId = ''
      return
    }
    this.timerId = GrowingAnalytics.trackTimerStart('wear_workout')
    this.status = `trackTimerStart: ${this.timerId}`
  }
}

/**
 * 手表触控面积小，统一放大点按区域，避免误触。
 */
@Extend(Button)
function wearableButton() {
  .width('80%')
  .height(40)
  .fontSize(14)
}
