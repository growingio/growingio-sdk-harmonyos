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

/**
 * 元素曝光验证页 - 跳转目标页
 * 返回上一页后，上一页中当前可见的曝光元素应各再上报一次
 */
@Entry
@Component
struct ViewImpressionDetail {
  build() {
    Column({ space: 16 }) {
      Text('返回上一页后，上一页中当前可见的曝光元素应各再上报一次')
        .fontSize(14)
        .fontColor('#666666')
      Text('imp_detail')
        .id('imp_detail')
        .width('100%')
        .height(100)
        .textAlign(TextAlign.Center)
        .borderRadius(8)
        .backgroundColor('#FFF8E1')
        .onAppear(() => {
          GrowingAnalytics.trackViewImpression('imp_detail', 'imp_detail')
        })
      Button('返回')
        .onClick(() => {
          this.getUIContext().getRouter().back()
        })
    }
    .width('100%')
    .height('100%')
    .padding(12)
  }
}
