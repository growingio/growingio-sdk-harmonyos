import { GrowingAnalytics } from '@growingio/analytics'
import Util from '../Util'

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
          // let context = getContext(this) as AppContext.UIAbilityContext
          // context.terminateSelf()
          this.getUIContext().getRouter().back()
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
      return {'dynamicProp' : Util.formatDate(new Date()) }
    })
  }
}