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
import Session from '../core/Session'
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
  // 存储SDK尚未初始化或应用处于后台时，触发的页面浏览事件
  static pagesCacheOnBackground: Array<PageInfo> = []
  // 存储当前所有的NavPathStack
  static navBarStack: Array<_NavBarInfo> = []
  // 存储监听Navigation路由触发的页面浏览事件 (主要是为了保证先发送routerPage，再发送deferNavDestinationPage)
  static deferNavDestinationPages: Array<PageInfo> = []
  // 存储最后一个pageInfo，无论是否发送了该pageInfo对应的页面浏览事件 (主要是为了适配延迟初始化；与PageEvent.lastPage不同)
  static lastPage: PageInfo | undefined = undefined

  static startObserver(context: UIContext) {
    context.getUIObserver().on('navDestinationUpdate', AutotrackPage.onPageUpdate)
    context.getUIObserver().on('navDestinationSwitch', AutotrackPage.onPageUpdate)
    context.getUIObserver().on('routerPageUpdate', AutotrackPage.onPageUpdate)
  }

  static startSubscribeToEvent() {
    emitter.once(EMIT_EVENT_MAIN_TRACKER_INITIALIZE, AutotrackPage.resendPageFromCacheOnBackground)
    emitter.on(EMIT_EVENT_SESSION_STATE_FOREGROUND, AutotrackPage.resendPageFromCacheOnBackground)
  }

  static onPageUpdate(info: NavDestinationInfo | uiObserver.NavDestinationSwitchInfo | RouterPageInfo) {
    // 1. Navigation页面切换：navDestinationSwitch和navDestinationUpdate会触发
    // 2. router页面切换: routerPageUpdate会触发
    // 3. 返回Navigation首页(navBar)：navDestinationSwitch会触发，navDestinationUpdate不会触发
    // 4. 后台回前台: navDestinationUpdate和routerPageUpdate会触发，navDestinationSwitch不会触发
    // 5. 触发时机: navDestinationUpdate、navDestinationSwitch不确定先后，navDestinationUpdate早于routerPageUpdate
    // 注意:
    // 以上仅在当前版本5.0.0(12)下有效，不保证后续系统更新后结果依旧
    if (!info) {
      return
    }

    if (Util.isNavDestinationSwitchInfo(info)) {
      // case: navDestinationSwitch
      // 负责:
      // (1) 记录当前navBar对应的首页，并在返回到首页时，发送对应的页面浏览事件
      // (2) Navigation页面切换时，若同一页面已触发navDestinationUpdate，发送对应的页面浏览事件；否则，存储为deferNavDestinationPage
      let switchInfo = info as uiObserver.NavDestinationSwitchInfo
      let from: NavDestinationInfo | NavBar = switchInfo.from
      let to: NavDestinationInfo | NavBar = switchInfo.to

      if (typeof to == 'string' && to != null && to != undefined) {
        // case：返回到首页
        let fromInfo = from as NavDestinationInfo
        let isFind = false

        // 找到对应的navBar，发送页面浏览事件
        while (!isFind && AutotrackPage.navBarStack.length > 0) {
          // LIFO
          let k = AutotrackPage.navBarStack.pop()!
          if (k.isEqual(fromInfo)) {
            AutotrackPage.sendNativePage(k.navBar)

            // 清除当前navBar栈中from对应的deferNavDestinationPage，减小内存占用
            // 该page可能是由于全模态返回时，在navDestinationUpdate监听下生成
            // TODO: 待优化，有当前navBar非from对应的deferNavDestinationPage占用内存的场景
            for (let i = 0; i < AutotrackPage.deferNavDestinationPages.length; i++) {
              let p = AutotrackPage.deferNavDestinationPages[i]
              if (k.dstId == p.dstId) {
                AutotrackPage.deferNavDestinationPages.splice(i, 1)
                break
              }
            }

            isFind = true
          }
        }
      } else {
        // case：NavDestination切换
        let toInfo = to as NavDestinationInfo

        if (typeof from == 'string' && from != null && from != undefined) {
          let lastPage = AutotrackPage.lastPage
          if (lastPage?.path != undefined) {
            // 将当前navBar对应的首页入栈，并同时关联NavDestination，避免在返回到首页时发错事件
            let navBarInfo = new _NavBarInfo(lastPage, toInfo)
            AutotrackPage.navBarStack.push(navBarInfo)
          }
        } else {
          // 刷新对应navBar的NavDestination
          let fromInfo = from as NavDestinationInfo
          // 从后往前遍历，在一般情况下，更快
          // 一般情况：子navBar而不是父navBar发生跳转
          for (let i = AutotrackPage.navBarStack.length - 1; i >= 0; i--) {
            let k = AutotrackPage.navBarStack[i]
            if (k.isEqual(fromInfo)) {
              k.refreshNavDestination(toInfo)
              break
            }
          }
        }

        // 发送Navigation页面切换对应的页面浏览事件
        AutotrackPage.sendNavDestinationPageIfNeeded(toInfo)
      }
    } else if (Util.isNavDestinationInfo(info)) {
      // case: navDestinationUpdate
      // 负责:
      // (1) 记录后台回前台时，所对应的deferNavDestinationPage
      // (2) Navigation页面切换时，若同一页面已触发navDestinationSwitch，发送对应的页面浏览事件；否则，存储为deferNavDestinationPage
      let navInfo = info as NavDestinationInfo
      AutotrackPage.sendNavDestinationPageIfNeeded(navInfo)
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
      let alias = Util.getAliasFromNavInfoParameter(param)
      if (alias.length > 0) {
        path = PATH_SEPARATOR + alias
      }
      let pageInfo = new PageInfo(path, title, attributes, alias)
      AutotrackPage.sendNativePage(pageInfo)

      while (AutotrackPage.deferNavDestinationPages.length > 0) {
        let pageInfo = AutotrackPage.deferNavDestinationPages.shift()!
        AutotrackPage.sendNativePage(pageInfo)
      }
    }
  }

  static sendNavDestinationPageIfNeeded(navInfo: NavDestinationInfo) {
    let pageInfo = AutotrackPage.getPageInfoFromNavDestinationInfo(navInfo)
    if (!pageInfo) {
      return
    }

    let isSend = false
    for (let i = 0; i < AutotrackPage.deferNavDestinationPages.length; i++) {
      let p = AutotrackPage.deferNavDestinationPages[i]
      if (p.isEqual(pageInfo)) {
        AutotrackPage.sendNativePage(pageInfo)
        AutotrackPage.deferNavDestinationPages.splice(i, 1)
        isSend = true
        break
      }
    }

    if (!isSend) {
      AutotrackPage.deferNavDestinationPages.push(pageInfo)
    }
  }

  static getPageInfoFromNavDestinationInfo(navInfo: NavDestinationInfo): PageInfo | undefined {
    if (navInfo.state != uiObserver.NavDestinationState.ON_SHOWN) {
      return undefined
    }
    let name = navInfo.name.toString()
    const GTK_NAV_PATH_PREFIX = '__GTK_'
    if (name.startsWith(GTK_NAV_PATH_PREFIX)) {
      return undefined
    }
    let path = PATH_SEPARATOR + name
    let title = name
    if (title.includes(PATH_SEPARATOR)) {
      title = title.substring(title.lastIndexOf(PATH_SEPARATOR) + 1)
    }
    let attributes = Util.getAttributesFromNavInfoParameter(navInfo.param)
    let alias = Util.getAliasFromNavInfoParameter(navInfo.param)
    if (alias.length > 0) {
      path = PATH_SEPARATOR + alias
    }
    let pageInfo = new PageInfo(path, title, attributes, alias, navInfo.navDestinationId)
    return pageInfo
  }

  static sendNativePage(pageInfo: PageInfo) {
    pageInfo.timestamp = Date.now()
    AutotrackPage.lastPage = pageInfo

    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (context == undefined) {
      return
    }
    if (!context.config.autotrackEnabled) {
      return
    }
    if (!context.config.autotrackAllPages) { // 该配置仅影响NativePage，不影响FlutterPage等
      // 若设置了页面别名，将继续发送该页面浏览事件
      if (!pageInfo.alias || (pageInfo.alias && pageInfo.alias.length == 0)) {
        return
      }
    }
    AutotrackPage.sendPage(pageInfo)
  }

  static sendPage(pageInfo: PageInfo) {
    AutotrackPage.resendPageFromCacheOnBackground()
    AutotrackPage.generatePage(pageInfo)
  }

  static async generatePage(pageInfo: PageInfo) {
    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (context == undefined) {
      return
    }
    if (AnalyticsCore.core.isInitializedSuccessfully()
      && Session.isOnForeground) {
      if (!context.config.dataCollectionEnabled) {
        return
      }
      let e = await PageEvent.create(
        pageInfo.path,
        pageInfo.title,
        pageInfo.attributes,
        pageInfo.timestamp,
        context
      )
      AnalyticsCore.writeEventToDisk(e, context, pageInfo.eventScene)
    } else {
      // 详见: https://github.com/growingio/growingio-sdk-harmonyos/pull/6#issuecomment-2232880146
      AutotrackPage.cachePageOnBackground(pageInfo)
    }
  }

  static resendPageFromCacheOnBackground() {
    let pages = [...AutotrackPage.pagesCacheOnBackground]
    AutotrackPage.pagesCacheOnBackground = []
    for (let page of pages) {
      AutotrackPage.generatePage(page)
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
  alias?: string
  dstId?: string
  timestamp: number = 0
  eventScene: EventScene = EventScene.Native

  constructor(
    path: string,
    title: string,
    attributes: AttributesType,
    alias?: string,
    dstId?: string,
  ) {
    this.path = path
    this.title = title
    this.attributes = attributes
    this.alias = alias
    this.dstId = dstId
  }

  isEqual(to: PageInfo): boolean {
    return this.path == to.path && this.dstId == to.dstId
  }
}

class _NavBarInfo {
  navBar: PageInfo
  dstId: string

  constructor(navBar: PageInfo, dst: NavDestinationInfo) {
    this.navBar = navBar
    this.dstId = dst.navDestinationId
  }

  isEqual(to: NavDestinationInfo): boolean {
    // 需要系统保证该navDestinationId全局唯一
    return this.dstId == to.navDestinationId
  }

  refreshNavDestination(dst: NavDestinationInfo) {
    this.dstId = dst.navDestinationId
  }
}