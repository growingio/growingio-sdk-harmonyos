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

import collections from '@arkts.collections'
import ArkTSUtils from '@arkts.utils'

import { AttributesType, ValueType } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import Util from '../utils/Util'

"use shared"

@Sendable
export type SendableDynamicGeneralPropsGenerator = () => AttributesType

@Sendable
function _DummyFunction(): AttributesType {
  return {}
}

@Sendable
export default class GeneralProps {
  private static _internalProps: collections.Map<string, string | number | boolean | collections.Array<string | number | boolean>> = new collections.Map()
  private static _dynamicGeneralPropsGenerator: SendableDynamicGeneralPropsGenerator = _DummyFunction
  private static _lock: ArkTSUtils.locks.AsyncLock = new ArkTSUtils.locks.AsyncLock()

  static async setGeneralProps(props: AttributesType) {
    LogUtil.info(() => 'Set generalProps: ' + JSON.stringify(props))
    try {
      let map = Util.objectToMap(props)
      await GeneralProps._lock.lockAsync(() => {
        map.forEach((value, key) => {
          if (value instanceof Array) {
            let sendableValue = new collections.Array<string | number | boolean>()
            value.forEach((v: string | number | boolean, index: number) => {
              sendableValue.push(v)
            })
            GeneralProps._internalProps.set(key, sendableValue)
          } else {
            GeneralProps._internalProps.set(key, value)
          }
        })
      })
      LogUtil.info(() => 'Current generalProps: ' + ArkTSUtils.ASON.stringify(GeneralProps._internalProps))
    } catch(e) {
      LogUtil.error(() => 'Failed to Set generalProps: ' + JSON.stringify(props) + ', error: ' + JSON.stringify(e))
    }
  }

  static async removeGeneralProps(keys: string[]) {
    LogUtil.info(() => 'Remove generalProps by keys: ' + keys)
    try {
      await GeneralProps._lock.lockAsync(() => {
        keys.forEach((key) => {
          GeneralProps._internalProps.delete(key)
        })
      })
      LogUtil.info(() => 'Current generalProps: ' + ArkTSUtils.ASON.stringify(GeneralProps._internalProps))
    } catch(e) {
      LogUtil.error(() => 'Failed to remove generalProps by keys: ' + keys + ', error: ' + JSON.stringify(e))
    }
  }

  static async clearGeneralProps() {
    LogUtil.info(() => 'Clear generalProps')
    try {
      await GeneralProps._lock.lockAsync(() => {
        GeneralProps._internalProps = new collections.Map()
      })
    } catch(e) {
      LogUtil.error(() => 'Failed to clear generalProps, error: ' + JSON.stringify(e))
    }
  }

  static async setDynamicGeneralProps(generator: SendableDynamicGeneralPropsGenerator) {
    LogUtil.info(() => 'Set dynamicGeneralProps')
    try {
      await GeneralProps._lock.lockAsync(() => {
        GeneralProps._dynamicGeneralPropsGenerator = generator
      })
    } catch(e) {
      LogUtil.error(() => 'Failed to set dynamicGeneralProps, error: ' + JSON.stringify(e))
    }
  }

  static async getGeneralProps(): Promise<AttributesType> {
    try {
      return await GeneralProps._lock.lockAsync(() => {
        let dynamicProps = GeneralProps._dynamicGeneralPropsGenerator()
        let map = new Map<string, ValueType>()
        GeneralProps._internalProps.forEach((value, key) => {
          if (value instanceof collections.Array) {
            let nonSendableValue = new Array<string | number | boolean>()
            value.forEach((v: string | number | boolean, index: number) => {
              nonSendableValue.push(v)
            })
            map.set(key, nonSendableValue as ValueType)
          } else {
            map.set(key, value as ValueType)
          }
        })
        let props = Util.cloneObject(Util.mapToObject(map))
        let properties = Util.concatObject(props, dynamicProps)
        return properties
      })
    } catch(e) {
      LogUtil.error(() => 'Failed to get generalProps, error: ' + JSON.stringify(e))
      return Promise.resolve({} as AttributesType)
    }
  }
}