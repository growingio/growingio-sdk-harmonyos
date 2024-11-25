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

import uiObserver from '@ohos.arkui.observer'
import emitter from '@ohos.events.emitter'
import router from '@ohos.router'

import AnalyticsCore from '../core/AnalyticsCore'
import GrowingContext from '../core/Context'
import Session, { SessionState } from '../core/Session'
import { EventScene } from '../event/Event'
import PageEvent from '../event/PageEvent'
import {
  AttributesType,
  EMIT_EVENT_MAIN_TRACKER_INITIALIZE,
  EMIT_EVENT_SESSION_STATE_FOREGROUND
} from '../utils/Constants'
import Util from '../utils/Util'

export default class AutotrackPage {
  static pagesCache: Array<PageInfo> = []
  static navBarStack: Array<PageInfo> = []

  static initAutotrackPage(context: UIContext) {
    uiObserver.on('navDestinationSwitch', context, AutotrackPage.onPageUpdate)
    uiObserver.on('routerPageUpdate', context, AutotrackPage.onPageUpdate)

    emitter.once({eventId: EMIT_EVENT_MAIN_TRACKER_INITIALIZE}, AutotrackPage.resendPageFromCache)
    emitter.on({eventId: EMIT_EVENT_SESSION_STATE_FOREGROUND}, AutotrackPage.resendPageFromCache)
  }

  static onPageUpdate(info: uiObserver.NavDestinationSwitchInfo | uiObserver.RouterPageInfo) {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (!context.config.autotrackAllPages) {
      return
    }

    if (!info) {
      return
    }
    let name = ''
    let attributes: AttributesType = {}
    if (Util.isNavDestinationSwitchInfo(info)) {
      // navigation
      let switchInfo = info as uiObserver.NavDestinationSwitchInfo
      let from: NavDestinationInfo | NavBar = switchInfo.from
      let to: NavDestinationInfo | NavBar = switchInfo.to

      // to
      if (typeof to == 'string' && to != null && to != undefined) {
        // 将当前NavPathStack对应的首页属性出栈
        let curNavBar = AutotrackPage.navBarStack.pop()
        if (curNavBar != undefined) {
          AutotrackPage.sendPage(curNavBar)
          return
        }
      } else {
        let navInfo = to as NavDestinationInfo
        if (navInfo.state != uiObserver.NavDestinationState.ON_SHOWN) {
          return
        }
        name = navInfo.name.toString()
        attributes = Util.getAttributesFromNavInfoParameter(navInfo.param)
      }

      // from
      if (typeof from == 'string' && from != null && from != undefined) {
        let lastPage = PageEvent.getLastPage(context)
        if (lastPage?.path != undefined) {
          // 将当前NavPathStack对应的首页属性入栈
          AutotrackPage.navBarStack.push(new PageInfo(
            lastPage.path,
            lastPage?.title ?? '',
            lastPage?.attributes ?? {},
            context.trackerId))
        }
      }
    } else {
      // router
      let routerInfo = info as uiObserver.RouterPageInfo
      if (routerInfo.state != uiObserver.RouterPageState.ON_PAGE_SHOW) {
        return
      }

      name = routerInfo.name.toString()
      let param = router.getParams()
      attributes = Util.getAttributesFromNavInfoParameter(param)
    }

    let path = '/' + name
    let title = name
    if (title.includes('/')) {
      title = title.substring(title.lastIndexOf("/") + 1)
    }

    let pageInfo = new PageInfo(path, title, attributes, context.trackerId)
    AutotrackPage.sendPage(pageInfo)
  }

  static sendPage(pageInfo: PageInfo, eventScene: EventScene = EventScene.Native) {
    AutotrackPage.resendPageFromCache()
    AutotrackPage.generatePage(pageInfo, eventScene)
  }

  static generatePage(pageInfo: PageInfo, eventScene: EventScene = EventScene.Native) {
    let context = GrowingContext.getContext(pageInfo.trackerId)
    if (context == undefined) {
      return
    }
    if (AnalyticsCore.tracker(pageInfo.trackerId).isInitializedSuccessfully()
      && Session.sessionState === SessionState.Foreground) {
      if (!context.config.dataCollectionEnabled) {
        return
      }
      let e = PageEvent.create(
        pageInfo.path,
        pageInfo.title,
        pageInfo.attributes,
        context
      )
      AnalyticsCore.writeEventToDisk(e, context, eventScene)
    } else {
      AutotrackPage.cachePage(pageInfo)
    }
  }

  static resendPageFromCache() {
    let pages = [...AutotrackPage.pagesCache]
    AutotrackPage.pagesCache = []
    for (let pageInfo of pages) {
      AutotrackPage.generatePage(pageInfo)
    }
  }

  static cachePage(pageInfo: PageInfo) {
    AutotrackPage.pagesCache.push(pageInfo)
  }
}

export class PageInfo {
  path: string
  title: string
  attributes: AttributesType
  trackerId: string

  constructor(
    path: string,
    title: string,
    attributes: AttributesType,
    trackerId: string
  ) {
    this.path = path
    this.title = title
    this.attributes = attributes
    this.trackerId = trackerId
  }
}