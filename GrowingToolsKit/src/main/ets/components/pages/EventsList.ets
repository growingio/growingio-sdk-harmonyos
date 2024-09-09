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

import { PullToRefresh } from '../views/PullToRefresh'
import EventDatabase from '../event/EventDatabase'
import EventPersistence from '../event/EventPersistence'
import { GrowingToolsKit } from '../interfaces/GrowingToolsKit'
import { NavTitle } from '../views/Common'
import { GTKColor, EventScene, MAIN_TRACKER_ID } from '../utils/Constants'
import TrackerTabBar from '../views/TrackerTabBar'
import TrackersInfo from '../core/TrackersInfo'

@ComponentV2
export default struct EventsList {
  @Local dataSource: EventsListDataSource = new EventsListDataSource()
  @Local isShowDetail: Map<string, boolean> = new Map()
  @Provider() trackerId: string = ''
  @Monitor('trackerId')
  onTrackerIdChange(monitor: IMonitor) {
    let trackerId = monitor.value()?.now as string
    if (trackerId.length > 0) {
      if (trackerId == MAIN_TRACKER_ID) {
        this.accountId = GrowingToolsKit.sdkConfig.accountId
        this.dataSourceId = GrowingToolsKit.sdkConfig.dataSourceId
      } else {
        TrackersInfo.info.forEach(info => {
          if (info.trackerId == trackerId) {
            this.accountId = info.config.accountId
            this.dataSourceId = info.config.dataSourceId
          }
        })
      }
    } else {
      this.accountId = ''
      this.dataSourceId = ''
    }
    this.refreshData()
  }
  accountId: string = ''
  dataSourceId: string = ''
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.refreshData()
  }

  build() {
    NavDestination() {
      Column() {
        TrackerTabBar()
        PullToRefresh({
          avoidAreaHeight: 40,
          scroller: this.scroller,
          customList: () => {
            this.getListView()
          },
          onRefresh: () => {
            return this.refreshData().then(() => {return '刷新成功'})
          },
          onLoadMore: () => {
            return this.refreshData(true).then(() => {return ''})
          },
          customLoad: null,
          customRefresh: null,
        })
      }
    }
    .title(this.getNavTitle)
  }

  @Builder
  private getNavTitle() {
    NavTitle({
      title: '事件库',
      isPopup: true,
      message: '是否清空事件库',
      confirm: '删除全部',
      confirmHandler: async () => {
        await EventDatabase.removeAllEvents()
        await this.refreshData()
      }
    })
  }

  @Builder
  private getListView() {
    List({ space: 3, scroller: this.scroller }) {
      LazyForEach(this.dataSource, (event: EventPersistence | string) => {
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
            Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
              Text(event.sequenceId() ?? '-')
                .textAlign(TextAlign.Center)
                .width('10%')
              Column() {
                Row() {
                  Text(event.eventType)
                    .constraintSize({maxWidth: '80%'})
                  if (event.eventScene == EventScene.Hybrid) {
                    Blank(5)
                    Text('Hybrid')
                      .fontSize(11)
                      .fontColor(GTKColor.primaryWhite)
                      .padding(4)
                      .borderRadius(4)
                      .backgroundColor(GTKColor.hybridTagLabel)
                      .alignSelf(ItemAlign.Start)
                  }
                  if (event.eventScene == EventScene.Flutter) {
                    Blank(5)
                    Text('Flutter')
                      .fontSize(11)
                      .fontColor(GTKColor.primaryWhite)
                      .padding(4)
                      .borderRadius(4)
                      .backgroundColor(GTKColor.flutterTagLabel)
                      .alignSelf(ItemAlign.Start)
                  }
                }
                if (event.path()) {
                  Text(event.path())
                }
              }
              .width('50%')
              .padding({ top: 5, bottom: 5 })
              .alignItems(HorizontalAlign.Start)
              Text(event.isSend ? '已发送' : '未发送')
                .fontColor(event.isSend ? GTKColor.primaryLabel : GTKColor.tertiaryTheme)
              Text(event.time())
            }
            .constraintSize({minHeight: 45})
            .margin({left: 8, right: 8 })
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
      }, (event: EventPersistence | string) => typeof event == 'string' ? event : event.uuid + String(event.isSend))
    }
    .width('100%')
    .height('100%')
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
      let originDataSource = this.dataSource.getAllData()
      let createAt = (originDataSource[originDataSource.length - 1] as EventPersistence).createAt
      let events = await EventDatabase.getEventsByCount(pageSize, createAt, this.accountId, this.dataSourceId)
      let dataSource = this.recalculateData(events, originDataSource)
      this.dataSource.pushData(dataSource)
    } else {
      let events = await EventDatabase.getEventsByCount(pageSize, 0, this.accountId, this.dataSourceId)
      let dataSource = this.recalculateData(events)
      this.dataSource.reloadData(dataSource)
    }
  }

  recalculateData(
    data: EventPersistence[],
    originData?: (EventPersistence | string)[]
  ): (EventPersistence | string)[] {
    let today = new Date().toISOString().split('T')[0]
    let yesterday = new Date(new Date().getTime() - 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    let currentLabel: string = ''
    return data.flatMap(e => {
      let day = e.day()
      let dateLabel = ''
      if (e.createAt > GrowingToolsKit.gioKitStartTime) {
        dateLabel = '运行期间'
      } else if (day == today) {
        dateLabel = '今日'
      } else if (day == yesterday) {
        dateLabel = '昨日'
      } else {
        dateLabel = day
      }

      if (currentLabel != dateLabel) {
        currentLabel = dateLabel
        if (originData && originData.indexOf(dateLabel) > 0) {
          return [e]
        }
        return [dateLabel, e]
      }
      return [e]
    })
  }
}

class EventsListDataSource implements IDataSource {
  private listeners: DataChangeListener[] = []
  private dataSource: (EventPersistence | string)[] = []

  public totalCount(): number {
    return this.dataSource.length
  }

  public getData(index: number): EventPersistence | string {
    return this.dataSource[index]
  }

  public getAllData(): (EventPersistence | string)[] {
    return [...this.dataSource]
  }

  public reloadData(data: (EventPersistence | string)[]): void {
    this.dataSource = data
    this.notifyDataReload()
  }

  public pushData(data: (EventPersistence | string)[]): void {
    let index = this.dataSource.length - 1
    this.dataSource = [...this.dataSource, ...data]
    this.notifyDataAdd(index, data.length)
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDatasetChange([{
        type: DataOperationType.RELOAD
      }])
    })
  }

  notifyDataAdd(index: number, count: number): void {
    this.listeners.forEach(listener => {
      listener.onDatasetChange([{
        type: DataOperationType.ADD,
        index: index,
        count: count
      }])
    })
  }
}