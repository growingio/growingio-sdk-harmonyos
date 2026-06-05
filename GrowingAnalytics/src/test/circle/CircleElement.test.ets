/**
 * @license
 * Copyright (C) 2026 Beijing Yishu Technology Co., Ltd.
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

import { describe, it, expect } from '@ohos/hypium'
import CircleElement, { _Element } from '../../main/ets/components/circle/CircleElement'
import { ImpressElement } from '../../main/ets/components/mobileDebugger/SaaSModel'
import {
  CIRCLE_NODE_BUTTON,
  CIRCLE_NODE_INPUT,
  CIRCLE_NODE_TEXT,
  CIRCLE_NODE_WEBVIEW,
} from '../../main/ets/components/utils/Constants'

export default function circleElementTests() {

  describe('CircleElement_assignParentXPath', () => {

    let build = (xpath: string): ImpressElement => {
      let el = new ImpressElement('button', xpath, 'com.example.app')
      el.isContainer = true
      return el
    }

    it('每个元素取最深的前缀容器作为 parentXPath', 0, () => {
      let a = build('/Page[0]')
      let b = build('/Page[0]/List[0]')
      let c = build('/Page[0]/List[0]/Text[0]')
      let elements: Array<ImpressElement> = [c, a, b]
      CircleElement._assignParentXPath(elements)

      expect(c.parentXPath).assertEqual('/Page[0]/List[0]')
      expect(b.parentXPath).assertEqual('/Page[0]')
      expect(a.parentXPath === undefined).assertTrue()
    })

    it('无前缀关系的元素不设置 parentXPath', 0, () => {
      let a = build('/Page[0]/Button[0]')
      let b = build('/Page[0]/Button[1]')
      let elements: Array<ImpressElement> = [a, b]
      CircleElement._assignParentXPath(elements)
      expect(a.parentXPath === undefined).assertTrue()
      expect(b.parentXPath === undefined).assertTrue()
    })

    it('非容器元素不参与容器集合，但仍会被赋 parentXPath', 0, () => {
      let container = build('/Page[0]')
      let leaf = new ImpressElement('text', '/Page[0]/Text[0]', 'com.example.app')
      leaf.isContainer = false
      let elements: Array<ImpressElement> = [container, leaf]
      CircleElement._assignParentXPath(elements)
      expect(leaf.parentXPath).assertEqual('/Page[0]')
      expect(container.parentXPath === undefined).assertTrue()
    })

    it('自身 xpath 不会被当作自己的 parentXPath', 0, () => {
      let a = build('/Page[0]')
      let elements: Array<ImpressElement> = [a]
      CircleElement._assignParentXPath(elements)
      expect(a.parentXPath === undefined).assertTrue()
    })
  })

  describe('CircleElement_isClickable', () => {

    let build = (type: string, nodeType: string, focusable: boolean): _Element => {
      let el = new _Element()
      el.type = type
      el.nodeType = nodeType
      el.attrs.focusable = focusable
      return el
    }

    it('overlay 永远不可点击', 0, () => {
      expect(CircleElement._isClickable(build('overlay', CIRCLE_NODE_BUTTON, true))).assertFalse()
    })

    it('Button 类组件强制可点击（不依赖 focusable）', 0, () => {
      expect(CircleElement._isClickable(build('Button', CIRCLE_NODE_BUTTON, false))).assertTrue()
    })

    it('WebView 强制可点击（不依赖 focusable，对齐 iOS WKWebView）', 0, () => {
      expect(CircleElement._isClickable(build('Web', CIRCLE_NODE_WEBVIEW, false))).assertTrue()
    })

    it('自定义组件 __Common__ 强制可点击', 0, () => {
      expect(CircleElement._isClickable(build('__Common__', CIRCLE_NODE_TEXT, false))).assertTrue()
    })

    it('输入框 focusable 时可点击', 0, () => {
      expect(CircleElement._isClickable(build('TextInput', CIRCLE_NODE_INPUT, true))).assertTrue()
    })

    it('输入框非 focusable（禁用态）时不可点击', 0, () => {
      expect(CircleElement._isClickable(build('TextInput', CIRCLE_NODE_INPUT, false))).assertFalse()
    })

    it('容器组件即使 focusable 也不可点击', 0, () => {
      expect(CircleElement._isClickable(build('List', CIRCLE_NODE_TEXT, true))).assertFalse()
    })

    it('普通文本 focusable 时可点击', 0, () => {
      expect(CircleElement._isClickable(build('Text', CIRCLE_NODE_TEXT, true))).assertTrue()
    })

    it('普通文本非 focusable 时不可点击', 0, () => {
      expect(CircleElement._isClickable(build('Text', CIRCLE_NODE_TEXT, false))).assertFalse()
    })
  })
}
