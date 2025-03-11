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
import { ConfigMode } from "../interfaces/GrowingConfig"
import { RefreshScreenshot } from "../mobileDebugger/Model"
import { INPUT_COMPONENTS, LIST_COMPONENTS, PATH_SEPARATOR, TEXT_COMPONENTS, WEB_COMPONENTS } from "../utils/Constants"
import Util from '../utils/Util'

export default class CircleElement {
  static setPagesAndElements(screenshot: RefreshScreenshot) {
    try {
      let inspectorTreeString = AnalyticsCore.uiContent.getFilteredInspectorTree(['id', 'content', 'label', 'focusable'])
      let inspectorTree = JSON.parse(inspectorTreeString)
      if (!inspectorTree) {
        return
      }

      let elementsTree = CircleElement._parseJsonTreeToElementsTree(inspectorTree)
      CircleElement._parseElementsTreeAndSetToScreenshot(elementsTree, screenshot)
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
    if (json["$attrs"] !== undefined) {
      element.attrs = new _ElementAttrs()
      if (json["$attrs"].id !== undefined) {
        element.attrs.id = json["$attrs"].id === "" ? undefined :
          isNaN(Number(json["$attrs"].id)) ? json["$attrs"].id : Number(json["$attrs"].id)
      }
      if (json["$attrs"].content !== undefined) {
        element.attrs.content = json["$attrs"].content
      } else if (json["$attrs"].label !== undefined) {
        element.attrs.content = json["$attrs"].label
      }
      if (json["$attrs"].focusable !== undefined) {
        element.attrs.focusable = json["$attrs"].focusable
      }
    }

    if (json["$children"] && Array.isArray(json["$children"])) {
      element.children = json["$children"].map((child: object) => CircleElement._parseJsonTreeToElementsTree(child))
    }

    return element
  }

  private static _parseElementsTreeAndSetToScreenshot(elementsTree: _Element, screenshot: RefreshScreenshot) {
    let pages: Array<_ScreenshotPage> = []
    let paths: Set<string> = new Set<string>()
    let elements: Array<_ScreenshotElement> = []
    let context = GrowingContext.getDefaultContext() as GrowingContext

    CircleElement._traverseAllNodes(elementsTree, (e) => {
      let nodeType = CircleElement._getNodeType(e.type ?? '')
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
      if (e.rect) {
        CircleElement._parseRectString(e.rect, element)
      }
      if (e.inList) {
        element.index = index
      }
      element.content = e.content

      // getPageInfo
      let pageInfo = AnalyticsCore.uiContent.getPageInfoByUniqueId(e.ID)
      let realPath: string | undefined = undefined
      let alias: string = ''
      if (pageInfo.navDestinationInfo) {
        realPath = PATH_SEPARATOR + pageInfo.navDestinationInfo.name.toString()
        alias = Util.getAliasFromNavInfoParameter(pageInfo.navDestinationInfo.param)
      } else if (pageInfo.routerPageInfo) {
        realPath = PATH_SEPARATOR + pageInfo.routerPageInfo.name.toString()
        alias = Util.getAliasFromNavInfoParameter(router.getParams())
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
      elements.push(element)
    })

    screenshot.pages = pages
    screenshot.elements = elements
  }

  private static _traverseAllNodes(rootElement: _Element, callback: (element: _Element) => void) {
    let queue: _Element[] = [rootElement]

    while (queue.length > 0) {
      let element = queue.shift()!
      if (element.type != 'root') {
        // 暂时用focusable判断元素可点击
        if (element.attrs && element.attrs.focusable) {
          callback(element)
        }
      } else {
        element.xpath.push('root')
        element.xcontent.push('0')
      }

      let parent = element
      if (parent.children && parent.children.length > 0) {
        let previousSiblingCount: Map<string, number> = new Map()

        for (let i = 0; i < parent.children.length; i++) {
          let e = parent.children[i]
          if (!e.type) {
            continue
          }
          e.xpath = [...parent.xpath]
          e.xcontent = [...parent.xcontent]

          // getXcontent
          let n = previousSiblingCount.get(e.type)
          if (n == undefined) {
            n = -1
          }
          let xcontent = n + 1
          previousSiblingCount.set(e.type, xcontent)

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
            if (e.attrs) {
              if (e.attrs.id && e.attrs.id.length > 0) {
                customId = '#' + e.attrs.id.replace(/\//g, '')
              }
            }
            e.xcontent.push(String(xcontent) + customId)
          }

          // content
          e.content = e.attrs?.content

          // reserve
          e.parent = new WeakRef(parent)
          queue.push(e)
        }
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
    let nodeText = 'TEXT'
    let nodeButton = 'BUTTON'
    let nodeInput = 'INPUT'
    let nodeList = 'LIST'
    let nodeWebView = 'WEB_VIEW'

    let result = nodeButton
    if (TEXT_COMPONENTS.includes(nodeType)) {
      result = nodeText
    } else if (INPUT_COMPONENTS.includes(nodeType)) {
      result = nodeInput
    } else if (LIST_COMPONENTS.includes(nodeType)) {
      result = nodeList
    } else if (WEB_COMPONENTS.includes(nodeType)) {
      result = nodeWebView
    }
    return result
  }
}

class _Element {
  ID?: number // unique id
  type?: string
  rect?: string
  attrs?: _ElementAttrs
  children?: Array<_Element>

  // XpathInfo
  xpath: Array<string> = []
  xcontent: Array<string> = []
  index: number = 0
  inList: boolean = false

  content?: string

  // reserve
  parent?: WeakRef<_Element>
}

class _ElementAttrs {
  id?: string // custom id
  content?: string
  focusable?: boolean
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