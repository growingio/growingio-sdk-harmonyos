import { AttributesType } from '../utils/Constants'

export default class GeneralProps {
  private _internalProps: AttributesType = {}

  setGeneralProps(props: AttributesType) {
    this._internalProps = { ...this._internalProps, ...props }
  }

  removeGeneralProps(keys: string[]) {
    keys.forEach((key) => {
      delete this._internalProps[key]
    })
  }

  clearGeneralProps() {
    this._internalProps = {}
  }

  getGeneralProps(): AttributesType {
    return { ...this._internalProps }
  }
}