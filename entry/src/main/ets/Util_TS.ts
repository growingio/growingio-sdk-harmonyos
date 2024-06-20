export default class Util_TS {
  static removeKeysForObject(keys: string[], obj: object) {
    keys.forEach((key) => {
      delete obj[key]
    })
  }
}