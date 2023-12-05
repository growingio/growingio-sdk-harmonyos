GrowingIO HarmonyOS SDK
======
![GrowingIO](https://www.growingio.com/vassets/images/home_v3/gio-logo-primary.svg)

## GrowingIO简介
创立于 2015 年，GrowingIO 是国内领先的一站式数据增长引擎方案服务商，属 StartDT 奇点云集团旗下品牌。**以数据智能分析为核心，GrowingIO 通过构建客户数据平台，打造增长营销闭环**，帮助企业提升数据驱动能力，赋能商业决策、实现业务增长。   
GrowingIO 专注于零售、电商、保险、酒旅航司、教育、内容社区等行业，成立以来，累计服务超过 1500 家企业级客户，获得 LVMH 集团、百事、达能、老佛爷百货、戴尔、lululemon、美素佳儿、宜家、乐高、美的、海尔、安踏、汉光百货、中原地产、上汽集团、广汽蔚来、理想汽车、招商仁和人寿、飞鹤、红星美凯龙、东方航空、滴滴、新东方、喜茶、每日优鲜、奈雪的茶、永辉超市等客户的青睐。

## SDK 简介
**GrowingIO HarmonyOS SDK** 自动采集用户访问事件，并支持手动调用相应埋点 APIs 采集埋点事件。

## 集成文档
### 通过 ohpm 集成
```c
ohpm install @growingio/analytics
```

### 初始化
在 EntryAbility.ets 的 onCreate 方法中初始化 SDK：
```typescript
onCreate(want, launchParam) {
    let config = new GrowingConfig(
      'Your AccountId', 
      'Your DataSourceId', 
      'Your UrlScheme', 
      'Your DataCollectionServerHost<Optional>'
    )
    GrowingAnalytics.start(this.context, config)
}
```
> 其中 accountId/dataSourceId/urlScheme 为必填项，dataCollectionServerHost 为可选项

其他初始化配置项见下表，在 start 方法调用前通过`config.<配置项> = 对应值`进行配置：

| 配置项                   | 参数类型 | 默认值 | 说明                                                         |
| ------------------------ | -------- | ------ | ------------------------------------------------------------ |
| accountId                | string   | -      | 项目 ID (AccountID)，每个应用对应唯一值                      |
| dataSourceId             | string   | -      | 应用的 DataSourceId，唯一值                                  |
| urlScheme                | string   | -      | 自定义 URL Scheme                                            |
| dataCollectionServerHost | string   | -      | 服务端部署后的 ServerHost，默认值为 https://napi.growingio.com |
| debugEnabled             | boolean  | false  | 调试模式，开启后会输出 SDK 日志，在线上环境请关闭            |
| sessionInterval          | number   | 30     | 设置会话后台留存时长，指当前会话在应用进入后台后的最大留存时间，默认为 30 秒。另外，其他情况下也会重新生成一个新的会话，如设置用户 ID 等核心信息，重新打开数据收集等 |
| dataCollectionEnabled    | boolean  | true   | 数据收集，当数据收集关闭时，SDK 将不会再产生事件和上报事件   |
| idMappingEnabled         | boolean  | false  | 是否开启多用户身份上报                                       |

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

`static async setLoginUserId(userId: string, userKey: string = '')`

当用户登录之后调用，设置登录用户 ID 和用户 Key
如果您的 App 每次用户升级版本时无需重新登录的话，为防止用户本地缓存被清除导致的无法被识别为登录用户，建议在用户每次升级 App 版本后初次访问时重新调用 setLoginUserId 方法

> **设置用户 Key 需在初始化 SDK 时设置 `config.idMappingEnabled = true`**

##### 参数说明

| 参数      | 参数类型 | 说明                                      |
| --------- | -------- | ----------------------------------------- |
| `userId`  | `string` | 长度限制大于 0 且小于等于 1000            |
| `userkey` | `string` | 长度限制大于 0 且小于等于 1000，默认为 '' |

##### 示例

```typescript
GrowingAnalytics.setLoginUserId('user')
GrowingAnalytics.setLoginUserId('user', 'harmony')
```

#### 清除登录用户 ID

`static async cleanLoginUserId()`

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

`static async track(eventName: string, attributes: { [key: string]: string | number | boolean | string[] | number[] } = {})`

发送一个埋点事件；注意：在添加发送的埋点事件代码之前，需在分析云平台事件管理界面创建埋点事件以及关联事件属性

##### 参数说明

| 参数         | 参数类型                                                                                                | 说明                                                    |
| ------------ |-----------------------------------------------------------------------------------------------------|-------------------------------------------------------|
| `eventName`  | `string`                                                                                            | 事件名，事件标识符                                             |
| `attributes` | <code>{ [key: string]: string &#124; number &#124; boolean &#124; string[] &#124; number[] }</code> | 事件发生时所伴随的属性信息；当事件属性关联有维度表时，属性值为对应的维度表模型 ID(记录 ID)（可选） |

##### 示例

```typescript
GrowingAnalytics.track('buyProduct1')

GrowingAnalytics.track('buyProduct2', {
  'name': 'apple',
  'money': 1000,
  'num': 100,
  'from': ['sichuan', 'guizhou', 'hunan']
})
```

> 详细使用示例：[埋点事件示例](https://growingio.github.io/growingio-sdk-docs/knowledge/basicknowledge/trackEventUse#埋点事件示例)

#### 事件计时器

`static async trackTimerStart(eventName: string): Promise<string>`

初始化一个事件计时器，参数为计时事件的事件名称，返回值为该事件计时器唯一标识

`static async trackTimerPause(timerId: string)`

暂停事件计时器，参数为 trackTimer 返回的唯一标识

`static async trackTimerResume(timerId: string)`

恢复事件计时器，参数为 trackTimer 返回的唯一标识

`static async trackTimerEnd(timerId: string, attributes: { [key: string]: string | number | boolean | string[] | number[] } = {})`

停止事件计时器，参数为 trackTimer 返回的唯一标识。调用该接口会自动触发删除定时器。

`static removeTimer(timerId: string)`

删除事件计时器，参数为 trackTimer 返回的唯一标识。
该接口会将标识为 timerId 的计时器置为空。调用停止计时器接口，会自动触发该接口。注意移除时不论计时器处于什么状态，都不会发送事件。

`static clearTrackTimer()`

清除所有已经注册的事件计时器。
存在所有计时器需要清除时调用。注意移除时不论计时器处于什么状态，都不会发送事件。

##### 参数说明

| 参数         | 参数类型                                                                                                | 说明                                                    |
| ------------ |-----------------------------------------------------------------------------------------------------|-------------------------------------------------------|
| `eventName`  | `string`                                                                                            | 事件名，事件标识符                                             |
| `attributes` | <code>{ [key: string]: string &#124; number &#124; boolean &#124; string[] &#124; number[] }</code> | 事件发生时所伴随的属性信息；当事件属性关联有维度表时，属性值为对应的维度表模型 ID(记录 ID)（可选） |
| `timerId`    | `string`                                                                                            | 计时器唯一标识符，由`trackTimerStart`返回                         |

##### 示例

```typescript
let timerId = await GrowingAnalytics.trackTimerStart('eventName')
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

#### 设置登录用户属性

`static async setLoginUserAttributes(attributes: { [key: string]: string | number | boolean | string[] | number[] })`

以登录用户的身份定义登录用户属性，用于用户信息相关分析

##### 参数说明

| 参数         | 参数类型                                                                                                | 说明         |
| ------------ |-----------------------------------------------------------------------------------------------------| ------------ |
| `attributes` | <code>{ [key: string]: string &#124; number &#124; boolean &#124; string[] &#124; number[] }</code> | 用户属性信息 |

##### 示例

```typescript
GrowingAnalytics.setLoginUserAttributes({
  'name': 'ben',
  'age': 30
})
```

> 详细使用示例：[用户属性事件示例](https://growingio.github.io/growingio-sdk-docs/knowledge/basicknowledge/trackEventUse#用户属性事件示例)

#### 获取设备 ID

`static async getDeviceId(): Promise<string>`

获取设备 id，又称为匿名用户 id，SDK 自动生成用来定义唯一设备

```typescript
let deviceId = await GrowingAnalytics.getDeviceId()
```

#### 埋点事件通用属性

`static setGeneralProps(props: { [key: string]: string | number | boolean | string[] | number[] })`

为所有自定义埋点事件设置通用属性，多次调用，相同字段的新值将覆盖旧值；需在分析云平台事件管理界面关联事件属性

`static removeGeneralProps(keys: string[])`

移除指定字段的埋点事件通用属性

`static clearGeneralProps()`

移除所有埋点事件通用属性

##### 参数说明

| 参数    | 参数类型                                                                                                | 说明                                                |
| ------- |-----------------------------------------------------------------------------------------------------|---------------------------------------------------|
| `props` | <code>{ [key: string]: string &#124; number &#124; boolean &#124; string[] &#124; number[] }</code> | 事件发生时所伴随的属性信息；当事件属性关联有维度表时，属性值为对应的维度表模型 ID(记录 ID) |

##### 示例

```typescript
GrowingAnalytics.setGeneralProps({
  'prop1': 10,
  'prop2': 'name',
  'prop3': [1, 2, 3],
  'prop4': ['a', 'b', 'c'],
  'name': 'banana'
})
GrowingAnalytics.removeGeneralProps(['prop1', 'prop2', 'prop3'])
GrowingAnalytics.clearGeneralProps()
```

## 约束与限制

在下述版本验证通过：

- DevEco Studio: 3.1.0.501, SDK: API9 Release(3.2.12.5)

## License
```
Copyright (C) 2023 Beijing Yishu Technology Co., Ltd.

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
