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

import { AttributesType } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import Util from '../utils/Util'
import collections from '@arkts.collections'

"use shared"

@Sendable
export default class GeneralProps {
  // private static _internalProps: collections.Map<string, SendableValueType>
  // private static _dynamicGeneralPropsGenerator: () => SendableAttributesType = () => {
  //   return {}
  // }

  static setGeneralProps(props: AttributesType) {
    // LogUtil.info(() => 'Set generalProps: ' + JSON.stringify(props))
    // GeneralProps._internalProps = Util.concatObject(GeneralProps._internalProps, props)
    // LogUtil.info(() => 'Current generalProps: ' + JSON.stringify(GeneralProps._internalProps))
  }

  static removeGeneralProps(keys: string[]) {
    // LogUtil.info(() => 'Remove generalProps by keys: ' + keys)
    // Util.removeKeysForObject(keys, GeneralProps._internalProps)
    // LogUtil.info(() => 'Current generalProps: ' + JSON.stringify(GeneralProps._internalProps))
  }

  static clearGeneralProps() {
    // LogUtil.info(() => 'Clear generalProps')
    // GeneralProps._internalProps = {}
  }

  static setDynamicGeneralProps(generator: () => AttributesType) {
    // LogUtil.info(() => 'Set dynamicGeneralProps')
    // GeneralProps._dynamicGeneralPropsGenerator = generator
  }

  static getGeneralProps(): AttributesType {
    // let dynamicProps = GeneralProps._dynamicGeneralPropsGenerator()
    // let props = Util.cloneObject(GeneralProps._internalProps)
    // let properties = Util.concatObject(props, dynamicProps)
    // return properties
    return {}
  }
}