---
name: growingio-arkts-coding-style
description: Use when writing or reviewing ArkTS/TypeScript files in this project, or when investigating ArkTS compiler rule violations
---

# GrowingIO ArkTS 编码规范

编写或审查 `.ets` / `.ts` 时使用。完整的 TypeScript 到 ArkTS 迁移规则见 [`docs/typescript-to-arkts-migration-guide.md`](../../../docs/typescript-to-arkts-migration-guide.md)，此处只保留高频检查和 SDK 特有约束。

## ArkTS 语法红线

| 类别 | 禁止 | 推荐写法 |
|------|------|----------|
| 类型 | `any`、`unknown`、交叉/条件/映射类型、`typeof` 类型查询 | 显式具名类型、联合类型、接口 |
| 类型转换 | `<T>value`、索引访问类型 | `value as T`、显式类型别名 |
| 对象 | 索引签名、运行时新增属性、`delete`、`in`、无类型对象字面量 | 预先声明字段、具名类或接口、`Map` |
| 解构 | 对象/数组解构、解构参数 | 逐个属性或元素赋值 |
| 函数 | 函数表达式、嵌套函数声明、生成器、独立函数中的 `this` | 箭头函数、Promise、类实例方法 |
| 控制流 | `var`、`for..in`、`with` | `let` / `const`、`for..of`、索引循环 |
| 类 | 构造参数声明字段、`#private`、类表达式、implements 类 | 类体声明字段、`private`、具名类、implements 接口 |
| 异常 | `catch (e: Type)`、抛出字符串或普通对象 | `catch (e)`、`throw new Error(...)` |

补充约束：

- 动态键访问不要写成 `obj['key']`，使用具名字符属性或项目已有的字典处理方式。
- 函数返回另一个函数调用时，显式声明返回类型。
- 构造函数不要写 `constructor(private value: string)`；在类体中声明字段后再赋值。
- 可选类字段使用项目已有的显式联合类型风格，例如 `string | undefined`。
- 不把 TypeScript 能编译当作 ArkTS 合规证据，以项目编译器输出为准。

## SDK 特有约束

- 公开 API 仅从模块入口导出，并同步对应 `obfuscation-rules.txt`。
- 数据库、文件和网络 IO 在 TaskPool / Worker 中执行，主线程不阻塞。
- TaskPool 任务使用 `@Concurrent`；回调使用箭头函数，不依赖 `this`。
- 新增采集字段时检查 `ignoreField` 和 `dataCollectionEnabled` 的影响。
- 不假设第三方库已存在；先检查 imports、`oh-package.json5` 和 lockfile。
- 不为了绕过编译错误引入 `any` 或新增依赖。能力缺失时明确报告。

## 格式与结构

- 优先匹配所在文件的缩进、导入顺序、命名和成员组织方式，不批量重排无关代码。
- 行宽不超过 120 个字符；字符串使用单引号，模板字符串使用反引号。
- 类、接口、枚举和类型别名使用 PascalCase；方法、字段和变量使用 camelCase；常量使用 UPPER_SNAKE_CASE。
- 新增源码文件保留项目的 Apache 2.0 许可证头。
- 默认不写解释显而易见行为的注释；公共契约和复杂约束按所在文件风格处理。

## 审查顺序

1. 先处理编译器给出的文件、行号和规则 ID，不凭 TypeScript 经验猜测。
2. 对照上表检查改动行，避免为修复一处错误引入另一处违规。
3. 检查公开 API、混淆、隐私和线程约束。
4. 按 `docs/sdk-review-checklist.md` 完成审查，以实际构建和测试结果收尾。
