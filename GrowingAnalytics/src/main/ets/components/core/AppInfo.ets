/**
 * @license
 * Copyright (C) 2023 Beijing Yishu Technology Co., Ltd.
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

import bundleManager from '@ohos.bundle.bundleManager'

export default class AppInfo {
  static domain: string = ''
  static appName: string = ''
  static appVersion: string = ''
  static appChannel: string | undefined = undefined

  static initAppInfo(context: Context) {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags)

    AppInfo.domain = bundleInfo.name
    let r_id = bundleInfo.appInfo.labelResource.id
    AppInfo.appName = context.resourceManager.getStringSync(r_id)
    AppInfo.appVersion = bundleInfo.versionName
    // AppInfo.appChannel = '应用市场'
  }
}