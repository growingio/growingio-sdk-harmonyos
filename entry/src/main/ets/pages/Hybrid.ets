import { GrowingAnalytics } from '@growingio/analytics';
import web_webview from '@ohos.web.webview';
import business_error from '@ohos.base';

@Entry
@Component
struct Hybrid {
  controller: web_webview.WebviewController = new web_webview.WebviewController()

  build() {
    Column() {
      // 运行时执行hybrid注入，需要refresh webView使当前页面生效
      Button('refresh')
        .onClick(() => {
          try {
            this.controller.refresh();
          } catch (error) {
            let e: business_error.BusinessError = error as business_error.BusinessError;
            console.error(`ErrorCode: ${e.code},  Message: ${e.message}`);
          }
        })
      Button('Register JavaScript To Window')
        .onClick(() => {
          try {
            let proxy = GrowingAnalytics.createHybridProxy(this.controller)
            this.controller.registerJavaScriptProxy(proxy?.object, proxy?.name, proxy?.methodList);
          } catch (error) {
            let e: business_error.BusinessError = error as business_error.BusinessError;
            console.error(`ErrorCode: ${e.code},  Message: ${e.message}`);
          }
        })
      Web({ src: $rawfile('newDemo.html'), controller: this.controller})
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .javaScriptProxy(GrowingAnalytics.createHybridProxy(this.controller))
    }
    .height('100%')
    .width('100%')
  }
}