import { describe, it, expect, beforeEach } from '@ohos/hypium'
import ViewImpression, {
  ImpressionBinding,
  ViewImpressionHost,
  unavailableReasonOfConfig
} from '../../main/ets/components/autotrack/ViewImpression'
import { GrowingImpressionConfig, GrowingImpressionDelegate } from '../../main/ets/components/interfaces/GrowingImpression'
import { ConfigMode, GrowingConfig } from '../../main/ets/components/interfaces/GrowingConfig'
import { AttributesType } from '../../main/ets/components/utils/Constants'

// ─── 测试替身 ──────────────────────────────────────────────────────────────

class FakeBinding implements ImpressionBinding {
  uniqueId: number
  pageKeys: Array<string>
  ratios: Array<number> = []
  intervalMs: number = 0
  onRatio: ((ratio: number) => void) | undefined = undefined
  onDisappear: (() => void) | undefined = undefined
  disposed: boolean = false

  constructor(uniqueId: number, pageKeys: Array<string>) {
    this.uniqueId = uniqueId
    this.pageKeys = pageKeys
  }

  getPageKeys(): Array<string> {
    return this.pageKeys
  }

  observe(ratios: Array<number>, intervalMs: number, onRatio: (ratio: number) => void, onDisappear: () => void) {
    this.ratios = ratios
    this.intervalMs = intervalMs
    this.onRatio = onRatio
    this.onDisappear = onDisappear
  }

  dispose() {
    this.disposed = true
  }

  emit(ratio: number) {
    if (this.onRatio) {
      this.onRatio(ratio)
    }
  }
}

class TrackedEvent {
  eventName: string = ''
  attributes: AttributesType = {}
}

class FakeHost implements ViewImpressionHost {
  reason: string = ''
  config: GrowingImpressionConfig = new GrowingImpressionConfig()
  nodes: Map<string, FakeBinding> = new Map()
  tasks: Array<() => void> = []
  events: Array<TrackedEvent> = []

  unavailableReason(): string {
    return this.reason
  }

  globalConfig(): GrowingImpressionConfig {
    return this.config
  }

  checkInterval(): number {
    return 500
  }

  findNode(componentId: string): ImpressionBinding | undefined {
    return this.nodes.get(componentId)
  }

  schedule(task: () => void, delayMs: number) {
    this.tasks.push(task)
  }

  track(eventName: string, attributes: AttributesType) {
    let e = new TrackedEvent()
    e.eventName = eventName
    e.attributes = attributes
    this.events.push(e)
  }

  // 执行当前已调度的全部任务（模拟时间流逝）
  flush() {
    let tasks = this.tasks
    this.tasks = []
    tasks.forEach((task: () => void) => {
      task()
    })
  }

  addNode(componentId: string, uniqueId: number = 1, pageKeys: Array<string> = ['router:1']): FakeBinding {
    let binding = new FakeBinding(uniqueId, pageKeys)
    this.nodes.set(componentId, binding)
    return binding
  }
}

export default function viewImpressionTests() {

  // ─── GrowingImpressionConfig ──────────────────────────────────────────────

  describe('GrowingImpressionConfig', () => {

    it('默认值：scale 0、stay 0、可重复', 0, () => {
      let config = new GrowingImpressionConfig()
      expect(config.impressionScale).assertEqual(0)
      expect(config.stayDuration).assertEqual(0)
      expect(config._repeatable).assertTrue()
    })

    it('公开 create(scale, stay) 默认可重复曝光', 0, () => {
      let config = GrowingImpressionConfig.create(0.5, 1)
      expect(config.impressionScale).assertEqual(0.5)
      expect(config.stayDuration).assertEqual(1)
      expect(config._repeatable).assertTrue()
    })

    it('impressionScale 超出 0~1 被截断', 0, () => {
      expect(ViewImpression.createConfig(-1, 0, true).impressionScale).assertEqual(0)
      expect(ViewImpression.createConfig(2, 0, true).impressionScale).assertEqual(1)
      expect(ViewImpression.createConfig(0.5, 0, true).impressionScale).assertEqual(0.5)
    })

    it('stayDuration 负值按 0 处理', 0, () => {
      expect(ViewImpression.createConfig(0, -3, true).stayDuration).assertEqual(0)
      expect(ViewImpression.createConfig(0, 1.5, true).stayDuration).assertEqual(1.5)
    })

    it('copy 与 isEqual', 0, () => {
      let config = ViewImpression.createConfig(0.5, 1, false)
      let copy = config.copy()
      expect(copy.isEqual(config)).assertTrue()
      copy.impressionScale = 0.500001
      expect(copy.isEqual(config)).assertFalse()
    })

    it('GrowingConfig 曝光默认值与 copy', 0, () => {
      let config = new GrowingConfig().NewSaaS('accountId', 'dataSourceId', 'growing.test')
      expect(config.viewImpressionEnabled).assertTrue()
      expect(config.viewImpressionCheckInterval).assertEqual(0.5)
      config.viewImpressionEnabled = false
      config.viewImpressionCheckInterval = 1
      config.viewImpressionCheckInterval = -1
      config.viewImpressionConfig = GrowingImpressionConfig.create(0.3, 2)
      let copy = config.copy()
      expect(copy.viewImpressionEnabled).assertFalse()
      expect(copy._viewImpressionCheckInterval).assertEqual(1000)
      expect(copy.viewImpressionConfig.isEqual(config.viewImpressionConfig)).assertTrue()
      expect(copy.viewImpressionConfig === config.viewImpressionConfig).assertFalse()
    })
  })

  // ─── 可用条件 ────────────────────────────────────────────────────────────

  describe('ViewImpression_availability', () => {

    it('仅 NewSaaS 模式可用，CDP / SaaS 不可用', 0, () => {
      let newSaaS = new GrowingConfig().NewSaaS('accountId', 'dataSourceId', 'growing.test')
      newSaaS.autotrackEnabled = true
      expect(unavailableReasonOfConfig(newSaaS)).assertEqual('')

      let cdp = new GrowingConfig().CDP('accountId', 'dataSourceId', 'growing.test', 'https://cdp.example.com')
      cdp.autotrackEnabled = true
      expect(cdp.mode).assertEqual(ConfigMode.CDP)
      expect(unavailableReasonOfConfig(cdp).length > 0).assertTrue()

      let saas = new GrowingConfig().SaaS('accountId', 'growing.test')
      saas.autotrackEnabled = true
      expect(saas.mode).assertEqual(ConfigMode.SaaS)
      expect(unavailableReasonOfConfig(saas).length > 0).assertTrue()
    })

    it('NewSaaS 下 autotrackEnabled 或 viewImpressionEnabled 关闭时不可用', 0, () => {
      let config = new GrowingConfig().NewSaaS('accountId', 'dataSourceId', 'growing.test')
      expect(unavailableReasonOfConfig(config).length > 0).assertTrue()
      config.autotrackEnabled = true
      config.viewImpressionEnabled = false
      expect(unavailableReasonOfConfig(config).length > 0).assertTrue()
    })
  })

  // ─── 基础曝光 ────────────────────────────────────────────────────────────

  describe('ViewImpression_basic', () => {
    let host = new FakeHost()

    beforeEach(() => {
      host = new FakeHost()
      ViewImpression._reset(host)
    })

    it('不可用时不标记（如非 NewSaaS 模式）', 0, () => {
      host.reason = '元素曝光仅支持 NewSaaS 模式'
      host.addNode('item')
      ViewImpression.mark('item', 'imp')
      expect(ViewImpression.targets.size).assertEqual(0)
    })

    it('进入可视区发送一次事件，持续可见不重复发送', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', { 'k': 'v' })
      expect(host.events.length).assertEqual(0)
      node.emit(0.3)
      node.emit(0.8)
      expect(host.events.length).assertEqual(1)
      expect(host.events[0].eventName).assertEqual('imp')
      expect(host.events[0].attributes['k']).assertEqual('v')
    })

    it('离开可视区再进入，可重复曝光', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp')
      node.emit(1)
      node.emit(0)
      node.emit(1)
      expect(host.events.length).assertEqual(2)
    })

    it('impressionScale 阈值：未达阈值不曝光，阈值附近容差内曝光', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', undefined, undefined, ViewImpression.createConfig(0.5, 0, true))
      expect(node.ratios.join(',')).assertEqual('0,0.5')
      expect(node.intervalMs).assertEqual(500)
      node.emit(0.3)
      expect(host.events.length).assertEqual(0)
      node.emit(0.4995)
      expect(host.events.length).assertEqual(1)
    })

    it('未指定 config 时使用全局配置', 0, () => {
      host.config = ViewImpression.createConfig(0.8, 0, true)
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp')
      node.emit(0.5)
      expect(host.events.length).assertEqual(0)
      node.emit(0.9)
      expect(host.events.length).assertEqual(1)
    })

    it('stopTrack 后不再曝光且解除监听', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp')
      ViewImpression.unmark('item')
      node.emit(1)
      expect(host.events.length).assertEqual(0)
      expect(node.disposed).assertTrue()
      expect(ViewImpression.targets.size).assertEqual(0)
    })

    it('组件移除（onDisappear）后标记随之移除', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp')
      node.onDisappear!()
      expect(ViewImpression.targets.size).assertEqual(0)
    })

    it('updateAttributes 不重置曝光状态，下次曝光使用新属性', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', { 'k': 'v1' })
      node.emit(1)
      ViewImpression.updateAttributes('item', { 'k': 'v2' })
      node.emit(1)
      expect(host.events.length).assertEqual(1)
      node.emit(0)
      node.emit(1)
      expect(host.events.length).assertEqual(2)
      expect(host.events[1].attributes['k']).assertEqual('v2')
    })
  })

  // ─── 重复标记 / 多槽位 ────────────────────────────────────────────────────

  describe('ViewImpression_marking', () => {
    let host = new FakeHost()

    beforeEach(() => {
      host = new FakeHost()
      ViewImpression._reset(host)
    })

    it('内容不变的重复标记保留曝光状态', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', { 'k': 'v' })
      node.emit(1)
      ViewImpression.mark('item', 'imp', { 'k': 'v' })
      node.emit(1)
      expect(host.events.length).assertEqual(1)
    })

    it('属性变化的重复标记重置曝光状态', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', { 'k': 'v1' })
      node.emit(1)
      ViewImpression.mark('item', 'imp', { 'k': 'v2' })
      expect(host.events.length).assertEqual(2)
      expect(host.events[1].attributes['k']).assertEqual('v2')
    })

    it('同一组件多个 identifier 独立曝光', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'impA', undefined, 'a')
      ViewImpression.mark('item', 'impB', undefined, 'b')
      node.emit(1)
      expect(host.events.length).assertEqual(2)
      ViewImpression.unmark('item', 'a')
      node.emit(0)
      node.emit(1)
      expect(host.events.length).assertEqual(3)
      expect(host.events[2].eventName).assertEqual('impB')
    })

    it('复用：同事件名换 identifier 时清除旧槽位', 0, () => {
      let node = host.addNode('cell')
      ViewImpression.mark('cell', 'imp', { 'id': '1' }, 'goods_1')
      ViewImpression.mark('cell', 'imp', { 'id': '2' }, 'goods_2')
      node.emit(1)
      expect(host.events.length).assertEqual(1)
      expect(host.events[0].attributes['id']).assertEqual('2')
    })

    it('组件重建（uniqueId 变化）后重新绑定', 0, () => {
      let oldNode = host.addNode('item', 1)
      ViewImpression.mark('item', 'imp')
      let newNode = host.addNode('item', 2)
      ViewImpression.mark('item', 'imp')
      expect(oldNode.disposed).assertTrue()
      oldNode.emit(1)
      expect(host.events.length).assertEqual(0)
      newNode.emit(1)
      expect(host.events.length).assertEqual(1)
    })

    it('组件被移除后重建（未收到 onDisappear）时重新曝光', 0, () => {
      let oldNode = host.addNode('item', 1)
      ViewImpression.mark('item', 'imp')
      oldNode.emit(1)
      let newNode = host.addNode('item', 2)
      ViewImpression.mark('item', 'imp')
      newNode.emit(1)
      expect(host.events.length).assertEqual(2)
    })

    it('标记时组件未挂载，重试找到后正常曝光', 0, () => {
      ViewImpression.mark('later', 'imp')
      expect(host.tasks.length).assertEqual(1)
      let node = host.addNode('later')
      host.flush()
      node.emit(1)
      expect(host.events.length).assertEqual(1)
    })

    it('列表项内容延迟创建：多次重试后找到仍能正常曝光', 0, () => {
      ViewImpression.mark('lazy', 'imp')
      for (let i = 0; i < 10; i++) {
        host.flush()
      }
      expect(ViewImpression.targets.has('lazy')).assertTrue()
      let node = host.addNode('lazy')
      host.flush()
      node.emit(1)
      expect(host.events.length).assertEqual(1)
    })

    it('重试多次仍找不到组件则放弃标记', 0, () => {
      ViewImpression.mark('missing', 'imp')
      for (let i = 0; i < 30; i++) {
        host.flush()
      }
      expect(ViewImpression.targets.size).assertEqual(0)
    })
  })

  // ─── 不可重复曝光 / reset ─────────────────────────────────────────────────

  describe('ViewImpression_repeatable', () => {
    let host = new FakeHost()

    beforeEach(() => {
      host = new FakeHost()
      ViewImpression._reset(host)
    })

    it('不可重复曝光：同一 identifier 只曝光一次，跨组件生效', 0, () => {
      let a = host.addNode('a', 1)
      let b = host.addNode('b', 2)
      let once = ViewImpression.createConfig(0, 0, false)
      ViewImpression.mark('a', 'imp', undefined, 'goods_1', once)
      a.emit(1)
      a.emit(0)
      a.emit(1)
      ViewImpression.mark('b', 'imp', undefined, 'goods_1', once)
      b.emit(1)
      expect(host.events.length).assertEqual(1)
    })

    it('不可重复曝光但未指定 identifier 时降级为可重复', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', undefined, undefined, ViewImpression.createConfig(0, 0, false))
      node.emit(1)
      node.emit(0)
      node.emit(1)
      expect(host.events.length).assertEqual(2)
    })

    it('resetState(identifier) 后仍可见的元素立即重新曝光', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', undefined, 'goods_1', ViewImpression.createConfig(0, 0, false))
      node.emit(1)
      ViewImpression.resetState('goods_1')
      expect(host.events.length).assertEqual(2)
    })

    it('resetState() 清除全部记录', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', undefined, 'goods_1', ViewImpression.createConfig(0, 0, false))
      node.emit(1)
      expect(ViewImpression.trackedIdentifiers.size).assertEqual(1)
      ViewImpression.resetState()
      expect(host.events.length).assertEqual(2)
    })
  })

  // ─── 停留时长 ────────────────────────────────────────────────────────────

  describe('ViewImpression_stayDuration', () => {
    let host = new FakeHost()

    beforeEach(() => {
      host = new FakeHost()
      ViewImpression._reset(host)
    })

    it('停留满时长后曝光', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', undefined, undefined, ViewImpression.createConfig(0, 1, true))
      node.emit(1)
      expect(host.events.length).assertEqual(0)
      host.flush()
      expect(host.events.length).assertEqual(1)
    })

    it('停留期间离开可视区则不曝光', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', undefined, undefined, ViewImpression.createConfig(0, 1, true))
      node.emit(1)
      node.emit(0)
      host.flush()
      expect(host.events.length).assertEqual(0)
    })

    it('停留期间退后台则计时中断，回前台重新计时', 0, () => {
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', undefined, undefined, ViewImpression.createConfig(0, 1, true))
      node.emit(1)
      ViewImpression.onBackground()
      host.flush()
      expect(host.events.length).assertEqual(0)
      ViewImpression.onForeground()
      host.flush()
      expect(host.events.length).assertEqual(1)
    })
  })

  // ─── 前后台 / 页面切换 ───────────────────────────────────────────────────

  describe('ViewImpression_lifecycle', () => {
    let host = new FakeHost()

    beforeEach(() => {
      host = new FakeHost()
      ViewImpression._reset(host)
    })

    it('退后台再回前台不重新曝光', 0, () => {
      let node = host.addNode('item', 1, ['router:1'])
      ViewImpression.mark('item', 'imp')
      node.emit(1)
      // 页面隐藏与退后台的回调顺序不确定，两种顺序都应不重新曝光
      ViewImpression.onPageHide('router:1')
      ViewImpression.onBackground()
      node.emit(0)
      ViewImpression.onForeground()
      ViewImpression.onPageShow('router:1')
      node.emit(1)

      ViewImpression.onBackground()
      ViewImpression.onPageHide('router:1')
      ViewImpression.onForeground()
      ViewImpression.onPageShow('router:1')
      expect(host.events.length).assertEqual(1)
    })

    it('页面跳转后返回重新曝光', 0, () => {
      let node = host.addNode('item', 1, ['nav:1', 'router:1'])
      ViewImpression.mark('item', 'imp')
      node.emit(1)
      ViewImpression.onPageHide('nav:1')
      ViewImpression.onPageShow('nav:1')
      expect(host.events.length).assertEqual(2)
    })

    it('页面隐藏期间的可见回调被忽略，重新显示后按系统回调曝光', 0, () => {
      let node = host.addNode('item', 1, ['nav:1'])
      ViewImpression.mark('item', 'imp')
      ViewImpression.onPageHide('nav:1')
      node.emit(1)
      expect(host.events.length).assertEqual(0)
      ViewImpression.onPageShow('nav:1')
      expect(host.events.length).assertEqual(0)
      node.emit(1)
      expect(host.events.length).assertEqual(1)
    })

    it('页面隐藏时系统回调 0 不会导致返回后重复曝光（退后台场景）', 0, () => {
      let node = host.addNode('item', 1, ['router:1'])
      ViewImpression.mark('item', 'imp')
      node.emit(1)
      ViewImpression.onBackground()
      ViewImpression.onPageHide('router:1')
      node.emit(0)
      ViewImpression.onForeground()
      ViewImpression.onPageShow('router:1')
      node.emit(1)
      expect(host.events.length).assertEqual(1)
    })

    it('页面销毁时移除该页面的标记', 0, () => {
      let node = host.addNode('item', 1, ['nav:1'])
      host.addNode('other', 2, ['nav:2'])
      ViewImpression.mark('item', 'imp')
      ViewImpression.mark('other', 'imp')
      ViewImpression.onPageDestroy('nav:1')
      expect(node.disposed).assertTrue()
      expect(ViewImpression.targets.has('item')).assertFalse()
      expect(ViewImpression.targets.has('other')).assertTrue()
    })
  })

  // ─── delegate ────────────────────────────────────────────────────────────

  describe('ViewImpression_delegate', () => {
    let host = new FakeHost()

    beforeEach(() => {
      host = new FakeHost()
      ViewImpression._reset(host)
    })

    it('shouldTrack 返回 false 时不发送，离开再进入时重新询问', 0, () => {
      let allow = false
      let asked = 0
      let delegate: GrowingImpressionDelegate = {
        viewImpressionShouldTrack: (componentId: string, eventName: string, identifier?: string): boolean => {
          asked++
          return allow
        }
      }
      ViewImpression.addDelegate(delegate)
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp')
      node.emit(1)
      node.emit(1)
      expect(asked).assertEqual(1)
      expect(host.events.length).assertEqual(0)
      allow = true
      node.emit(0)
      node.emit(1)
      expect(host.events.length).assertEqual(1)
    })

    it('动态属性覆盖静态属性，didTrack 被回调', 0, () => {
      let tracked: Array<string> = []
      let delegate: GrowingImpressionDelegate = {
        viewImpressionDynamicAttributes: (componentId: string, eventName: string,
          identifier?: string): AttributesType | undefined => {
          return { 'k': 'dynamic', 'd': 1 }
        },
        viewImpressionDidTrack: (componentId: string, eventName: string, identifier?: string) => {
          tracked.push(componentId + '/' + eventName + '/' + identifier)
        }
      }
      ViewImpression.addDelegate(delegate)
      ViewImpression.addDelegate(delegate)
      expect(ViewImpression.delegates.length).assertEqual(1)
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp', { 'k': 'static', 's': 's' }, 'id_1')
      node.emit(1)
      expect(host.events[0].attributes['k']).assertEqual('dynamic')
      expect(host.events[0].attributes['s']).assertEqual('s')
      expect(host.events[0].attributes['d']).assertEqual(1)
      expect(tracked[0]).assertEqual('item/imp/id_1')
    })

    it('delegate 抛异常不影响曝光', 0, () => {
      let delegate: GrowingImpressionDelegate = {
        viewImpressionShouldTrack: (componentId: string, eventName: string, identifier?: string): boolean => {
          throw new Error('boom')
        }
      }
      ViewImpression.addDelegate(delegate)
      let node = host.addNode('item')
      ViewImpression.mark('item', 'imp')
      node.emit(1)
      expect(host.events.length).assertEqual(1)
      ViewImpression.removeDelegate(delegate)
      expect(ViewImpression.delegates.length).assertEqual(0)
    })
  })
}
