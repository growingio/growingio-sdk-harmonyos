# GrowingToolsKit 模块 - 智能体指南

本模块是 GrowingIO HarmonyOS SDK 的**开发者工具模块**（`@growingio/tools`），提供调试和检查工具。

## 模块概述

GrowingToolsKit 模块是一个插件，为开发者提供：
- 悬浮调试图标，快速访问
- 实时事件检查
- 网络请求监控
- SDK 配置查看
- 多追踪器信息
- 事件数据库检查

## 模块结构

```
GrowingToolsKit/
├── src/main/ets/
│   ├── components/
│   │   ├── interfaces/
│   │   │   └── GrowingToolsKit.ets    # 主插件类
│   │   ├── core/
│   │   │   ├── NavStackManager.ets    # 导航管理
│   │   │   └── TrackersInfo.ets       # 多追踪器信息存储
│   │   ├── event/
│   │   │   ├── EventDatabase.ets      # ToolsKit 事件数据库
│   │   │   └── EventPersistence.ets   # 事件持久化模型
│   │   ├── network/
│   │   │   └── RequestPersistence.ets # 网络请求模型
│   │   ├── pages/
│   │   │   ├── EntryIcon.ets          # 悬浮入口按钮
│   │   │   ├── Home.ets               # ToolsKit 主页
│   │   │   ├── EventsList.ets         # 事件检查页面
│   │   │   ├── Realtime.ets           # 实时事件流
│   │   │   ├── SdkInfo.ets            # SDK 信息页面
│   │   │   ├── NetFlow.ets            # 网络监控
│   │   │   └── FPSCanvas.ets          # FPS 显示
│   │   ├── utils/
│   │   │   ├── Constants.ets          # ToolsKit 常量
│   │   │   ├── LogUtil.ets            # 日志工具
│   │   │   └── SharedPreferences.ets  # 偏好存储
│   │   └── views/
│   │       ├── Common.ets             # 通用 UI 组件
│   │       ├── ModuleButton.ets       # 模块按钮
│   │       ├── TrackerTabBar.ets      # 追踪器选择器
│   │       ├── PullToRefresh.ets      # 下拉刷新
│   │       └── PullToRefreshConfigurator.ets
│   └── test/, ohosTest/               # 测试
├── oh-package.json5                   # 包: @growingio/tools
└── BuildProfile.ets                   # 构建版本信息
```

## 核心文件

### GrowingToolsKit.ets
主插件类，包含与 `PluginsInterface` 一致的方法：

```typescript
export class GrowingToolsKit {
  constructor(options?: GrowingToolsKitOptions)
  
  // 插件生命周期回调
  onSDKWillInitialize()
  onSDKDidInitialize(config: GTKConfig, version: string)
  onStartSubTracker(trackerId: string, config: GTKConfig)
  afterWindowStageCreate(context: UIAbilityContext, windowStage: WindowStage)
  onEventWroteToDisk(event: GTKEventPersistence, eventScene: number)
  onEventsRemoveFromDisk(events: string[])
  onResponseReceive(response: rcp.Response)
  setAutotrackStatusFetcher(fetcher: () => boolean)
  onDeferStart()
  
  // 兼容旧版本 SDK (<=2.1.0)
  onWindowStageCreate(ability: UIAbility, windowStage: WindowStage)
}

interface GrowingToolsKitOptions {
  x?: number           // 悬浮图标 X 位置（默认: 16）
  y?: number           // 悬浮图标 Y 位置（默认: 400）
  useInRelease?: boolean  // 发布模式启用（默认: false）
}
```

## 功能特性

### 1. 悬浮调试图标
- 可拖拽的悬浮按钮覆盖层
- 点击打开 ToolsKit 面板
- 不使用时自动最小化
- 通过构造函数选项自定义位置

### 2. 事件检查（EventsList）
- 查看所有追踪的事件
- 按追踪器实例筛选
- 事件详情视图（JSON 格式）
- 复制事件数据到剪贴板

### 3. 实时事件流（Realtime）
- 实时事件监控
- 自动滚动新事件
- 事件类型颜色编码

### 4. SDK 信息（SdkInfo）
- SDK 版本显示
- 配置详情
- 追踪器列表及状态
- 设备信息

### 5. 网络监控（NetFlow）
- HTTP 请求/响应日志
- 请求时间信息
- 响应状态码
- 请求/响应体检查

## 使用方法

### 基本用法
```typescript
import { GrowingToolsKit } from '@growingio/tools'

// 在 AbilityStage setupAnalytics()
let config = new GrowingConfig().NewSaaS(...)
config.plugins = [new GrowingToolsKit()]
GrowingAnalytics.configure(config)
```

### 自定义位置
```typescript
config.plugins = [new GrowingToolsKit({ x: 100, y: 200 })]
```

### 发布模式启用
```typescript
// 警告：仅用于调试发布版本
config.plugins = [new GrowingToolsKit({ useInRelease: true })]
```

## 与 SDK 集成

ToolsKit 通过插件系统与 GrowingAnalytics 集成：

```typescript
// SDK 自动调用以下回调：

// 1. SDK 初始化开始
onSDKWillInitialize()

// 2. SDK 初始化完成
onSDKDidInitialize(config, version)

// 3. 子追踪器启动
onStartSubTracker(trackerId, config)

// 4. 窗口阶段创建（UI 就绪）
afterWindowStageCreate(context, windowStage)
  // 创建悬浮子窗口
  // 初始化 ToolsKit 数据库

// 5. 事件写入磁盘
onEventWroteToDisk(event, eventScene)
  // 复制事件到 ToolsKit 数据库供显示

// 6. 事件发送到服务器
onEventsRemoveFromDisk(events)
  // 更新 ToolsKit 中的事件状态

// 7. HTTP 响应接收
onResponseReceive(response)
  // 记录网络请求
```

## 数据模型

### GTKEventPersistence
```typescript
interface GTKEventPersistence {
  uuid: string
  data: string  // JSON 字符串
  eventType: string
  sdkVersion: string
  accountId: string
  dataSourceId: string
}
```

### GTKConfig（SDK 配置副本）
```typescript
interface GTKConfig {
  mode: ConfigMode
  accountId: string
  dataSourceId: string
  urlScheme: string
  dataCollectionServerHost: string
  // ... 其他配置字段
  copy(): GTKConfig
}
```

### RequestPersistence
```typescript
interface RequestPersistence {
  url: string
  method: string
  timestamp: number
  statusCode: number
  // ... 其他字段
}
```

## 窗口管理

ToolsKit 创建悬浮子窗口覆盖层：

```typescript
// 创建名为 "GrowingToolsKitSubWindow" 的子窗口
windowStage.createSubWindow(SUB_WINDOW_NAME)
  .then(subWindow => {
    subWindow.loadContentByName(routeName, localStorage)
    subWindow.setWindowBackgroundColor(GTKColor.blackAlpha)
    subWindow.moveWindowTo(x, y)
    subWindow.resize(56vp, 56vp)  // 悬浮图标大小
    subWindow.showWindow()
    subWindow.setWindowLayoutFullScreen(true)
  })
```

## 数据库

ToolsKit 维护自己的 SQLite 数据库：
- 存储从主 SDK 复制的事件
- 存储网络请求日志
- 与 SDK 的 EventDatabase 分离

## 常量

```typescript
// 窗口名称
const SUB_WINDOW_NAME = 'GrowingToolsKitSubWindow'

// 颜色
const GTKColor = {
  blackAlpha: '#00000000',
  primary: '#007DFF',
  // ...
}

// 事件场景
enum GTKEventScene {
  Native = 0,
  Hybrid = 1,
  Flutter = 2
}
```

## 依赖项

```json
{
  "dependencies": {
    "snappyjs": "0.7.0",
    "@ohos/protobufjs": "2.1.0",
    "long": "5.2.1"
  }
}
```

注意：ToolsKit 依赖以上库，这些依赖在 oh-package.json5 中显式声明。部分依赖与 GrowingAnalytics 共享。

## 构建信息

- **包**: `@growingio/tools`
- **许可证**: Apache License 2.0
- **主入口**: `Index.ets`

## 重要说明

1. **仅调试模式**: 默认情况下，ToolsKit 仅在调试构建中工作（`appInfo.debug === true`）
2. **插件架构**: 必须添加到 `config.plugins` 数组
3. **自动初始化**: 添加到插件后无需手动初始化
4. **窗口权限**: 需要创建子窗口的权限
5. **性能**: 对应用性能影响最小；事件异步复制
