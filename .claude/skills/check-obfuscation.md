# 混淆规则检查

检查 GrowingAnalytics / GrowingToolsKit 的混淆保留规则是否与代码同步。

## 用法

```
/check-obfuscation [--all] [--base <branch>]
```

- 无参数：检查当前分支相对 master 的变更文件
- `--all`：全量扫描所有受监控文件（上线前推荐）
- `--base <branch>`：指定对比基准分支

## 执行步骤

1. 根据参数构造命令，在项目根目录运行：
   ```
   python3 scripts/check_obfuscation_rules.py [args]
   ```

2. 解读输出结果：
   - ✓ 绿色通过：规则与代码同步，无需操作
   - ⚠ 黄色警告：发现可能缺失的保留规则，按以下判断标准处理

3. 对每个被标记的符号，判断是否真正需要保留：

   | 需要保留 ✓ | 无需保留 ✗ |
   |-----------|-----------|
   | Event 类属性（会被 JSON.stringify 序列化） | 仅在编译期使用的类型名 |
   | SQL 列名（作为字符串 key 传入 RDB API） | 内部常量（值不是自身名字） |
   | HTTP header key（构造 Record<string,string>） | 普通 TypeScript 类方法名 |
   | Protobuf 运行时反射用到的类/命名空间名 | 不跨模块边界的私有属性 |
   | 圈选/Hybrid JSON 协议中的 $-prefixed key | 枚举值字符串（已被保留为 string literal） |

4. 如果有符号需要保留，在对应规则文件中同步添加：
   - `GrowingAnalytics/obfuscation-rules.txt`
   - `GrowingAnalytics/consumer-rules.txt`（与上面保持一致）
   - `GrowingToolsKit/obfuscation-rules.txt`（如涉及 Tools 模块）
   - `GrowingToolsKit/consumer-rules.txt`（与上面保持一致）

5. 修改规则文件后，告知用户具体添加了哪些条目及原因。

## 规则文件格式提醒

```
-keep-property-name
# 新增条目放在对应分类注释下
newPropertyName

-keep-global-name
NewProtobufClassName
```

`obfuscation-rules.txt` 和 `consumer-rules.txt` 内容必须保持完全一致。
