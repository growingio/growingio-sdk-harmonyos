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

import { FrameNode } from '@ohos.arkui.node'
import uiObserver from '@ohos.arkui.observer'

import Autotrack from './Autotrack'
import AnalyticsCore from '../core/AnalyticsCore'
import GrowingContext from '../core/Context'
import { GrowingImpressionConfig, GrowingImpressionDelegate } from '../interfaces/GrowingImpression'
import { AttributesType } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import Util from '../utils/Util'

// 未指定 identifier 时使用的槽位
const DEFAULT_SLOT = '@default'
// 不可重复曝光的 identifier 记录上限，超出后淘汰最早的记录
const TRACKED_IDENTIFIERS_CAPACITY = 10000
// 系统可见比例在阈值附近存在 ≤0.001 的舍入误差，且回调在"接近"阈值时触发
const SCALE_TOLERANCE = 0.001
// 停留时长定时复检的额外余量，单位 ms
const RECHECK_SLACK = 10
// 标记时组件尚未挂树，按此间隔重试查找，单位 ms
const BIND_RETRY_INTERVAL = 50
const BIND_RETRY_TIMES = 5
const NAV_PAGE_KEY_PREFIX = 'nav:'
const ROUTER_PAGE_KEY_PREFIX = 'router:'

/**
 * 组件与可见面积监听之间的绑定，抽象出来便于单元测试替换
 */
export interface ImpressionBinding {
  // 绑定的 FrameNode uniqueId，用于识别组件是否已被重建
  uniqueId: number
  // 组件所在页面的标识（Navigation 子页 / router 页），用于页面隐藏/销毁时的状态处理
  pageKeys: Array<string>

  observe(ratios: Array<number>, intervalMs: number, onRatio: (ratio: number) => void, onDisappear: () => void): void

  dispose(): void
}

/**
 * 曝光模块依赖的外部环境，默认实现见 _DefaultHost，单元测试可替换
 */
export interface ViewImpressionHost {
  // SDK 已初始化 && 无埋点开启 && 曝光开启 && 已开启无埋点监听
  isAvailable(): boolean

  globalConfig(): GrowingImpressionConfig

  // 可见面积检测间隔，单位 ms
  checkInterval(): number

  findNode(componentId: string): ImpressionBinding | undefined

  schedule(task: () => void, delayMs: number): void

  track(eventName: string, attributes: AttributesType): void
}

export class ImpressionSlot {
  eventName: string = ''
  attributes: AttributesType | undefined = undefined
  identifier: string | undefined = undefined
  config: GrowingImpressionConfig = new GrowingImpressionConfig()
  // 本轮可见期内是否已曝光（不可见后重置）
  tracked: boolean = false
  // 是否已开始计算停留时长（对应 iOS visibleSince != 0）
  visibleStarted: boolean = false
  // 本轮可见期内停留时长是否已满足
  stayReached: boolean = false
  // 自增令牌，令已调度的停留时长复检失效
  recheckToken: number = 0

  matches(eventName: string, attributes: AttributesType | undefined, config: GrowingImpressionConfig): boolean {
    if (this.eventName != eventName) {
      return false
    }
    if (!Util.isAttributesEqual(this.attributes, attributes)) {
      return false
    }
    return this.config.isEqual(config)
  }

  invalidate() {
    this.visibleStarted = false
    this.stayReached = false
    this.recheckToken += 1
  }
}

export class ImpressionTarget {
  componentId: string = ''
  slots: Map<string, ImpressionSlot> = new Map()
  binding: ImpressionBinding | undefined = undefined
  // 最近一次回调的可见面积比例
  ratio: number = 0
  // 当前监听的阈值，用于判断是否需要重新注册
  observedRatios: string = ''
  bindRetryCount: number = 0

  constructor(componentId: string) {
    this.componentId = componentId
  }

  pageKeys(): Array<string> {
    return this.binding ? this.binding.pageKeys : []
  }
}

class _HiddenPageInfo {
  // 隐藏时应用是否已在后台（后台导致的隐藏，回到前台后不重新曝光）
  hiddenInBackground: boolean = false
  // 隐藏时的后台计数，显示时若已变化，说明期间经历过前后台切换
  backgroundEpoch: number = 0
}

// ─── 默认实现 ───────────────────────────────────────────────────────────────

class _FrameNodeBinding implements ImpressionBinding {
  uniqueId: number
  pageKeys: Array<string>
  node: FrameNode

  constructor(node: FrameNode, pageKeys: Array<string>) {
    this.node = node
    this.uniqueId = node.getUniqueId()
    this.pageKeys = pageKeys
  }

  observe(ratios: Array<number>, intervalMs: number, onRatio: (ratio: number) => void, onDisappear: () => void) {
    // commonEvent 设置的事件与声明式事件并存，不会覆盖业务侧的回调
    let options: VisibleAreaEventOptions = { ratios: ratios, expectedUpdateInterval: intervalMs }
    this.node.commonEvent.setOnVisibleAreaApproximateChange(options, (isExpanding: boolean, currentRatio: number) => {
      onRatio(currentRatio)
    })
    this.node.commonEvent.setOnDisappear(() => {
      onDisappear()
    })
  }

  dispose() {
    try {
      let options: VisibleAreaEventOptions = { ratios: [0] }
      this.node.commonEvent.setOnVisibleAreaApproximateChange(options, undefined)
      this.node.commonEvent.setOnDisappear(undefined)
    } catch (e) {
      // 节点已销毁时无需清理
    }
  }
}

class _DefaultHost implements ViewImpressionHost {
  isAvailable(): boolean {
    if (!AnalyticsCore.core.isInitializedSuccessfully()) {
      return false
    }
    if (!Autotrack.uiContent) {
      return false
    }
    let context = GrowingContext.getDefaultContext()
    if (!context) {
      return false
    }
    // 曝光采集属于无埋点能力的一部分，随无埋点开关一起关闭
    return context.config.autotrackEnabled && context.config.viewImpressionEnabled
  }

  globalConfig(): GrowingImpressionConfig {
    let context = GrowingContext.getDefaultContext()
    return context ? context.config.viewImpressionConfig : new GrowingImpressionConfig()
  }

  checkInterval(): number {
    let context = GrowingContext.getDefaultContext()
    return context ? context.config._viewImpressionCheckInterval : 500
  }

  findNode(componentId: string): ImpressionBinding | undefined {
    let uiContext = Autotrack.uiContent
    let node = uiContext.getAttachedFrameNodeById(componentId)
    if (!node) {
      return undefined
    }

    let pageKeys: Array<string> = []
    let pageInfo = uiContext.getPageInfoByUniqueId(node.getUniqueId())
    if (pageInfo?.navDestinationInfo) {
      pageKeys.push(NAV_PAGE_KEY_PREFIX + String(pageInfo.navDestinationInfo.navDestinationId ?? ''))
    }
    if (pageInfo?.routerPageInfo) {
      pageKeys.push(ROUTER_PAGE_KEY_PREFIX + String(pageInfo.routerPageInfo.pageId ?? ''))
    }
    return new _FrameNodeBinding(node, pageKeys)
  }

  schedule(task: () => void, delayMs: number) {
    setTimeout(task, delayMs)
  }

  track(eventName: string, attributes: AttributesType) {
    AnalyticsCore.core.track(eventName, attributes)
  }
}

export default class ViewImpression {
  static host: ViewImpressionHost = new _DefaultHost()
  static targets: Map<string, ImpressionTarget> = new Map()
  static trackedIdentifiers: Set<string> = new Set()
  static trackedIdentifiersOverflowWarned: boolean = false
  static delegates: Array<GrowingImpressionDelegate> = []
  static hiddenPages: Map<string, _HiddenPageInfo> = new Map()
  static inBackground: boolean = false
  static backgroundEpoch: number = 0

  // ─── 监听 ────────────────────────────────────────────────────────────────

  static startObserver(context: UIContext) {
    context.getUIObserver().on('navDestinationUpdate', ViewImpression.onNavDestinationUpdate)
    context.getUIObserver().on('routerPageUpdate', ViewImpression.onRouterPageUpdate)
  }

  static onNavDestinationUpdate(info: NavDestinationInfo) {
    if (!info) {
      return
    }
    let key = NAV_PAGE_KEY_PREFIX + String(info.navDestinationId ?? '')
    if (info.state == uiObserver.NavDestinationState.ON_SHOWN) {
      ViewImpression.onPageShow(key)
    } else if (info.state == uiObserver.NavDestinationState.ON_HIDDEN) {
      ViewImpression.onPageHide(key)
    } else if (info.state == uiObserver.NavDestinationState.ON_DISAPPEAR) {
      ViewImpression.onPageDestroy(key)
    }
  }

  static onRouterPageUpdate(info: RouterPageInfo) {
    if (!info) {
      return
    }
    let key = ROUTER_PAGE_KEY_PREFIX + String(info.pageId ?? '')
    if (info.state == uiObserver.RouterPageState.ON_PAGE_SHOW) {
      ViewImpression.onPageShow(key)
    } else if (info.state == uiObserver.RouterPageState.ON_PAGE_HIDE) {
      ViewImpression.onPageHide(key)
    } else if (info.state == uiObserver.RouterPageState.ABOUT_TO_DISAPPEAR) {
      ViewImpression.onPageDestroy(key)
    }
  }

  static onPageHide(key: string) {
    let info = new _HiddenPageInfo()
    info.hiddenInBackground = ViewImpression.inBackground
    info.backgroundEpoch = ViewImpression.backgroundEpoch
    ViewImpression.hiddenPages.set(key, info)

    // 只中断停留计时，是否重置曝光状态等页面重新显示时再判定：
    // 页面隐藏与应用退后台的回调先后不确定，此时无法区分是页面跳转还是退后台
    ViewImpression.forEachTargetInPage(key, (target: ImpressionTarget) => {
      target.slots.forEach((slot: ImpressionSlot) => slot.invalidate())
    })
  }

  static onPageShow(key: string) {
    let info = ViewImpression.hiddenPages.get(key)
    if (!info) {
      return
    }
    ViewImpression.hiddenPages.delete(key)

    // 与 iOS 保持一致：页面跳转后返回会重新曝光，退后台再回前台不会
    let causedByBackground = info.hiddenInBackground || info.backgroundEpoch != ViewImpression.backgroundEpoch
    ViewImpression.forEachTargetInPage(key, (target: ImpressionTarget) => {
      if (!causedByBackground) {
        target.slots.forEach((slot: ImpressionSlot) => {
          slot.tracked = false
        })
      }
      ViewImpression.evaluateTarget(target)
    })
  }

  static onPageDestroy(key: string) {
    ViewImpression.hiddenPages.delete(key)
    let removed: Array<string> = []
    ViewImpression.forEachTargetInPage(key, (target: ImpressionTarget) => {
      removed.push(target.componentId)
    })
    removed.forEach((componentId: string) => ViewImpression.removeTarget(componentId))
  }

  static onForeground() {
    if (!ViewImpression.inBackground) {
      return
    }
    ViewImpression.inBackground = false
    ViewImpression.targets.forEach((target: ImpressionTarget) => ViewImpression.evaluateTarget(target))
  }

  static onBackground() {
    if (ViewImpression.inBackground) {
      return
    }
    ViewImpression.inBackground = true
    ViewImpression.backgroundEpoch += 1
    // 与 iOS 一致：只中断停留计时，不重置已曝光状态
    ViewImpression.targets.forEach((target: ImpressionTarget) => {
      target.slots.forEach((slot: ImpressionSlot) => slot.invalidate())
    })
  }

  // ─── 标记 ────────────────────────────────────────────────────────────────

  static mark(
    componentId: string,
    eventName: string,
    attributes?: AttributesType,
    identifier?: string,
    config?: GrowingImpressionConfig
  ) {
    if (!componentId || componentId.length == 0) {
      LogUtil.warn(() => '[ViewImpression] componentId 为空，事件 ' + eventName + ' 的曝光标记被忽略')
      return
    }
    if (!eventName || eventName.length == 0) {
      LogUtil.warn(() => '[ViewImpression] eventName 为空，组件 ' + componentId + ' 的曝光标记被忽略')
      return
    }
    if (!ViewImpression.host.isAvailable()) {
      LogUtil.warn(() => '[ViewImpression] 曝光采集不可用：请确认 SDK 已初始化、已调用 onWindowStageCreate，' +
        '且 autotrackEnabled 与 viewImpressionEnabled 均为 true')
      return
    }

    let nodeConfig = config ? config.copy() : ViewImpression.host.globalConfig().copy()
    let hasIdentifier = identifier != undefined && identifier.length > 0
    if (!nodeConfig.repeatable && !hasIdentifier) {
      nodeConfig.repeatable = true
      LogUtil.warn(() => '[ViewImpression] 事件 ' + eventName + ' 配置了不可重复曝光但未指定 identifier，已按可重复曝光处理')
    }
    let slotKey = hasIdentifier ? identifier as string : DEFAULT_SLOT
    let attrs = attributes ? Util.cloneObject(attributes) : undefined

    let target = ViewImpression.targets.get(componentId)
    if (!target) {
      target = new ImpressionTarget(componentId)
      ViewImpression.targets.set(componentId, target)
    }

    // 复用场景：同一组件先后承载不同元素，事件名不变而 identifier 变了。
    // 旧槽位若留着，组件下次进入可视区时会带着上一个元素的属性再发一次
    let staleSlots: Array<string> = []
    target.slots.forEach((slot: ImpressionSlot, key: string) => {
      if (key != slotKey && slot.eventName == eventName) {
        staleSlots.push(key)
      }
    })
    let slots = target.slots
    staleSlots.forEach((key: string) => {
      slots.get(key)?.invalidate()
      slots.delete(key)
    })

    // 列表刷新会对可见元素原样重标一次，内容没变就保留原槽位，
    // 否则曝光状态被重置，必然多发一次
    let existing = target.slots.get(slotKey)
    if (existing && existing.matches(eventName, attrs, nodeConfig)) {
      ViewImpression.bindTarget(target)
      return
    }

    let slot = new ImpressionSlot()
    slot.eventName = eventName
    slot.attributes = attrs
    slot.identifier = hasIdentifier ? identifier : undefined
    slot.config = nodeConfig
    existing?.invalidate()
    target.slots.set(slotKey, slot)

    ViewImpression.bindTarget(target)
    if (target.binding) {
      ViewImpression.evaluateSlot(target, slot)
    }
  }

  static updateAttributes(componentId: string, attributes: AttributesType, identifier?: string) {
    let slotKey = identifier && identifier.length > 0 ? identifier : DEFAULT_SLOT
    let slot = ViewImpression.targets.get(componentId)?.slots.get(slotKey)
    if (!slot) {
      LogUtil.warn(() => '[ViewImpression] 组件 ' + componentId + ' 的槽位 ' + slotKey + ' 尚未标记，属性更新被忽略')
      return
    }
    slot.attributes = attributes ? Util.cloneObject(attributes) : undefined
  }

  static unmark(componentId: string, identifier?: string) {
    if (!identifier || identifier.length == 0) {
      ViewImpression.removeTarget(componentId)
      return
    }
    let target = ViewImpression.targets.get(componentId)
    if (!target) {
      return
    }
    target.slots.get(identifier)?.invalidate()
    target.slots.delete(identifier)
    if (target.slots.size == 0) {
      ViewImpression.removeTarget(componentId)
    } else {
      ViewImpression.observeTarget(target, false)
    }
  }

  static removeTarget(componentId: string) {
    let target = ViewImpression.targets.get(componentId)
    if (!target) {
      return
    }
    target.slots.forEach((slot: ImpressionSlot) => slot.invalidate())
    target.binding?.dispose()
    target.binding = undefined
    ViewImpression.targets.delete(componentId)
  }

  // ─── 状态 ────────────────────────────────────────────────────────────────

  static resetState(identifier?: string) {
    if (identifier != undefined) {
      if (identifier.length == 0) {
        return
      }
      ViewImpression.trackedIdentifiers.delete(identifier)
    } else {
      ViewImpression.trackedIdentifiers.clear()
    }

    ViewImpression.targets.forEach((target: ImpressionTarget) => {
      let changed = false
      target.slots.forEach((slot: ImpressionSlot) => {
        if (identifier == undefined || slot.identifier == identifier) {
          slot.tracked = false
          changed = true
        }
      })
      // 没有轮询检测，重置后立即复检，仍在可视区的元素随即重新曝光
      if (changed) {
        ViewImpression.evaluateTarget(target)
      }
    })
  }

  static addDelegate(delegate: GrowingImpressionDelegate) {
    if (!delegate || ViewImpression.delegates.indexOf(delegate) >= 0) {
      return
    }
    ViewImpression.delegates.push(delegate)
  }

  static removeDelegate(delegate: GrowingImpressionDelegate) {
    let index = ViewImpression.delegates.indexOf(delegate)
    if (index >= 0) {
      ViewImpression.delegates.splice(index, 1)
    }
  }

  // ─── 绑定 ────────────────────────────────────────────────────────────────

  static bindTarget(target: ImpressionTarget) {
    let binding: ImpressionBinding | undefined = undefined
    try {
      binding = ViewImpression.host.findNode(target.componentId)
    } catch (e) {
      LogUtil.error(() => '[ViewImpression] 查找组件 ' + target.componentId + ' 失败: ' + e?.message)
    }

    if (!binding) {
      if (target.binding) {
        // 组件已绑定过，只是此刻查不到（例如正在重建），沿用原绑定
        ViewImpression.observeTarget(target, false)
        return
      }
      ViewImpression.scheduleBindRetry(target)
      return
    }
    target.bindRetryCount = 0

    if (target.binding && target.binding.uniqueId == binding.uniqueId) {
      ViewImpression.observeTarget(target, false)
      return
    }

    // 组件被重建（LazyForEach / if-else 等）：旧节点上的监听随节点失效，需重新注册。
    // 曝光状态保留：元素若真的离开过可视区，旧节点已回调过 0，tracked 已被重置
    target.binding?.dispose()
    target.binding = binding
    target.ratio = 0
    ViewImpression.observeTarget(target, true)
  }

  static scheduleBindRetry(target: ImpressionTarget) {
    if (target.bindRetryCount >= BIND_RETRY_TIMES) {
      LogUtil.warn(() => '[ViewImpression] 未找到 id 为 ' + target.componentId + ' 的已挂载组件，曝光标记被忽略。' +
        '请确认已为组件设置 .id()，并在组件的 onAppear 中调用 trackViewImpression')
      ViewImpression.removeTarget(target.componentId)
      return
    }
    target.bindRetryCount += 1
    ViewImpression.host.schedule(() => {
      // 期间可能已被移除或替换
      if (ViewImpression.targets.get(target.componentId) !== target || target.binding) {
        return
      }
      ViewImpression.bindTarget(target)
      if (target.binding) {
        ViewImpression.evaluateTarget(target)
      }
    }, BIND_RETRY_INTERVAL)
  }

  static observeTarget(target: ImpressionTarget, force: boolean) {
    let binding = target.binding
    if (!binding) {
      return
    }
    let ratios = ViewImpression.ratiosOf(target)
    let ratiosKey = ratios.join(',')
    if (!force && ratiosKey == target.observedRatios) {
      return
    }
    target.observedRatios = ratiosKey

    try {
      binding.observe(ratios, ViewImpression.host.checkInterval(), (ratio: number) => {
        if (ViewImpression.targets.get(target.componentId) !== target || target.binding !== binding) {
          return
        }
        // 后台 / 页面隐藏期间界面不会真实变化，此时上报的比例多为转场产物（如隐藏时回调 0），
        // 记录下来会让回到前台时误判为"离开过可视区"而重复曝光，因此直接丢弃
        if (ViewImpression.inBackground || ViewImpression.isTargetHidden(target)) {
          return
        }
        target.ratio = ratio
        ViewImpression.evaluateTarget(target)
      }, () => {
        // 组件从组件树上移除：与 iOS 视图释放一致，曝光标记随之移除，再次出现时需重新标记
        if (ViewImpression.targets.get(target.componentId) === target && target.binding === binding) {
          ViewImpression.removeTarget(target.componentId)
        }
      })
    } catch (e) {
      LogUtil.error(() => '[ViewImpression] 监听组件 ' + target.componentId + ' 可见面积失败: ' + e?.message)
    }
  }

  static ratiosOf(target: ImpressionTarget): Array<number> {
    // 系统默认包含阈值 0；阈值 0 本身用于感知"完全离开可视区"
    let ratios: Array<number> = [0]
    target.slots.forEach((slot: ImpressionSlot) => {
      let scale = slot.config.impressionScale
      if (scale > 0 && ratios.indexOf(scale) < 0) {
        ratios.push(scale)
      }
    })
    return ratios.sort((a: number, b: number) => a - b)
  }

  // ─── 判定 ────────────────────────────────────────────────────────────────

  static isTargetHidden(target: ImpressionTarget): boolean {
    let keys = target.pageKeys()
    for (let i = 0; i < keys.length; i++) {
      if (ViewImpression.hiddenPages.has(keys[i])) {
        return true
      }
    }
    return false
  }

  static isRatioVisible(ratio: number, scale: number): boolean {
    if (scale <= 0) {
      return ratio > 0
    }
    return ratio >= scale - SCALE_TOLERANCE
  }

  static evaluateTarget(target: ImpressionTarget) {
    let slots: Array<ImpressionSlot> = []
    target.slots.forEach((slot: ImpressionSlot) => slots.push(slot))
    slots.forEach((slot: ImpressionSlot) => ViewImpression.evaluateSlot(target, slot))
  }

  static evaluateSlot(target: ImpressionTarget, slot: ImpressionSlot) {
    // 后台、页面隐藏期间不做判定，只记录比例；回到前台 / 页面重新显示时统一复检
    if (ViewImpression.inBackground || ViewImpression.isTargetHidden(target)) {
      return
    }

    if (!ViewImpression.isRatioVisible(target.ratio, slot.config.impressionScale)) {
      if (slot.visibleStarted) {
        slot.invalidate()
      }
      slot.tracked = false
      return
    }

    if (slot.tracked) {
      return
    }

    // 停留时长已满足（例如 resetState 后仍在可视区），直接曝光
    if (slot.stayReached) {
      ViewImpression.trackSlot(target, slot)
      return
    }

    // 停留计时进行中，等待定时复检
    if (slot.visibleStarted) {
      return
    }

    slot.visibleStarted = true
    let stayDuration = slot.config.stayDuration
    if (stayDuration <= 0) {
      slot.stayReached = true
      ViewImpression.trackSlot(target, slot)
      return
    }

    // 界面静止时系统不再回调可见面积，停留时长只能靠这一次定时复检收口
    slot.recheckToken += 1
    let token = slot.recheckToken
    ViewImpression.host.schedule(() => {
      if (slot.recheckToken != token || ViewImpression.targets.get(target.componentId) !== target) {
        return
      }
      if (ViewImpression.inBackground || ViewImpression.isTargetHidden(target)) {
        return
      }
      if (!ViewImpression.isRatioVisible(target.ratio, slot.config.impressionScale)) {
        slot.invalidate()
        slot.tracked = false
        return
      }
      slot.stayReached = true
      if (!slot.tracked) {
        ViewImpression.trackSlot(target, slot)
      }
    }, stayDuration * 1000 + RECHECK_SLACK)
  }

  static trackSlot(target: ImpressionTarget, slot: ImpressionSlot) {
    slot.tracked = true

    // 不可重复曝光以 identifier 为准记在全局：列表复用后组件相同而元素不同，
    // 同一元素滚回来又可能落在另一个组件上，挂在组件上判不准。
    // identifier 缺失时配置已在标记阶段降级为可重复曝光，故此处 identifier 必非空
    let identifier = slot.identifier ?? ''
    if (!slot.config.repeatable && ViewImpression.trackedIdentifiers.has(identifier)) {
      return
    }

    if (!ViewImpression.shouldTrack(target, slot)) {
      return
    }

    if (!slot.config.repeatable) {
      ViewImpression.rememberTrackedIdentifier(identifier)
    }

    ViewImpression.host.track(slot.eventName, ViewImpression.attributesOf(target, slot))
    ViewImpression.notifyDidTrack(target, slot)
  }

  static shouldTrack(target: ImpressionTarget, slot: ImpressionSlot): boolean {
    let delegates = [...ViewImpression.delegates]
    for (let i = 0; i < delegates.length; i++) {
      let callback = delegates[i].viewImpressionShouldTrack
      if (!callback) {
        continue
      }
      try {
        if (!callback(target.componentId, slot.eventName, slot.identifier)) {
          return false
        }
      } catch (e) {
        LogUtil.error(() => '[ViewImpression] viewImpressionShouldTrack 执行异常: ' + e?.message)
      }
    }
    return true
  }

  static attributesOf(target: ImpressionTarget, slot: ImpressionSlot): AttributesType {
    let merged: AttributesType = slot.attributes ? Util.cloneObject(slot.attributes) : {}
    let delegates = [...ViewImpression.delegates]
    for (let i = 0; i < delegates.length; i++) {
      let callback = delegates[i].viewImpressionDynamicAttributes
      if (!callback) {
        continue
      }
      try {
        let dynamic = callback(target.componentId, slot.eventName, slot.identifier)
        if (dynamic) {
          merged = Util.concatObject(merged, dynamic)
        }
      } catch (e) {
        LogUtil.error(() => '[ViewImpression] viewImpressionDynamicAttributes 执行异常: ' + e?.message)
      }
    }
    return merged
  }

  static notifyDidTrack(target: ImpressionTarget, slot: ImpressionSlot) {
    let delegates = [...ViewImpression.delegates]
    for (let i = 0; i < delegates.length; i++) {
      let callback = delegates[i].viewImpressionDidTrack
      if (!callback) {
        continue
      }
      try {
        callback(target.componentId, slot.eventName, slot.identifier)
      } catch (e) {
        LogUtil.error(() => '[ViewImpression] viewImpressionDidTrack 执行异常: ' + e?.message)
      }
    }
  }

  static rememberTrackedIdentifier(identifier: string) {
    let identifiers = ViewImpression.trackedIdentifiers
    identifiers.add(identifier)
    if (identifiers.size <= TRACKED_IDENTIFIERS_CAPACITY) {
      return
    }

    if (!ViewImpression.trackedIdentifiersOverflowWarned) {
      ViewImpression.trackedIdentifiersOverflowWarned = true
      LogUtil.warn(() => '[ViewImpression] 不可重复曝光的元素标识已超过 ' + TRACKED_IDENTIFIERS_CAPACITY +
        ' 个，最早的记录将被淘汰，请在合适的时机调用 resetAllViewImpressionState 主动清理')
    }
    let oldest = identifiers.values().next()
    if (!oldest.done) {
      identifiers.delete(oldest.value)
    }
  }

  static forEachTargetInPage(key: string, action: (target: ImpressionTarget) => void) {
    let matched: Array<ImpressionTarget> = []
    ViewImpression.targets.forEach((target: ImpressionTarget) => {
      if (target.pageKeys().indexOf(key) >= 0) {
        matched.push(target)
      }
    })
    matched.forEach(action)
  }

  // test-only helper (do NOT call in production code)
  static _reset(host?: ViewImpressionHost) {
    ViewImpression.targets.forEach((target: ImpressionTarget) => {
      target.slots.forEach((slot: ImpressionSlot) => slot.invalidate())
    })
    ViewImpression.host = host ?? new _DefaultHost()
    ViewImpression.targets = new Map()
    ViewImpression.trackedIdentifiers = new Set()
    ViewImpression.trackedIdentifiersOverflowWarned = false
    ViewImpression.delegates = []
    ViewImpression.hiddenPages = new Map()
    ViewImpression.inBackground = false
    ViewImpression.backgroundEpoch = 0
  }
}
