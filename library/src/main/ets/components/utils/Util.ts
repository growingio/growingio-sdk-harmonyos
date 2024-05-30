import { ValueType, AttributesType } from '../utils/Constants'

export default class Util {
  static mapToObject(map: Map<string, ValueType>): { [key: string]: ValueType } {
    const object: { [key: string]: ValueType } = {}
    map.forEach((value, key) => {
      object[key] = value
    })
    return object
  }

  static concatObject(objA: AttributesType, objB: AttributesType): AttributesType {
    return { ...objA, ...objB }
  }

  static removeKeysForObject(keys: string[], obj: AttributesType) {
    keys.forEach((key) => {
      delete obj[key]
    })
  }

  static cloneObject(obj: AttributesType): AttributesType {
    return { ...obj }
  }

  static serializableAttributes(attr: AttributesType): AttributesType | undefined {
    let result: AttributesType = {}
    Object.keys(attr).forEach(key => {
      let value = attr[key] as ValueType
      if (Array.isArray(value)) {
        let stringValue = value.map(String).join('||')
        result[key] = stringValue
      } else {
        result[key] = String(value)
      }
    })
    return Object.keys(result).length > 0 ? result : undefined
  }

  static getHintFromTime(time: number): Uint8Array {
    let hexString: string = time.toString(16)
    let lastByteHex: string = hexString.slice(-2)
    let lastByte: number = parseInt(lastByteHex, 16)
    return new Uint8Array([lastByte])
  }
}