## HarmonyOS 5 无埋点 (仅支持 New SaaS)

### 如何集成

#### 开启无埋点监听

若您的应用需要使用无埋点功能，在主窗口对应的 Ability 的 onWindowStageCreate 方法中开启无埋点监听: 

```typescript
onWindowStageCreate(windowStage: window.WindowStage) {
  try {
    windowStage.loadContent('pages/Index',  (err: BusinessError) => {
      const errCode: number = err.code
      if (errCode) {
        console.error(`Failed to load the content. Cause code: ${err.code}, message: ${err.message}`)
        return;
      }
      console.info('Succeeded in loading the content.')
      // 在 windowStage.loadContent 完成时，开启无埋点监听
      GrowingAnalytics.onWindowStageCreate(this, windowStage)
    });
  } catch (exception) {
    console.error(`Failed to load the content. Cause code: ${exception.code}, message: ${exception.message}`)
  }
}
```

> 注意：
> 该监听在未初始化 SDK 之前不会获取任何设备信息，以及产生事件数据

#### 开启无埋点采集

在 SDK 初始化时，设置配置项 `autotrackEnabled` 为 `true` (2.1.0 版本默认为 `true`，2.2.0 版本起，默认为 `false`，后续版本可能会有所改动) 来开启采集无埋点数据: 

```typescript
startAnalytics() {
  let config = new GrowingConfig().NewSaaS(
    'Your AccountId',
    'Your DataSourceId',
    'Your UrlScheme',
    'Your DataCollectionServerHost<Optional>'
  )
  config.autotrackEnabled = true
  GrowingAnalytics.start(this.context, config)
}
```

#### 开启页面浏览事件自动埋点

在 SDK 初始化时，设置配置项 `autotrackAllPages` 为 `true` (默认为 `false`) 来开启页面浏览事件自动埋点，适配组件导航 (Navigation) 和页面路由 (@ohos.router): 

```typescript
startAnalytics() {
  let config = new GrowingConfig().NewSaaS(
    'Your AccountId',
    'Your DataSourceId',
    'Your UrlScheme',
    'Your DataCollectionServerHost<Optional>'
  )
  config.autotrackAllPages = true
  GrowingAnalytics.start(this.context, config)
}
```

### 设置页面别名

您也可以通过手动设置页面别名，设置后：

* 页面路径为对应的别名
* 无论是否开启页面浏览事件自动埋点，该页面的页面浏览事件都将生成

#### 基于组件导航 (Navigation)

```typescript
let destination = new NavPathInfo(name, {
  "growing_alias": "homePage"
} as Record<string, Object>)
this.pageStack.pushDestination(destination)
```

#### 基于页面路由 (@ohos.router)

```typescript
router.pushUrl({
  url: path,
  params: {
    "growing_alias": "homePage"
  }
})
```

### 设置页面标题

#### 基于组件导航 (Navigation)

```typescript
let destination = new NavPathInfo(name, {
  "growing_title": "home"
} as Record<string, Object>)
this.pageStack.pushDestination(destination)
```

#### 基于页面路由 (@ohos.router)

```typescript
router.pushUrl({
  url: path,
  params: {
    "growing_title": "home"
  }
})
```

### 设置页面属性

通过手动设置页面属性为该页面添加事件发生时所伴随的维度信息

#### 基于组件导航 (Navigation)

```typescript
let destination = new NavPathInfo(name, {
  "growing_attributes": {
    "key1": "value1",
    "key2": 100
  } as Record<string, Object>
} as Record<string, Object>)
this.pageStack.pushDestination(destination)
```

#### 基于页面路由 (@ohos.router)

```typescript
router.pushUrl({
  url: path,
  params: {
    "growing_attributes": {
      "key1": "value1",
      "key2": 100
    }
  }
})
```

### 元素曝光

为组件打上曝光标记后，当组件满足曝光条件（可见面积占比、最小可见时长）时，SDK 自动发送对应的埋点事件；需在分析云平台事件管理界面创建该埋点事件以及关联事件属性。

元素曝光属于无埋点能力的一部分，需完成【开启无埋点监听】并开启 `autotrackEnabled`。

#### 标记曝光元素

`static trackViewImpression(componentId: string, eventName: string, attributes?: GrowingAttrType)`

标记曝光元素，默认支持重复曝光：元素离开可视区再次进入时会再发送一次

`static stopTrackViewImpression(componentId: string)`

移除组件上的全部曝光标记

组件需通过 `.id()` 设置唯一的 componentId，并在该组件的 `onAppear` 中调用（组件从组件树移除或所在页面销毁后，曝光标记随之移除，再次出现时需重新标记）

| 参数          | 参数类型              | 说明                              |
|-------------|-------------------|---------------------------------|
| `componentId` | `string`          | 组件 id，与组件 `.id()` 一致，需在窗口内唯一 |
| `eventName`   | `string`          | 埋点事件名                          |
| `attributes`  | `GrowingAttrType` | 事件属性（可选）                       |

以下情况不会重复发送：
- 元素一直停留在可视区内，无论停留多久
- 应用退到后台再回到前台，期间元素没有离开过可视区
- 重复标记，但事件名、属性、配置都没有变化（因此列表刷新时对可见元素原样重标一次是安全的）

跳转到其他页面后返回，仍可见的元素会再次曝光。

```typescript
import { GrowingAnalytics } from '@growingio/analytics'

List() {
  ForEach(this.goodsList, (item: Goods) => {
    ListItem() {
      GoodsCell({ goods: item })
    }
    .id('goods_' + item.id)
    .onAppear(() => {
      GrowingAnalytics.trackViewImpression('goods_' + item.id, 'goodsImp', { 'goodsId': item.id })
    })
  }, (item: Goods) => item.id)
}
```

#### 曝光条件

曝光条件通过全局配置统一设置：

| 配置项                           | 参数类型                      | 默认值    | 说明                                         |
|-------------------------------|---------------------------|--------|--------------------------------------------|
| `viewImpressionConfig`        | `GrowingImpressionConfig` | -      | 全局曝光条件，见下表                                 |
| `viewImpressionEnabled`       | `boolean`                 | `true` | 曝光采集开关；`autotrackEnabled` 为 `false` 时曝光同样不采集 |
| `viewImpressionCheckInterval` | `number`                  | `0.5`  | 曝光检测间隔，单位秒，最小 0.1                          |

`GrowingImpressionConfig`：

| 属性                | 参数类型     | 说明                              |
|-------------------|----------|---------------------------------|
| `impressionScale` | `number` | 可见面积占比阈值，有效范围 0~1，默认 0（露出即算曝光） |
| `stayDuration`    | `number` | 最小可见时长，单位秒，默认 0（无需停留）          |

```typescript
let config = new GrowingConfig().NewSaaS(
  'Your AccountId',
  'Your DataSourceId',
  'Your UrlScheme',
  'Your DataCollectionServerHost<Optional>'
)
config.autotrackEnabled = true
config.viewImpressionConfig = GrowingImpressionConfig.create(0.5, 1)
```

配置在 SDK 初始化时读取，初始化之后再改不会生效。

> 注意：
> 可见面积由系统计算，仅考虑祖先组件裁剪与窗口边界，不计算兄弟组件遮挡（如 Stack 叠放、zIndex）、窗口遮挡与旋转

### 最佳实践

#### 设置组件标识

为了确保点击事件中组件路径的准确性，在必要时，可以对自定义组件添加组件唯一标识符。这是由于自定义组件在其有渲染内容时，其类型为`__Common__`

> 相关文档: 
>
> *https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-arkui-framenode-V5#getnodetype12*
>
> *https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-universal-attributes-component-id-V5*

#### 设置页面别名

如果您的应用中有 NavDestination 页面名称相同，或 Router 目标命名路由页面名称相同的情况，请通过设置页面别名来避免数据分析异常

#### Hybrid 页面的无埋点圈选

如果您的应用中有 Hybrid 页面，需要进行无埋点圈选，请在 Hybrid 打通时传入 webviewId，具体请参考【Hybrid 打通】相关文档
