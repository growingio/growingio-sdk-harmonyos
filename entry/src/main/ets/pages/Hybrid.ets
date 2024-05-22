import web_webview from '@ohos.web.webview'
import { GrowingAnalytics } from '@growingio/analytics'

@Entry
@Component
struct Hybrid {
  controller: web_webview.WebviewController = new web_webview.WebviewController()

  aboutToAppear() {
    // 配置Web开启调试模式
    web_webview.WebviewController.setWebDebuggingAccess(true)
  }

  build() {
    Column() {
      // 运行时执行hybrid注入，需要refresh webView使当前页面生效
      // Button('refresh')
      //   .onClick(() => {
      //     try {
      //       this.controller.refresh();
      //     } catch (e) {
      //       console.error(`ErrorCode: ${e.code},  Message: ${e.message}`);
      //     }
      //   })
      // Button('Register JavaScript To Window')
      //   .onClick(() => {
      //     try {
      //       let proxy = GrowingAnalytics.createHybridProxy(this.controller)
      //       this.controller.registerJavaScriptProxy(proxy?.object, proxy?.name, proxy?.methodList);
      //     } catch (e) {
      //       console.error(`ErrorCode: ${e.code},  Message: ${e.message}`);
      //     }
      //   })
      Web({ src: $rawfile('newDemo.html'), controller: this.controller})
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .javaScriptProxy(GrowingAnalytics.createHybridProxy(this.controller))
    }
    .height('100%')
    .width('100%')
  }
}