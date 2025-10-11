import AppContext from '@ohos.app.ability.common'
import Want from '@ohos.app.ability.Want'

export default class Util {
  static getRandomString(): string {
    const characters = 'abcdefghijklmnopqrstuvwxyz0123456789'
    let random = ''

    for (let i = 0; i < 10; i++) {
      const randomIndex = Math.floor(Math.random() * characters.length)
      random += characters.charAt(randomIndex)
    }
    return random
  }

  static startAbility(context: UIContext, name: string, path: string, params?: Record<string, Object>, isRouter: boolean = true) {
    try {
      if (isRouter) {
        if (params) {
          context.getRouter().pushUrl({
            url: path,
            params: params
          })
        } else {
          context.getRouter().pushUrl({
            url: path
          })
        }
      } else {
        let appContext = context.getHostContext() as AppContext.UIAbilityContext
        const want: Want = {
          bundleName: appContext.applicationInfo.name,
          abilityName: name
        }
        if (params) {
          want.parameters = params
        }
        appContext.startAbility(want)
      }
    } catch {

    }
  }

  static formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    const milliseconds = String(date.getMilliseconds()).padStart(3, '0');

    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}.${milliseconds}`;
  }
}