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

import AnalyticsCore from './AnalyticsCore'
import GrowingContext from './Context'
import AutotrackPage, { PageInfo } from '../autotrack/AutotrackPage'
import { EventScene, EventType } from '../event/Event'
import ViewElementEvent from '../event/ViewElementEvent'
import { AttributesType, ValueType } from '../utils/Constants'
import { ConfigMode } from '../interfaces/GrowingConfig'
import { LogUtil } from '../utils/LogUtil'

export default class Flutter {
  constructor() {}

  static trackFlutterPage(argument: Map<string, Object>) {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (!context.config.dataCollectionEnabled) {
      LogUtil.info(() => 'Failed to dispatch flutter event, dataCollectionEnabled is false')
      return
    }

    let path = argument.get('path') as string
    if (path == null || path == undefined || path.length == 0) {
      return
    }
    let title = argument.get('title') as string
    let map = argument.get('attributes') as Map<string, ValueType>
    let attributes = Flutter.attributesFromMap(map)
    // 可能会出现在后台触发PAGE的场景(类似ANLSPI-20126)，走AutotrackPage内部缓存机制进行规避
    // 与iOS不同在于：
    // iOS上在特定条件下(Flutter应用在后台进行跳转)必定复现且该事件的前后台状态必定处于后台；HarmonyOS NEXT则是在同等条件下偶现
    // 因此，为避免事件数据差异，处理方式也有所不同，iOS丢弃这些PAGE；HarmonyOS NEXT则将这些PAGE缓存于内存中，回到前台时生成
    // 见：https://github.com/growingio/growingio-sdk-ios-autotracker/commit/1ae98f066d979c724aba9598f038e4781dac38d9
    let pageInfo = new PageInfo(path, title, attributes, context.trackerId)
    AutotrackPage.sendPage(pageInfo, EventScene.Flutter)
  }

  static trackFlutterClickEvent(argument: Map<string, Object>) {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (!context.config.dataCollectionEnabled) {
      LogUtil.info(() => 'Failed to dispatch flutter event, dataCollectionEnabled is false')
      return
    }

    let mode = context.config.mode

    let eventType = argument.get('eventType') as string
    if (eventType == null || eventType == undefined || eventType.length == 0) {
      return
    }

    let path = argument.get('path') as string
    if (mode == ConfigMode.CDP) {
      if (path == null || path == undefined || path.length == 0) {
        return
      }
    }

    let xpath = argument.get('xpath') as string
    if (xpath == null || xpath == undefined || xpath.length == 0) {
      return
    }

    let xcontent = argument.get('xcontent') as string
    if (mode == ConfigMode.NewSaaS) {
      if (xcontent == null || xcontent == undefined || xcontent.length == 0) {
        return
      }
    }

    let textValue = argument.get('textValue') as string
    let index = argument.get('index') as number
    let map = argument.get('attributes') as Map<string, ValueType>
    let attributes = Flutter.attributesFromMap(map)
    if (AnalyticsCore.core.isInitializedSuccessfully()) {
      let e = ViewElementEvent.create(
        path,
        textValue,
        xpath,
        xcontent,
        index,
        attributes,
        eventType === 'VIEW_CLICK' ? EventType.ViewClick : EventType.ViewChange,
        context
      )
      AnalyticsCore.writeEventToDisk(e, context, EventScene.Flutter)
    }
  }

  private static attributesFromMap(map: Map<string, ValueType>): AttributesType {
    let attributes: AttributesType = {}
    if (map == null || map == undefined) {
      return {}
    }
    map.forEach((value, key) => {
      attributes[key] = value
    })
    return attributes
  }
}