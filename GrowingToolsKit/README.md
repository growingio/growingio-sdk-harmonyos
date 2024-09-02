GrowingIO HarmonyOS NEXT SDK ToolsKit
======
![GrowingIO](https://www.growingio.com/vassets/images/home_v3/gio-logo-primary.svg)

## GrowingIO简介
创立于 2015 年，GrowingIO 是国内领先的一站式数据增长引擎方案服务商，属 StartDT 奇点云集团旗下品牌。**以数据智能分析为核心，GrowingIO 通过构建客户数据平台，打造增长营销闭环**，帮助企业提升数据驱动能力，赋能商业决策、实现业务增长。   
GrowingIO 专注于零售、电商、保险、酒旅航司、教育、内容社区等行业，成立以来，累计服务超过 1500 家企业级客户，获得 LVMH 集团、百事、达能、老佛爷百货、戴尔、lululemon、美素佳儿、宜家、乐高、美的、海尔、安踏、汉光百货、中原地产、上汽集团、广汽蔚来、理想汽车、招商仁和人寿、飞鹤、红星美凯龙、东方航空、滴滴、新东方、喜茶、每日优鲜、奈雪的茶、永辉超市等客户的青睐。

## SDK 简介
**GrowingIO HarmonyOS NEXT SDK ToolsKit** GrowingToolsKit 旨在帮助用户提高集成 GrowingIO SDK 效率，在使用 SDK 的开发过程中，便于排查问题，为用户提供最好的埋点服务。

## 集成文档
### 通过 ohpm 中心仓集成
```c
ohpm install @growingio/tools
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

### 初始化
在初始化 GrowingIO HarmonyOS NEXT SDK 时添加 GrowingToolsKit：

```typescript
let config = new GrowingConfig().NewSaaS(
  'Your AccountId',
  'Your DataSourceId',
  'Your UrlScheme',
  'Your DataCollectionServerHost<Optional>'
)
config.plugins = [new GrowingToolsKit()]
GrowingAnalytics.start(this.context, config)
```

> 注意：请仅在 DEBUG 环境下使用 GrowingToolsKit

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
