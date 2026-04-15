---
name: growingio-arkts-coding-style
description: Use when writing or reviewing .ets/.ts files in this project, or when seeing any, unknown, obj['key'] index access, destructuring assignment, var declarations, #privateField, intersection types, conditional types, index signatures, function expressions, for..in loops, delete operator, throw non-Error, <T> casts, catch type annotation, nested functions, in operator, or object literals typed as Object in code
---

# GrowingIO HarmonyOS SDK - ArkTS 编码规范

本 skill 覆盖 GrowingIO HarmonyOS SDK 项目的 ArkTS 语法约束和代码风格要求。

> 📚 完整约束原文见 [`docs/typescript-to-arkts-migration-guide.md`](../../../docs/typescript-to-arkts-migration-guide.md)。

---

## 第一部分：ArkTS 语法约束（编译错误级别）

### 1. 类型系统

| 约束 | 禁止 | 允许 | 规则 ID |
|------|------|------|---------|
| any/unknown | `any`, `unknown` | 显式类型声明 | `arkts-no-any` |
| 结构化类型 | 相同结构的类直接赋值 | `implements Interface` | `arkts-no-structural` |
| 交叉类型 | `A & B` | 继承 / 接口组合 | `arkts-no-intersection` |
| 条件类型 | `T extends U ? X : Y` | 显式类或联合类型 | `arkts-no-conditional` |
| 映射类型 | `{ [P in keyof T]: boolean }` | 显式声明的具名类 | `arkts-no-mapped-types` |
| `this` 类型标注 | `this` 作为返回类型 | 具名类型 | `arkts-no-this-type` |
| 类型转换语法 | `<T>value` | `value as T` | `arkts-as-casts` |
| `typeof` 类型查询 | `let n: typeof x` | 直接写类型 `number` | `arkts-no-type-query` |
| 索引访问类型 | `T['key']`（类型层面） | 显式声明类型别名 | `arkts-no-idx-access-types` |

```typescript
// ✅ 正确
let count: number = 0
let result = value as string

// ❌ 错误
let count: any = 0
let result = <string>value
let t: typeof count
```

### 2. 对象与属性

| 约束 | 禁止 | 允许 | 规则 ID |
|------|------|------|---------|
| 动态属性名 | `{ 'name': 'x', 2: 'y' }` | 标识符属性名 | `arkts-identifiers-as-prop-names` |
| 索引签名 | `[key: string]: T` | 具名字段 / `Map<K,V>` | `arkts-no-idx-signatures` |
| 运行时动态添加属性 | `obj.newProp = val`（未在类中声明） | 类中提前声明所有字段 | 对象布局不可变 |
| `delete` 操作符 | `delete obj.prop` | `obj.prop = null`（字段改为 nullable） | `arkts-no-delete` |
| 方法重新赋值 | `c2.foo = bar` | 子类继承 + 覆写 | `arkts-no-method-reassignment` |
| `in` 操作符 | `'name' in obj` | `obj instanceof Class` | `arkts-no-in` |
| 对象字面量类型 | `let o: Object = { n: 1 }` | 必须对应已声明的类或接口 | `arkts-no-untyped-obj-literals` |

```typescript
// ✅ 正确
class EventAttr {
  key: string = ''
  value: string = ''
}
let attr: EventAttr = { key: 'page', value: 'Home' }

// ❌ 错误 - 字面量不能赋给 Object 类型
let attr: Object = { key: 'page', value: 'Home' }

// ✅ 正确 - 替代 delete
class Config {
  userId: string | null = null
}
config.userId = null   // 代替 delete config.userId

// ✅ 正确 - 替代 in
if (tracker instanceof SubTracker) { ... }  // 代替 'subId' in tracker
```

**SDK 中的 `AttributesType`：**

```typescript
// SDK 使用类型别名表示事件属性字典，不用 Record<string, any>
type AttributesType = Record<string, string | number | boolean>

// 赋值时必须确保值类型匹配
let attrs: AttributesType = {}
attrs['key'] = 'value'  // ❌ 索引访问
// 实际 SDK 中通过 Map 或具名字段处理
```

### 3. 函数与方法

| 约束 | 禁止 | 允许 | 规则 ID |
|------|------|------|---------|
| 函数表达式 | `let f = function(x) { }` | 箭头函数 `let f = (x) => { }` | `arkts-no-func-expressions` |
| 嵌套函数 | 函数内部 `function` 定义 | 用箭头函数（lambda）替代 | `arkts-no-nested-funcs` |
| 解构参数 | `function f({ x, y })` | 普通参数 + 手动解构 | `arkts-no-destruct-params` |
| `this` 在独立函数 | 顶层函数 / 静态方法中用 `this` | 仅在实例方法中用 `this` | `arkts-no-standalone-this` |
| 生成器函数 | `function* gen()` | 异步 + Promise 替代 | `arkts-no-generators` |
| 省略返回类型 | 返回值为另一个函数调用时省略 | 显式声明返回类型 | `arkts-no-implicit-return-types` |

```typescript
// ✅ 正确 - 箭头函数
let handler = (event: ClickEvent): void => {
  LogUtil.info('clicked')
}

// ❌ 错误 - 函数表达式
let handler = function(event: ClickEvent) {
  LogUtil.info('clicked')
}

// ✅ 正确 - 嵌套逻辑用 lambda
function processEvent(event: Event): void {
  let validate = (e: Event): boolean => e.eventName.length > 0
  if (validate(event)) { ... }
}

// ❌ 错误 - 嵌套函数
function processEvent(event: Event): void {
  function validate(e: Event): boolean { return e.eventName.length > 0 }
}

// ✅ 正确 - 解构参数改为普通参数
function buildEvent(eventName: string, timestamp: number): Event { ... }

// ❌ 错误
function buildEvent({ eventName, timestamp }: EventParams): Event { ... }

// ✅ 正确 - 显式返回类型（调用其他函数时必须标注）
function getSessionId(): string {
  return SessionManager.currentId()
}
```

### 4. 控制流

| 约束 | 禁止 | 允许 | 规则 ID |
|------|------|------|---------|
| `for..in` | `for (let k in obj)` | `for..of` / 索引 `for` / `Object.keys()` | `arkts-no-for-in` |
| `with` 语句 | `with (Math) { ... }` | 直接用限定名 `Math.PI` | `arkts-no-with` |
| Catch 类型标注 | `catch (e: unknown)` | `catch (e)` | `arkts-no-types-in-catch` |
| `throw` 任意值 | `throw 'error'` / `throw 42` | `throw new Error('msg')` | `arkts-limited-throw` |

```typescript
// ✅ 正确 - for..of 遍历数组
for (let event of events) {
  process(event)
}

// ✅ 正确 - 索引遍历
for (let i = 0; i < events.length; i++) {
  process(events[i])
}

// ❌ 错误
for (let key in attrs) { ... }

// ✅ 正确 - catch 无类型标注
try {
  await database.write(event)
} catch (e) {
  LogUtil.error('write failed')
}

// ❌ 错误
} catch (e: unknown) { ... }

// ✅ 正确 - throw 只抛 Error
throw new Error('dataSourceId is required')

// ❌ 错误
throw 'invalid config'
throw { code: 400, msg: 'bad request' }
```

### 5. 解构

| 约束 | 禁止 | 允许 | 规则 ID |
|------|------|------|---------|
| 解构赋值 | `let { x, y } = point` | `let x = point.x` | `arkts-no-destruct-assignment` |
| 解构参数 | `function f({ x, y })` | 普通参数（见函数部分） | `arkts-no-destruct-params` |
| 数组解构 | `let [a, b] = arr` | `let a = arr[0]` | `arkts-no-destruct-assignment` |

```typescript
// ✅ 正确
let eventName = event.name
let timestamp = event.timestamp

// ❌ 错误
let { name: eventName, timestamp } = event
let [first, ...rest] = events
```

### 6. 类与接口

| 约束 | 禁止 | 允许 | 规则 ID |
|------|------|------|---------|
| 构造函数参数声明字段 | `constructor(private id: string)` | 类体中单独声明字段 | `arkts-no-ctor-prop-decls` |
| 接口中构造函数签名 | `interface F { new(): T }` | 工厂方法 / 抽象类 | `arkts-no-ctor-signatures-iface` |
| `implements` 中使用类 | `class A implements SomeClass` | 只能 implements 接口 | `arkts-implements-only-iface` |
| 类字面量 | `const R = class { ... }` | 具名类定义 | `arkts-no-class-literals` |
| 私有 `#` 字段 | `#foo: number` | `private foo: number` | `arkts-no-private-identifiers` |
| 多个静态代码块 | 类中 `static { }` 超过一个 | 合并到单个静态块 | `arkts-no-multiple-static-blocks` |
| `Symbol()` | `Symbol('id')` | —（`Symbol.iterator` 除外） | `arkts-no-symbol` |

```typescript
// ✅ 正确 - 字段在类体中声明
class EventSender {
  private config: GrowingConfig
  private isUploading: boolean = false

  constructor(config: GrowingConfig) {
    this.config = config
  }
}

// ❌ 错误 - 构造函数参数声明字段
class EventSender {
  constructor(private config: GrowingConfig) { }
}

// ✅ 正确 - implements 只用接口
class AnalyticsCore implements GrowingAnalyticsInterface { ... }

// ❌ 错误 - implements 类
class SubTracker implements AnalyticsCore { ... }
```

---

## 第二部分：SDK 特有模式

### TaskPool 回调

TaskPool 中的任务必须用 `@Concurrent` 装饰器，内部只能用箭头函数（无 `this`）：

```typescript
// ✅ 正确 - TaskPool 任务函数
@Concurrent
function writeEventTask(serialized: string, dbPath: string): void {
  // 纯函数，无 this
}

taskpool.execute(writeEventTask, JSON.stringify(event), dbPath)
```

### 可选字段

```typescript
// ✅ 正确 - 显式 union 类型
class UserIdentifier {
  userId: string | undefined = undefined
  userKey: string | undefined = undefined
}

// ❌ 避免 - 可选 ? 语法（ArkTS 支持但 SDK 内部统一用显式 union）
userId?: string
```

### niceTry 包装模式

SDK 内部用 `niceTry` 包装可能抛出的表达式，返回值或 `undefined`：

```typescript
// niceTry 签名（工具函数）
function niceTry<T>(fn: () => T): T | undefined {
  try {
    return fn()
  } catch (e) {
    return undefined
  }
}

// 使用
let deviceId: string | undefined = niceTry(() => DeviceInfo.udid)
```

### 事件属性字典

SDK 使用 `GrowingAttrType`（内部）和 `AttributesType`（公开）表示键值对属性，不用 `Record<string, any>`：

```typescript
// ✅ 正确
type AttributesType = Record<string, string | number | boolean>

function track(eventName: string, attributes: AttributesType): void { ... }
```

---

## 第三部分：格式规范

### 基础格式

- **缩进**：4 个空格，禁用 tab
- **行宽**：≤ 120 字符
- **字符串**：单引号 `'hello'`（模板字符串用反引号）
- **括号**：`{` 同行，不换行

### 导入顺序

```typescript
// 1. 系统 / HarmonyOS API
import AbilityStage from '@ohos.app.ability.AbilityStage'
import window from '@ohos.window'

// 2. 第三方库

// 3. 内部模块（相对路径）
import { GrowingConfig } from '../interfaces/GrowingConfig'
import { LogUtil } from '../utils/LogUtil'
```

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类 / 接口 / 枚举 / 类型别名 | PascalCase | `AnalyticsCore`, `EventType`, `AttributesType` |
| 方法 / 函数 / 属性 / 变量 | camelCase | `trackEvent()`, `sessionId` |
| 常量 | UPPER_SNAKE_CASE | `SDK_VERSION`, `MAX_BATCH_SIZE` |

### 类成员顺序

1. 静态公共字段
2. 静态私有字段
3. 公共实例字段
4. 私有实例字段
5. 构造函数
6. 公共静态方法
7. 公共实例方法
8. 私有 / 受保护方法

### 文件头（Apache 2.0）

```typescript
/**
 * @license
 * Copyright (C) 2023 Beijing Yishu Technology Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * ...
 */
```

---

## 第四部分：代码审查清单

### ArkTS 语法

- [ ] 无 `any` / `unknown`（含 `as any` cast）
- [ ] 无解构赋值 / 解构参数（`let { x } = o` / `function f({ x })`）
- [ ] 无 `var`（用 `let` / `const`）
- [ ] 无 `#` 私有字段（用 `private`）
- [ ] 无 `obj['key']` 索引访问
- [ ] 无函数表达式（`function(x) {}`）→ 箭头函数
- [ ] 无嵌套函数定义（用 lambda 替代）
- [ ] 无 `for..in`（用 `for..of` / 索引 `for`）
- [ ] 无 `delete` 操作符（字段改为 nullable）
- [ ] 无 `in` 操作符（用 `instanceof`）
- [ ] `throw` 只抛 `Error` 或其子类
- [ ] `catch (e)` 无类型标注
- [ ] 类型转换只用 `as T`（无 `<T>value`）
- [ ] 函数调用其他函数时返回类型显式声明
- [ ] 无交叉类型 / 条件类型 / 映射类型
- [ ] 无索引签名（`[key: string]: T`）
- [ ] 对象字面量对应已声明的类或接口（不赋给 `Object` / `object`）
- [ ] `implements` 后只有接口（不是类）
- [ ] 构造函数参数不包含字段声明

### SDK 规范

- [ ] 文件包含 Apache 2.0 许可证头
- [ ] 新增公开 API 同步更新 `obfuscation-rules.txt`
- [ ] 新增采集字段确认是否需要 `ignoreField` 支持
- [ ] IO 操作在 TaskPool / Worker 中（主线程零阻塞）
- [ ] 导入顺序：系统 → 第三方 → 内部
- [ ] 4 空格缩进，行宽 ≤ 120
- [ ] 字符串单引号

## 避免这么想

| 想法 | 现实 |
|---|---|
| "TypeScript 能这么写 ArkTS 应该也行" | ArkTS 是严格子集，解构/动态属性/any 都禁用；不看约束表就是埋雷 |
| "先用 `any` 让它编过，后面再改" | `any` 是 ArkTS 第一红线，改不回来；上来就用正确类型 |
| "`obj['key']` 很方便" | 禁用，必须用 `obj.key` 或定义接口 |
| "新增字段先不改 `obfuscation-rules.txt`" | HAR 打包后混淆会把公开 API 符号名改掉，接入方直接挂 |
| "IO 操作在 onClick 里同步调一下无所谓" | 主线程零阻塞是红线；必须走 TaskPool |
| "`throw 'error'` 抛个字符串够用了" | ArkTS 要求只抛 `Error` 或其子类 |
| "类里加 `#private` 字段更现代" | ArkTS 不支持 `#`，用 `private` 关键字 |

## 关联 skill

- **上游触发：** 写或审查任何 `.ets` / `.ts` 文件时
- **调度 subagent：** 无（本 skill 是规范手册，由编码者/审查者自己对照）
- **完成后交接：** `sdk-code-review` 的 code-reviewer subagent 必须用本 skill 的约束清单做审查
- **替代路径：** 遇到 TypeScript 代码需迁移 → 交叉参考 `docs/typescript-to-arkts-migration-guide.md`
