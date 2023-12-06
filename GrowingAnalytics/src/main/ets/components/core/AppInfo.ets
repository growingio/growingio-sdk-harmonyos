import bundleManager from '@ohos.bundle.bundleManager'

export default class AppInfo {
  static domain: string = ''
  static appChannel: string = ''
  static appName: string = ''
  static appVersion: string = ''

  static async initAppInfo() {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleFlags)
    this.domain = bundleInfo.name
    this.appChannel = 'Harmony'
    this.appName = bundleInfo.name // TODO
    this.appVersion = bundleInfo.versionName
  }
}