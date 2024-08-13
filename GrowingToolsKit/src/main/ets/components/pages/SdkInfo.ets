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
import { ConfigMode, GTKColor } from '../utils/Constants'

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
  @Local dataSource: _SdkInfo[] = []

  aboutToAppear(): void {
    this.refreshData()
  }

  build() {
    NavDestination() {
      List({ space: 3 }) {
        ListItem() {
            Row() {
              Text('SDK信息')
                .fontColor(GTKColor.primaryWhite)
                .padding(10)
            }
            .backgroundColor(GTKColor.secondaryTheme)
            .width('100%')
            .height(40)
        }
        ForEach(this.dataSource, (info: _SdkInfo) => {
          ListItem() {
            Flex() {
              Text(info.key)
              Blank()
              Text(info.value)
                .flexBasis('auto')
            }
            .padding({ left: 10, right: 10 })
            .width('100%')
          }
          .width('100%')
          .height(45)
        })
      }
      .backgroundColor(GTKColor.primaryWhite)
      .divider({ strokeWidth: 0.5, startMargin: 10, color: GTKColor.tertiaryBlack })
    }
  }

  refreshData() {
    let config = GrowingToolsKit.config
    let mode = '-New SaaS'
    if (config.mode == ConfigMode.SaaS) {
      mode = '-SaaS'
    } else if (config.mode == ConfigMode.CDP) {
      mode = '-CDP'
    }
    this.dataSource.push(new _SdkInfo('SDK', 'GrowingAnalytics' + mode))
    this.dataSource.push(new _SdkInfo('SDK版本号', GrowingToolsKit.version))

    let time = GrowingToolsKit.sdkEndTime - GrowingToolsKit.sdkStartTime
    this.dataSource.push(new _SdkInfo('初始化耗时', String(time) + 'ms'))

    this.dataSource.push(new _SdkInfo('AccountId', config.accountId))
    this.dataSource.push(new _SdkInfo('DataSourceId', config.dataSourceId))
    this.dataSource.push(new _SdkInfo('ServerHost', config.dataCollectionServerHost))
    this.dataSource.push(new _SdkInfo('URL Scheme', config.urlScheme))
    this.dataSource.push(new _SdkInfo('调试模式', config.debugEnabled ? 'YES' : 'NO'))
    this.dataSource.push(new _SdkInfo('数据加密', config.encryptEnabled ? 'YES' : 'NO'))
    this.dataSource.push(new _SdkInfo('数据压缩', config.compressEnabled ? 'YES' : 'NO'))
    this.dataSource.push(new _SdkInfo('数据发送间隔', String(config._dataUploadInterval / 1000)))
    this.dataSource.push(new _SdkInfo('会话后台留存时长', String(config._sessionInterval / 1000)))
    this.dataSource.push(new _SdkInfo('是否采集数据', config.dataCollectionEnabled ? 'YES' : 'NO'))

    if (config.mode != ConfigMode.SaaS) {
      this.dataSource.push(new _SdkInfo('Id Mapping', config.idMappingEnabled ? 'YES' : 'NO'))
    }

    this.dataSource.push(new _SdkInfo('事件请求尝试连接等待时长', String(config.requestOptions._connectTimeout / 1000) + 's'))
    this.dataSource.push(new _SdkInfo('事件请求读取响应等待时长', String(config.requestOptions._readTimeout / 1000) + 's'))
    this.dataSource.push(new _SdkInfo('本地事件数据有效时长', String(config._dataValidityPeriod / 86400000) + 'd'))
    this.dataSource.push(new _SdkInfo('无埋点采集', config.autotrackEnabled ? 'YES' : 'NO'))
    this.dataSource.push(new _SdkInfo('页面浏览事件自动埋点', config.autotrackAllPages ? 'YES' : 'NO'))
  }
}