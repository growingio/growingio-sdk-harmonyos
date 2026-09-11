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
 *
 * 注意：每个点击目标都必须挂 onClick，否则 UIObserver 的 willClick 不会针对该组件触发，
 * 事件会冒泡记到祖先节点上。
 */
@CustomDialog
struct Verify26CustomDialog {
  controller?: CustomDialogController

  build() {
    Column({ space: 16 }) {
      Text('预期 xpath 前缀 /root/Dialog')
        .fontSize(14)
      Button('click-in-custom-dialog')
        .onClick(() => {
        })
      Button('close-custom-dialog')
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
  @State selectValue: string = 'open-select'
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: Verify26CustomDialog()
  })

  @Builder
  popupBuilder() {
    Column({ space: 12 }) {
      Text('预期 /root/Popup')
        .fontSize(14)
      Button('click-in-popup')
        .onClick(() => {
        })
    }
    .padding(16)
  }

  @Builder
  menuBuilder() {
    Column({ space: 12 }) {
      Text('预期 /root/MenuWrapper')
        .fontSize(14)
      Button('click-in-menu')
        .onClick(() => {
        })
    }
    .padding(16)
  }

  @Builder
  sheetBuilder() {
    Column({ space: 12 }) {
      Text('预期 /root/SheetWrapper')
        .fontSize(14)
      Button('click-in-sheet')
        .onClick(() => {
        })
      Button('close-sheet')
        .onClick(() => {
          this.sheetVisible = false
        })
    }
    .padding(24)
  }

  @Builder
  modalBuilder() {
    Column({ space: 12 }) {
      Text('预期 /root/ModalPage')
        .fontSize(14)
      Button('click-in-modal')
        .onClick(() => {
        })
      Button('close-modal')
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
      Column({ space: 12 }) {
        Text('弹窗 xpath 验证')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 12 })
        Text('逐个打开并点击弹窗内的 click-in-* 按钮，对比 xpath 前缀与 path 回退')
          .fontSize(12)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .padding({ left: 16, right: 16 })

        Button('open-alert-dialog')
          .onClick(() => {
            this.getUIContext().showAlertDialog({
              title: 'AlertDialog',
              message: '预期 xpath 前缀 /root/AlertDialog',
              primaryButton: {
                value: 'click-in-alert-dialog',
                action: () => {
                }
              },
              secondaryButton: {
                value: 'close-alert-dialog',
                action: () => {
                }
              }
            })
          })

        Button('open-custom-dialog')
          .onClick(() => {
            this.dialogController.open()
          })

        Button('open-popup')
          .onClick(() => {
            this.popupVisible = true
          })
          .bindPopup(this.popupVisible, {
            builder: this.popupBuilder,
            // 不标注 PopupStateChangeParam：那个类型是 API 18 才有的，
            // 而工程的 compatibleSdkVersion 是 5.0.0(12)，标注了会报兼容性告警。
            // CustomPopupOptions.onStateChange 本身用的是更老的内联类型。
            onStateChange: (event) => {
              if (!event.isVisible) {
                this.popupVisible = false
              }
            }
          })

        Button('open-menu')
          .bindMenu(this.menuBuilder)

        Button('open-sheet')
          .onClick(() => {
            this.sheetVisible = true
          })
          .bindSheet(this.sheetVisible, this.sheetBuilder, {
            height: 300,
            onDisappear: () => {
              this.sheetVisible = false
            }
          })

        Button('open-modal')
          .onClick(() => {
            this.modalVisible = true
          })
          .bindContentCover(this.modalVisible, this.modalBuilder, {
            modalTransition: ModalTransition.DEFAULT,
            onDisappear: () => {
              this.modalVisible = false
            }
          })

        Select([{ value: 'select-option-0' }, { value: 'select-option-1' }, { value: 'select-option-2' }])
          .value(this.selectValue)
          .onSelect((index: number, value: string) => {
            this.selectValue = value
          })

        Text('long-press-me 长按选中这段文字，唤起文本选择菜单（预期 /root/SelectOverlay）')
          .fontSize(14)
          .copyOption(CopyOptions.LocalDevice)
          .padding({ left: 16, right: 16 })

        TextInput({ text: 'focus-textinput' })
          .width('80%')
          .margin({ bottom: 24 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
