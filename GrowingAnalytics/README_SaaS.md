GrowingIO HarmonyOS NEXT SDK
======
![GrowingIO](https://www.growingio.com/vassets/images/home_v3/gio-logo-primary.svg)

## GrowingIO简介
创立于 2015 年，GrowingIO 是国内领先的一站式数据增长引擎方案服务商，属 StartDT 奇点云集团旗下品牌。**以数据智能分析为核心，GrowingIO 通过构建客户数据平台，打造增长营销闭环**，帮助企业提升数据驱动能力，赋能商业决策、实现业务增长。   
GrowingIO 专注于零售、电商、保险、酒旅航司、教育、内容社区等行业，成立以来，累计服务超过 1500 家企业级客户，获得 LVMH 集团、百事、达能、老佛爷百货、戴尔、lululemon、美素佳儿、宜家、乐高、美的、海尔、安踏、汉光百货、中原地产、上汽集团、广汽蔚来、理想汽车、招商仁和人寿、飞鹤、红星美凯龙、东方航空、滴滴、新东方、喜茶、每日优鲜、奈雪的茶、永辉超市等客户的青睐。

## SDK 简介
**GrowingIO HarmonyOS NEXT SDK** 自动采集用户访问事件，并支持手动调用相应埋点 APIs 采集埋点事件。

> 支持 HarmonyOS NEXT，基于 OpenHarmony API 12

## 集成文档
### 通过 ohpm 中心仓集成
```c
ohpm install @growingio/analytics
```

### 通过本地 har 集成
或者，您也可以通过本地 har 集成
首先请联系您的专属项目经理或技术支持，获取最新 SDK har 静态共享包下载地址并下载，再执行以下命令：
```c
ohpm install <您所下载的 har 文件路径>
```

### 配置标准化 OHMUrl

在工程级 build-profile.json5 中配置 useNormalizedOHMUrl 为 true
```typescript
{
  "app": {
    "products": [
      {
        "buildOption": {
          "strictMode": {
            "useNormalizedOHMUrl": true
          }
        }
      }
    ]
  }
}
```

### 配置权限

在 module.json5 中配置所需权限：
```typescript
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET"
  },
  {
    "name": "ohos.permission.GET_NETWORK_INFO"
  }
]
```

### 初始化

在 AbilityStage 的 onCreate 方法中初始化 SDK (Stage 模型)：
```typescript
import AbilityStage from '@ohos.app.ability.AbilityStage'
import type Want from '@ohos.app.ability.Want'
import { GrowingAnalytics, GrowingConfig } from '@growingio/analytics'

// Entry类型的module对应配置的srcEntry
export default class MyAbilityStage extends AbilityStage {
  onCreate(): void {
    // 应用的HAP在首次加载的时，为该Module初始化操作
    this.startAnalytics()
  }
  onAcceptWant(want: Want): string {
    // 仅specified模式下触发
    return 'MyAbilityStage'
  }

  startAnalytics() {
    let config = new GrowingConfig().SaaS(
      'Your AccountId',
      'Your UrlScheme'
    )
    GrowingAnalytics.start(this.context, config)
  }
}
```

### 延迟初始化

若您的应用需要延迟初始化 SDK，请使用 deferStart 进行初始化，需确保传入的是 UIAbilityContext：

```typescript
GrowingAnalytics.deferStart(getContext(this) as common.UIAbilityContext, config)
```

其他初始化配置项见下表，在 start 方法调用前通过`config.<配置项> = 对应值`进行配置：

| 配置项                        | 参数类型 | 默认值 | 说明                                                                                   |
| ----------------------------- | -------- | ------ |--------------------------------------------------------------------------------------|
| accountId                     | string   | -      | 项目 ID (AccountID)，每个应用对应唯一值                                                          |
| urlScheme                     | string   | -      | 自定义 URL Scheme                                                                       |
| dataCollectionServerHost      | string   | -      | 服务端部署后的 ServerHost，默认值为 https://api.growingio.com                                    |
| debugEnabled                  | boolean  | false  | 调试模式，开启后会输出 SDK 日志，在线上环境请关闭                                                          |
| sessionInterval               | number   | 30     | 设置会话后台留存时长，指当前会话在应用进入后台后的最大留存时间，默认为 30 秒。另外，其他情况下也会重新生成一个新的会话，如设置用户 ID 等核心信息，重新打开数据收集等 |
| dataUploadInterval            | number   | 15     | 数据发送的间隔，默认为 15 秒。SDK 会先将事件存入数据库中，然后以每隔默认时间 15 秒向服务器发送事件包                             |
| dataCollectionEnabled         | boolean  | true   | 数据收集，当数据收集关闭时，SDK 将不会再产生事件和上报事件                                                      |
| requestOptions.connectTimeout | number   | 30     | 事件请求尝试建立连接的最大等待时间，默认为 30 秒                                                           |
| requestOptions.transferTimeout| number   | 30     | 事件请求允许传输数据的最大等待时间，默认为 30 秒                                                           |
| dataValidityPeriod            | number   | 7      | 本地未上报的事件数据有效时长，默认为 7 天                                                               |
| encryptEnabled                | boolean  | true   | 事件请求是否开启加密传输，加密上报时，不会明文显示                                                            |
| compressEnabled               | boolean  | true   | 事件请求是否开启压缩传输 (snappy)                                                                |
| hybridAutotrackEnabled        | boolean  | true   | 是否集成无埋点对应的 Hybrid JS SDK                                                             |

### 数据采集 API

#### 初始化是否成功

`static isInitializedSuccessfully(): boolean`

返回是否初始化成功

```typescript
let success = GrowingAnalytics.isInitializedSuccessfully()
```

#### 数据采集开关

`static setDataCollectionEnabled(enabled: boolean)`

打开或关闭数据采集

```typescript
GrowingAnalytics.setDataCollectionEnabled(true)
```

#### 设置登录用户 ID

`static setLoginUserId(userId: string)`

当用户登录之后调用，设置登录用户 ID
如果您的 App 每次用户升级版本时无需重新登录的话，为防止用户本地缓存被清除导致的无法被识别为登录用户，建议在用户每次升级 App 版本后初次访问时重新调用 setLoginUserId 方法

##### 参数说明

| 参数      | 参数类型 | 说明                                      |
| --------- | -------- | ----------------------------------------- |
| `userId`  | `string` | 长度限制大于 0 且小于等于 1000            |

##### 示例

```typescript
GrowingAnalytics.setLoginUserId('user')
```

#### 清除登录用户 ID

`static cleanLoginUserId()`

当用户登出之后调用，清除已经设置的登录用户ID

```typescript
GrowingAnalytics.cleanLoginUserId()
```

#### 设置用户的地理位置

`static setLocation(latitude: number, longitude: number)`

设置用户当前的地理位置，基于WGS-84坐标

##### 参数说明

| 参数        | 参数类型 | 说明           |
| ----------- | -------- | -------------- |
| `latitude`  | `number` | 地理坐标点纬度 |
| `longitude` | `number` | 地理坐标点经度 |

##### 示例

```typescript
const latitude: number = 30.0
const longitude: number = 120.0
GrowingAnalytics.setLocation(latitude, longitude)
```

#### 清除用户的地理位置

`static cleanLocation()`

清除用户当前的地理位置

```typescript
GrowingAnalytics.cleanLocation()
```

#### 设置埋点事件

`static track(eventName: string, attributes: GrowingAttrType = {})`

发送一个埋点事件；注意：在添加发送的埋点事件代码之前，需在分析云平台事件管理界面创建埋点事件以及关联事件属性

:::info
`GrowingAttrType` 为 SDK 限定的事件属性类型，实际为：

```
{ [key: string]: string | number | boolean | string[] | number[] | boolean[] }
```
:::

##### 参数说明

| 参数         | 参数类型          | 说明                                                         |
| ------------ | ----------------- | ------------------------------------------------------------ |
| `eventName`  | `string`          | 事件名，事件标识符                                           |
| `attributes` | `GrowingAttrType` | 事件发生时所伴随的属性信息；当事件属性关联有维度表时，属性值为对应的维度表模型 ID(记录 ID)（可选） |

##### 示例

```typescript
GrowingAnalytics.track('buyProduct1')

GrowingAnalytics.track('buyProduct2', {
  'name': 'apple',
  'money': 1000,
  'num': 100,
  'from': ['sichuan', 'guizhou', 'hunan']
})

let attributes: GrowingAttrType = {}
attributes['a'] = 'b'
GrowingAnalytics.track('buyProduct3', attributes)
```

#### 事件计时器

`static trackTimerStart(eventName: string): string`

初始化一个事件计时器，参数为计时事件的事件名称，返回值为该事件计时器唯一标识

`static trackTimerPause(timerId: string)`

暂停事件计时器，参数为 trackTimer 返回的唯一标识

`static trackTimerResume(timerId: string)`

恢复事件计时器，参数为 trackTimer 返回的唯一标识

`static trackTimerEnd(timerId: string, attributes: GrowingAttrType = {})`

停止事件计时器，参数为 trackTimer 返回的唯一标识。调用该接口会自动触发删除定时器。

`static removeTimer(timerId: string)`

删除事件计时器，参数为 trackTimer 返回的唯一标识。
该接口会将标识为 timerId 的计时器置为空。调用停止计时器接口，会自动触发该接口。注意移除时不论计时器处于什么状态，都不会发送事件。

`static clearTrackTimer()`

清除所有已经注册的事件计时器。
存在所有计时器需要清除时调用。注意移除时不论计时器处于什么状态，都不会发送事件。

##### 参数说明

| 参数         | 参数类型          | 说明                                                         |
| ------------ | ----------------- | ------------------------------------------------------------ |
| `eventName`  | `string`          | 事件名，事件标识符                                           |
| `attributes` | `GrowingAttrType` | 事件发生时所伴随的属性信息；当事件属性关联有维度表时，属性值为对应的维度表模型 ID(记录 ID)（可选） |
| `timerId`    | `string`          | 计时器唯一标识符，由`trackTimerStart`返回                    |

##### 示例

```typescript
let timerId = GrowingAnalytics.trackTimerStart('eventName')
GrowingAnalytics.trackTimerPause(timerId)
GrowingAnalytics.trackTimerResume(timerId)
GrowingAnalytics.trackTimerEnd(timerId)
GrowingAnalytics.trackTimerEnd(timerId, {
  'property': 'value',
  'property2': 100
})
GrowingAnalytics.removeTimer(timerId)
GrowingAnalytics.clearTrackTimer()
```

> 注意：
>
> endTimer 时发送 CUSTOM 事件上报数据：
>
> - eventName 埋点事件标识符（trackTimerStart 传入）
> - attributes 用户自定义事件属性（trackTimerEnd 传入）
> - event_duration 事件时长 （SDK 内部根据 timerId 自动计算获取 ）
    >   event_duration 按照秒上报，小数点精度保证到毫秒
    >   event_duration 变量及其值会自动添加在 attributes 中
    >   event_duration 时间统计不会计算后台时间
> - eventName 对应的埋点事件需要在平台中**绑定**标识符为 event_duration， 且类型为小数的事件属性

#### 设置登录用户变量

`static setPeopleVariable(attributes: GrowingAttrType)`

以登录用户的身份定义登录用户变量，用于登录用户信息相关分析，在添加代码之前必须在打点管理界面上创建登录用户变量

##### 参数说明

| 参数         | 参数类型          | 说明     |
| ------------ | ----------------- |--------|
| `attributes` | `GrowingAttrType` | 用户变量信息 |

##### 示例

```typescript
GrowingAnalytics.setPeopleVariable({
  'name': 'ben',
  'age': 30
})
```

#### 设置访问用户变量

`static setVisitor(attributes: GrowingAttrType)`

以访问用户的身份定义访问用户变量，用于访问用户信息相关分析，也可用于A/B测试上传标签。在添加代码之前必须在打点管理界面上创建访问用户变量

##### 参数说明

| 参数         | 参数类型          | 说明     |
| ------------ | ----------------- |--------|
| `attributes` | `GrowingAttrType` | 用户变量信息 |

##### 示例

```typescript
GrowingAnalytics.setVisitor({
  'name': 'ben',
  'age': 30
})
```

#### 设置转化变量

`static setEvar(attributes: GrowingAttrType)`

发送一个转化信息用于高级归因分析，在添加代码之前必须在打点管理界面上创建转化变量

##### 参数说明

| 参数         | 参数类型          | 说明     |
| ------------ | ----------------- |--------|
| `attributes` | `GrowingAttrType` | 转化变量信息 |

##### 示例

```typescript
GrowingAnalytics.setEvar({
  'campaignOwner': 'Li Si',
  'campaignId': 12345
})
```

#### 获取设备 ID

`static getDeviceId(): string`

获取设备 id，又称为匿名用户 id，SDK 自动生成用来定义唯一设备

```typescript
let deviceId = GrowingAnalytics.getDeviceId()
```

#### 事件通用属性

`static setGeneralProps(props: GrowingAttrType)`

为所有事件设置通用属性，多次调用，相同字段的新值将覆盖旧值；需在分析云平台事件管理界面关联事件属性

`static removeGeneralProps(keys: string[])`

移除指定字段的事件通用属性

`static clearGeneralProps()`

移除所有事件通用属性

`static setDynamicGeneralProps(generator: () => GrowingAttrType)`

设置动态通用属性

##### 参数说明

| 参数    | 参数类型          | 说明                                                         |
| ------- | ----------------- | ------------------------------------------------------------ |
| `props` | `GrowingAttrType` | 事件发生时所伴随的属性信息；当事件属性关联有维度表时，属性值为对应的维度表模型 ID(记录 ID) |

##### 示例

```typescript
// 设置通用属性
GrowingAnalytics.setGeneralProps({
  'prop1': 10,
  'prop2': 'name',
  'prop3': [1, 2, 3],
  'prop4': ['a', 'b', 'c'],
  'name': 'banana'
})
// 清除指定字段的通用属性
GrowingAnalytics.removeGeneralProps(['prop1', 'prop2', 'prop3'])
// 清除通用属性
GrowingAnalytics.clearGeneralProps()
// 设置动态通用属性
GrowingAnalytics.setDynamicGeneralProps(() => {
  return {'dynamicProp' : Util.formatDate(new Date()) }
})
// 清除动态通用属性
GrowingAnalytics.setDynamicGeneralProps(() => ({}))
```

### Hybrid 打通

```typescript
static createHybridProxy(controller: webview.WebviewController): {
object: object;
name: string;
methodList: Array<string>;
controller: WebviewController;
} | undefined

static javaScriptOnDocumentStart(
  scriptRules?: Array<string>,
  saasJavaScriptConfig?: {
    hashTagEnabled: boolean;
    impEnabled: boolean;
}): Array<ScriptItem>

static javaScriptOnDocumentEnd(scriptRules?: Array<string>): Array<ScriptItem>
```

##### 参数说明

| 参数    | 参数类型      | 默认值                      | 说明 |
| ------- |-----------| -------------------------- | ------- |
| `hashTagEnabled` | `boolean` | false | 设置是否启用 Hash Tag |
| `impEnabled` | `boolean` | false | 设置是否发送元素的展现次数（浏览量、曝光量） |

##### 示例

在 webView 控件中注入 hybrid 实现打通 (javaScriptAccess 和 domStorageAccess 需同时设置为 true)，并在 onDocumentStart 和 onDocumentEnd 2 个时机注入 SDK 提供的脚本：
```typescript
let url = 'https://www.example.com'
Web({ src: url, controller: this.controller})
  .javaScriptAccess(true)
  .domStorageAccess(true)
  .javaScriptProxy(GrowingAnalytics.createHybridProxy(this.controller))
  .javaScriptOnDocumentStart(GrowingAnalytics.javaScriptOnDocumentStart())
  .javaScriptOnDocumentEnd(GrowingAnalytics.javaScriptOnDocumentEnd())
```

如果您的 H5 页面集成的是仅埋点的 Hybrid JS SDK (`gio_hybrid_track.js`)，那么需要修改 SDK 的初始化配置项 `hybridAutotrackEnabled` 为 `false`, 且仅注入 hybrid：
```typescript
// 初始化配置项hybridAutotrackEnabled设置为false
startAnalytics() {
  let config = new GrowingConfig().SaaS(
    'Your AccountId',
    'Your UrlScheme'
  )
  config.hybridAutotrackEnabled = false
  GrowingAnalytics.start(this.context, config)
}

//仅注入hybrid
let url = 'https://www.example.com'
Web({ src: url, controller: this.controller})
  .javaScriptAccess(true)
  .domStorageAccess(true)
  .javaScriptProxy(GrowingAnalytics.createHybridProxy(this.controller))
```

如果您需要注入多个 JavaScript 对象或者通过 permission 配置权限管控，请在 `onControllerAttached` 回调中使用 `registerJavaScriptProxy` 进行注入 hybrid：
```typescript
let url = 'https://www.example.com'
// 通过permission配置权限管控
let permission = 'Your Permission'
Web({ src: url, controller: this.controller})
  .javaScriptAccess(true)
  .domStorageAccess(true)
  .javaScriptOnDocumentStart(GrowingAnalytics.javaScriptOnDocumentStart()) // H5页面集成的是仅埋点的Hybrid JS SDK则不需要此操作
  .javaScriptOnDocumentEnd(GrowingAnalytics.javaScriptOnDocumentEnd()) // H5页面集成的是仅埋点的Hybrid JS SDK则不需要此操作
  .onControllerAttached(() => {
    let proxy = GrowingAnalytics.createHybridProxy(this.controller)
    if (proxy) {
      this.controller.registerJavaScriptProxy(proxy.object, proxy.name, proxy.methodList, [], permission)
    }
    
    // 如果需要注入多个JavaScript对象
    let yourProxy = new YourProxy()
    if (yourProxy) {
      this.controller.registerJavaScriptProxy(yourProxy.object, yourProxy.name, yourProxy.methodList, yourProxy.asyncMethodList, permission)
    }
  })
```

> 当前 Hybrid 打通不支持点击事件、表单提交事件等无埋点事件

## License
```
Copyright (C) 2024 Beijing Yishu Technology Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
