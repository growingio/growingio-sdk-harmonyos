# DeviceInfo & AppInfo 逻辑详解

> **模块归属**: 核心模块 (core)  
> **源文件**: 
> - `GrowingAnalytics/src/main/ets/components/core/DeviceInfo.ets`
> - `GrowingAnalytics/src/main/ets/components/core/AppInfo.ets`

本文档详细描述 GrowingIO HarmonyOS SDK 的设备信息和应用信息采集逻辑。

## 目录

- [概述](#概述)
- [DeviceInfo 设备信息](#deviceinfo-设备信息)
- [AppInfo 应用信息](#appinfo-应用信息)
- [字段忽略机制](#字段忽略机制)
- [网络状态监听](#网络状态监听)

---

## 概述

`DeviceInfo` 和 `AppInfo` 负责采集设备和应用的基本信息，这些信息会填充到每个上报的事件中，用于数据分析和用户画像构建。

### 信息采集流程

```
SDK 初始化
    │
    ▼
┌─────────────────────┐
│ AppInfo.initAppInfo │
│ 应用信息            │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ DeviceInfo.init     │
│ DeviceInfo          │
│ 设备信息            │
└────────┬────────────┘
         │
         ▼
    信息存入静态变量
         │
         ▼
┌─────────────────────┐
│ EventBuilder.build  │
│ 填充到事件          │
└─────────────────────┘
```

---

## DeviceInfo 设备信息

### 采集字段

| 字段 | 类型 | 说明 | 来源 |
|------|------|------|------|
| `deviceId` | string | 设备唯一标识 | SharedPreferences / UUID 生成 |
| `platform` | string | 平台名称 | 常量: 'HarmonyOS' |
| `platformVersion` | string | 系统版本 | `@ohos.deviceInfo` |
| `screenHeight` | number | 屏幕高度 | `@ohos.display` |
| `screenWidth` | number | 屏幕宽度 | `@ohos.display` |
| `orientation` | string | 屏幕方向 | `@ohos.display` |
| `deviceBrand` | string | 设备品牌 | `@ohos.deviceInfo` |
| `deviceModel` | string | 设备型号 | `@ohos.deviceInfo` |
| `deviceType` | string | 设备类型 | `@ohos.deviceInfo` |
| `language` | string | 系统语言 | `@ohos.i18n` |
| `timezoneOffset` | string | 时区偏移 | `Date.getTimezoneOffset()` |
| `networkState` | string | 网络状态 | `@ohos.net.connection` |

### 默认值

```typescript
static defaultScreenHeight: number = 1260
static defaultScreenWidth: number = 2720
static defaultPlatformVersion: string = '5.0.0'
static defaultDeviceBrand: string = 'HUAWEI'
static defaultDeviceModel: string = '-'
static defaultDeviceType: string = 'phone'
```

### 初始化流程

```typescript
static initDeviceInfo(context: GrowingContext) {
  // 1. 设置平台
  DeviceInfo.platform = SDK_PLATFORM  // 'HarmonyOS'

  // 2. 屏幕信息
  if (DeviceInfo.isNotIgnoreField(context, IgnoreFields.ScreenSize)) {
    let displayInfo = niceTry(() => display.getDefaultDisplaySync())
    if (displayInfo) {
      DeviceInfo.screenHeight = displayInfo.height
      DeviceInfo.screenWidth = displayInfo.width
      // 方向判断
      let isPortrait = displayInfo.orientation == 0 || displayInfo.orientation == 2
      DeviceInfo.orientation = isPortrait ? 'PORTRAIT' : 'LANDSCAPE'
    }
  } else {
    DeviceInfo.screenHeight = undefined
    DeviceInfo.screenWidth = undefined
    DeviceInfo.orientation = undefined
  }

  // 3. 系统版本
  DeviceInfo.platformVersion = DeviceInfo.isNotIgnoreField(context, IgnoreFields.PlatformVersion) 
    ? deviceInfo.displayVersion 
    : undefined

  // 4. 设备信息
  DeviceInfo.deviceBrand = DeviceInfo.isNotIgnoreField(context, IgnoreFields.DeviceBrand) 
    ? deviceInfo.brand 
    : undefined
  DeviceInfo.deviceModel = DeviceInfo.isNotIgnoreField(context, IgnoreFields.DeviceModel) 
    ? deviceInfo.productModel 
    : undefined
  DeviceInfo.deviceType = DeviceInfo.isNotIgnoreField(context, IgnoreFields.DeviceType) 
    ? deviceInfo.deviceType 
    : undefined

  // 5. 语言和时区
  DeviceInfo.language = DeviceInfo.isNotIgnoreField(context, IgnoreFields.SystemLanguage) 
    ? I18n.System.getSystemLanguage() 
    : undefined
  DeviceInfo.timezoneOffset = DeviceInfo.isNotIgnoreField(context, IgnoreFields.TimezoneOffset) 
    ? new Date().getTimezoneOffset() + '' 
    : undefined

  // 6. 网络状态
  DeviceInfo.initNetworkState(context)

  // 7. 设备 ID
  DeviceInfo.initDeviceId()
}
```

### 屏幕方向判断

```
┌─────────────────────────────────────────┐
│           屏幕方向判断                   │
├─────────────────────────────────────────┤
│                                         │
│  displayInfo.orientation 值：           │
│                                         │
│  0 │ 2  →  PORTRAIT (竖屏)              │
│  1 │ 3  →  LANDSCAPE (横屏)             │
│                                         │
└─────────────────────────────────────────┘
```

### 设备 ID 初始化

```typescript
static initDeviceId() {
  let deviceId = SharedPreferences.getValue(PREFERENCE_DEVICE_ID) as string
  LogUtil.info(() => 'DeviceId from preferences is ' + deviceId)
  
  if (deviceId == '') {
    // 首次使用，生成新的 UUID
    deviceId = util.generateRandomUUID(false)
    SharedPreferences.put(PREFERENCE_DEVICE_ID, deviceId)
  }
  
  DeviceInfo.deviceId = deviceId
}
```

---

## AppInfo 应用信息

### 采集字段

| 字段 | 类型 | 说明 | 来源 |
|------|------|------|------|
| `domain` | string | 应用包名（Bundle Name） | `bundleManager.getBundleInfoForSelfSync` |
| `appName` | string | 应用名称 | `resourceManager.getStringSync` |
| `appVersion` | string | 应用版本 | `bundleInfo.versionName` |
| `appChannel` | string | 应用渠道 | 预留字段 |
| `debug` | boolean | 是否为调试版本 | `appInfo.debug` |

### 初始化流程

```typescript
static initAppInfo(context: Context) {
  try {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags)

    // 1. 包名（作为 domain）
    AppInfo.domain = bundleInfo.name
    
    // 2. 应用名称
    let r_id = bundleInfo.appInfo.labelResource.id
    AppInfo.appName = context.resourceManager.getStringSync(r_id)
    
    // 3. 应用版本
    AppInfo.appVersion = bundleInfo.versionName
    
    // 4. 是否为调试版本
    AppInfo.debug = bundleInfo.appInfo.debug
    
    // 5. 应用渠道（预留）
    // AppInfo.appChannel = '应用市场'
    
  } catch (e) {
    // 异常处理
  }
}
```

### BundleInfo 结构

```
┌─────────────────────────────────────────┐
│ BundleInfo                              │
├─────────────────────────────────────────┤
│ name: string              ← domain      │
│ versionName: string       ← appVersion  │
│ appInfo: ApplicationInfo                │
│   ├── labelResource.id    ← appName     │
│   └── debug: boolean      ← debug       │
└─────────────────────────────────────────┘
```

---

## 字段忽略机制

### 背景

NewSaaS 模式支持忽略某些设备字段，以满足特定的合规要求或隐私需求。

### 忽略字段枚举

```typescript
export enum IgnoreFields {
  NetworkState = (1 << 0),     // 00000001
  ScreenSize = (1 << 1),       // 00000010
  DeviceBrand = (1 << 2),      // 00000100
  DeviceModel = (1 << 3),      // 00001000
  DeviceType = (1 << 4),       // 00010000
  SystemLanguage = (1 << 5),   // 00100000
  TimezoneOffset = (1 << 6),   // 01000000
  PlatformVersion = (1 << 7),  // 10000000
}

// 忽略所有字段
export const IgnoreFieldsAll = 
  IgnoreFields.NetworkState | 
  IgnoreFields.ScreenSize | 
  IgnoreFields.DeviceBrand | 
  IgnoreFields.DeviceModel | 
  IgnoreFields.DeviceType | 
  IgnoreFields.SystemLanguage | 
  IgnoreFields.TimezoneOffset | 
  IgnoreFields.PlatformVersion  // = 255
```

### 判断逻辑

```typescript
static isNotIgnoreField(context: GrowingContext, field: IgnoreFields): boolean {
  // 非 NewSaaS 模式，所有字段都采集
  if (context.config.mode != ConfigMode.NewSaaS) {
    return true
  }

  // 位运算判断：对应位为 0 表示不忽略
  return (context.config.ignoreField & field) == 0
}
```

### 使用示例

```typescript
// 忽略网络状态和设备型号
let config = new GrowingConfig().NewSaaS(...)
config.ignoreField = IgnoreFields.NetworkState | IgnoreFields.DeviceModel

// 忽略所有字段
config.ignoreField = IgnoreFieldsAll
```

### 字段忽略效果

| 字段 | 不忽略 | 忽略后 |
|------|--------|--------|
| screenHeight/screenWidth | 实际值 | undefined |
| orientation | PORTRAIT/LANDSCAPE | undefined |
| deviceBrand | HUAWEI/... | undefined |
| deviceModel | 实际型号 | undefined |
| deviceType | phone/... | undefined |
| platformVersion | 5.0.0/... | undefined |
| language | zh-CN/... | undefined |
| timezoneOffset | -480/... | undefined |
| networkState | WIFI/5G/... | undefined |

---

## 网络状态监听

### 监听机制

使用 `@ohos.net.connection` 模块监听网络状态变化：

```typescript
static netConnection = connection.createNetConnection()

static initNetworkState(context: GrowingContext) {
  if (DeviceInfo.isNotIgnoreField(context, IgnoreFields.NetworkState)) {
    DeviceInfo.networkState = 'UNKNOWN'
    
    // 注册网络监听
    DeviceInfo.netConnection.register((e) => {
      if (e) {
        DeviceInfo.networkState = 'WIFI'
      }
    })
    
    // 网络丢失
    DeviceInfo.netConnection.on("netLost", (data) => {
      DeviceInfo.networkState = 'UNKNOWN'
    })
    
    // 网络不可用
    DeviceInfo.netConnection.on("netUnavailable", (data) => {
      DeviceInfo.networkState = 'UNKNOWN'
    })
    
    // 网络能力变化
    DeviceInfo.netConnection.on("netCapabilitiesChange", (data) => {
      if (!data.netCap || !data.netCap.bearerTypes || data.netCap.bearerTypes.length == 0) {
        return
      }
      
      let bearerType = data.netCap.bearerTypes[0]
      
      if (bearerType == connection.NetBearType.BEARER_CELLULAR) {
        DeviceInfo.networkState = '5G'  // 简化为 5G
      } else if (bearerType == connection.NetBearType.BEARER_WIFI) {
        DeviceInfo.networkState = 'WIFI'
      } else if (bearerType == connection.NetBearType.BEARER_ETHERNET) {
        DeviceInfo.networkState = 'WIFI'  // Ethernet 归类为 WIFI
      }
    })
  } else {
    DeviceInfo.networkState = undefined
  }
}
```

### 网络类型映射

| 系统网络类型 | SDK 网络状态 |
|-------------|-------------|
| BEARER_CELLULAR | 5G (简化处理) |
| BEARER_WIFI | WIFI |
| BEARER_ETHERNET | WIFI |
| 无网络 | UNKNOWN |

### 实时更新

网络状态是实时监听的，切换网络时会自动更新：

```
WIFI ──▶ 移动数据    networkState: 'WIFI' ──▶ '5G'
移动数据 ──▶ WIFI    networkState: '5G' ──▶ 'WIFI'
有网 ──▶ 无网        networkState: 'WIFI' ──▶ 'UNKNOWN'
```

---

## 总结

DeviceInfo 和 AppInfo 提供了完整的设备和应用信息采集功能：

1. **设备信息**: 设备 ID、屏幕信息、设备型号、系统版本、网络状态等
2. **应用信息**: 包名、应用名称、版本、调试标识
3. **字段忽略**: NewSaaS 模式支持选择性忽略敏感字段
4. **实时更新**: 网络状态实时监听，自动更新
5. **容错设计**: 采集失败时使用默认值，保证事件完整性

---

*文档生成时间: 2026-02-25*
*基于 GrowingIO HarmonyOS SDK v2.7.1*
