import { AttributesType } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'

export default class GeneralProps {
  private static _internalProps: AttributesType = {}

  static setGeneralProps(props: AttributesType) {
    LogUtil.info('Set generalProps: ' + JSON.stringify(props))
    this._internalProps = { ...this._internalProps, ...props }
  }

  static removeGeneralProps(keys: string[]) {
    LogUtil.info('Remove generalProps by keys: ' + keys)
    keys.forEach((key) => {
      delete this._internalProps[key]
    })
  }

  static clearGeneralProps() {
    LogUtil.info('Clear generalProps')
    this._internalProps = {}
  }

  static getGeneralProps(): AttributesType {
    return { ...this._internalProps }
  }
}