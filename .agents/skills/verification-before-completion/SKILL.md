---
name: verification-before-completion
description: Use before claiming work is complete, fixed, or ready to review, or when a build or test fails and the cause is unclear
---

# 完成前验证与调试

只报告实际运行过的验证。命令启动、编译完成或上一次通过，都不能替代当前交付版本的结果。

## 选择验证范围

| 变更 | 最低验证 |
|------|----------|
| Agent、skill、文档配置 | 校验文件内容、链接和引用；无需构建 SDK |
| GrowingAnalytics 源码 | 构建 GrowingAnalytics HAR |
| GrowingToolsKit 源码 | 构建 GrowingToolsKit HAR |
| entry 示例应用 | 构建 entry HAP |
| 事件、存储、网络、Session 等核心路径 | 对应 HAR 构建和 Hypium 测试 |
| 跨模块变更 | 分别验证所有受影响模块 |

构建命令统一见 `docs/sdk-build-commands.md`。标准 GrowingAnalytics 测试命令：

```bash
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js \
  test --mode module -p module=GrowingAnalytics@default -p product=default
```

## 读取并报告证据

- 等命令结束，读完成功标志和错误输出，不只看退出码或开头几行。
- 构建需看到 `BUILD SUCCESSFUL`，检查没有实际编译错误，并确认目标产物存在。
- Hypium 需核对用例数、通过数、失败数及失败位置；`BUILD SUCCESSFUL` 可能掩盖断言失败。
- 用户要求的原始场景要端到端验证，不能只验证 import 或编译。
- 真机、实际上传或外部服务未验证时明确说明，不把 Mock 结果描述成真机结果。
- 既有失败与本次失败分开报告；不擅自修复无关问题，也不把红测试称为全部通过。
- 最后检查 `git status`，删除验证产生且交付不需要的临时文件，保留用户原有改动。

推荐交付表述：`构建成功，产物路径为 …`；`401 个用例，398 通过、3 个既有失败，本次新增用例全部通过`。没有证据时不写“已修复”或“全部通过”。

## 失败时先定位再修改

1. 保存完整的预期值、实际值、文件行号和堆栈，用一句话描述问题。
2. 阅读失败路径和近期相关改动，区分本次回归、环境问题和既有失败。
3. 每次只验证一个明确假设，用最小复现和最小修复确认根因。
4. 不在调试期间顺手重构，不同时改多处猜测哪个起效，不无目的地重复同一命令。
5. 修复后重新运行原失败场景和对应标准验证，清理临时日志、Mock 和调试开关。

无法定位或缺少设备、凭据等必要条件时，报告已经确认的事实、剩余假设和阻塞项，不继续随机试错。

验证后按 `docs/sdk-review-checklist.md` 审查。需要提交或创建 PR 时使用 `git-conventions`；只有明确发版时才使用 `release`。
