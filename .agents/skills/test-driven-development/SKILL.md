---
name: test-driven-development
description: Use when implementing or modifying core SDK paths such as event processing, storage, network, session management, or user identification
---

# 核心路径测试驱动开发

核心行为变更先用失败测试固定预期，再写最小实现。纯文档、配置字段赋值和视觉样式调整不需要机械套用 TDD。

## Red → Green → Refactor

1. **Red**：写一个描述外部行为的测试，运行并确认因缺少目标行为而失败。第一次就通过时，检查测试是否无效或行为已经存在。
2. **Green**：写刚好让测试通过的实现，不顺手扩展需求或重构无关代码。
3. **Refactor**：在测试保护下去除重复、改善命名和职责划分，每次改动后重新验证。

不要先写完整实现再补一个只验证现有代码的测试，也不要为了让测试通过而放宽原有断言。

## 必测范围

- 事件管道：`EventBuilder`、`EventPersistence`、`EventSender`。
- 存储与序列化：RDB、JSON / Protobuf、加密和压缩。
- 网络：请求构造、重试、成功删除与失败保留。
- Session：生成、超时、前后台切换。
- 用户标识：访问用户 ID、`userId` / `userKey` 及关联事件。

共享行为按实际影响覆盖 NewSaaS / SaaS / CDP；无需为明确不受影响的产品线虚构变化。

## 测试矩阵

按变更涉及的路径选择，不要求所有改动机械跑满组合：

- NewSaaS / CDP 的 Protobuf 与 SaaS 的 JSON 路径分别验证。
- 网络编码变化至少覆盖压缩、加密都开启和都关闭；必要时覆盖完整四组合。
- 采集路径必须覆盖 `dataCollectionEnabled=false`，确认不采集。
- 覆盖边界输入、重复调用、失败重试和状态重置，不只测成功路径。

## 仓库测试约定

- 测试放在对应模块的 `src/test/` 目录，命名为 `<Module>.test.ets`。
- 新增 GrowingAnalytics 测试文件后，在 `src/test/List.test.ets` 注册。
- 复用 `src/test/doubles/` 和 `src/test/helpers/TestBuilders.ets`，不重复搭建整套替身。
- 在 `beforeEach` / `afterEach` 中隔离 `AnalyticsCore`、`GrowingContext` 等全局状态。
- 单测不依赖真实网络或真实数据库；平台能力通过项目已有的依赖注入或测试替身隔离。
- 异步链路使用等待钩子或同步执行器，不用固定时长的 `setTimeout` 猜测完成时机。
- 一个用例聚焦一个行为，失败信息应能直接定位问题。

标准测试命令：

```bash
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  test --mode module -p module=GrowingAnalytics@default -p product=default
```

hvigor 的 `BUILD SUCCESSFUL` 不等于测试全部通过，必须读取 Hypium 的实际断言结果。与本次无关的既有失败不要擅自修复或隐藏，应在交付时明确列出。

完成后使用 `verification-before-completion` 验证最终交付版本。
