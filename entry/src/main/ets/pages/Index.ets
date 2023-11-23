import { GrowingAnalytics } from '@growingio/analytics'

@Entry
@Component
struct Index {
  @State message: string = 'Hello World'

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Button('track')
        .onClick(() => {
          this.track()
        }).margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
  }

  track() {
    GrowingAnalytics.track('buyProduct', {
      'name': 'apple',
      'money': 1000,
      'num': 100,
      'from': ['sichuan', 'guizhou', 'hunan']
    })
  }
}