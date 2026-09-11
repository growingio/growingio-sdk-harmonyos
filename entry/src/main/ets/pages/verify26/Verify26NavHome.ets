/**
 * 验证点 1：主页 NavDestination（HomePathInfo，API 20 起）
 *
 * 注意：每个点击目标都必须挂 onClick，否则 UIObserver 的 willClick 不会针对该组件触发。
 *
 * 26.0.0 行为变更（全部生效，不受 targetSdkVersion 隔离）：
 * queryNavDestinationInfo 变更后可以取到"主页 NavDestination"的信息，此前取不到。
 *
 * 需要对比的内容：
 * 1) 进入本页时，PAGE 事件的 path 是 /pages/verify26/Verify26NavHome（router 页面）
 *    还是 /Verify26NavHome（主页 NavDestination）；
 * 2) 点击主页 NavDestination 内的按钮时，VIEW_CLICK 事件的 path 归属到哪一个；
 * 3) push 到 Detail 再返回主页，PAGE 事件是否重复/缺失。
 */
@Entry
@Component
struct Verify26NavHome {
  private stack: NavPathStack = new NavPathStack()

  @Builder
  pageMap(name: string) {
    if (name === 'Verify26NavDetail') {
      Verify26NavDetail()
    } else {
      Verify26NavHomeDestination()
    }
  }

  build() {
    Navigation(this.stack, { name: 'Verify26NavHome' })
      .title('Verify26NavHome')
      .mode(NavigationMode.Stack)
      .navDestination(this.pageMap)
      .width('100%')
      .height('100%')
  }
}

@Component
struct Verify26NavHomeDestination {
  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('这是通过 HomePathInfo 指定的主页 NavDestination')
          .fontSize(14)
          .textAlign(TextAlign.Center)
        Text('对比 PAGE 事件的 path：router 页面路径 vs /Verify26NavHome')
          .fontSize(12)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
        Button('click-in-home-navdestination')
          .onClick(() => {
          })
        Button('push -> Verify26NavDetail')
          .onClick(() => {
            this.queryNavigationInfo()?.pathStack.pushPath({ name: 'Verify26NavDetail' })
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding(16)
    }
    .title('Verify26NavHome')
  }
}

@Component
struct Verify26NavDetail {
  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('二级 NavDestination')
          .fontSize(14)
        Button('click-in-detail-navdestination')
          .onClick(() => {
          })
        Button('pop -> 返回主页 NavDestination')
          .onClick(() => {
            this.queryNavigationInfo()?.pathStack.pop()
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding(16)
    }
    .title('Verify26NavDetail')
  }
}
