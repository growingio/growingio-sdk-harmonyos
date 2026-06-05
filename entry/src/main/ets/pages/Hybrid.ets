import web_webview from '@ohos.web.webview'
import { GrowingAnalytics, GrowingAnalyticsInterface } from '@growingio/analytics'

const SDK_MODE_SAAS: number = 1

@Entry({useSharedStorage: true})
@Component
struct Hybrid {
  @StorageProp('sdkMode') sdkMode: number = 0
  @LocalStorageProp('trackerId') trackerIdFromStorage: string = ''
  @State trackerIdFromRouterParams: string = this.getUIContext().getRouter().getParams()
    ? ((this.getUIContext().getRouter().getParams() as Record<string, Object>)['trackerId'] as string)
    : ''
  controller: web_webview.WebviewController = new web_webview.WebviewController()

  aboutToAppear() {
    // 配置Web开启调试模式
    web_webview.WebviewController.setWebDebuggingAccess(true)
  }

  build() {
    Column() {
      if (this.getTrackerId().length > 0) {
        Text('trackerId = ' + this.getTrackerId())
      }

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
      if (this.sdkMode === SDK_MODE_SAAS) {
        Web({ src: $rawfile('SaaSDemo.html'), controller: this.controller })
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .javaScriptProxy(this.getJavaScriptProxy('Web1'))
          .javaScriptOnDocumentStart(GrowingAnalytics.javaScriptOnDocumentStart())
          .javaScriptOnDocumentEnd(GrowingAnalytics.javaScriptOnDocumentEnd())
          .onPageEnd(() => {
            GrowingAnalytics.onPageEnd(this.controller, 'Web1')
          })
          .height('90%')
          .id('Web1')
      } else {
        Web({ src: $rawfile('newDemo.html'), controller: this.controller })
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .javaScriptProxy(this.getJavaScriptProxy('Web1'))
          .height('90%')
          .id('Web1')
      }
      Button('Back')
        .onClick(() => {
          // let context = getContext(this) as AppContext.UIAbilityContext
          // context.terminateSelf()
          this.getUIContext().getRouter().back()
        }).margin({ top: 15 })
    }
    .height('100%')
    .width('100%')
  }

  getJavaScriptProxy(webviewId: string): JavaScriptProxy | undefined {
    let trackerId = this.getTrackerId()
    if (trackerId && trackerId.length > 0) {
      return this.subTracker().createHybridProxy(this.controller, webviewId)
    } else {
      return GrowingAnalytics.createHybridProxy(this.controller, webviewId)
    }
  }

  subTracker(): GrowingAnalyticsInterface {
    return GrowingAnalytics.tracker(this.getTrackerId()) as GrowingAnalyticsInterface
  }

  getTrackerId(): string {
    if (this.trackerIdFromStorage && this.trackerIdFromStorage.length > 0) {
      return this.trackerIdFromStorage
    } else if (this.trackerIdFromRouterParams && this.trackerIdFromRouterParams.length > 0) {
      return this.trackerIdFromRouterParams
    }
    return ''
  }
}