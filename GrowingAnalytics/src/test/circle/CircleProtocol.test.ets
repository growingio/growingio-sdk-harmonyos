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
import { ClientInit, ClientQuit, ImpressElement, SdkConfig, UserAction } from '../../main/ets/components/mobileDebugger/SaaSModel'

export default function circleProtocolTests() {

  describe('Circle_SaaS_Protocol', () => {

    it('ClientInit 字段与 iOS client_init 一致', 0, () => {
      let init = new ClientInit('ACCOUNT_ID', 'com.example.app', '1.2.3')
      let raw = JSON.stringify(init)
      expect(raw.includes('"msgId":"client_init"')).assertEqual(true)
      expect(raw.includes('"ai":"ACCOUNT_ID"')).assertEqual(true)
      expect(raw.includes('"spn":"com.example.app"')).assertEqual(true)
      expect(raw.includes('"appVersion":"1.2.3"')).assertEqual(true)
      expect(raw.includes('"protocolVersion":1')).assertEqual(true)
      expect(raw.includes('"sdkVersion":')).assertEqual(true)
    })

    it('ClientQuit 字段与 iOS client_quit 一致', 0, () => {
      let raw = JSON.stringify(new ClientQuit())
      expect(raw.includes('"msgId":"client_quit"')).assertEqual(true)
    })

    it('SdkConfig.isTrackWebView 序列化为布尔', 0, () => {
      let raw = JSON.stringify(new SdkConfig('1.0', true))
      expect(raw.includes('"isTrackWebView":true')).assertEqual(true)
      expect(raw.includes('"appVersion":"1.0"')).assertEqual(true)
    })

    it('UserAction(refresh) 顶层字段名/类型一致', 0, () => {
      let sdkConfig = new SdkConfig('1.2.3', false)
      let action = new UserAction('refresh', '更新截图', '首页', '/HomePage', 'com.example.app',
        'data:image/jpeg;base64,AAAA', 750, 1334, '1.2.3', sdkConfig, 1234)
      expect(action.msgId).assertEqual('user_action')
      expect(action.userAction).assertEqual('refresh')
      expect(action.actionDesc).assertEqual('更新截图')
      expect(action.title).assertEqual('首页')
      expect(action.page).assertEqual('/HomePage')
      expect(action.domain).assertEqual('com.example.app')
      expect(action.screenshotWidth).assertEqual(750)
      expect(action.screenshotHeight).assertEqual(1334)
      expect(action.sk).assertEqual(1234)
      expect(action.impress.length).assertEqual(0)
      let raw = JSON.stringify(action)
      expect(raw.includes('"msgId":"user_action"')).assertEqual(true)
      expect(raw.includes('"msgType"')).assertEqual(false)
      expect(raw.includes('"screenshotWidth":750')).assertEqual(true)
      expect(raw.includes('"screenshotHeight":1334')).assertEqual(true)
      expect(raw.includes('"sk":1234')).assertEqual(true)
      expect(raw.includes('"isTrackWebView":false')).assertEqual(true)
      expect(raw.includes('"impress":[]')).assertEqual(true)
    })

    it('UserAction.targets 默认不序列化', 0, () => {
      let sdkConfig = new SdkConfig('1.0', true)
      let action = new UserAction('refresh', '更新截图', 't', '/p', 'd',
        's', 100, 200, '1.0', sdkConfig, 1)
      expect(JSON.stringify(action).includes('targets')).assertEqual(false)
    })

    it('ImpressElement 字段名/类型与 iOS impress 一致', 0, () => {
      let el = new ImpressElement('button', '/Column[0]/Button[0]', 'com.example.app')
      el.left = 0
      el.top = 1296
      el.width = 750
      el.height = 88
      el.isClickable = 1
      el.isContainer = true
      el.isTab = false
      el.isWebview = 0
      el.zLevel = 10
      el.index = '3'
      el.content = 'hello'
      el.page = '/HomePage'
      el.parentXPath = '/Column[0]'

      let raw = JSON.stringify(el)
      expect(raw.includes('"nodeType":"button"')).assertEqual(true)
      expect(raw.includes('"xpath":"/Column[0]/Button[0]"')).assertEqual(true)
      expect(raw.includes('"domain":"com.example.app"')).assertEqual(true)
      expect(raw.includes('"left":0')).assertEqual(true)
      expect(raw.includes('"top":1296')).assertEqual(true)
      expect(raw.includes('"width":750')).assertEqual(true)
      expect(raw.includes('"height":88')).assertEqual(true)
      expect(raw.includes('"isClickable":1')).assertEqual(true)
      expect(raw.includes('"isWebview":0')).assertEqual(true)
      expect(raw.includes('"isContainer":true')).assertEqual(true)
      expect(raw.includes('"isTab":false')).assertEqual(true)
      expect(raw.includes('"zLevel":10')).assertEqual(true)
      expect(raw.includes('"index":"3"')).assertEqual(true)
      expect(raw.includes('"content":"hello"')).assertEqual(true)
      expect(raw.includes('"page":"/HomePage"')).assertEqual(true)
      expect(raw.includes('"parentXPath":"/Column[0]"')).assertEqual(true)
    })

    it('ImpressElement 可选字段未设置时不序列化', 0, () => {
      let raw = JSON.stringify(new ImpressElement('text', '/Text[0]', 'd'))
      expect(raw.includes('index')).assertEqual(false)
      expect(raw.includes('content')).assertEqual(false)
      expect(raw.includes('parentXPath')).assertEqual(false)
      expect(raw.includes('"nodeType":"text"')).assertEqual(true)
    })

    it('UserAction 内嵌 impress 数组结构正确', 0, () => {
      let sdkConfig = new SdkConfig('1.0', true)
      let action = new UserAction('click', '点击了按钮', 't', '/p', 'd',
        's', 100, 200, '1.0', sdkConfig, 1)
      let el = new ImpressElement('button', '/Button[0]', 'd')
      el.isClickable = 1
      action.impress = [el]
      expect(action.impress.length).assertEqual(1)
      expect(action.impress[0].nodeType).assertEqual('button')
      expect(action.impress[0].xpath).assertEqual('/Button[0]')
      let raw = JSON.stringify(action)
      expect(raw.includes('"userAction":"click"')).assertEqual(true)
      expect(raw.includes('"nodeType":"button"')).assertEqual(true)
    })
  })
}
