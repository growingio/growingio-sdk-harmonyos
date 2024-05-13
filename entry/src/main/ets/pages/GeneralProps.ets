import { GrowingAnalytics } from '@growingio/analytics'
import AppContext from '@ohos.app.ability.common'
import Want from '@ohos.app.ability.Want'
import router from '@ohos.router'

@Entry
@Component
struct GeneralProps {
  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
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
      Button('setDynamicGeneralProps')
        .onClick(() => {
          this.setDynamicGeneralProps()
        }).margin({ top: 15 })
      Button('Back')
        .onClick(() => {
          let context = getContext(this) as AppContext.UIAbilityContext
          // context.terminateSelf()
          router.back()
        }).margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
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

  setDynamicGeneralProps() {
    GrowingAnalytics.setDynamicGeneralProps(() => {
      return {'dynamicProp' : this.formatDate(new Date()) }
    })
  }

  formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    const milliseconds = String(date.getMilliseconds()).padStart(3, '0');

    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}.${milliseconds}`;
  }
}