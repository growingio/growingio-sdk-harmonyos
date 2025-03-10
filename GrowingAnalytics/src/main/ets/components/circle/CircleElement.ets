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

import AnalyticsCore from "../core/AnalyticsCore"
import AppInfo from "../core/AppInfo"
import GrowingContext from "../core/Context"
import { ConfigMode } from "../interfaces/GrowingConfig"
import { RefreshScreenshot } from "../mobileDebugger/Model"
import { PATH_SEPARATOR } from "../utils/Constants"

export default class CircleElement {
  static setPagesAndElements(screenshot: RefreshScreenshot) {
    let inspectorTreeString = AnalyticsCore.uiContent.getFilteredInspectorTree(['id', 'content', 'focusable'])
    let inspectorTree = JSON.parse(inspectorTreeString)
    if (!inspectorTree) {
      return
    }
    let elementsTree = CircleElement._parseJsonTreeToElementsTree(inspectorTree)
    let elements = CircleElement._parseElementsTreeToElements(elementsTree)
    screenshot.elements = [...elements]
    screenshot.pages = []
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

  private static _parseElementsTreeToElements(elementsTree: _Element): Array<_ScreenshotElement> {
    let elements: Array<_ScreenshotElement> = []
    let context = GrowingContext.getDefaultContext() as GrowingContext

    CircleElement._traverseAllNodes(elementsTree, (e) => {
      let nodeType = e.type ?? ''
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
        '',
      )

      if (e.rect) {
        CircleElement._parseRectString(e.rect, element)
      }
      if (e.inList) {
        element.index = index
      }
      element.content = e.content

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

    return elements
  }

  private static _traverseAllNodes(rootElement: _Element, callback: (element: _Element) => void) {
    let queue: _Element[] = [rootElement]

    let listComponents: Array<string> = [
      "ListItem",
      "GridItem",
      "GridCol",
    ]

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
          if (listComponents.includes(e.type)) {
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
  page: string
  index?: number
  content?: string
  parentXPath?: string
  parentXContent?: string
  isContainer?: boolean

  left: number = 0
  top: number = 0
  width: number = 0
  height: number = 0

  constructor(
    nodeType: string,
    domain: string,
    zLevel: number,
    xpath: string,
    xcontent: string,
    page: string,
  ) {
    this.nodeType = nodeType
    this.domain = domain
    this.zLevel = zLevel
    this.xpath = xpath
    this.xcontent = xcontent
    this.page = page
  }
}