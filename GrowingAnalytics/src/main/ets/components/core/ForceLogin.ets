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

// @doc-impl UserIdentifier.md

import GrowingContext from './Context'
import DeviceInfo from './DeviceInfo'
import { ConfigMode } from '../interfaces/GrowingConfig'
import { PREFERENCE_IDENTIFY_DEVICE_ID } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import SharedPreferences from '../utils/SharedPreferences'

// 与 Web SDK identify 一致：超出部分截断而非拒绝
const IDENTIFY_DEVICE_ID_MAX_LENGTH = 1000

export default class ForceLogin {
  private static identifiedDeviceId: string = ''
  private static unlocked: boolean = false

  static init() {
    ForceLogin.identifiedDeviceId = SharedPreferences.getValue(PREFERENCE_IDENTIFY_DEVICE_ID, '') as string
    ForceLogin.unlocked = false
  }

  /**
   * 强制登录是否生效
   *
   * 与 Web SDK 一致，仅由主 Tracker 配置决定：主 Tracker 为 NewSaaS 且开启 forceLogin 时，
   * 所有 NewSaaS Tracker（含子 Tracker）统一阻塞并由主入口 identify 统一解锁；子 Tracker 自身的 forceLogin 不生效。
   */
  static isEnabled(): boolean {
    let main = GrowingContext.getDefaultContext()
    return main != undefined && main.config.mode == ConfigMode.NewSaaS && main.config.forceLogin
  }

  static identify(deviceId: string): boolean {
    if (!ForceLogin.isEnabled() || ForceLogin.unlocked) {
      LogUtil.info(() => 'Failed to identify, only available once when NewSaaS forceLogin is enabled')
      return false
    }
    // 与 Web SDK 校验规则一致：非空字符串即有效，不去除首尾空白，超过 1000 字符截断
    if (!deviceId) {
      LogUtil.info(() => 'Failed to identify, deviceId is empty')
      return false
    }

    let identifiedDeviceId = deviceId.slice(0, IDENTIFY_DEVICE_ID_MAX_LENGTH)
    ForceLogin.identifiedDeviceId = identifiedDeviceId
    ForceLogin.unlocked = true
    SharedPreferences.put(PREFERENCE_IDENTIFY_DEVICE_ID, identifiedDeviceId)
    LogUtil.info(() => 'Identify deviceId for all NewSaaS trackers')
    return true
  }

  static canSend(context: GrowingContext): boolean {
    return context.config.mode != ConfigMode.NewSaaS || !ForceLogin.isEnabled() || ForceLogin.unlocked
  }

  /**
   * 当前有效设备 ID：NewSaaS 优先使用已持久化的访问用户 ID，否则使用自动生成的设备 ID
   */
  static getDeviceId(context: GrowingContext): string {
    if (context.config.mode == ConfigMode.NewSaaS && ForceLogin.identifiedDeviceId.length > 0) {
      return ForceLogin.identifiedDeviceId
    }
    return DeviceInfo.deviceId
  }

  /**
   * 事件是否需要在发送时替换 deviceId
   *
   * 强制登录未解锁时构建的 NewSaaS 事件入库时带待替换标志（数据库独立列，不写入事件数据）；
   * canSend 对 SaaS/CDP 恒为 true，标志只会出现在 NewSaaS 事件中。
   */
  static isPending(context: GrowingContext): boolean {
    return !ForceLogin.canSend(context)
  }

  /**
   * 构建事件时使用的设备 ID
   *
   * 待替换事件写入自动生成的设备 ID，与老版本 SDK 一致：SDK 降级后老版本忽略待替换标志，按设备 ID 原样上报；
   * 新版本发送时只替换带标志的事件，已带真实 ID 的事件（老版本遗留、此前启动已确认身份）不改写。
   */
  static getEventDeviceId(context: GrowingContext): string {
    if (ForceLogin.isPending(context)) {
      return DeviceInfo.deviceId
    }
    return ForceLogin.getDeviceId(context)
  }

  /**
   * 发送时替换待替换事件 deviceId 所用的值；SaaS/CDP 事件不会带标志，返回空字符串表示无需替换
   */
  static getPendingReplacement(context: GrowingContext): string {
    if (context.config.mode != ConfigMode.NewSaaS) {
      return ''
    }
    return ForceLogin.getDeviceId(context)
  }

  static _reset() {
    ForceLogin.identifiedDeviceId = ''
    ForceLogin.unlocked = false
  }
}
