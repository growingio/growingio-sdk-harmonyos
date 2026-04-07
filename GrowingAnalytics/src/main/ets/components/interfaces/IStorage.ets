/**
 * @license
 * Copyright (C) 2024 Beijing Yishu Technology Co., Ltd.
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

import preferences from '@ohos.data.preferences'

/**
 * 键值存储接口
 *
 * 生产实现：SharedPreferences（基于 @ohos.data.preferences）
 * 测试实现：InMemoryStorage（基于 Map，无平台依赖）
 */
export interface IStorage {
  put(key: string, value: preferences.ValueType): Promise<void>
  getValue(key: string, defValue: preferences.ValueType): preferences.ValueType
}
