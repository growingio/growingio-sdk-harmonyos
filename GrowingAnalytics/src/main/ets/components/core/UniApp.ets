/**
 * @license
* Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.
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

import GrowingContext from './Context'
import AutotrackPage, { PageInfo } from '../autotrack/AutotrackPage'
import { EventScene } from '../event/Event'
import { AttributesType, ValueType } from '../utils/Constants'
import { ConfigMode } from '../interfaces/GrowingConfig'
import { LogUtil } from '../utils/LogUtil'

export class UniApp {
  static trackUniAppPage(argument: Map<string, Object>) {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (!context) {
      LogUtil.info(() => 'Failed to dispatch UniApp event, must call GrowingAnalytics.start(context, configuration) first')
      return
    }
    if (context.config.mode != ConfigMode.NewSaaS) {
      LogUtil.info(() => 'Failed to dispatch UniApp event, must be New SaaS mode')
      return
    }
    if (!context.config.dataCollectionEnabled) {
      LogUtil.info(() => 'Failed to dispatch UniApp event, dataCollectionEnabled is false')
      return
    }

    let path = argument.get('path') as string
    if (path == null || path == undefined || path.length == 0) {
      return
    }
    let map = argument.get('attributes') as Map<string, ValueType>
    let attributes = UniApp.attributesFromMap(map)
    let pageInfo = new PageInfo(path, '', attributes)
    pageInfo.eventScene = EventScene.UniApp
    AutotrackPage.sendPage(pageInfo)
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