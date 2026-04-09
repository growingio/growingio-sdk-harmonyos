import { describe, it, expect, beforeEach } from '@ohos/hypium'
import GeneralProps from '../../main/ets/components/core/GeneralProps'

export default function generalPropsTests() {

  // ─── 初始状态 ─────────────────────────────────────────────────────────────

  describe('GeneralProps_initialState', () => {

    beforeEach(() => {
      GeneralProps._reset()
    })

    it('初始 getGeneralProps 应返回空对象', 0, () => {
      let props = GeneralProps.getGeneralProps()
      expect(Object.keys(props).length).assertEqual(0)
    })
  })

  // ─── setGeneralProps ──────────────────────────────────────────────────────

  describe('GeneralProps_setGeneralProps', () => {

    beforeEach(() => {
      GeneralProps._reset()
    })

    it('设置单个属性后应能获取到', 0, () => {
      GeneralProps.setGeneralProps({ 'channel': 'appstore' })
      let props = GeneralProps.getGeneralProps()
      expect(props['channel']).assertEqual('appstore')
    })

    it('设置多个属性应全部生效', 0, () => {
      GeneralProps.setGeneralProps({ 'channel': 'appstore', 'version': '1.0' })
      let props = GeneralProps.getGeneralProps()
      expect(props['channel']).assertEqual('appstore')
      expect(props['version']).assertEqual('1.0')
    })

    it('多次 set 应合并属性（后者覆盖前者）', 0, () => {
      GeneralProps.setGeneralProps({ 'channel': 'appstore', 'region': 'cn' })
      GeneralProps.setGeneralProps({ 'channel': 'huawei', 'level': '3' })
      let props = GeneralProps.getGeneralProps()
      expect(props['channel']).assertEqual('huawei')
      expect(props['region']).assertEqual('cn')
      expect(props['level']).assertEqual('3')
    })

    it('设置空对象应无副作用', 0, () => {
      GeneralProps.setGeneralProps({ 'key': 'value' })
      GeneralProps.setGeneralProps({})
      let props = GeneralProps.getGeneralProps()
      expect(props['key']).assertEqual('value')
    })
  })

  // ─── removeGeneralProps ───────────────────────────────────────────────────

  describe('GeneralProps_removeGeneralProps', () => {

    beforeEach(() => {
      GeneralProps._reset()
    })

    it('移除已存在的 key 应成功', 0, () => {
      GeneralProps.setGeneralProps({ 'a': '1', 'b': '2', 'c': '3' })
      GeneralProps.removeGeneralProps(['b'])
      let props = GeneralProps.getGeneralProps()
      expect(props['a']).assertEqual('1')
      expect(props['b']).assertUndefined()
      expect(props['c']).assertEqual('3')
    })

    it('移除多个 key 应全部生效', 0, () => {
      GeneralProps.setGeneralProps({ 'a': '1', 'b': '2', 'c': '3' })
      GeneralProps.removeGeneralProps(['a', 'c'])
      let props = GeneralProps.getGeneralProps()
      expect(props['a']).assertUndefined()
      expect(props['b']).assertEqual('2')
      expect(props['c']).assertUndefined()
    })

    it('移除不存在的 key 应静默忽略（不崩溃）', 0, () => {
      GeneralProps.setGeneralProps({ 'a': '1' })
      GeneralProps.removeGeneralProps(['nonexistent'])
      let props = GeneralProps.getGeneralProps()
      expect(props['a']).assertEqual('1')
    })

    it('移除空数组应无副作用', 0, () => {
      GeneralProps.setGeneralProps({ 'a': '1' })
      GeneralProps.removeGeneralProps([])
      let props = GeneralProps.getGeneralProps()
      expect(props['a']).assertEqual('1')
    })
  })

  // ─── clearGeneralProps ────────────────────────────────────────────────────

  describe('GeneralProps_clearGeneralProps', () => {

    beforeEach(() => {
      GeneralProps._reset()
    })

    it('清空后 getGeneralProps 应返回空对象', 0, () => {
      GeneralProps.setGeneralProps({ 'a': '1', 'b': '2' })
      GeneralProps.clearGeneralProps()
      let props = GeneralProps.getGeneralProps()
      expect(Object.keys(props).length).assertEqual(0)
    })

    it('清空后再设置新属性应正常工作', 0, () => {
      GeneralProps.setGeneralProps({ 'old': 'value' })
      GeneralProps.clearGeneralProps()
      GeneralProps.setGeneralProps({ 'new': 'value' })
      let props = GeneralProps.getGeneralProps()
      expect(props['old']).assertUndefined()
      expect(props['new']).assertEqual('value')
    })

    it('对空状态调用 clear 应安全完成', 0, () => {
      GeneralProps.clearGeneralProps()
      let props = GeneralProps.getGeneralProps()
      expect(Object.keys(props).length).assertEqual(0)
    })
  })

  // ─── setDynamicGeneralProps ───────────────────────────────────────────────

  describe('GeneralProps_dynamicGeneralProps', () => {

    beforeEach(() => {
      GeneralProps._reset()
    })

    it('动态属性应在 getGeneralProps 时实时求值', 0, () => {
      let counter = 0
      GeneralProps.setDynamicGeneralProps(() => {
        counter++
        return { 'callCount': String(counter) }
      })

      let props1 = GeneralProps.getGeneralProps()
      expect(props1['callCount']).assertEqual('1')

      let props2 = GeneralProps.getGeneralProps()
      expect(props2['callCount']).assertEqual('2')
    })

    it('动态属性应覆盖同名静态属性（动态优先）', 0, () => {
      GeneralProps.setGeneralProps({ 'channel': 'static' })
      GeneralProps.setDynamicGeneralProps(() => {
        return { 'channel': 'dynamic' }
      })
      let props = GeneralProps.getGeneralProps()
      expect(props['channel']).assertEqual('dynamic')
    })

    it('静态与动态的不同 key 应合并', 0, () => {
      GeneralProps.setGeneralProps({ 'static_key': 'static_value' })
      GeneralProps.setDynamicGeneralProps(() => {
        return { 'dynamic_key': 'dynamic_value' }
      })
      let props = GeneralProps.getGeneralProps()
      expect(props['static_key']).assertEqual('static_value')
      expect(props['dynamic_key']).assertEqual('dynamic_value')
    })

    it('动态生成器返回空对象时只包含静态属性', 0, () => {
      GeneralProps.setGeneralProps({ 'key': 'value' })
      GeneralProps.setDynamicGeneralProps(() => {
        return {}
      })
      let props = GeneralProps.getGeneralProps()
      expect(props['key']).assertEqual('value')
      expect(Object.keys(props).length).assertEqual(1)
    })
  })

  // ─── getGeneralProps 返回值隔离 ──────────────────────────────────────────

  describe('GeneralProps_returnIsolation', () => {

    beforeEach(() => {
      GeneralProps._reset()
    })

    it('getGeneralProps 返回副本，外部修改不影响内部状态', 0, () => {
      GeneralProps.setGeneralProps({ 'key': 'original' })
      let props = GeneralProps.getGeneralProps()
      props['key'] = 'tampered'

      let propsAgain = GeneralProps.getGeneralProps()
      expect(propsAgain['key']).assertEqual('original')
    })

    it('clearGeneralProps 不影响动态生成器', 0, () => {
      GeneralProps.setGeneralProps({ 'static': 'value' })
      GeneralProps.setDynamicGeneralProps(() => {
        return { 'dynamic': 'value' }
      })
      GeneralProps.clearGeneralProps()

      let props = GeneralProps.getGeneralProps()
      expect(props['static']).assertUndefined()
      expect(props['dynamic']).assertEqual('value')
    })
  })

  // ─── _reset 隔离验证 ──────────────────────────────────────────────────────

  describe('GeneralProps_reset_isolation', () => {

    beforeEach(() => {
      GeneralProps._reset()
    })

    it('_reset 应清空静态属性', 0, () => {
      GeneralProps.setGeneralProps({ 'key': 'value' })
      GeneralProps._reset()
      let props = GeneralProps.getGeneralProps()
      expect(Object.keys(props).length).assertEqual(0)
    })

    it('_reset 应重置动态生成器', 0, () => {
      GeneralProps.setDynamicGeneralProps(() => {
        return { 'dynamic': 'value' }
      })
      GeneralProps._reset()
      let props = GeneralProps.getGeneralProps()
      expect(props['dynamic']).assertUndefined()
    })
  })
}
