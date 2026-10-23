/**
 * @license
 * Copyright (C) 2026 Beijing Yishu Technology Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import {
  GrowingAnalytics,
  GrowingAttrType,
  GrowingImpressionConfig,
  GrowingImpressionDelegate
} from '@growingio/analytics'

function makeGoodsList(count: number): Array<number> {
  let list: Array<number> = []
  for (let i = 0; i < count; i++) {
    list.push(i)
  }
  return list
}

@Entry
@Component
struct ViewImpression {
  @State goodsList: Array<number> = makeGoodsList(50)
  @State logs: Array<string> = []
  private delegate: GrowingImpressionDelegate = {
    viewImpressionDynamicAttributes: (componentId: string, eventName: string,
      identifier?: string): GrowingAttrType | undefined => {
      return { 'impTime': Date.now() }
    },
    viewImpressionDidTrack: (componentId: string, eventName: string, identifier?: string) => {
      this.logs = [componentId + ' -> ' + eventName, ...this.logs].slice(0, 5)
    }
  }

  aboutToAppear() {
    GrowingAnalytics.addViewImpressionDelegate(this.delegate)
  }

  aboutToDisappear() {
    GrowingAnalytics.removeViewImpressionDelegate(this.delegate)
  }

  build() {
    Column() {
      Text('banner (scale 0, repeatable)')
        .id('imp_banner')
        .width('100%')
        .height(80)
        .textAlign(TextAlign.Center)
        .backgroundColor('#FFE7D2')
        .onAppear(() => {
          GrowingAnalytics.trackViewImpression('imp_banner', 'bannerImp', { 'position': 'top' })
        })

      Row() {
        Button('resetAll')
          .onClick(() => {
            GrowingAnalytics.resetAllViewImpressionState()
          })
        Button('stop banner')
          .margin({ left: 12 })
          .onClick(() => {
            GrowingAnalytics.stopTrackViewImpression('imp_banner')
          })
      }.margin({ top: 8, bottom: 8 })

      List({ space: 8 }) {
        ForEach(this.goodsList, (item: number) => {
          ListItem() {
            Text('goods ' + item + ' (scale 0.5, stay 1s, once)')
              .width('100%')
              .height(100)
              .textAlign(TextAlign.Center)
              .backgroundColor('#F1F3F5')
          }
          .id('imp_goods_' + item)
          .onAppear(() => {
            GrowingAnalytics.trackViewImpression('imp_goods_' + item, 'goodsImp', { 'goodsId': item },
              'goods_' + item, GrowingImpressionConfig.create(0.5, 1, false))
          })
        }, (item: number) => String(item))
      }
      .layoutWeight(1)

      ForEach(this.logs, (log: string) => {
        Text(log).fontSize(12).fontColor('#666666')
      }, (log: string, index: number) => index + log)
    }
    .width('100%')
    .height('100%')
    .padding(12)
  }
}
