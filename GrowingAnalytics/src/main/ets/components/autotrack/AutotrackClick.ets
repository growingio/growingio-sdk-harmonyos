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

import AnalyticsCore from '../core/AnalyticsCore'
import GrowingContext from '../core/Context'
import { EventType } from '../event/Event'
import PageEvent from '../event/PageEvent'
import ViewElementEvent from '../event/ViewElementEvent'
import { ConfigMode } from '../interfaces/GrowingConfig'
import { PATH_SEPARATOR } from '../utils/Constants'
import Util from '../utils/Util'

export default class AutotrackClick {
  private static uiContent: UIContext
  private static listComponents: Array<string> = [
    "ListItem",
    "GridItem",
    "GridCol",
  ]

  private static inputComponents: Array<string> = [
    "TextInput",
    "TextArea",
    "RichEditor",
  ]

  static initAutotrackClick(context: UIContext) {
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

    let context = GrowingContext.getDefaultContext() as GrowingContext

    // page
    let pageInfo = AutotrackClick.getPageInfo(frameNode)
    let path = pageInfo.path
    let ptm = pageInfo.pageShowTimestamp

    // view
    let textValue = Util.getComponentLabel(frameNode.getInspectorInfo())
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

  static getPageInfo(frameNode: FrameNode): PageInfo {
    let info = new PageInfo()

    // get real page
    let pageInfo = AutotrackClick.uiContent.getPageInfoByUniqueId(frameNode.getUniqueId())
    let realPath: string | undefined = undefined
    if (pageInfo.navDestinationInfo) {
      realPath = PATH_SEPARATOR + pageInfo.navDestinationInfo.name.toString()
    } else if (pageInfo.routerPageInfo) {
      realPath = PATH_SEPARATOR + pageInfo.routerPageInfo.name.toString()
    }

    if (realPath) {
      info.path = realPath

      let context = GrowingContext.getDefaultContext() as GrowingContext
      if (context.config.mode == ConfigMode.CDP) {
        // compare with last page in cache
        let lastPage = PageEvent.getLastPage(context)
        let path = lastPage?.path
        if (path == realPath) {
          info.pageShowTimestamp = lastPage?.timestamp ?? 0
        }
      }
    }

    return info
  }

  static getXpathInfo(frameNode: FrameNode): XpathInfo {
    let info = new XpathInfo()
    let f: FrameNode | null = frameNode
    info.eventType = AutotrackClick.getEventType(f.getNodeType())

    while (f) {
      AutotrackClick.setXpathInfo(info, f)
      f = f.getParent()
    }

    return info
  }

  static setXpathInfo(info: XpathInfo, frameNode: FrameNode) {
    let curNodeType = frameNode.getNodeType()
    info.xpath.push(curNodeType)

    let xcontent = AutotrackClick.getXcontent(frameNode)
    if (!info.inList && AutotrackClick.listComponents.includes(curNodeType)) {
      info.xcontent.push('-')
      info.index = xcontent
      info.inList = true
    } else {
      info.xcontent.push(String(xcontent))
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

  static getEventType(nodeType: string) {
    if (AutotrackClick.inputComponents.includes(nodeType)) {
      return EventType.ViewChange
    }
    return EventType.ViewClick
  }
}

class PageInfo {
  path: string = ''
  pageShowTimestamp: number = 0
}

class XpathInfo {
  xpath: Array<string> = []
  xcontent: Array<string> = []
  index = 0
  eventType: EventType = EventType.ViewClick
  inList = false
}
