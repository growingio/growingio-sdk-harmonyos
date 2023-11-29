import bundleManager from '@ohos.bundle.bundleManager'

export default class AppInfo {
  domain: string = ''
  appState: string = ''
  appChannel: string = ''
  appName: string = ''
  appVersion: string = ''

  static instance: AppInfo = null
  constructor() { }

  static sharedInstance(): AppInfo {
    if (this.instance == null) {
      this.instance = new AppInfo()
      this.instance.initAppInfo()
    }
    return this.instance
  }

  async initAppInfo() {
    var bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    this.domain = bundleInfo.name
    this.appChannel = 'Harmony'
    this.appName = bundleInfo.appInfo.label
    this.appVersion = bundleInfo.versionName
  }
}