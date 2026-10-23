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

import { GrowingAnalytics } from '@growingio/analytics'

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

  build() {
    Column() {
      Text('banner')
        .id('imp_banner')
        .width('100%')
        .height(80)
        .textAlign(TextAlign.Center)
        .backgroundColor('#FFE7D2')
        .onAppear(() => {
          GrowingAnalytics.trackViewImpression('imp_banner', 'bannerImp', { 'position': 'top' })
        })

      Button('stop banner')
        .margin({ top: 8, bottom: 8 })
        .onClick(() => {
          GrowingAnalytics.stopTrackViewImpression('imp_banner')
        })

      List({ space: 8 }) {
        ForEach(this.goodsList, (item: number) => {
          ListItem() {
            Text('goods ' + item)
              .width('100%')
              .height(100)
              .textAlign(TextAlign.Center)
              .backgroundColor('#F1F3F5')
          }
          .id('imp_goods_' + item)
          .onAppear(() => {
            GrowingAnalytics.trackViewImpression('imp_goods_' + item, 'goodsImp', { 'goodsId': item })
          })
        }, (item: number) => String(item))
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(12)
  }
}
