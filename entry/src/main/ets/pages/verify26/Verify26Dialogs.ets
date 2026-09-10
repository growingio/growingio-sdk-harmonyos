/**
 * 验证点 2：弹窗族的 xpath 前缀（SDK 常量 DIALOG_PATH_PREFIXES）
 *
 * 26.0.0 相关变更（targetSdkVersion ≥ 26 生效）：
 * Dialog、Toast、AlphabetIndexer 和文本选择菜单默认开启沉浸式系统材质，
 * 弹窗的节点树包装层有可能变化。
 *
 * 需要对比的内容：点击每类弹窗内的按钮，检查 VIEW_CLICK 事件的
 * 1) xpath 是否仍以 /root/AlertDialog、/root/Dialog、/root/Popup、/root/MenuWrapper、
 *    /root/SheetWrapper、/root/ModalPage、/root/SelectOverlay、/root/Keyboard 开头；
 * 2) path 是否正确回退到宿主页面 /pages/verify26/Verify26Dialogs。
 */
@CustomDialog
struct Verify26CustomDialog {
  controller?: CustomDialogController

  build() {
    Column({ space: 16 }) {
      Text('CustomDialog（预期 xpath 前缀 /root/Dialog）')
        .fontSize(14)
      Button('click-in-custom-dialog')
      Button('关闭')
        .onClick(() => {
          this.controller?.close()
        })
    }
    .padding(24)
  }
}

@Entry
@Component
struct Verify26Dialogs {
  @State popupVisible: boolean = false
  @State sheetVisible: boolean = false
  @State modalVisible: boolean = false
  @State selectValue: string = 'Select'
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: Verify26CustomDialog()
  })

  @Builder
  popupBuilder() {
    Column({ space: 12 }) {
      Text('Popup（预期 /root/Popup）')
        .fontSize(14)
      Button('click-in-popup')
    }
    .padding(16)
  }

  @Builder
  menuBuilder() {
    Column({ space: 12 }) {
      Text('Menu（预期 /root/MenuWrapper）')
        .fontSize(14)
      Button('click-in-menu')
    }
    .padding(16)
  }

  @Builder
  sheetBuilder() {
    Column({ space: 12 }) {
      Text('Sheet 半模态（预期 /root/SheetWrapper）')
        .fontSize(14)
      Button('click-in-sheet')
      Button('关闭')
        .onClick(() => {
          this.sheetVisible = false
        })
    }
    .padding(24)
  }

  @Builder
  modalBuilder() {
    Column({ space: 12 }) {
      Text('ContentCover 全模态（预期 /root/ModalPage）')
        .fontSize(14)
      Button('click-in-modal')
      Button('关闭')
        .onClick(() => {
          this.modalVisible = false
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.White)
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('弹窗 xpath 验证')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 12 })
        Text('逐个打开并点击弹窗内的按钮，对比 xpath 前缀与 path 回退')
          .fontSize(12)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .padding({ left: 16, right: 16 })

        Button('AlertDialog（预期 /root/AlertDialog）')
          .onClick(() => {
            this.getUIContext().showAlertDialog({
              title: 'AlertDialog',
              message: '点击下方按钮后对比 xpath 前缀',
              primaryButton: {
                value: 'click-in-alert-dialog',
                action: () => {
                }
              },
              secondaryButton: {
                value: '关闭',
                action: () => {
                }
              }
            })
          })

        Button('CustomDialog（预期 /root/Dialog）')
          .onClick(() => {
            this.dialogController.open()
          })

        Button('Popup（预期 /root/Popup）')
          .onClick(() => {
            this.popupVisible = true
          })
          .bindPopup(this.popupVisible, {
            builder: this.popupBuilder,
            onStateChange: (event: PopupStateChangeParam) => {
              if (!event.isVisible) {
                this.popupVisible = false
              }
            }
          })

        Button('Menu 长按（预期 /root/MenuWrapper）')
          .bindMenu(this.menuBuilder)

        Button('Sheet 半模态（预期 /root/SheetWrapper）')
          .onClick(() => {
            this.sheetVisible = true
          })
          .bindSheet(this.sheetVisible, this.sheetBuilder, {
            height: 300,
            onDisappear: () => {
              this.sheetVisible = false
            }
          })

        Button('ContentCover 全模态（预期 /root/ModalPage）')
          .onClick(() => {
            this.modalVisible = true
          })
          .bindContentCover(this.modalVisible, this.modalBuilder, {
            modalTransition: ModalTransition.DEFAULT,
            onDisappear: () => {
              this.modalVisible = false
            }
          })

        Select([{ value: 'option-0' }, { value: 'option-1' }, { value: 'option-2' }])
          .value(this.selectValue)
          .onSelect((index: number, value: string) => {
            this.selectValue = value
          })

        Text('长按选中这段文字，唤起文本选择菜单（预期 /root/SelectOverlay）')
          .fontSize(14)
          .copyOption(CopyOptions.LocalDevice)
          .padding({ left: 16, right: 16 })

        TextInput({ placeholder: '点击弹出键盘（预期 /root/Keyboard）' })
          .width('80%')
          .margin({ bottom: 24 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
