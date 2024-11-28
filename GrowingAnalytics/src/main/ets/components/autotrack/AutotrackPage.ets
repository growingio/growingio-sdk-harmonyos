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
  EMIT_EVENT_SESSION_STATE_FOREGROUND,
  PATH_SEPARATOR
} from '../utils/Constants'
import Util from '../utils/Util'

export default class AutotrackPage {
  static pagesCacheOnBackground: Array<PageInfo> = []
  static navBarStack: Array<PageInfo> = []
  static deferNavDestinationPage: PageInfo | undefined = undefined

  static initAutotrackPage(context: UIContext) {
    uiObserver.on('navDestinationUpdate', AutotrackPage.onPageUpdate)
    uiObserver.on('navDestinationSwitch', context, AutotrackPage.onPageUpdate)
    uiObserver.on('routerPageUpdate', context, AutotrackPage.onPageUpdate)

    emitter.once({eventId: EMIT_EVENT_MAIN_TRACKER_INITIALIZE}, AutotrackPage.resendPageFromCacheOnBackground)
    emitter.on({eventId: EMIT_EVENT_SESSION_STATE_FOREGROUND}, AutotrackPage.resendPageFromCacheOnBackground)
  }

  static onPageUpdate(info: NavDestinationInfo | uiObserver.NavDestinationSwitchInfo | RouterPageInfo) {
    // 1. Navigation页面切换：navDestinationSwitch和navDestinationUpdate会触发
    // 2. router页面切换: routerPageUpdate会触发
    // 3. 返回Navigation首页(navBar)：navDestinationSwitch会触发，navDestinationUpdate不会触发
    // 4. 后台回前台: navDestinationUpdate和routerPageUpdate会触发，navDestinationSwitch不会触发
    // 5. 触发时机: navDestinationUpdate早于navDestinationSwitch早于routerPageUpdate
    // 注意:
    // 以上仅在当前版本5.0.0(12)下有效，不保证后续系统更新后结果依旧
    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (!context.config.autotrackAllPages) {
      return
    }
    if (!info) {
      return
    }

    if (Util.isNavDestinationSwitchInfo(info)) {
      // case: navDestinationSwitch
      // 负责:
      // (1) 记录当前NavPathStack对应的首页，并在返回到首页时，发送对应的页面浏览事件
      // (2) 发送由navDestinationUpdate在Navigation页面切换时记录的deferNavDestinationPage
      let switchInfo = info as uiObserver.NavDestinationSwitchInfo
      let from: NavDestinationInfo | NavBar = switchInfo.from
      let to: NavDestinationInfo | NavBar = switchInfo.to

      // to
      if (typeof to == 'string' && to != null && to != undefined) {
        // 将当前NavPathStack对应的首页属性出栈
        let curNavBar = AutotrackPage.navBarStack.pop()
        if (curNavBar != undefined) {
          //发送当前返回的navBar首页对应的页面浏览事件
          AutotrackPage.sendPage(curNavBar)
        }
      } else {
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

        // 发送Navigation页面切换对应的页面浏览事件
        if (AutotrackPage.deferNavDestinationPage) {
          AutotrackPage.sendPage(AutotrackPage.deferNavDestinationPage)
          AutotrackPage.deferNavDestinationPage = undefined
        }
      }
    } else if (Util.isNavDestinationInfo(info)) {
      // case: navDestinationUpdate
      // 负责记录在Navigation页面切换时和后台回前台时，所对应的deferNavDestinationPage
      let navInfo = info as NavDestinationInfo
      if (navInfo.state != uiObserver.NavDestinationState.ON_SHOWN) {
        return
      }
      let name = navInfo.name.toString()
      const GTK_NAV_PATH_PREFIX = '__GTK_'
      if (name.startsWith(GTK_NAV_PATH_PREFIX)) {
        return
      }
      let path = PATH_SEPARATOR + name
      let title = name
      if (title.includes(PATH_SEPARATOR)) {
        title = title.substring(title.lastIndexOf(PATH_SEPARATOR) + 1)
      }
      let attributes = Util.getAttributesFromNavInfoParameter(navInfo.param)
      let pageInfo = new PageInfo(path, title, attributes, context.trackerId)
      AutotrackPage.deferNavDestinationPage = pageInfo
    } else {
      // case: routerPageUpdate
      // 负责:
      // (1) 发送router页面切换时对应的页面浏览事件
      // (2) 发送由navDestinationUpdate在后台回前台时记录的deferNavDestinationPage
      // 注意:
      // 这里假设应用导航架构是router嵌套Navigation(推荐)，因此在后台回前台时先发送routerPage，再发送deferNavDestinationPage
      // 如果应用导航架构是纯Navigation(推荐)，后台回前台时不会发送当前正在显示的NavDestinationPage
      let routerInfo = info as RouterPageInfo
      if (routerInfo.state != uiObserver.RouterPageState.ON_PAGE_SHOW) {
        return
      }

      let name = routerInfo.name.toString()
      let path = PATH_SEPARATOR + name
      let title = name
      if (title.includes(PATH_SEPARATOR)) {
        title = title.substring(title.lastIndexOf(PATH_SEPARATOR) + 1)
      }
      let param = router.getParams()
      let attributes = Util.getAttributesFromNavInfoParameter(param)
      let pageInfo = new PageInfo(path, title, attributes, context.trackerId)
      AutotrackPage.sendPage(pageInfo)

      if (AutotrackPage.deferNavDestinationPage) {
        AutotrackPage.sendPage(AutotrackPage.deferNavDestinationPage)
        AutotrackPage.deferNavDestinationPage = undefined
      }
    }
  }

  static sendPage(pageInfo: PageInfo, eventScene: EventScene = EventScene.Native) {
    AutotrackPage.resendPageFromCacheOnBackground()
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
      // 详见: https://github.com/growingio/growingio-sdk-harmonyos/pull/6#issuecomment-2232880146
      AutotrackPage.cachePageOnBackground(pageInfo)
    }
  }

  static resendPageFromCacheOnBackground() {
    let pages = [...AutotrackPage.pagesCacheOnBackground]
    AutotrackPage.pagesCacheOnBackground = []
    for (let pageInfo of pages) {
      AutotrackPage.generatePage(pageInfo)
    }
  }

  static cachePageOnBackground(pageInfo: PageInfo) {
    AutotrackPage.pagesCacheOnBackground.push(pageInfo)
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