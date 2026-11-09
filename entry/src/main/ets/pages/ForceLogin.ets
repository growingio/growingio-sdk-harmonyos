import { GrowingAnalytics } from '@growingio/analytics'
import Util from '../Util'
import DemoSettings from '../DemoSettings'

const SDK_MODE_NEW_SAAS: number = 0
const PENDING_MARKER: string = 'growingio_force_login_pending'

@Entry
@Component
struct ForceLogin {
  @StorageProp('sdkMode') sdkMode: number = 0
  @StorageProp('forceLogin') currentForceLogin: boolean = false
  @State nextLaunchForceLogin: boolean = false
  @State inputDeviceId: string = ''
  @State deviceId: string = ''
  @State trackCount: number = 0
  @State logs: string[] = []

  aboutToAppear(): void {
    let context = this.getUIContext().getHostContext()
    if (context) {
      this.nextLaunchForceLogin = DemoSettings.isForceLoginEnabled(context)
    }
    this.refreshDeviceId()
  }

  build() {
    Column({ space: 10 }) {
      Text('本次启动：mode = ' + this.modeName() + '，forceLogin = ' + this.currentForceLogin)
        .fontSize(14)
      Text('getDeviceId() = ' + this.deviceId)
        .fontSize(14)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 10 }) {
        Text('下次启动开启 forceLogin').fontSize(14)
        Toggle({ type: ToggleType.Switch, isOn: this.nextLaunchForceLogin })
          .onChange((isOn: boolean) => {
            this.setNextLaunchForceLogin(isOn)
          })
      }
      Text('切换后需结束进程并重新打开 App 才会生效')
        .fontSize(12)
        .fontColor(Color.Gray)

      TextInput({ placeholder: '输入访问用户 ID', text: this.inputDeviceId })
        .onChange((value: string) => {
          this.inputDeviceId = value
        })
      Row({ space: 10 }) {
        Button('identify(输入值)')
          .onClick(() => {
            this.identify(this.inputDeviceId, '输入值')
          })
        Button('identify(随机)')
          .onClick(() => {
            this.identify('visitor_' + Util.getRandomString(), '随机')
          })
      }
      Row({ space: 10 }) {
        Button('identify(空)')
          .onClick(() => {
            this.identify('', '空字符串')
          })
        Button('identify(标记)')
          .onClick(() => {
            this.identify(PENDING_MARKER, '保留标记')
          })
        Button('identify(1001)')
          .onClick(() => {
            this.identify('x'.repeat(1000) + 'y', '1001 字符')
          })
      }
      Row({ space: 10 }) {
        Button('track 事件')
          .onClick(() => {
            this.track()
          })
        Button('刷新 deviceId')
          .onClick(() => {
            this.refreshDeviceId()
            this.addLog('getDeviceId() = ' + this.deviceId)
          })
      }

      Text('操作记录（identify 是否生效请结合 debug 日志确认）')
        .fontSize(12)
        .fontColor(Color.Gray)
      List({ space: 4 }) {
        ForEach(this.logs, (log: string) => {
          ListItem() {
            Text(log).fontSize(12)
          }
        }, (log: string, index: number) => index + '_' + log)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .padding(16)
    .width('100%')
    .height('100%')
  }

  modeName(): string {
    if (this.sdkMode === SDK_MODE_NEW_SAAS) {
      return 'NewSaaS'
    }
    return this.sdkMode === 1 ? 'SaaS' : 'CDP'
  }

  setNextLaunchForceLogin(enabled: boolean) {
    this.nextLaunchForceLogin = enabled
    let context = this.getUIContext().getHostContext()
    if (context) {
      DemoSettings.setForceLoginEnabled(context, enabled)
    }
    this.addLog('下次启动 forceLogin = ' + enabled)
  }

  identify(deviceId: string, desc: string) {
    let before = GrowingAnalytics.getDeviceId()
    GrowingAnalytics.identify(deviceId)
    this.refreshDeviceId()
    let changed = before !== this.deviceId ? '已变化' : '未变化'
    this.addLog('identify(' + desc + ')，getDeviceId() ' + changed + '：' + this.shorten(this.deviceId))
  }

  track() {
    this.trackCount++
    GrowingAnalytics.track('force_login_test', {
      'seq': this.trackCount,
      'forceLogin': this.currentForceLogin
    })
    this.addLog('track force_login_test #' + this.trackCount)
  }

  refreshDeviceId() {
    this.deviceId = GrowingAnalytics.getDeviceId()
  }

  addLog(message: string) {
    let time = Util.formatDate(new Date()).substring(11)
    this.logs = [time + '  ' + message, ...this.logs]
  }

  shorten(value: string): string {
    return value.length > 40 ? value.substring(0, 40) + '…(' + value.length + ')' : value
  }
}
