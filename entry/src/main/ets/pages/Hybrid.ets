import { GrowingAnalytics } from '@growingio/analytics';
import web_webview from '@ohos.web.webview';

@Entry
@Component
struct Hybrid {
  controller: web_webview.WebviewController = new web_webview.WebviewController()

  build() {
    Column() {
      Web({ src: $rawfile('hybrid.html'), controller: this.controller})
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .javaScriptProxy(GrowingAnalytics.createHybridProxy(this.controller))
    }
    .height('100%')
    .width('100%')
  }
}