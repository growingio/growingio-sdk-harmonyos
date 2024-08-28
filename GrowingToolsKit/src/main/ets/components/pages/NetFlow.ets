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
import { GrowingToolsKit } from '../interfaces/GrowingToolsKit'
import RequestPersistence from '../network/RequestPersistence'
import { NavTitle } from '../views/Common'
import { GTKColor } from '../utils/Constants'
import Util from '../utils/Util'

@ComponentV2
export default struct NetFlow {
  @Local dataSource: (RequestPersistence | string)[] = []
  @Local isShowDetail: Map<string, boolean> = new Map()
  @Local isShowRequestDetail: boolean = true
  requests: RequestPersistence[] = []
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
    .title(this.getNavTitle)
  }

  @Builder
  private getNavTitle() {
    NavTitle({
      title: '网络记录',
      isPopup: true,
      message: '是否清空网络记录',
      confirm: '删除全部',
      confirmHandler: async () => {
        await EventDatabase.removeAllRequests()
        await this.refreshData()
      }
    })
  }

  @Builder
  private getListView() {
    List({ space: 3, scroller: this.scroller }) {
      ForEach(this.dataSource, (request: RequestPersistence | string) => {
        ListItem() {
          if (typeof request == 'string') {
            Row() {
              Text(request)
                .fontColor(GTKColor.secondaryBlack)
                .padding(10)
            }
            .backgroundColor(GTKColor.secondaryWhite)
            .width('100%')
            .height(40)
          } else {
            Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
              Column() {
                Text(request.info.statusCode + '')
                  .fontSize(16)
                  .fontColor(request.info.statusCode >= 200 && request.info.statusCode < 300
                    ? Color.Green
                    : GTKColor.tertiaryTheme)
                Text(request.info.status)
                  .fontSize(12)
                  .fontColor(GTKColor.secondaryBlack)
                  .textAlign(TextAlign.Center)
                  .minFontSize(10)
                  .maxLines(2)
              }
              .width('20%')
              Column() {
                Text(request.info.url)
                  .fontSize(12)
                  .fontColor(GTKColor.secondaryBlack)
                Row() {
                  Text(request.info.time)
                    .fontSize(12)
                    .fontColor(GTKColor.primaryBlack)
                  Blank(5)
                  Text('耗时：' + Math.floor(request.info.totalDuration) + '毫秒')
                    .fontSize(9)
                    .fontColor(GTKColor.primaryWhite)
                    .padding(4)
                    .borderRadius(4)
                    .backgroundColor(GTKColor.secondaryTheme)
                }
                Row() {
                  Text(request.info.method)
                    .fontSize(12)
                    .fontColor(GTKColor.secondaryTheme)
                  Blank(5)
                  Text('↑'
                  + (request.uploadFlow > (1024 * 1024)
                      ? ((request.uploadFlow / (1024 * 1024)).toFixed(2) + ' MB')
                      : (request.uploadFlow > 1024
                        ? ((request.uploadFlow / 1024).toFixed(2) + ' KB')
                        : request.uploadFlow.toFixed(2) + ' bytes')
                    )
                  )
                    .fontSize(12)
                    .fontColor(GTKColor.primaryBlack)
                }
              }
              .alignItems(HorizontalAlign.Start)
              .width('75%')
            }
            .padding({ top: 5, left: 5, bottom: 5, right: 5 })
            .margin({ top: 2, left: 8, bottom: 2, right: 8 })
            .borderRadius(4)
            .backgroundColor(GTKColor.primaryWhite)
            .onClick(() => {
              this.isShowDetail.set(request.uuid, true)
            })
            .bindSheet(this.isShowDetail.get(request.uuid), this.getDetailView(request), {
              height: SheetSize.LARGE,
              blurStyle: BlurStyle.Thick,
              showClose: true,
              title: this.getDetailTitle,
              preferType: SheetType.CENTER,
              shouldDismiss: (sheetDismiss: SheetDismiss) => {
                sheetDismiss.dismiss()
                this.isShowDetail.set(request.uuid, false)
                this.isShowRequestDetail = true
              },
              onWillSpringBackWhenDismiss: ((SpringBackAction: SpringBackAction) => {
                // 没有注册springBack, 下拉半模态页面无回弹行为
              }),
            })
          }
        }
      }, (request: RequestPersistence | string) => typeof request == 'string' ? request : request.uuid)
    }
    .backgroundColor(GTKColor.secondaryWhite)
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.None) // 必须设置列表为滑动到边缘无效果
  }

  @Builder
  private getDetailTitle() {
    Row() {
      Column() {
        Button('请求')
          .fontColor(this.isShowRequestDetail ? GTKColor.primaryTheme : GTKColor.primaryBlack)
          .backgroundColor(GTKColor.blackAlpha)
          .onClick(() => {
            this.isShowRequestDetail = true
          })
        if (this.isShowRequestDetail) {
          Line({width: 20, height: 1})
            .backgroundColor(GTKColor.primaryTheme)
        }
      }
      .alignItems(HorizontalAlign.Center)
      Column() {
        Button('响应')
          .fontColor(this.isShowRequestDetail ? GTKColor.primaryBlack : GTKColor.primaryTheme)
          .backgroundColor(GTKColor.blackAlpha)
          .onClick(() => {
            this.isShowRequestDetail = false
          })
        if (!this.isShowRequestDetail) {
          Line({ width: 20, height: 1 })
            .backgroundColor(GTKColor.primaryTheme)
        }
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private getDetailView(request: RequestPersistence) {
    Column() {
      if (this.isShowRequestDetail) {
        this.getDetailHeader('消息体')
        Column() {
          this.getDetailText('链接：' + request.info.url)
          this.getDetailText('请求方式：' + request.info.method)
          this.getDetailText('请求大小：' + (request.uploadFlow > (1024 * 1024)
            ? ((request.uploadFlow / (1024 * 1024)).toFixed(2) + ' MB')
            : (request.uploadFlow > 1024
              ? ((request.uploadFlow / 1024).toFixed(2) + ' KB')
              : request.uploadFlow.toFixed(2) + ' bytes'))
            + ', Body ' + (request.requestBodyLength > (1024 * 1024)
            ? ((request.requestBodyLength / (1024 * 1024)).toFixed(2) + ' MB')
            : (request.requestBodyLength > 1024
              ? ((request.requestBodyLength / 1024).toFixed(2) + ' KB')
              : request.requestBodyLength.toFixed(2) + ' bytes'))
          )
          this.getDetailText('耗时：' + Math.floor(request.info.totalDuration) + '毫秒')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 5, bottom: 5 })
        this.getDetailHeader('请求头')
        Column() {
          this.getDetailText(JSON.stringify(JSON.parse(request.info.requestHeader), null, 4))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 5, bottom: 5 })
        this.getDetailHeader('请求数据')
        Column() {
          this.getDetailRequestBody(request)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 5, bottom: 5 })
      } else {
        this.getDetailHeader('消息体')
        Column() {
          this.getDetailText('链接：' + request.info.url)
          this.getDetailText('返回码：' + request.info.statusCode)
          this.getDetailText('返回信息：' + request.info.status)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 5, bottom: 5 })
        this.getDetailHeader('响应头')
        Column() {
          this.getDetailText(JSON.stringify(JSON.parse(request.info.responseHeader), null, 4))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 5, bottom: 5 })
        if (request.responseBody && request.responseBody?.byteLength > 0) {
          this.getDetailHeader('响应数据')
          Column() {
            this.getDetailResponseBody(request)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ top: 5, bottom: 5 })
        }
      }
    }
  }

  @Builder
  private getDetailHeader(title: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(GTKColor.primaryWhite)
        .padding(10)
    }
    .backgroundColor(GTKColor.secondaryTheme)
    .width('100%')
    .height(40)
  }

  @Builder
  private getDetailText(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor(GTKColor.primaryBlack)
      .copyOption(CopyOptions.LocalDevice)
      .width('100%')
      .padding({ left: 8, right: 8 })
  }

  @Builder
  private getDetailRequestBody(request: RequestPersistence) {
    this.getDetailText(JSON.stringify(
      JSON.parse(Util.getRequestBodyText(request.info.requestHeader, request.requestBody)), null, 4))
  }

  @Builder
  private getDetailResponseBody(request: RequestPersistence) {
    this.getDetailText(JSON.stringify(request.responseBody, null, 4))
  }

  async refreshData(loadMore: boolean = false): Promise<void> {
    let pageSize = 15
    if (loadMore) {
      let createAt = this.requests[this.requests.length - 1].info.startTimestamp
      let requests = await EventDatabase.getRequestsByCount(pageSize, createAt)
      this.requests = [...this.requests, ...requests]
    } else {
      let requests = await EventDatabase.getRequestsByCount(pageSize)
      this.requests = requests
    }
    this.dataSource = this.recalculateData()
  }

  recalculateData(): (RequestPersistence | string)[] {
    let today = new Date().toISOString().split('T')[0]
    let yesterday = new Date(new Date().getTime() - 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    let currentLabel: string = ''
    return this.requests.flatMap(req => {
      let day = req.info.day
      let dateLabel = ''
      if (req.info.startTimestamp > GrowingToolsKit.gioKitStartTime) {
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
        return [dateLabel, req]
      }
      return [req]
    })
  }
}