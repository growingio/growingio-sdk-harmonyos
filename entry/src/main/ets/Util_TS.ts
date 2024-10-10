export default class Util_TS {
  static removeKeysForObject(keys: string[], obj: object) {
    keys.forEach((key) => {
      delete obj[key]
    })
  }
}

export type ValueType = string | number | boolean | string[] | number[] | boolean[]
export type AttributesType = { [key: string]: ValueType }