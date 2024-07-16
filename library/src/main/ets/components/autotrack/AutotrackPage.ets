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

  static initAutotrackPage(context: UIContext) {
    if (deviceInfo.sdkApiVersion < 12) {
      return
    }

    uiObserver.on('navDestinationUpdate', AutotrackPage.onPageUpdate)
    uiObserver.on('routerPageUpdate', context, AutotrackPage.onPageUpdate)
    emitter.once({eventId: EMIT_EVENT_MAIN_TRACKER_INITIALIZE}, AutotrackPage.resendPageFromCache)
    emitter.on({eventId: EMIT_EVENT_SESSION_STATE_FOREGROUND}, AutotrackPage.resendPageFromCache)
  }

  static onPageUpdate(info: NavDestinationInfo | uiObserver.RouterPageInfo) {
    if (!info) {
      return
    }
    if (Util.isRouterPageInfo(info)) {
      if ((info as uiObserver.RouterPageInfo).state != uiObserver.RouterPageState.ON_PAGE_SHOW) {
        return
      }
    } else if ((info as NavDestinationInfo).state != uiObserver.NavDestinationState.ON_SHOWN) {
      return
    }

    let name = info.name.toString()
    let path = '/' + name
    let title = name
    if (title.includes('/')) {
      title = title.substring(title.lastIndexOf("/") + 1)
    }

    let context = GrowingContext.getDefaultContext() as GrowingContext
    let pageInfo = new PageInfo(path, title, {}, context.trackerId)
    AutotrackPage.generatePage(pageInfo)
  }

  static generatePage(pageInfo: PageInfo) {
    let context = GrowingContext.getContext(pageInfo.trackerId)
    if (context == undefined) {
      return
    }
    if (AnalyticsCore.tracker(pageInfo.trackerId).isInitializedSuccessfully()
      && Session.sessionState === SessionState.Foreground) {
      let e = PageEvent.create(
        pageInfo.path,
        pageInfo.title,
        pageInfo.attributes,
        context
      )
      AnalyticsCore.writeEventToDisk(e, context, EventScene.Native)
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

class PageInfo {
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