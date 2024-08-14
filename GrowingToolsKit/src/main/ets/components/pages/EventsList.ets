/**
 * @license
 * Copyright (C) 2024 Beijing Yishu Technology Co., Ltd.
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

import { PullToRefresh } from '@ohos/pulltorefresh'
import EventDatabase from '../event/EventDatabase'
import EventPersistence, { EventScene } from '../event/EventPersistence'
import { GTKColor } from '../utils/Constants'

@ComponentV2
export default struct EventsList {
  @Local dataSource: (EventPersistence | string)[] = []
  @Local isShowDetail: Map<string, boolean> = new Map()
  events: EventPersistence[] = []
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.refreshData()
  }

  build() {
    NavDestination() {
      Column() {
        PullToRefresh({
          data: this.dataSource,
          scroller: this.scroller,
          customList: () => {
            this.getListView()
          },
          onRefresh: () => {
            return new Promise<string>((resolve, reject) => {
              this.refreshData().then(() => {
                resolve('刷新成功')
              })
            })
          },
          onLoadMore: () => {
            return new Promise<string>((resolve, reject) => {
              this.refreshData(true).then(() => {
                resolve('')
              })
            });
          },
          customLoad: null,
          customRefresh: null,
        })
      }
    }
  }

  @Builder
  private getListView() {
    List({ space: 3, scroller: this.scroller }) {
      ForEach(this.dataSource, (event: EventPersistence | string) => {
        ListItem() {
          if (typeof event == 'string') {
            Row() {
              Text(event)
                .fontColor(GTKColor.primaryWhite)
                .padding(10)
            }
            .backgroundColor(GTKColor.secondaryTheme)
            .width('100%')
            .height(40)
          } else {
            Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceAround }) {
              Text(event.sequenceId() ?? '-')
              Column() {
                Row() {
                  Text(event.eventType)
                  if (event.eventScene == EventScene.Hybrid) {
                    Blank(5)
                    Text('Hybrid')
                      .fontSize(11)
                      .fontColor(GTKColor.primaryWhite)
                      .padding(4)
                      .borderRadius(4)
                      .backgroundColor(GTKColor.hybridTagLabel)
                  }
                  if (event.eventScene == EventScene.Flutter) {
                    Blank(5)
                    Text('Flutter')
                      .fontSize(11)
                      .fontColor(GTKColor.primaryWhite)
                      .padding(4)
                      .borderRadius(4)
                      .backgroundColor(GTKColor.flutterTagLabel)
                  }
                }
                if (event.path()) {
                  Text(event.path())
                }
              }
              .width('50%')
              .alignItems(HorizontalAlign.Start)
              Text(event.isSend ? '已发送' : '未发送')
                .fontColor(event.isSend ? GTKColor.primaryLabel : GTKColor.tertiaryTheme)
              Text(event.time())
            }
            .width('100%')
            .height(45)
            .onClick(() => {
              this.isShowDetail.set(event.uuid, true)
            })
            .bindSheet(this.isShowDetail.get(event.uuid), this.getDetailView(event), {
              height: SheetSize.LARGE,
              blurStyle: BlurStyle.Thick,
              showClose: true,
              title: { title: event.eventType },
              preferType: SheetType.CENTER,
              shouldDismiss: (sheetDismiss: SheetDismiss) => {
                sheetDismiss.dismiss()
                this.isShowDetail.set(event.uuid, false)
              },
              onWillSpringBackWhenDismiss: ((SpringBackAction: SpringBackAction) => {
                // 没有注册springBack, 下拉半模态页面无回弹行为
              }),
            })
          }
        }
      })
    }
    .backgroundColor(GTKColor.primaryWhite)
    .divider({ strokeWidth: 0.5, startMargin: 10, color: GTKColor.tertiaryBlack })
    .edgeEffect(EdgeEffect.None) // 必须设置列表为滑动到边缘无效果
  }

  @Builder
  private getDetailView(event: EventPersistence) {
    Column() {
      Text(JSON.stringify(JSON.parse(event.data), null, 4))
        .copyOption(CopyOptions.LocalDevice)
    }
  }

  async refreshData(loadMore: boolean = false): Promise<void> {
    let pageSize = 50
    if (loadMore) {
      let createAt = this.events[this.events.length - 1].createAt
      let events = await EventDatabase.getEventsByCount(pageSize, createAt)
      this.events = [...this.events, ...events]
    } else {
      let events = await EventDatabase.getEventsByCount(pageSize)
      this.events = events
    }
    this.dataSource = this.recalculateData()
  }

  recalculateData(): (EventPersistence | string)[] {
    let today = new Date().toISOString().split('T')[0]
    let yesterday = new Date(new Date().getTime() - 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    let currentDate: string = ''
    return this.events.flatMap(e => {
      let day = e.day()
      let dateLabel = day
      if (day == today) {
        dateLabel = '今日'
      } else if (day == yesterday) {
        dateLabel = '昨日'
      }

      if (day != currentDate) {
        currentDate = day
        return [dateLabel, e]
      }
      return [e]
    })
  }
}