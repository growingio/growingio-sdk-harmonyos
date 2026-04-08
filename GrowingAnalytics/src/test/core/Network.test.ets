import { describe, it, expect } from '@ohos/hypium'
import Network from '../../main/ets/components/core/Network'
import { GrowingConfig, ConfigMode } from '../../main/ets/components/interfaces/GrowingConfig'
import GrowingContext from '../../main/ets/components/core/Context'

/**
 * Network 测试策略说明：
 *
 * Network.generateUrl 和 Network.generateHeaders 是纯计算函数：
 *   - 输入：time(number) + urlPath(string) + context(GrowingContext)
 *   - 输出：string / Record<string, string>
 *   - 无任何 IO 副作用，零平台依赖
 *
 * Network.request 依赖 rcp.Session（Platform API），不在本地单元测试范围内。
 *
 * URL 格式：{serverHost}{urlPath.replace('accountId', accountId)}?stm={time}
 */

/** buildContext 可选参数 */
interface NetworkTestOptions {
  encrypt?: boolean
  compress?: boolean
  protobuf?: boolean
}

/** 最小 GrowingContext 替身的中间结构 */
interface MinimalNetworkContext {
  trackerId: string
  config: GrowingConfig
}

function buildContext(
  mode: ConfigMode,
  accountId: string,
  serverHost: string,
  options?: NetworkTestOptions
): GrowingContext {
  let config = new GrowingConfig()
  config.mode = mode
  config.accountId = accountId
  config.dataCollectionServerHost = serverHost
  config.encryptEnabled = options?.encrypt ?? true
  config.compressEnabled = options?.compress ?? true
  config.useProtobuf = options?.protobuf ?? true

  let ctx: MinimalNetworkContext = { trackerId: 'default', config: config }
  return ctx as ESObject as GrowingContext
}

export default function networkTests() {

  // ─── generateUrl ─────────────────────────────────────────────────────────

  describe('Network - generateUrl', () => {

    it('NewSaaS 路径：accountId 模板应被正确替换', 0, () => {
      const urlPath = '/v3/projects/accountId/collect'
      let ctx = buildContext(ConfigMode.NewSaaS, 'acct-001', 'https://napi.growingio.com')
      let url = Network.generateUrl(Date.now(), urlPath, ctx)

      expect(url).assertContain('acct-001')
      expect(url.includes('/accountId/')).assertFalse()  // 模板变量已被替换
      expect(url).assertContain('/v3/projects/acct-001/collect')
    })

    it('SaaS PV 路径：accountId 模板应被正确替换', 0, () => {
      const urlPath = '/v3/accountId/harmonyos/pv'
      let ctx = buildContext(ConfigMode.SaaS, 'saas-acct', 'https://api.growingio.com')
      let url = Network.generateUrl(Date.now(), urlPath, ctx)

      expect(url).assertContain('saas-acct')
      expect(url).assertContain('/harmonyos/pv')
      expect(url.includes('/accountId/')).assertFalse()
    })

    it('SaaS CSTM 路径：accountId 模板应被正确替换', 0, () => {
      const urlPath = '/v3/accountId/harmonyos/cstm'
      let ctx = buildContext(ConfigMode.SaaS, 'saas-acct', 'https://api.growingio.com')
      let url = Network.generateUrl(Date.now(), urlPath, ctx)

      expect(url).assertContain('/harmonyos/cstm')
      expect(url).assertContain('saas-acct')
    })

    it('URL 应包含 stm 时间戳参数', 0, () => {
      let ctx = buildContext(ConfigMode.NewSaaS, 'a', 'https://napi.growingio.com')
      let time = 1700000000000
      let url = Network.generateUrl(time, '/v3/projects/accountId/collect', ctx)

      expect(url).assertContain('?stm=')
      expect(url).assertContain(String(time))
    })

    it('serverHost 末尾有斜杠时应自动去除', 0, () => {
      let ctx = buildContext(ConfigMode.NewSaaS, 'acct', 'https://napi.growingio.com/')
      let url = Network.generateUrl(Date.now(), '/v3/projects/accountId/collect', ctx)

      // 不应出现双斜杠
      expect(url.indexOf('//')).assertEqual(6)  // 只有协议部分有 //
    })

    it('自定义 serverHost 应正确拼接', 0, () => {
      let ctx = buildContext(ConfigMode.CDP, 'cdp-acct', 'https://custom.example.com:8080')
      let url = Network.generateUrl(Date.now(), '/v3/projects/accountId/collect', ctx)

      expect(url).assertContain('custom.example.com:8080')
      expect(url).assertContain('cdp-acct')
    })
  })

  // ─── generateHeaders ─────────────────────────────────────────────────────

  describe('Network - generateHeaders', () => {

    it('useProtobuf=true → Content-Type 应为 application/protobuf', 0, () => {
      let opts: NetworkTestOptions = { encrypt: false, compress: false, protobuf: true }
      let ctx = buildContext(ConfigMode.NewSaaS, 'a', 'https://x.com', opts)
      let headers = Network.generateHeaders(Date.now(), true, ctx)
      expect(headers['Content-Type']).assertEqual('application/protobuf')
    })

    it('useProtobuf=false → Content-Type 应为 application/json', 0, () => {
      let opts: NetworkTestOptions = { encrypt: false, compress: false, protobuf: false }
      let ctx = buildContext(ConfigMode.SaaS, 'a', 'https://x.com', opts)
      let headers = Network.generateHeaders(Date.now(), false, ctx)
      expect(headers['Content-Type']).assertEqual('application/json')
    })

    it('Accept 应始终为 application/json', 0, () => {
      let ctx = buildContext(ConfigMode.NewSaaS, 'a', 'https://x.com')
      let headers = Network.generateHeaders(Date.now(), true, ctx)
      expect(headers['Accept']).assertEqual('application/json')
    })

    it('X-Timestamp 应包含时间戳值', 0, () => {
      let ctx = buildContext(ConfigMode.NewSaaS, 'a', 'https://x.com')
      let time = 1700000000000
      let headers = Network.generateHeaders(time, true, ctx)
      expect(headers['X-Timestamp']).assertEqual(String(time))
    })

    it('compressEnabled=true → 应包含 X-Compress-Codec 头', 0, () => {
      let opts: NetworkTestOptions = { encrypt: false, compress: true }
      let ctx = buildContext(ConfigMode.NewSaaS, 'a', 'https://x.com', opts)
      let headers = Network.generateHeaders(Date.now(), true, ctx)
      expect(Object.keys(headers).indexOf('X-Compress-Codec')).assertLarger(-1)
      expect(headers['X-Compress-Codec']).assertEqual('2')
    })

    it('compressEnabled=false → 不应包含 X-Compress-Codec 头', 0, () => {
      let opts: NetworkTestOptions = { encrypt: false, compress: false }
      let ctx = buildContext(ConfigMode.NewSaaS, 'a', 'https://x.com', opts)
      let headers = Network.generateHeaders(Date.now(), true, ctx)
      expect(Object.keys(headers).indexOf('X-Compress-Codec')).assertEqual(-1)
    })

    it('encryptEnabled=true → 应包含 X-Crypt-Codec 头', 0, () => {
      let opts: NetworkTestOptions = { encrypt: true, compress: false }
      let ctx = buildContext(ConfigMode.NewSaaS, 'a', 'https://x.com', opts)
      let headers = Network.generateHeaders(Date.now(), true, ctx)
      expect(Object.keys(headers).indexOf('X-Crypt-Codec')).assertLarger(-1)
      expect(headers['X-Crypt-Codec']).assertEqual('1')
    })

    it('encryptEnabled=false → 不应包含 X-Crypt-Codec 头', 0, () => {
      let opts: NetworkTestOptions = { encrypt: false, compress: false }
      let ctx = buildContext(ConfigMode.NewSaaS, 'a', 'https://x.com', opts)
      let headers = Network.generateHeaders(Date.now(), true, ctx)
      expect(Object.keys(headers).indexOf('X-Crypt-Codec')).assertEqual(-1)
    })

    it('同时启用加密和压缩 → 两个头都应存在', 0, () => {
      let opts: NetworkTestOptions = { encrypt: true, compress: true }
      let ctx = buildContext(ConfigMode.NewSaaS, 'a', 'https://x.com', opts)
      let headers = Network.generateHeaders(Date.now(), true, ctx)
      expect(Object.keys(headers).indexOf('X-Compress-Codec')).assertLarger(-1)
      expect(Object.keys(headers).indexOf('X-Crypt-Codec')).assertLarger(-1)
    })

    it('同时禁用加密和压缩 → 两个头都不应存在', 0, () => {
      let opts: NetworkTestOptions = { encrypt: false, compress: false }
      let ctx = buildContext(ConfigMode.NewSaaS, 'a', 'https://x.com', opts)
      let headers = Network.generateHeaders(Date.now(), false, ctx)
      expect(Object.keys(headers).indexOf('X-Compress-Codec')).assertEqual(-1)
      expect(Object.keys(headers).indexOf('X-Crypt-Codec')).assertEqual(-1)
    })
  })
}
