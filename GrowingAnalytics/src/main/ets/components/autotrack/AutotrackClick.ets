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

import { FrameNode } from '@ohos.arkui.node'
import router from '@ohos.router'

import AutotrackPage from './AutotrackPage'
import AnalyticsCore from '../core/AnalyticsCore'
import GrowingContext from '../core/Context'
import { EventType } from '../event/Event'
import ViewElementEvent from '../event/ViewElementEvent'
import { ConfigMode } from '../interfaces/GrowingConfig'
import { PATH_SEPARATOR, LIST_COMPONENTS } from '../utils/Constants'
import Util from '../utils/Util'

export default class AutotrackClick {
  private static uiContent: UIContext

  private static dialogPathPrefixes: Array<string> = [
    "/root",
    // "/root/AlertDialog",
    // "/root/Dialog",
    // "/root/Keyboard",
    // "/root/MenuWrapper",
    // "/root/ModalPage",
    // "/root/Popup",
    // "/root/SheetWrapper",
    // "/root/SelectOverlay",
    // "/root/Video",
  ]

  static startObserver(context: UIContext) {
    AutotrackClick.uiContent = context
    context.getUIObserver().on('willClick', AutotrackClick.onWillClick)
  }

  static onWillClick(event: ClickEvent, frameNode?: FrameNode) {
    if (!frameNode) {
      return
    }
    if (frameNode.getUniqueId() <= 0) {
      return
    }

    if (!AnalyticsCore.core.isInitializedSuccessfully()) {
      return
    }

    let context = GrowingContext.getDefaultContext() as GrowingContext
    if (context.config.mode == ConfigMode.SaaS) {
      // mode SaaS not support
      return
    }
    if (!context.config.autotrackEnabled) {
      return
    }
    if (!context.config.dataCollectionEnabled) {
      return
    }

    // page
    let pageInfo = AutotrackClick.getPageInfo(frameNode)
    let path = pageInfo.path
    let ptm = pageInfo.pageShowTimestamp

    // view
    let textValue = AutotrackClick.getTextValue(frameNode)
    let xpathInfo = AutotrackClick.getXpathInfo(frameNode)
    let xpath = ''
    let xcontent = ''
    let index = xpathInfo.index
    if (context.config.mode == ConfigMode.NewSaaS) {
      xpath = PATH_SEPARATOR + xpathInfo.xpath.reverse().join(PATH_SEPARATOR)
      xcontent = PATH_SEPARATOR + xpathInfo.xcontent.reverse().join(PATH_SEPARATOR)
      if (xpathInfo.inList) {
        index = index + 1
      }
    } else if (context.config.mode == ConfigMode.CDP) {
      for (let i = xpathInfo.xpath.length - 1; i >= 0; i--) {
        xpath = xpath + PATH_SEPARATOR + xpathInfo.xpath[i] + '[' + xpathInfo.xcontent[i] + ']'
      }
    }
    let eventType = xpathInfo.eventType
    // let attributes: AttributesType = frameNode.getCustomProperty('growing_attributes') as AttributesType

    if (!path || path.length == 0) {
      // 该frameNode所在页面并不是通过Navigation或Router跳转，可能是弹窗视图
      for (let i = 0; i < AutotrackClick.dialogPathPrefixes.length; i++) {
        let prefix = AutotrackClick.dialogPathPrefixes[i]
        if (xpath.startsWith(prefix)) {
          let lastPage = AutotrackPage.lastPage
          path = lastPage?.path ?? ''
          if (context.config.mode == ConfigMode.CDP) {
            ptm = lastPage?.timestamp ?? 0
          }
          break
        }
      }
    }

    // send event
    let e = ViewElementEvent.create(
      path,
      ptm,
      textValue,
      xpath,
      xcontent,
      index,
      {},
      eventType,
      context
    )
    AnalyticsCore.writeEventToDisk(e, context)
  }

  static getPageInfo(frameNode: FrameNode): _PageInfo {
    let info = new _PageInfo()

    // get real page
    let pageInfo = AutotrackClick.uiContent.getPageInfoByUniqueId(frameNode.getUniqueId())
    let realPath: string | undefined = undefined
    if (pageInfo.navDestinationInfo) {
      realPath = PATH_SEPARATOR + pageInfo.navDestinationInfo.name.toString()
      let alias = Util.getAliasFromNavInfoParameter(pageInfo.navDestinationInfo.param)
      if (alias.length > 0) {
        realPath = PATH_SEPARATOR + alias
      }
    } else if (pageInfo.routerPageInfo) {
      realPath = PATH_SEPARATOR + pageInfo.routerPageInfo.name.toString()
      let param = router.getParams()
      let alias = Util.getAliasFromNavInfoParameter(param)
      if (alias.length > 0) {
        realPath = PATH_SEPARATOR + alias
      }
    }

    if (realPath) {
      info.path = realPath

      let context = GrowingContext.getDefaultContext() as GrowingContext
      if (context.config.mode == ConfigMode.CDP) {
        // compare with last page in cache
        let lastPage = AutotrackPage.lastPage
        let path = lastPage?.path
        if (path == realPath) {
          info.pageShowTimestamp = lastPage?.timestamp ?? 0
        }
      }
    }

    return info
  }

  static getXpathInfo(frameNode: FrameNode): _XpathInfo {
    let info = new _XpathInfo()
    let f: FrameNode | null = frameNode
    info.eventType = EventType.ViewClick

    while (f) {
      AutotrackClick.setXpathInfo(info, f)
      f = f.getParent()
    }

    info.xpath.push('root')
    info.xcontent.push('0')
    
    return info
  }

  static setXpathInfo(info: _XpathInfo, frameNode: FrameNode) {
    let curNodeType = frameNode.getNodeType()
    info.xpath.push(curNodeType)

    let xcontent = AutotrackClick.getXcontent(frameNode)
    if (!info.inList && LIST_COMPONENTS.includes(curNodeType)) {
      info.xcontent.push('-')
      info.index = xcontent
      info.inList = true
    } else {
      info.xcontent.push(String(xcontent) + AutotrackClick.getCustomId(frameNode))
    }
  }

  static getXcontent(frameNode: FrameNode) {
    let xcontent = 0
    if (frameNode.getParent()) {
      let curNodeType = frameNode.getNodeType()
      let preSibling = frameNode.getPreviousSibling()
      while (preSibling) {
        let nodeType = preSibling.getNodeType()
        if (nodeType.length > 0 && nodeType == curNodeType) {
          xcontent++
        }
        preSibling = preSibling.getPreviousSibling()
      }
    }

    return xcontent
  }

  static getCustomId(frameNode: FrameNode) {
    let customId = frameNode.getId()
    if (customId && customId.length > 0) {
      customId = customId.replace(/\//g, '')
      return '#' + customId
    }
    return ''
  }

  static getTextValue(frameNode: FrameNode): string {
    try {
      let queue: Array<FrameNode> = [frameNode]
      while (queue.length > 0) {
        let f = queue.shift()!
        let textValue = Util.getComponentLabel(f.getInspectorInfo())
        if (textValue.length > 0) {
          return textValue
        }

        let count = f.getChildrenCount()
        for (let i = 0; i < count; i++) {
          let child = f.getChild(i)
          if (child) {
            queue.push(child)
          }
        }
      }
      return ''
    } catch (e) {
      return ''
    }
  }
}

class _PageInfo {
  path: string = ''
  pageShowTimestamp: number = 0
}

class _XpathInfo {
  xpath: Array<string> = []
  xcontent: Array<string> = []
  index = 0
  eventType: EventType = EventType.ViewClick
  inList = false
}
