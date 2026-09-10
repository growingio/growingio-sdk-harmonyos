import Util from '../../Util'

/**
 * HarmonyOS 26.0.0 适配验证入口
 *
 * 用法：同一个 HAP 分别装到 HarmonyOS 26.0.0 设备和 6.0.0(20)/5.x 设备上，
 * 按页面提示依次操作，对比两侧采集到的 PAGE / VIEW_CLICK 事件（path、xpath、xcontent、index）。
 * 事件可通过 config.debugEnabled 的日志或 GrowingToolsKit 悬浮窗查看。
 */
@Entry
@Component
struct Verify26Index {
  @State sliderValue: number = 30
  @State checked: boolean = false
  @State radioChecked: boolean = true

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('HarmonyOS 26.0.0 适配验证')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 12 })
        Text('在 26.0.0 与低版本设备上分别操作，对比事件的 path / xpath / xcontent / index')
          .fontSize(12)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .padding({ left: 16, right: 16 })

        Button('1. 主页 NavDestination（page path 归属）')
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/verify26/Verify26NavHome' })
          })
        Button('2. 弹窗族（DIALOG_PATH_PREFIXES）')
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/verify26/Verify26Dialogs' })
          })
        Button('3. 列表族（LIST_COMPONENTS 的 index）')
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/verify26/Verify26Lists' })
          })
        Button('4. Hybrid / ArkWeb 144（复用已有 Hybrid 页）')
          .onClick(() => {
            Util.startAbility(this.getUIContext(), 'HybridAbility', 'pages/Hybrid')
          })

        Divider().margin({ top: 8, bottom: 8 })

        Text('5. 圈选 UX 对照区')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Text('26.0.0 变更了表单类组件触摸热区最小高度与组件阴影模糊半径规格（targetSdkVersion ≥ 26 生效）。\n开启圈选后，对比下方元素高亮框的位置与大小是否仍与组件贴合。')
          .fontSize(12)
          .fontColor('#666666')
          .padding({ left: 16, right: 16 })

        Row({ space: 20 }) {
          Checkbox({ name: 'verify26Checkbox', group: 'verify26' })
            .select(this.checked)
            .onChange((value: boolean) => {
              this.checked = value
            })
          Radio({ value: 'verify26Radio', group: 'verify26RadioGroup' })
            .checked(this.radioChecked)
            .onChange((value: boolean) => {
              this.radioChecked = value
            })
          Toggle({ type: ToggleType.Switch, isOn: false })
        }

        Slider({ value: this.sliderValue, min: 0, max: 100, style: SliderStyle.OutSet })
          .width('80%')
          .onChange((value: number) => {
            this.sliderValue = value
          })

        Column() {
          Text('带阴影的卡片（对比阴影模糊半径）')
            .fontSize(14)
        }
        .width('80%')
        .height(80)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .shadow({ radius: 20, color: '#33000000', offsetX: 0, offsetY: 4 })
        .margin({ bottom: 24 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
