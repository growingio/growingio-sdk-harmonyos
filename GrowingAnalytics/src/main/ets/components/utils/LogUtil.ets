export class LogUtil {
  static debugEnabled: boolean = false

  static info(message: string, ...args: any[]) {
    if (!this.debugEnabled) {
      return
    }
    console.info('[GrowingAnalytics] ' + message, args)
  }

  static error(message: string, ...args: any[]) {
    if (!this.debugEnabled) {
      return
    }
    console.error('[GrowingAnalytics] ' + message, args)
  }

  static warn(message: string, ...args: any[]) {
    if (!this.debugEnabled) {
      return
    }
    console.warn('[GrowingAnalytics] ' + message, args)
  }
}