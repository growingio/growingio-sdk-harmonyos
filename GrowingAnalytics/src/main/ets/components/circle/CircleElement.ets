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

import JSON from '@ohos.util.json'
import router from '@ohos.router'

import AnalyticsCore from "../core/AnalyticsCore"
import AppInfo from "../core/AppInfo"
import GrowingContext from "../core/Context"
import Hybrid from '../core/Hybrid'
import { ConfigMode } from "../interfaces/GrowingConfig"
import { RefreshScreenshot } from "../mobileDebugger/Model"
import {
  BUTTON_COMPONENTS,
  DIALOG_PATH_PREFIXES,
  INPUT_COMPONENTS,
  LIST_COMPONENTS,
  PATH_SEPARATOR,
  TEXT_COMPONENTS,
  WEB_COMPONENTS,
  CONTAINER_COMPONENTS,
  CIRCLE_NODE_TEXT,
  CIRCLE_NODE_BUTTON,
  CIRCLE_NODE_INPUT,
  CIRCLE_NODE_LIST,
  CIRCLE_NODE_WEBVIEW,
  AUTOTRACK_ELEMENT_ID } from "../utils/Constants"
import Util from '../utils/Util'
import AutotrackPage from '../autotrack/AutotrackPage'
import AutotrackClick from '../autotrack/AutotrackClick'

export default class CircleElement {
  static async setPagesAndElements(screenshot: RefreshScreenshot) {
    try {
      let filter = ['id', 'content', 'focusable', 'label', 'opacity', 'visibility']
      let inspectorTreeString = AnalyticsCore.uiContent.getFilteredInspectorTree(filter)
      let inspectorTree = JSON.parse(inspectorTreeString)
      if (!inspectorTree) {
        return
      }

      let elementsTree = CircleElement._parseJsonTreeToElementsTree(inspectorTree)
      await CircleElement._parseElementsTreeAndSetToScreenshot(elementsTree, screenshot)
    } catch (e) {

    }
  }

  private static _parseJsonTreeToElementsTree(json: object): _Element {
    let element = new _Element()
    if (json["$ID"] !== undefined) {
      element.ID = json["$ID"]
    }
    if (json["$type"] !== undefined) {
      element.type = json["$type"]
    }
    if (json["$rect"] !== undefined) {
      element.rect = json["$rect"]
    }

    element.attrs = new _ElementAttrs()
    if (json["$attrs"] !== undefined) {
      if (json["$attrs"].id !== undefined) {
        element.attrs.id = json["$attrs"].id
      }
      if (json["$attrs"].content !== undefined) {
        element.attrs.content = json["$attrs"].content
      } else if (json["$attrs"].label !== undefined) {
        element.attrs.content = json["$attrs"].label
      }
      if (json["$attrs"].focusable !== undefined) {
        element.attrs.focusable = json["$attrs"].focusable
      }
      if (json["$attrs"].visibility !== undefined) {
        element.attrs.visibility = json["$attrs"].visibility
      }
      if (json["$attrs"].opacity !== undefined) {
        element.attrs.opacity = json["$attrs"].opacity
      }
    }

    if (json["$children"] && Array.isArray(json["$children"])) {
      element.children = json["$children"].map((child: object) => CircleElement._parseJsonTreeToElementsTree(child))
    }

    return element
  }

  private static async _parseElementsTreeAndSetToScreenshot(elementsTree: _Element, screenshot: RefreshScreenshot) {
    let pages: Array<_ScreenshotPage> = []
    let paths: Set<string> = new Set<string>()
    let elements: Array<_ScreenshotElement> = []
    let context = GrowingContext.getDefaultContext() as GrowingContext

    await CircleElement._traverseAllNodes(elementsTree, async (e) => {
      let nodeType = e.nodeType
      if (nodeType == CIRCLE_NODE_INPUT) {
        // 目前不支持VIEW_CHANGE事件，都以VIEW_CLICK来圈选
        nodeType = CIRCLE_NODE_BUTTON
      }

      let domain = AppInfo.domain
      let zLevel = 0
      let xpath = ''
      let xcontent = ''
      let index = e.index

      // unused
      let parentXPath = ''
      let parentXContent = ''
      let isContainer = false

      if (context.config.mode == ConfigMode.NewSaaS) {
        xpath = PATH_SEPARATOR + e.xpath.join(PATH_SEPARATOR)
        xcontent = PATH_SEPARATOR + e.xcontent.join(PATH_SEPARATOR)
        if (e.inList) {
          index = index + 1
        }

        // unused
        parentXPath = PATH_SEPARATOR + e.xpath.slice(0, -1).join(PATH_SEPARATOR)
        parentXContent = PATH_SEPARATOR + e.xcontent.slice(0, -1).join(PATH_SEPARATOR)
      } else if (context.config.mode == ConfigMode.CDP) {
        for (let i = 0; i < e.xpath.length; i++) {
          xpath = xpath + PATH_SEPARATOR + e.xpath[i] + '[' + e.xcontent[i] + ']'

          // unused
          if (i < (e.xpath.length - 1)) {
            parentXPath = parentXPath + PATH_SEPARATOR + e.xpath[i] + '[' + e.xcontent[i] + ']'
          }
        }
      }

      let element = new _ScreenshotElement(
        nodeType,
        domain,
        zLevel,
        xpath,
        xcontent,
      )
      CircleElement._parseRectString(e.rect, element)
      if (element.left >= screenshot.screenWidth
        || element.top >= screenshot.screenHeight
        || element.width == 0
        || element.height == 0
        || (element.width >= screenshot.screenWidth && element.height >= screenshot.screenHeight)
      ) {
        return
      }
      if (e.inList) {
        element.index = index
      }
      element.content = e.content

      // getPageInfo
      let pageInfo = AnalyticsCore.uiContent.getPageInfoByUniqueId(e.ID)
      let realPath: string | undefined = undefined
      let alias: string = ''
      let customTitle: string = ''
      if (pageInfo.navDestinationInfo) {
        let navInfo = pageInfo.navDestinationInfo
        realPath = PATH_SEPARATOR + navInfo.name.toString()
        alias = Util.getAliasFromNavInfoParameter(navInfo.param)
        customTitle = Util.getTitleFromNavInfoParameter(navInfo.param)
      } else if (pageInfo.routerPageInfo) {
        let param = router.getParams()
        realPath = PATH_SEPARATOR + pageInfo.routerPageInfo.name.toString()
        alias = Util.getAliasFromNavInfoParameter(param)
        customTitle = Util.getTitleFromNavInfoParameter(param)
      }

      // set element.page
      if (realPath) {
        let pagePath = realPath
        if (alias.length > 0) {
          pagePath = PATH_SEPARATOR + alias
        }
        element.page = pagePath

        // set pages
        if (!paths.has(realPath)) {
          paths.add(realPath)

          let title = realPath
          if (title.includes(PATH_SEPARATOR)) {
            title = title.substring(title.lastIndexOf(PATH_SEPARATOR) + 1)
          }
          if (customTitle.length > 0) {
            title = customTitle
          }
          let page = new _ScreenshotPage(
            0,
            0,
            screenshot.screenWidth,
            screenshot.screenHeight,
            pagePath,
            title
          )
          pages.push(page)
        }
      } else {
        // 该frameNode所在页面并不是通过Navigation或Router跳转，可能是弹窗视图
        for (let i = 0; i < DIALOG_PATH_PREFIXES.length; i++) {
          let prefix = DIALOG_PATH_PREFIXES[i]
          if (element.xpath.startsWith(prefix)) {
            let lastPage = AutotrackPage.lastPage
            element.page = lastPage?.path ?? ''
            break
          }
        }
      }

      // TODO Real Content
      // TODO ZLevel

      // unused
      if (context.config.mode == ConfigMode.NewSaaS) {
        element.parentXPath = parentXPath
        element.parentXContent = parentXContent
      } else if (context.config.mode == ConfigMode.CDP) {
        element.parentXPath = parentXPath
        element.isContainer = isContainer
      }

      // webview
      if (nodeType == CIRCLE_NODE_WEBVIEW) {
        let webviewId = ''
        if (e.attrs.id && e.attrs.id.length > 0) {
          webviewId = e.attrs.id
          let domTree = await Hybrid.getDomTreeById(webviewId, element.left, element.top, element.width, element.height)
          try {
            element.webView = JSON.parse(domTree) ?? undefined
          } catch {
            element.webView = undefined
          }
        }
      }
      elements.push(element)
    })

    screenshot.pages = pages
    screenshot.elements = elements
  }

  private static async _traverseAllNodes(rootElement: _Element, callback: (element: _Element) => Promise<void>) {
    let stack: _Element[] = [rootElement]

    while (stack.length > 0) {
      let element = stack.pop()!
      if (CircleElement._isVisible(element) && CircleElement._isClickable(element)) {
        await callback(element)
      }

      if (element.type == 'root') {
        element.xpath.push('root')
        element.xcontent.push('0')
      }

      let parent = element
      let parentType = parent.type
      if (CircleElement._isVisible(parent) && parent.children && parent.children.length > 0) {
        let children: _Element[] = []
        // without offset
        let previousSiblingXContents: Map<string, number> = new Map()
        // offset of children that parse from InspectorTree
        let childOffset = 0
        let parentFrameNode = AnalyticsCore.uiContent.getFrameNodeByUniqueId(parent.ID)

        for (let i = 0; i < parent.children.length; i++) {
          let e = parent.children[i]
          e.nodeType = CircleElement._getNodeType(e.type)
          e.xpath = [...parent.xpath]
          e.xcontent = [...parent.xcontent]

          // getXcontent
          let n = previousSiblingXContents.get(e.type)
          if (n == undefined) {
            n = -1
          }
          // fast getXcontent
          let xcontent = n + 1
          previousSiblingXContents.set(e.type, xcontent)

          xcontent = xcontent + childOffset
          if (parentType != 'root') {
            let frameNode = AnalyticsCore.uiContent.getFrameNodeByUniqueId(e.ID)
            if (!frameNode || !parentFrameNode) {
              continue
            }
            // 当children皆为同种组件时，可以不调用AutotrackClick.getXcontent而加快速度
            if (parentFrameNode.getChild(i + childOffset) != frameNode) {
              // slow getXcontent
              let actualXContent = AutotrackClick.getXcontent(frameNode)
              childOffset = actualXContent - xcontent
              xcontent = actualXContent
            }
          }

          if (parentType == 'TabBar') {
            // 在TabBar下的子组件focusable为false，将子组件Column的focusable改为true
            if (e.type == 'Column') {
              e.attrs.focusable = true
            }
          }

          // setXpathInfo
          e.xpath.push(e.type)
          if (LIST_COMPONENTS.includes(e.type)) {
            if (parent.inList) {
              let j = e.xcontent.indexOf('-')
              if (j !== -1) {
                e.xcontent[j] = String(parent.index)
              }
            }
            e.xcontent.push('-')
            e.index = xcontent
            e.inList = true
          } else {
            e.index = parent.index
            e.inList = parent.inList

            // getCustomId
            let customId = ''
            if (e.attrs.id && e.attrs.id.length > 0) {
              customId = '#' + e.attrs.id.replace(/\//g, '')
              if (customId.includes(AUTOTRACK_ELEMENT_ID)) {
                // 如果该组件标记为可点击，将该组件的focusable改为true
                e.attrs.focusable = true
              }
            }
            e.xcontent.push(String(xcontent) + customId)
          }

          // content
          e.content = e.attrs.content

          // reserve
          e.parent = new WeakRef(parent)
          children.push(e)
        }

        children = children.reverse()
        stack.push(...children)
      }
    }
  }

  private static _parseRectString(rect: string, element: _ScreenshotElement) {
    let matches = rect.match(/\[([\d.]+),\s*([\d.]+)\],\[([\d.]+),\s*([\d.]+)\]/)
    if (!matches || matches.length < 5) {
      return
    }

    let left = parseFloat(matches[1])
    let top = parseFloat(matches[2])
    let right = parseFloat(matches[3])
    let bottom = parseFloat(matches[4])

    element.top = px2vp(top)
    element.left = px2vp(left)
    element.width = px2vp(right - left)
    element.height = px2vp(bottom - top)
  }

  private static _getNodeType(nodeType: string): string {
    let result = CIRCLE_NODE_TEXT
    if (BUTTON_COMPONENTS.includes(nodeType)) {
      result = CIRCLE_NODE_BUTTON
    } else if (TEXT_COMPONENTS.includes(nodeType)) {
      result = CIRCLE_NODE_TEXT
    } else if (INPUT_COMPONENTS.includes(nodeType)) {
      result = CIRCLE_NODE_INPUT
    } else if (LIST_COMPONENTS.includes(nodeType)) {
      result = CIRCLE_NODE_LIST
    } else if (WEB_COMPONENTS.includes(nodeType)) {
      result = CIRCLE_NODE_WEBVIEW
    }
    return result
  }

  private static _isVisible(element: _Element): boolean {
    if (element.type == 'root') {
      return true
    }
    let visibility = element.attrs.visibility
    let opacity = element.attrs.opacity
    return visibility == 'Visibility.Visible' && opacity > 0
  }

  private static _isClickable(element: _Element): boolean {
    let type = element.type
    if (type == 'overlay') {
      return false
    }
    if (element.nodeType && element.nodeType == CIRCLE_NODE_BUTTON) {
      // Button类型组件默认可点击
      return true
    }
    if (type == '__Common__') {
      // 自定义组件默认可点击
      return true
    }
    // 没有clickable，用focusable代替
    if (element.attrs.focusable) {
      // 容器组件不可点击
      if (!CONTAINER_COMPONENTS.includes(type)) {
        return true
      }
    }
    return false
  }
}

class _Element {
  ID: number = 0 // unique id
  type: string = ''
  rect: string = '[0.00, 0.00],[0.00, 0.00]'
  children: Array<_Element> = []
  attrs: _ElementAttrs = new _ElementAttrs()

  // XpathInfo
  xpath: Array<string> = []
  xcontent: Array<string> = []
  index: number = 0
  inList: boolean = false

  content?: string
  nodeType: string = CIRCLE_NODE_TEXT

  // reserve
  parent?: WeakRef<_Element>
}

class _ElementAttrs {
  id?: string // custom id
  content?: string
  focusable: boolean = false
  visibility: string = 'Visibility.Visible'
  opacity: number = 1
}

class _ScreenshotPage {
  left: number
  top: number
  width: number
  height: number
  path: string
  title?: string

  constructor(
    left: number,
    top: number,
    width: number,
    height: number,
    path: string,
    title?: string,
  ) {
    this.left = left
    this.top = top
    this.width = width
    this.height = height
    this.path = path
    this.title = title
  }
}

class _ScreenshotElement {
  nodeType: string
  domain: string
  zLevel: number
  xpath: string
  xcontent: string
  index?: number
  content?: string
  parentXPath?: string
  parentXContent?: string
  isContainer?: boolean

  left: number = 0
  top: number = 0
  width: number = 0
  height: number = 0
  page: string = ''
  webView?: object

  constructor(
    nodeType: string,
    domain: string,
    zLevel: number,
    xpath: string,
    xcontent: string,
  ) {
    this.nodeType = nodeType
    this.domain = domain
    this.zLevel = zLevel
    this.xpath = xpath
    this.xcontent = xcontent
  }
}