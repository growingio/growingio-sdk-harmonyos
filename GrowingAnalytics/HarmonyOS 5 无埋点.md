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

为组件打上曝光标记后，当组件满足可见条件（可见面积占比、停留时长）时，SDK 自动发送对应的埋点事件；需在分析云平台事件管理界面创建该埋点事件以及关联事件属性。

元素曝光属于无埋点能力的一部分，需完成【开启无埋点监听】并开启 `autotrackEnabled`。

#### 标记曝光元素

`static trackViewImpression(componentId: string, eventName: string, attributes?: GrowingAttrType, identifier?: string, config?: GrowingImpressionConfig)`

组件需通过 `.id()` 设置唯一的 componentId，并在该组件的 `onAppear` 中调用（组件从组件树移除或所在页面销毁后，曝光标记随之移除，再次出现时需重新标记）

| 参数          | 参数类型                      | 说明                                                                                     |
|-------------|---------------------------|----------------------------------------------------------------------------------------|
| `componentId` | `string`                  | 组件 id，与组件 `.id()` 一致，需在窗口内唯一                                                         |
| `eventName`   | `string`                  | 埋点事件名                                                                                 |
| `attributes`  | `GrowingAttrType`         | 事件属性（可选）                                                                              |
| `identifier`  | `string`                  | 曝光标识（可选）。同一组件可挂载多个 identifier 不同的曝光标记；配置为不可重复曝光时必须传入，否则按可重复曝光处理                    |
| `config`      | `GrowingImpressionConfig` | 单元素曝光配置（可选），不传则使用全局配置 `GrowingConfig.viewImpressionConfig`                                |

`GrowingImpressionConfig`：

| 属性                | 参数类型      | 说明                                           |
|-------------------|-----------|----------------------------------------------|
| `impressionScale` | `number`  | 可见面积占比阈值，有效范围 0~1，默认 0（露出即算曝光）              |
| `stayDuration`    | `number`  | 最小可见时长，单位秒，默认 0（无需停留）                       |
| `repeatable`      | `boolean` | 是否允许同一元素多次曝光，默认 `true`；为 `false` 时同一 identifier 只曝光一次 |

曝光规则：
- 元素离开可视区后再次进入，会再次曝光（`repeatable` 为 `false` 的元素除外）
- 跳转到其他页面后返回，仍可见的元素会再次曝光
- 退到后台再回到前台，不会再次曝光

```typescript
import { GrowingAnalytics, GrowingImpressionConfig } from '@growingio/analytics'

List() {
  ForEach(this.goodsList, (item: Goods) => {
    ListItem() {
      GoodsCell({ goods: item })
    }
    .id('goods_' + item.id)
    .onAppear(() => {
      GrowingAnalytics.trackViewImpression('goods_' + item.id, 'goodsImp', { 'goodsId': item.id },
        'goods_' + item.id, GrowingImpressionConfig.create(0.5, 1, false))
    })
  }, (item: Goods) => item.id)
}
```

#### 更新与移除

`static updateViewImpressionAttributes(componentId: string, attributes: GrowingAttrType, identifier?: string)`

仅更新已标记元素的属性，不重置曝光状态、不触发重新曝光

`static stopTrackViewImpression(componentId: string, identifier?: string)`

移除组件上的曝光标记；传入 identifier 时只移除该标记，否则移除全部

`static resetViewImpressionState(identifier: string)` / `static resetAllViewImpressionState()`

清除"已曝光"记录，之后对应元素可再次曝光，仅对 `repeatable` 为 `false` 的元素有意义，适用于下拉刷新、切换数据源等场景

#### 曝光回调

`static addViewImpressionDelegate(delegate: GrowingImpressionDelegate)` / `static removeViewImpressionDelegate(delegate: GrowingImpressionDelegate)`

回调均在 UI 线程同步执行，实现中不要做耗时操作；不再需要时请调用 `removeViewImpressionDelegate` 移除

```typescript
let delegate: GrowingImpressionDelegate = {
  // 返回 false 则本次不发送曝光事件，元素离开可视区再次进入时会重新询问
  viewImpressionShouldTrack: (componentId: string, eventName: string, identifier?: string): boolean => {
    return true
  },
  // 曝光时刻求值的动态属性，与标记时的属性合并，同名键以动态属性为准
  viewImpressionDynamicAttributes: (componentId: string, eventName: string,
    identifier?: string): GrowingAttrType | undefined => {
    return { 'impTime': Date.now() }
  },
  // 曝光事件已生成
  viewImpressionDidTrack: (componentId: string, eventName: string, identifier?: string) => {
  }
}
GrowingAnalytics.addViewImpressionDelegate(delegate)
```

#### 全局配置

| 配置项                           | 参数类型                      | 默认值   | 说明                                         |
|-------------------------------|---------------------------|-------|--------------------------------------------|
| `viewImpressionEnabled`       | `boolean`                 | `true` | 曝光采集开关；`autotrackEnabled` 为 `false` 时曝光同样不采集 |
| `viewImpressionConfig`        | `GrowingImpressionConfig` | -     | 全局默认曝光配置                                   |
| `viewImpressionCheckInterval` | `number`                  | `0.5` | 曝光检测间隔，单位秒，最小 0.1                          |

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
