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

import { GrowingToolsKit } from '../interfaces/GrowingToolsKit'
import { NavTitle } from '../views/Common'
import { ConfigMode, GTKColor } from '../utils/Constants'
import TrackersInfo from '../core/TrackersInfo'

class _SdkInfo {
  key: string
  value: string

  constructor(key: string, value: string) {
    this.key = key
    this.value = value
  }
}

@ComponentV2
export default struct SdkInfo {
  @Local isExpand: Map<string, boolean> = new Map()
  @Local data: Map<string, _SdkInfo[]> = new Map()
  @Local dataSource: string[] = []

  aboutToAppear(): void {
    this.refreshData()
  }

  build() {
    NavDestination() {
      List({ space: 3 }) {
        ForEach(this.dataSource, (header: string) => {
          ListItemGroup({ header: this.itemHead(header) }) {
            if (this.isExpand.get(header)) {
              ForEach(this.data.get(header), (info: _SdkInfo) => {
                ListItem() {
                  Flex() {
                    Text(info.key)
                      .padding({ left: 10, right: 15 })
                    Blank()
                    Text(info.value)
                      .flexBasis('auto')
                      .padding({ left: 15, right: 10 })
                  }
                  .padding({ top: 10, bottom: 10 })
                  .width('100%')
                }
              })
            }
          }
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(GTKColor.primaryWhite)
      .divider({ strokeWidth: 0.5, startMargin: 10, color: GTKColor.tertiaryBlack })
    }
    .title(this.getNavTitle)
  }

  @Builder itemHead(header: string) {
    Row() {
      Text(header)
        .fontColor(GTKColor.primaryWhite)
        .padding(10)
      Blank()
      Image($r('app.media.growingtk_arrow_right'))
        .width(30)
        .height(30)
        .rotate({angle: this.isExpand.get(header) ? 90 : 0})
    }
    .backgroundColor(GTKColor.secondaryTheme)
    .width('100%')
    .height(40)
    .onClick(() => {
      this.isExpand.set(header, !this.isExpand.get(header))
    })
  }

  @Builder
  private getNavTitle() {
    NavTitle({
      title: 'SDK信息',
      isPopup: false
    })
  }

  refreshData() {
    this.data = new Map()
    this.refreshDataForMainTracker()
    this.refreshDataForSubTrackers()

    this.dataSource = []
    this.isExpand = new Map()
    this.data.forEach((infoList, header) => {
      this.dataSource.push(header)
      this.isExpand.set(header, true)
    })
  }

  refreshDataForMainTracker() {
    let header = '主实例'
    let infoList: _SdkInfo[] = []

    let config = GrowingToolsKit.sdkConfig
    let mode = '-New SaaS'
    if (config.mode == ConfigMode.SaaS) {
      mode = '-SaaS'
    } else if (config.mode == ConfigMode.CDP) {
      mode = '-CDP'
    }
    infoList.push(new _SdkInfo('SDK', 'GrowingAnalytics' + mode))
    infoList.push(new _SdkInfo('SDK版本号', GrowingToolsKit.sdkVersion))

    let time = GrowingToolsKit.sdkEndTime - GrowingToolsKit.sdkStartTime
    infoList.push(new _SdkInfo('初始化耗时', String(time) + 'ms'))

    infoList.push(new _SdkInfo('AccountId', config.accountId))
    infoList.push(new _SdkInfo('DataSourceId', config.dataSourceId))
    infoList.push(new _SdkInfo('ServerHost', config.dataCollectionServerHost))
    infoList.push(new _SdkInfo('URL Scheme', config.urlScheme))
    infoList.push(new _SdkInfo('调试模式', config.debugEnabled ? 'YES' : 'NO'))
    infoList.push(new _SdkInfo('数据加密', config.encryptEnabled ? 'YES' : 'NO'))
    infoList.push(new _SdkInfo('数据压缩', config.compressEnabled ? 'YES' : 'NO'))
    infoList.push(new _SdkInfo('数据发送间隔', String(config._dataUploadInterval / 1000)))
    infoList.push(new _SdkInfo('会话后台留存时长', String(config._sessionInterval / 1000)))
    infoList.push(new _SdkInfo('是否采集数据', config.dataCollectionEnabled ? 'YES' : 'NO'))

    if (config.mode != ConfigMode.SaaS) {
      infoList.push(new _SdkInfo('Id Mapping', config.idMappingEnabled ? 'YES' : 'NO'))
    }

    infoList.push(new _SdkInfo('事件请求尝试连接最长时间', String(config.requestOptions._connectTimeout / 1000) + 's'))
    infoList.push(new _SdkInfo('事件请求传输数据最长时间', String(config.requestOptions._transferTimeout / 1000) + 's'))
    infoList.push(new _SdkInfo('本地事件数据有效时长', String(config._dataValidityPeriod / 86400000) + 'd'))
    infoList.push(new _SdkInfo('无埋点采集', config.autotrackEnabled ? 'YES' : 'NO'))
    infoList.push(new _SdkInfo('页面浏览事件自动埋点', config.autotrackAllPages ? 'YES' : 'NO'))

    this.data.set(header, infoList)
  }

  refreshDataForSubTrackers() {
    TrackersInfo.info.forEach((info) => {
      let header = '子实例-' +  info.trackerId
      let infoList: _SdkInfo[] = []

      let config = info.config
      let mode = '-New SaaS'
      if (config.mode == ConfigMode.SaaS) {
        mode = '-SaaS'
      } else if (config.mode == ConfigMode.CDP) {
        mode = '-CDP'
      }
      infoList.push(new _SdkInfo('SDK', 'GrowingAnalytics' + mode))
      infoList.push(new _SdkInfo('AccountId', config.accountId))
      infoList.push(new _SdkInfo('DataSourceId', config.dataSourceId))
      infoList.push(new _SdkInfo('ServerHost', config.dataCollectionServerHost))
      infoList.push(new _SdkInfo('URL Scheme', config.urlScheme))
      infoList.push(new _SdkInfo('数据加密', config.encryptEnabled ? 'YES' : 'NO'))
      infoList.push(new _SdkInfo('数据压缩', config.compressEnabled ? 'YES' : 'NO'))
      infoList.push(new _SdkInfo('数据发送间隔', String(config._dataUploadInterval / 1000)))
      infoList.push(new _SdkInfo('会话后台留存时长', String(config._sessionInterval / 1000)))
      infoList.push(new _SdkInfo('是否采集数据', config.dataCollectionEnabled ? 'YES' : 'NO'))

      if (config.mode != ConfigMode.SaaS) {
        infoList.push(new _SdkInfo('Id Mapping', config.idMappingEnabled ? 'YES' : 'NO'))
      }

      infoList.push(new _SdkInfo('事件请求尝试连接最长时间', String(config.requestOptions._connectTimeout / 1000) + 's'))
      infoList.push(new _SdkInfo('事件请求传输数据最长时间', String(config.requestOptions._transferTimeout / 1000) + 's'))

      this.data.set(header, infoList)
    })
  }
}