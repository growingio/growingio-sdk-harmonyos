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

import deviceInfo from '@ohos.deviceInfo'
import uiObserver from '@ohos.arkui.observer'
import emitter from '@ohos.events.emitter'

import AnalyticsCore from '../core/AnalyticsCore'
import GrowingContext from '../core/Context'
import { EventScene } from '../event/Event'
import PageEvent from '../event/PageEvent'
import { AttributesType, EMIT_EVENT_VISIT_DID_SEND } from '../utils/Constants'
import Util from '../utils/Util'

export default class AutotrackPage {
  static pagesCache: Map<string, Array<PageInfo>> = new Map()

  static initAutotrackPage(context: Object) {
    if (deviceInfo.sdkApiVersion >= 12) {
      uiObserver.on('navDestinationUpdate', AutotrackPage.onNavDestinationUpdate)

      //实际上context要求传入的是UIAbilityContext，但由于UIAbilityContext未export无法编译，用UIContext绕过
      uiObserver.on('routerPageUpdate', context as UIContext, AutotrackPage.onRouterPageUpdate)

      emitter.on({eventId: EMIT_EVENT_VISIT_DID_SEND}, AutotrackPage.resendPageFromCache)
    }
  }

  static onNavDestinationUpdate(info: NavDestinationInfo) {
    if (!info) {
      return
    }
    if (info.state != uiObserver.NavDestinationState.ON_SHOWN) {
      return
    }

    let name = info.name.toString()
    let path = name
    let title = name
    if (title.includes('/')) {
      title = title.substring(title.lastIndexOf("/") + 1)
    }

    AutotrackPage.generatePage(path, title, {})
  }

  static onRouterPageUpdate(info: uiObserver.RouterPageInfo) {
    if (!info || !Util.isUIAbilityContext(info.context)) {
      return
    }

    if (info.state != uiObserver.RouterPageState.ON_PAGE_SHOW) {
      return
    }

    let c = info.context as gUIAbilityContext
    let moduleName = c.abilityInfo.moduleName
    let path = moduleName + '/' + info.name
    let title = info.name
    if (title.includes('/')) {
      title = title.substring(title.lastIndexOf("/") + 1)
    }

    AutotrackPage.generatePage(path, title, {})
  }

  static generatePage(path: string, title: string, attributes: AttributesType) {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (AnalyticsCore.core.isInitializedSuccessfully()) {
      let e = PageEvent.create(
        path,
        title,
        attributes,
        context
      )
      AnalyticsCore.writeEventToDisk(e, context, EventScene.Native)
    } else {
      let pageInfo = new PageInfo(path, title, attributes)
      AutotrackPage.cachePage(pageInfo)
    }
  }

  static resendPageFromCache(data: emitter.EventData) {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    let pages = AutotrackPage.pagesCache.get(context.trackerId)
    if (pages) {
      for (let page of pages) {
        let e = PageEvent.create(
          page.path,
          page.title,
          page.attributes,
          context
        )
        let params = data.data
        if (params != undefined) {
          e.timestamp = params['timestamp']
        }
        AnalyticsCore.writeEventToDisk(e, context, EventScene.Native)
      }
      AutotrackPage.pagesCache.set(context.trackerId, [])
    }
  }

  static cachePage(page: PageInfo) {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    let pages = AutotrackPage.pagesCache.get(context.trackerId)
    if (pages) {
      pages.push(page)
      AutotrackPage.pagesCache.set(context.trackerId, pages)
    } else {
      AutotrackPage.pagesCache.set(context.trackerId, [page])
    }
  }
}

class PageInfo {
  path: string
  title: string
  attributes: AttributesType

  constructor(
    path: string,
    title: string,
    attributes: AttributesType
  ) {
    this.path = path
    this.title = title
    this.attributes = attributes
  }
}

class gAbilityInfo {
  bundleName: string = ''
  moduleName: string = ''
}

class gUIAbilityContext {
  abilityInfo: gAbilityInfo = new gAbilityInfo()
}