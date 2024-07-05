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
import { EventScene, EventType } from '../event/Event'
import PageEvent from '../event/PageEvent'
import ViewElementEvent from '../event/ViewElementEvent'
import { AttributesType, ValueType } from '../utils/Constants'

export default class Flutter {
  constructor() {}

  static trackFlutterPage(argument: Map<string, Object>) {
    let path = argument.get('path') as string
    if (path == null || path == undefined || path.length == 0) {
      return
    }
    let title = argument.get('title') as string
    let map = argument.get('attributes') as Map<string, ValueType>
    let attributes = Flutter.attributesFromMap(map)
    let context = GrowingContext.getDefaultContext() as GrowingContext
    let e = PageEvent.create(
      path,
      title,
      attributes,
      context
    )
    AnalyticsCore.writeEventToDisk(e, context, EventScene.Flutter)
  }

  static trackFlutterClickEvent(argument: Map<string, Object>) {
    let path = argument.get('path') as string
    let textValue = argument.get('textValue') as string
    let xpath = argument.get('xpath') as string
    if (xpath == null || xpath == undefined || xpath.length == 0) {
      return
    }
    let xcontent = argument.get('xcontent') as string
    if (xcontent == null || xcontent == undefined || xcontent.length == 0) {
      return
    }
    let index = argument.get('index') as number
    let eventType = argument.get('eventType') as string
    if (eventType == null || eventType == undefined || eventType.length == 0) {
      return
    }
    let map = argument.get('attributes') as Map<string, ValueType>
    let attributes = Flutter.attributesFromMap(map)
    let context = GrowingContext.getDefaultContext() as GrowingContext
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