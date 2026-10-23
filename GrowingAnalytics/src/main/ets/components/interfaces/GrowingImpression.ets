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

// @doc-impl ViewImpression.md

import { AttributesType } from '../utils/Constants'

/**
 * 元素曝光配置
 */
export class GrowingImpressionConfig {
  _impressionScale: number = 0
  _stayDuration: number = 0
  // 内部预留，暂不公开：是否允许同一元素多次曝光，默认 true（元素离开可视区再次进入时会再发送一次）。
  // 置为 false 时必须为元素指定 identifier，否则将被降级为 true 处理
  _repeatable: boolean = true

  constructor() {}

  static create(impressionScale: number, stayDuration: number): GrowingImpressionConfig {
    let config = new GrowingImpressionConfig()
    config.impressionScale = impressionScale
    config.stayDuration = stayDuration
    return config
  }

  /**
   * 可见面积占比阈值，有效范围 0~1，超出范围将被截断，默认 0（露出即算曝光）
   */
  set impressionScale(scale: number) {
    if (Number.isNaN(scale) || scale < 0) {
      scale = 0
    } else if (scale > 1) {
      scale = 1
    }
    this._impressionScale = scale
  }

  get impressionScale(): number {
    return this._impressionScale
  }

  /**
   * 最小可见时长，单位秒，负值按 0 处理，默认 0（无需停留）
   */
  set stayDuration(duration: number) {
    if (Number.isNaN(duration) || duration < 0) {
      duration = 0
    }
    this._stayDuration = duration
  }

  get stayDuration(): number {
    return this._stayDuration
  }

  copy(): GrowingImpressionConfig {
    let config = new GrowingImpressionConfig()
    config._impressionScale = this._impressionScale
    config._stayDuration = this._stayDuration
    config._repeatable = this._repeatable
    return config
  }

  /**
   * 精确比较：这里要回答的是"调用方传进来的还是不是同一份配置"，
   * 留容差反而会把 0.5 与 0.500001 当成同一份配置，静默沿用旧的
   */
  isEqual(other: GrowingImpressionConfig): boolean {
    return this._impressionScale == other._impressionScale &&
      this._stayDuration == other._stayDuration &&
      this._repeatable == other._repeatable
  }
}

/**
 * 内部预留，暂不公开（未经 index.ets 导出）
 *
 * 元素曝光回调，三个回调均在 UI 线程同步执行，实现中不要做耗时操作
 *
 * componentId 为调用 trackViewImpression 时传入的组件 id，identifier 为曝光标识（未指定时为 undefined）
 */
export interface GrowingImpressionDelegate {
  /**
   * 返回 false 则本次不发送曝光事件。元素离开可视区再次进入时会重新询问。
   * 注册了多个 delegate 时，任一返回 false 即不发送
   */
  viewImpressionShouldTrack?: (componentId: string, eventName: string, identifier?: string) => boolean

  /**
   * 曝光时刻求值的动态属性，与标记时的静态属性合并后作为事件属性，同名键以动态属性为准
   */
  viewImpressionDynamicAttributes?: (componentId: string, eventName: string,
    identifier?: string) => AttributesType | undefined

  /**
   * 曝光事件已生成
   */
  viewImpressionDidTrack?: (componentId: string, eventName: string, identifier?: string) => void
}
