import bundleManager from '@ohos.bundle.bundleManager'

export default class AppInfo {
  domain: string = ''
  appChannel: string = ''
  appName: string = ''
  appVersion: string = ''

  static instance: AppInfo = null
  constructor() { }

  static async sharedInstance(): Promise<AppInfo> {
    if (this.instance == null) {
      this.instance = new AppInfo()
      await this.instance.initAppInfo()
    }
    return this.instance
  }

  async initAppInfo() {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleFlags)
    this.domain = bundleInfo.name
    this.appChannel = 'Harmony'
    this.appName = bundleInfo.name // TODO
    this.appVersion = bundleInfo.versionName
  }
}