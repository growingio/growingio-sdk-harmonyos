export class LogUtil {
  static debugEnabled: boolean = false

  static info(message: string, ...args: any[]) {
    if (!this.debugEnabled) {
      return
    }
    console.info(message, args)
  }

  static error(message: string, ...args: any[]) {
    if (!this.debugEnabled) {
      return
    }
    console.error(message, args)
  }

  static warn(message: string, ...args: any[]) {
    if (!this.debugEnabled) {
      return
    }
    console.warn(message, args)
  }
}