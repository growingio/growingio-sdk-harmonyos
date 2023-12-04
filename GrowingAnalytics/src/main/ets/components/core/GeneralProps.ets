import { AttributesType } from '../utils/Constants'

export default class GeneralProps {
  private static _internalProps: AttributesType = {}

  static setGeneralProps(props: AttributesType) {
    this._internalProps = { ...this._internalProps, ...props }
  }

  static removeGeneralProps(keys: string[]) {
    keys.forEach((key) => {
      delete this._internalProps[key]
    })
  }

  static clearGeneralProps() {
    this._internalProps = {}
  }

  static getGeneralProps(): AttributesType {
    return { ...this._internalProps }
  }
}