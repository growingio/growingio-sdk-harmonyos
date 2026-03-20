---
name: growingio-arkts-coding-style
description: GrowingIO HarmonyOS SDK 代码风格规范。在编写或审查本项目代码时使用，确保代码符合 ArkTS 语言约束、项目命名约定和格式化标准。
---

# GrowingIO HarmonyOS SDK - 代码风格指南

本技能用于强制执行 GrowingIO HarmonyOS SDK 项目的代码风格标准，使用 ArkTS（HarmonyOS TypeScript 变体）。

## 语言约束（ArkTS）

本项目使用 **ArkTS**，而非标准 TypeScript。以下特性被严格禁止。

> 📚 **详细参考**: 关于 ArkTS 语言约束的完整说明和迁移示例，请参考 [`docs/typescript-to-arkts-migration-guide.md`](../../../docs/typescript-to-arkts-migration-guide.md)。

### 关键约束

| 规则 | 禁止 | 允许 |
|------|------|------|
| 类型 | `any`, `unknown` | 显式类型 |
| 结构化类型 | 相同结构的类直接赋值 | 使用 `implements Interface` |
| 解构赋值 | `let { x, y } = point` | `let x = point.x` |
| 索引访问 | `obj['key']` | `obj.key` |
| 变量声明 | `var x = 1` | `let x = 1` 或 `const x = 1` |
| 私有字段 | `#foo: number` | `private foo: number` |
| 一元加号 | `+'42'`（字符串） | `+42`（仅数字） |

### 其他限制

- 禁止使用 `Symbol()`（`Symbol.iterator` 除外）
- 类中禁止多个静态代码块
- 禁止索引签名
- 禁止交叉类型（使用继承）
- 禁止使用 `this` 类型标注
- 禁止条件类型
- 禁止在构造函数参数中声明字段
- 接口中禁止构造函数签名

## 文件命名规范

| 文件类型 | 命名规范 | 扩展名 | 示例 |
|---------|---------|--------|------|
| ArkTS 类 | PascalCase | `.ets` | `GrowingAnalytics.ets` |
| TypeScript 工具类 | PascalCase/camelCase | `.ts` | `LogUtil.ts` |
| 测试文件 | PascalCase + `.test` | `.ets` | `LocalUnit.test.ets` |
| 配置文件 | kebab-case | `.json5` | `build-profile.json5` |

## 代码格式化

### 缩进和间距

- **缩进**：4 个空格（禁用 tab）
- **行宽限制**：120 个字符
- **最大空行数**：2

```typescript
// ✅ 正确
class AnalyticsCore {
    private context: GrowingContext
    
    constructor(context: GrowingContext) {
        this.context = context
    }
}

// ❌ 错误 - 缩进不正确
class AnalyticsCore {
  private context: GrowingContext
}
```

### 括号和控制流

```typescript
// ✅ 正确 - 括号在同一行
if (condition) {
    doSomething()
} else {
    doSomethingElse()
}

// ✅ 正确 - 允许短函数
getDeviceId(): string {
    return DeviceInfo.deviceId
}

// ❌ 错误 - 括号在新行
if (condition)
{
    doSomething()
}
```

### 行续接

```typescript
// ✅ 正确 - 在 120 字符处换行，缩进 4 空格
static writeEventToDisk<T extends Event>(
    event: T,
    context: GrowingContext,
    eventScene: EventScene = EventScene.Native
): void {
    // 实现
}

// ✅ 正确 - 链式调用分行
subWindow.loadContentByName(routeName, localStorage)
    .then(() => {
        subWindow.setWindowBackgroundColor(color)
    })
```

## 命名规范

| 构造类型 | 规范 | 示例 |
|---------|------|------|
| 类 | PascalCase | `AnalyticsCore`, `EventDatabase` |
| 接口 | PascalCase | `GrowingAnalyticsInterface` |
| 枚举 | PascalCase | `EventType`, `ConfigMode` |
| 方法/函数 | camelCase | `trackEvent()`, `getDeviceId()` |
| 属性/字段 | camelCase | `dataSourceId`, `sessionInterval` |
| 常量 | UPPER_SNAKE_CASE（类枚举） | `SDK_VERSION` |
| 静态成员 | 类名 PascalCase，方法 camelCase | `LogUtil.info()` |
| 类型别名 | PascalCase | `AttributesType`, `GrowingAttrType` |

## 导入组织

导入必须按以下三组组织，组间空行分隔：

```typescript
// 1. 系统/HarmonyOS 导入优先
import AbilityStage from '@ohos.app.ability.AbilityStage'
import UIAbility from '@ohos.app.ability.UIAbility'
import window from '@ohos.window'

// 2. 第三方库导入
import { SomeClass } from 'third-party-lib'

// 3. 内部模块导入（相对路径）
import { GrowingConfig } from '../interfaces/GrowingConfig'
import { LogUtil } from '../utils/LogUtil'
import Util from '../utils/Util'
```

## 文件头模板

每个源文件必须包含 Apache 2.0 许可证头：

```typescript
/**
 * @license
 * Copyright (C) 2023 Beijing Yishu Technology Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
```

## 类结构

### 字段声明顺序

1. 静态公共字段
2. 静态私有字段
3. 公共实例字段
4. 私有实例字段

```typescript
class Example {
    // 1. 静态公共
    static debugEnabled: boolean = false
    
    // 2. 静态私有
    private static _instance: Example
    
    // 3. 公共实例
    context: GrowingContext
    config: GrowingConfig
    
    // 4. 私有实例
    private _isInitialized: boolean = false
    private _eventQueue: Event[] = []
}
```

### 方法组织顺序

1. 构造函数
2. 公共静态方法
3. 公共实例方法
4. 私有/受保护方法

## 类型安全模式

### 显式类型

```typescript
// ✅ 正确 - 显式类型
let eventName: string = 'click'
let attributes: AttributesType = {}

// ❌ 错误 - 隐式类型（ArkTS 可能拒绝）
let eventName = 'click'
let attributes = {}
```

### 可选字段的联合类型

```typescript
// ✅ 正确
userId: string | undefined = undefined
networkState: string | undefined = undefined

// ❌ 错误 - 避免使用 ? 简写，优先使用显式联合类型
userId?: string
```

### 接口实现

```typescript
// ✅ 正确 - 使用接口实现多态
export interface GrowingAnalyticsInterface {
    isInitializedSuccessfully(): boolean
    setDataCollectionEnabled(enabled: boolean): void
}

export class AnalyticsCore implements GrowingAnalyticsInterface {
    // 实现
}
```

## 字符串和字面量规范

### 字符串引号

字符串使用单引号：

```typescript
// ✅ 正确
let message: string = 'Hello World'

// ❌ 错误
let message: string = "Hello World"
```

### 模板字符串

插值使用模板字符串：

```typescript
// ✅ 正确
let message: string = `Event ${eventName} tracked with id ${eventId}`

// ❌ 错误 - 字符串拼接
let message: string = 'Event ' + eventName + ' tracked with id ' + eventId
```

## 错误处理

### 易错操作的返回类型

```typescript
// ✅ 正确 - 返回布尔值或结果类型
static handleOpenURL(uri: string): boolean {
    // 实现
}

// ✅ 正确 - 对外部操作使用 try-catch
try {
    let subWindow = window.findWindow(SUB_WINDOW_NAME)
    return subWindow
} catch (e) {
    return undefined
}
```

## 注释

### 行内注释

```typescript
// 使用单行注释进行解释说明
// 使用完整句子，正确使用标点符号

// 根据调试模式计算延迟
let delay: number = config.debugEnabled ? 1000 : interval
```

### 区域注释

```typescript
// ==================== 事件处理 ====================

// ==================== 会话管理 ====================
```

## 代码审查清单

审查代码时，请验证：

- [ ] 文件包含 Apache 2.0 许可证头
- [ ] 未使用 `any` 或 `unknown` 类型
- [ ] 未使用解构赋值
- [ ] 未使用 `var` 关键字（使用 `let`/`const`）
- [ ] 未使用私有 `#` 字段（使用 `private` 关键字）
- [ ] 未使用索引属性访问（`obj['key']`）
- [ ] 导入组织正确（系统 → 第三方 → 内部）
- [ ] 命名符合规范（类/类型用 PascalCase，方法/字段用 camelCase）
- [ ] 行长度 ≤ 120 字符
- [ ] 4 空格缩进（无 tab）
- [ ] 所有声明都有显式类型
- [ ] 字符串使用单引号
- [ ] 可选字段正确使用 `undefined` 联合类型
