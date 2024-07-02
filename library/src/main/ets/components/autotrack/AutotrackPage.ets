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
import { LogUtil } from '../utils/LogUtil'
import Util from '../utils/Util'

export default class AutotrackPage {
  static pagesCache: Map<string, Array<PageEvent>> =  new Map()

  static initAutotrackPage(context: Object) {
    if (deviceInfo.sdkApiVersion >= 12) {
      uiObserver.on('navDestinationUpdate', AutotrackPage.onNavDestinationUpdate)

      //实际上context要求传入的是UIAbilityContext，但由于UIAbilityContext未export无法编译，用UIContext绕过
      uiObserver.on('routerPageUpdate', context as UIContext, AutotrackPage.onRouterPageUpdate)

      emitter.on({eventId: EMIT_EVENT_VISIT_DID_SEND}, AutotrackPage.resendPageFromCache)
    }
  }

  static onNavDestinationUpdate(info: NavDestinationInfo) {
    if (info) {
      LogUtil.info(() => 'info.navigationId = ' + info.navigationId + ', info.navDestinationId = ' + info.navDestinationId + ', info.name = ' + info.name)
    }
  }

  static onRouterPageUpdate(info: uiObserver.RouterPageInfo) {
    if (!info || !Util.isUIAbilityContext(info.context)) {
      return
    }

    if (info.state != uiObserver.RouterPageState.ON_PAGE_SHOW) {
      return
    }

    let c = info.context as gUIAbilityContext
    let bundleName = c.abilityInfo.bundleName
    let moduleName = c.abilityInfo.moduleName
    let path = bundleName +  '/' + moduleName + '/' + info.path
    let title = info.name
    if (info.name.includes('/')) {
      title = info.name.substring(title.lastIndexOf("/") + 1)
    }

    AutotrackPage.generatePage(path, title, {})
  }

  static generatePage(path: string, title: string, attributes: AttributesType) {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    let e = PageEvent.create(
      path,
      title,
      attributes,
      context
    )
    if (AnalyticsCore.core.isInitializedSuccessfully()) {
      AnalyticsCore.writeEventToDisk(e, context, EventScene.Native)
    } else {
      AutotrackPage.cachePage(e)
    }
  }

  static resendPageFromCache(data: emitter.EventData) {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    let pages = AutotrackPage.pagesCache.get(context.trackerId)
    if (pages) {
      for (let page of pages) {
        let params = data.data
        if (params != undefined) {
          page.timestamp = params['timestamp']
        }
        AnalyticsCore.writeEventToDisk(page, context, EventScene.Native)
      }
      AutotrackPage.pagesCache.set(context.trackerId, [])
    }
  }

  static cachePage(e: PageEvent) {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    let pages = AutotrackPage.pagesCache.get(context.trackerId)
    if (pages) {
      pages.push(e)
      AutotrackPage.pagesCache.set(context.trackerId, pages)
    } else {
      AutotrackPage.pagesCache.set(context.trackerId, [e])
    }
  }
}

class gAbilityInfo {
  bundleName: string = ''
  moduleName: string = ''
}

class gUIAbilityContext {
  abilityInfo: gAbilityInfo = new gAbilityInfo()
}