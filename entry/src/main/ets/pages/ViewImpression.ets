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

// 与 ConfigMode.NewSaaS 一致
const SDK_MODE_NEW_SAAS = 0

const ID_BASIC = 'imp_basic'
const ID_ATTRS = 'imp_attrs'
const ID_TOGGLE = 'imp_toggle'
const ID_GOODS_PREFIX = 'imp_goods_'

function makeGoodsList(count: number): Array<number> {
  let list: Array<number> = []
  for (let i = 0; i < count; i++) {
    list.push(i)
  }
  return list
}

/**
 * 元素曝光验证页
 *
 * 曝光事件为埋点事件（CUSTOM），可通过以下方式查看：
 * 1. GrowingToolsKit 悬浮窗 → 事件库
 * 2. hilog 中搜索 "Track custom event with eventName: imp_"（debugEnabled 为 true 时输出）
 * 3. hilog 中搜索 "[ViewImpression]" 查看标记被忽略的原因（如非 NewSaaS 模式）
 *
 * 全局曝光条件在 EntryAbilityStage 中通过 config.viewImpressionConfig 设置
 *
 * 注意：.id() 与调用 trackViewImpression 的 onAppear 需设置在同一个组件上
 */
@Entry
@Component
struct ViewImpression {
  @StorageProp('sdkMode') sdkMode: number = SDK_MODE_NEW_SAAS
  @State basicMarked: boolean = true
  @State attrsVersion: number = 1
  @State toggleVisible: boolean = true
  @State goodsList: Array<number> = makeGoodsList(30)
  @State tip: string = ''

  build() {
    Column() {
      Text(this.sdkMode == SDK_MODE_NEW_SAAS
        ? '当前为 NewSaaS 模式，曝光采集可用'
        : '当前非 NewSaaS 模式，曝光采集不可用（trackViewImpression 将被忽略）')
        .fontSize(13)
        .fontColor(this.sdkMode == SDK_MODE_NEW_SAAS ? '#2E7D32' : '#C62828')
        .width('100%')
      Text('全局曝光条件（见 EntryAbilityStage）：可见面积 ≥ 50% 且连续可见 ≥ 1 秒\n曝光事件请在 GrowingToolsKit「事件库」或 hilog 中查看')
        .fontSize(12)
        .fontColor('#666666')
        .width('100%')
        .margin({ top: 4 })
      if (this.tip.length > 0) {
        Text(this.tip)
          .fontSize(12)
          .fontColor('#1565C0')
          .width('100%')
          .margin({ top: 4 })
      }

      List({ space: 12 }) {
        // ─── 1. 基础标记 / 停止标记 ───
        ListItem() {
          Column({ space: 8 }) {
            this.CaseTitle('1. 基础标记 / 停止标记',
              '进入页面后上报 imp_basic；停止后滚出再滚回不再上报；重新标记后再上报一次')
            Column() {
              this.Target('imp_basic（无属性）' + (this.basicMarked ? '' : ' - 已停止'), '#FFE7D2')
            }
            .id(ID_BASIC)
            .onAppear(() => {
              if (this.basicMarked) {
                GrowingAnalytics.trackViewImpression(ID_BASIC, 'imp_basic')
              }
            })
            Row({ space: 12 }) {
              Button('停止标记')
                .onClick(() => {
                  GrowingAnalytics.stopTrackViewImpression(ID_BASIC)
                  this.basicMarked = false
                  this.tip = '已停止 imp_basic，之后不会再上报'
                })
              Button('重新标记')
                .onClick(() => {
                  GrowingAnalytics.trackViewImpression(ID_BASIC, 'imp_basic')
                  this.basicMarked = true
                  this.tip = '已重新标记 imp_basic，满足曝光条件后应上报一次'
                })
            }
          }
        }

        // ─── 2. 带属性 / 重复标记 ───
        ListItem() {
          Column({ space: 8 }) {
            this.CaseTitle('2. 带属性 / 重复标记',
              '原样重标不应再上报；改属性重标应再上报一次，且属性 version 为新值')
            Column() {
              this.Target('imp_attrs（version = ' + this.attrsVersion + '）', '#E3F2FD')
            }
            .id(ID_ATTRS)
            .onAppear(() => {
              this.markAttrs()
            })
            Row({ space: 12 }) {
              Button('原样重标')
                .onClick(() => {
                  this.markAttrs()
                  this.tip = '原样重标 imp_attrs，不应再上报'
                })
              Button('改属性重标')
                .onClick(() => {
                  this.attrsVersion += 1
                  this.markAttrs()
                  this.tip = '改属性重标 imp_attrs（version = ' + this.attrsVersion + '），满足曝光条件后应再上报一次'
                })
            }
          }
        }

        // ─── 3. 组件移除 / 重新出现 ───
        ListItem() {
          Column({ space: 8 }) {
            this.CaseTitle('3. 组件移除 / 重新出现',
              '隐藏后组件被移除，标记随之移除；再次显示时在 onAppear 中重新标记并上报')
            if (this.toggleVisible) {
              Column() {
                this.Target('imp_toggle', '#E8F5E9')
              }
              .id(ID_TOGGLE)
              .onAppear(() => {
                GrowingAnalytics.trackViewImpression(ID_TOGGLE, 'imp_toggle', { 'from': 'toggle' })
              })
            }
            Button(this.toggleVisible ? '隐藏组件' : '显示组件')
              .onClick(() => {
                this.toggleVisible = !this.toggleVisible
                this.tip = this.toggleVisible ? '已显示 imp_toggle，满足曝光条件后应上报一次' : '已隐藏 imp_toggle'
              })
          }
        }

        // ─── 4. 页面跳转 / 前后台 ───
        ListItem() {
          Column({ space: 8 }) {
            this.CaseTitle('4. 页面跳转 / 前后台',
              '跳转后返回：当前可见的曝光元素应各再上报一次\n退到后台再回前台：不应再上报')
            Button('跳转到下一页')
              .onClick(() => {
                this.getUIContext().getRouter().pushUrl({ url: 'pages/ViewImpressionDetail' })
              })
          }
        }

        // ─── 5. 列表滚动 ───
        ListItem() {
          this.CaseTitle('5. 列表滚动',
            '每个商品满足曝光条件时上报 imp_goods（属性 goodsId）；露出不足 50% 或停留不足 1 秒不上报；滚出后再滚回会再次上报，停留在可视区内不会重复上报')
        }

        ForEach(this.goodsList, (item: number) => {
          ListItem() {
            this.Target('imp_goods（goodsId = ' + item + '）', '#F1F3F5')
          }
          .id(ID_GOODS_PREFIX + item)
          .onAppear(() => {
            GrowingAnalytics.trackViewImpression(ID_GOODS_PREFIX + item, 'imp_goods', { 'goodsId': item })
          })
        }, (item: number): string => String(item))
      }
      .layoutWeight(1)
      .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .padding(12)
  }

  markAttrs() {
    GrowingAnalytics.trackViewImpression(ID_ATTRS, 'imp_attrs', { 'version': this.attrsVersion })
  }

  @Builder
  CaseTitle(title: string, desc: string) {
    Column({ space: 4 }) {
      Text(title).fontSize(15).fontWeight(FontWeight.Medium)
      Text(desc).fontSize(12).fontColor('#666666')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  Target(label: string, color: string) {
    Text(label)
      .width('100%')
      .height(100)
      .textAlign(TextAlign.Center)
      .borderRadius(8)
      .backgroundColor(color)
  }
}
