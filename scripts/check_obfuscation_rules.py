#!/usr/bin/env python3
"""
check_obfuscation_rules.py

检查 GrowingAnalytics / GrowingToolsKit 的混淆保留规则是否与代码同步。

触发场景：
  - git pre-push hook（自动）
  - 手动执行：python3 scripts/check_obfuscation_rules.py [--base <branch>] [--strict]

退出码：
  0  无问题 / 仅警告
  1  --strict 模式下检测到缺失规则
"""

import re
import sys
import subprocess
import textwrap
from pathlib import Path
from dataclasses import dataclass, field

# ──────────────────────────────────────────────────────────────────────────────
# ANSI 颜色
# ──────────────────────────────────────────────────────────────────────────────
RESET  = "\033[0m"
BOLD   = "\033[1m"
RED    = "\033[31m"
YELLOW = "\033[33m"
GREEN  = "\033[32m"
CYAN   = "\033[36m"
DIM    = "\033[2m"


def _no_color() -> bool:
    import os
    return not sys.stdout.isatty() or os.environ.get("NO_COLOR")


def bold(s: str) -> str:   return s if _no_color() else f"{BOLD}{s}{RESET}"
def red(s: str) -> str:    return s if _no_color() else f"{RED}{s}{RESET}"
def yellow(s: str) -> str: return s if _no_color() else f"{YELLOW}{s}{RESET}"
def green(s: str) -> str:  return s if _no_color() else f"{GREEN}{s}{RESET}"
def cyan(s: str) -> str:   return s if _no_color() else f"{CYAN}{s}{RESET}"
def dim(s: str) -> str:    return s if _no_color() else f"{DIM}{s}{RESET}"


# ──────────────────────────────────────────────────────────────────────────────
# 路径常量
# ──────────────────────────────────────────────────────────────────────────────
ROOT = Path(__file__).parent.parent

ANALYTICS_RULES_FILES = [
    ROOT / "GrowingAnalytics/obfuscation-rules.txt",
    ROOT / "GrowingAnalytics/consumer-rules.txt",
]
TOOLS_RULES_FILES = [
    ROOT / "GrowingToolsKit/obfuscation-rules.txt",
    ROOT / "GrowingToolsKit/consumer-rules.txt",
]
ATOMIC_SERVICE_RULES_FILES = [
    ROOT / "GrowingAnalyticsAtomicService/obfuscation-rules.txt",
    ROOT / "GrowingAnalyticsAtomicService/consumer-rules.txt",
]

# ──────────────────────────────────────────────────────────────────────────────
# 数据结构
# ──────────────────────────────────────────────────────────────────────────────
@dataclass
class RuleSet:
    """从 obfuscation-rules.txt 中解析出的保留名单"""
    global_names: set[str] = field(default_factory=set)
    property_names: set[str] = field(default_factory=set)


@dataclass
class Finding:
    """一条检查结果：某个符号应被保留但未出现在规则中"""
    symbol: str          # 缺失的符号名
    kind: str            # 'global' | 'property'
    source_file: str     # 发现它的源文件（相对路径）
    reason: str          # 为什么需要保留
    rules_files: list[str]  # 应该添加到哪些规则文件


# ──────────────────────────────────────────────────────────────────────────────
# 规则文件解析
# ──────────────────────────────────────────────────────────────────────────────
def parse_rules(rules_files: list[Path]) -> RuleSet:
    """合并解析一组规则文件，返回当前已保留的名单"""
    result = RuleSet()
    for path in rules_files:
        if not path.exists():
            continue
        current_section: str | None = None
        for line in path.read_text(encoding="utf-8").splitlines():
            stripped = line.strip()
            if stripped.startswith("#") or not stripped:
                continue
            if stripped == "-keep-global-name":
                current_section = "global"
            elif stripped == "-keep-property-name":
                current_section = "property"
            elif stripped.startswith("-"):
                current_section = None  # 其他指令，不属于 keep 区
            elif current_section == "global":
                result.global_names.add(stripped)
            elif current_section == "property":
                result.property_names.add(stripped)
    return result


# ──────────────────────────────────────────────────────────────────────────────
# Git 工具
# ──────────────────────────────────────────────────────────────────────────────
def get_changed_files(base_branch: str) -> list[Path]:
    """返回当前分支相对于 base_branch 发生变化的文件列表（相对于 ROOT）"""
    try:
        out = subprocess.check_output(
            ["git", "diff", "--name-only", f"{base_branch}...HEAD"],
            cwd=ROOT,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        files = [ROOT / f.strip() for f in out.splitlines() if f.strip()]
        # 过滤掉已删除的文件
        return [f for f in files if f.exists()]
    except subprocess.CalledProcessError:
        # fallback：git diff 失败时（如首次 push、无公共祖先等），返回空列表跳过检查
        return []


def get_current_branch() -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=ROOT, text=True, stderr=subprocess.DEVNULL,
        ).strip()
    except Exception:
        return "HEAD"


# ──────────────────────────────────────────────────────────────────────────────
# 符号提取器
# ──────────────────────────────────────────────────────────────────────────────

# ── 1. Event 类属性 ────────────────────────────────────────────────────────────
# 匹配 ArkTS class body 中的公有属性声明（非函数、非本地变量）
# 例：`  userId: string | undefined = undefined`
_EVENT_PROP_RE = re.compile(
    r"^  ([a-zA-Z_][a-zA-Z0-9_]+)\s*[?!]?\s*:\s*"
    r"(?:string|number|boolean|[A-Z]\w*|AttributesType)",
    re.MULTILINE,
)

def extract_event_properties(content: str, filepath: Path) -> list[tuple[str, str]]:
    """
    从 Event 类定义文件中提取属性名。
    返回 [(symbol, reason), ...]
    """
    results = []
    for m in _EVENT_PROP_RE.finditer(content):
        name = m.group(1)
        # 排除明显的非序列化属性（私有前缀、全大写常量等）
        if name.startswith("_") or name.isupper():
            continue
        results.append((name, "Event 属性，经 JSON/Protobuf 序列化后发送到服务端"))
    return results


# ── 2. 数据库列名 ──────────────────────────────────────────────────────────────
# 只匹配真正作为「对象属性 key」使用的列名，不匹配函数参数字符串。
#
# 需要保留：
#   ValuesBucket 对象字面量 key：{ 'EVENT_UUID': value }
#     ← 这是对象属性，-enable-property-obfuscation 会把 key 混淆
#
# 不需要保留（函数参数字符串，arkguard 不动）：
#   getColumnIndex('EVENT_UUID')   ← 字符串值参数，不是属性名
#   predicates.equalTo('TYPE', x)  ← 同上
#   predicates.in('TYPE', list)    ← 同上
#
_DB_COL_BUCKET_RE = re.compile(r"['\"`]([A-Z][A-Z0-9_]{2,})['\"`]\s*:")

def extract_db_columns(content: str, filepath: Path) -> list[tuple[str, str]]:
    seen: set[str] = set()
    results = []

    for m in _DB_COL_BUCKET_RE.finditer(content):
        name = m.group(1)
        # 只收全大写下划线风格（数据库列名惯例），排除 HTTP header（含连字符）
        if re.match(r'^[A-Z][A-Z0-9_]+$', name) and name not in seen:
            seen.add(name)
            results.append((name, "ValuesBucket 对象字面量 key，混淆后 RDB insert 会写入错误列名"))

    return results


# ── 3. HTTP 请求头 key ─────────────────────────────────────────────────────────
# 关注以 X- 开头或 Content-Type 等约定 header
_HTTP_HEADER_RE = re.compile(r'["\']([A-Za-z][A-Za-z0-9_-]*(?:-[A-Za-z0-9_]+)+)["\']')

_HTTP_HEADER_KEEP = {
    # 凡是作为对象 key 访问或赋值的 header 名都需要保留
    "X-Compress-Codec", "X-Crypt-Codec", "X-Timestamp",
    "Content-Type", "Accept",
}

def extract_http_headers(content: str, filepath: Path) -> list[tuple[str, str]]:
    seen: set[str] = set()
    results = []
    for m in _HTTP_HEADER_RE.finditer(content):
        name = m.group(1)
        if name in _HTTP_HEADER_KEEP and name not in seen:
            seen.add(name)
            results.append((name, "HTTP 请求头 key，以对象属性形式构造，混淆后服务端无法识别"))
    return results


# ── 4. Protobuf 全局名（event_pb.d.ts）────────────────────────────────────────
_PB_GLOBAL_RE = re.compile(
    r"(?:export\s+)?(?:class|interface|namespace|enum)\s+([A-Za-z_][A-Za-z0-9_]+)"
)
_PB_NAMESPACE_RE = re.compile(r"export\s+namespace\s+([a-zA-Z_]\w+)")

def extract_protobuf_globals(content: str, filepath: Path) -> list[tuple[str, str]]:
    seen: set[str] = set()
    results = []

    # namespace（如 event_pb）
    for m in _PB_NAMESPACE_RE.finditer(content):
        name = m.group(1)
        if name not in seen:
            seen.add(name)
            results.append((name, "Protobuf 命名空间，运行时通过 $root.lookup() 反射访问"))

    # class / interface / enum
    for m in _PB_GLOBAL_RE.finditer(content):
        name = m.group(1)
        if name not in seen and not name[0].islower():
            seen.add(name)
            results.append((name, "Protobuf 生成的类/接口，运行时字符串引用"))

    return results


# ── 5. 圈选 / Hybrid JSON key（$-prefixed）────────────────────────────────────
_DOLLAR_KEY_RE = re.compile(r'["\'](\$[a-zA-Z_][a-zA-Z0-9_]*)["\']')

def extract_dollar_json_keys(content: str, filepath: Path) -> list[tuple[str, str]]:
    seen: set[str] = set()
    results = []
    for m in _DOLLAR_KEY_RE.finditer(content):
        name = m.group(1)
        if name not in seen:
            seen.add(name)
            results.append((name, "圈选/Inspector JSON 树中的 $ 前缀 key，动态属性访问"))
    return results


# ── 6. Hybrid / 其他 string literal key（growing_ 前缀）──────────────────────
_GROWING_KEY_RE = re.compile(r'["\']([a-zA-Z_][a-zA-Z0-9_]*)["\']')
_GROWING_PREFIXES = ("growing_",)

def extract_growing_keys(content: str, filepath: Path) -> list[tuple[str, str]]:
    seen: set[str] = set()
    results = []
    for m in _GROWING_KEY_RE.finditer(content):
        name = m.group(1)
        if any(name.startswith(p) for p in _GROWING_PREFIXES) and name not in seen:
            seen.add(name)
            results.append((name, "Hybrid JSBridge / JSON 消息 key，动态字符串访问"))
    return results


# ── 7. msgType / msgId 等圈选协议 key ─────────────────────────────────────────
_CIRCLE_MSG_KEYS = {"msgType", "msgId", "content", "label", "source", "key", "url"}
_CIRCLE_MSG_RE   = re.compile(r'["\']([a-zA-Z_][a-zA-Z0-9_]*)["\']')

def extract_circle_message_keys(content: str, filepath: Path) -> list[tuple[str, str]]:
    """只收 Circle/Hybrid 协议中已知需要保留的 key"""
    seen: set[str] = set()
    results = []
    for m in _CIRCLE_MSG_RE.finditer(content):
        name = m.group(1)
        if name in _CIRCLE_MSG_KEYS and name not in seen:
            seen.add(name)
            results.append((name, "圈选/Hybrid WebSocket 协议消息 key"))
    return results


# ──────────────────────────────────────────────────────────────────────────────
# 监控规则：哪些文件应该用哪些提取器检查哪些规则文件
# ──────────────────────────────────────────────────────────────────────────────

# kind: 'property' | 'global'
# extractors: list of (fn, kind)
# rules_files: 应当同步的规则文件

@dataclass
class MonitorRule:
    # glob 相对于 ROOT
    path_patterns: list[str]
    extractors: list[tuple]   # (fn, kind: str)
    rules_files: list[Path]
    label: str


MONITOR_RULES: list[MonitorRule] = [
    # ── GrowingAnalytics Event 属性 ───────────────────────────────────────────
    # 只匹配 *Event.ets（事件类定义），排除 EventSender/EventDatabase/EventBuilder 等
    MonitorRule(
        path_patterns=[
            "GrowingAnalytics/src/main/ets/components/event/*Event.ets",
            "GrowingAnalytics/src/main/ets/components/event/hybrid/*Event.ets",
            "GrowingAnalytics/src/main/ets/components/event/saas/*Event.ets",
            "GrowingAnalytics/src/main/ets/components/event/flutter/*Event.ets",
            "GrowingAnalytics/src/main/ets/components/event/uniapp/*Event.ets",
        ],
        extractors=[(extract_event_properties, "property")],
        rules_files=ANALYTICS_RULES_FILES,
        label="GrowingAnalytics · Event 属性",
    ),

    # ── GrowingAnalytics 数据库列名 ───────────────────────────────────────────
    MonitorRule(
        path_patterns=[
            "GrowingAnalytics/src/main/ets/components/event/EventDatabase.ets",
        ],
        extractors=[(extract_db_columns, "property")],
        rules_files=ANALYTICS_RULES_FILES,
        label="GrowingAnalytics · 数据库列名",
    ),

    # ── GrowingAnalytics HTTP Header ──────────────────────────────────────────
    MonitorRule(
        path_patterns=[
            "GrowingAnalytics/src/main/ets/components/core/Network.ets",
        ],
        extractors=[(extract_http_headers, "property")],
        rules_files=ANALYTICS_RULES_FILES,
        label="GrowingAnalytics · HTTP 请求头",
    ),

    # ── GrowingAnalytics Protobuf 全局名 ──────────────────────────────────────
    MonitorRule(
        path_patterns=[
            "GrowingAnalytics/src/main/ets/components/utils/protobuf/event_pb.d.ts",
        ],
        extractors=[(extract_protobuf_globals, "global")],
        rules_files=ANALYTICS_RULES_FILES,
        label="GrowingAnalytics · Protobuf 全局名",
    ),

    # ── GrowingAnalytics 圈选 JSON Schema ────────────────────────────────────
    MonitorRule(
        path_patterns=[
            "GrowingAnalytics/src/main/ets/components/circle/CircleElement.ets",
            "GrowingAnalytics/src/main/ets/components/core/Hybrid.ets",
        ],
        extractors=[
            (extract_dollar_json_keys,    "property"),
            (extract_growing_keys,        "property"),
            (extract_circle_message_keys, "property"),
        ],
        rules_files=ANALYTICS_RULES_FILES,
        label="GrowingAnalytics · 圈选/Hybrid JSON key",
    ),

    # ── GrowingToolsKit Event 属性（Tools 模块内部事件结构）──────────────────
    MonitorRule(
        path_patterns=[
            "GrowingToolsKit/src/main/ets/components/event/*Event.ets",
        ],
        extractors=[(extract_event_properties, "property")],
        rules_files=TOOLS_RULES_FILES,
        label="GrowingToolsKit · Event 属性",
    ),

    # ── GrowingToolsKit 数据库列名 ────────────────────────────────────────────
    MonitorRule(
        path_patterns=[
            "GrowingToolsKit/src/main/ets/components/event/EventDatabase.ets",
        ],
        extractors=[(extract_db_columns, "property")],
        rules_files=TOOLS_RULES_FILES,
        label="GrowingToolsKit · 数据库列名",
    ),

    # ── GrowingToolsKit Protobuf 全局名 ──────────────────────────────────────
    MonitorRule(
        path_patterns=[
            "GrowingToolsKit/src/main/ets/components/utils/protobuf/event_pb.d.ts",
        ],
        extractors=[(extract_protobuf_globals, "global")],
        rules_files=TOOLS_RULES_FILES,
        label="GrowingToolsKit · Protobuf 全局名",
    ),

    # ── GrowingToolsKit HTTP Header ───────────────────────────────────────────
    MonitorRule(
        path_patterns=[
            "GrowingToolsKit/src/main/ets/components/core/Network.ets",
            "GrowingToolsKit/src/main/ets/components/utils/Network.ets",
        ],
        extractors=[(extract_http_headers, "property")],
        rules_files=TOOLS_RULES_FILES,
        label="GrowingToolsKit · HTTP 请求头",
    ),

    # ── GrowingAnalyticsAtomicService Event 属性 ─────────────────────────────
    MonitorRule(
        path_patterns=[
            "GrowingAnalyticsAtomicService/src/main/ets/components/event/*Event.ets",
        ],
        extractors=[(extract_event_properties, "property")],
        rules_files=ATOMIC_SERVICE_RULES_FILES,
        label="GrowingAnalyticsAtomicService · Event 属性",
    ),

    # ── GrowingAnalyticsAtomicService HTTP Header ─────────────────────────────
    MonitorRule(
        path_patterns=[
            "GrowingAnalyticsAtomicService/src/main/ets/components/core/Network.ets",
        ],
        extractors=[(extract_http_headers, "property")],
        rules_files=ATOMIC_SERVICE_RULES_FILES,
        label="GrowingAnalyticsAtomicService · HTTP 请求头",
    ),

    # ── GrowingAnalyticsAtomicService 圈选 JSON Schema ────────────────────────
    MonitorRule(
        path_patterns=[
            "GrowingAnalyticsAtomicService/src/main/ets/components/circle/CircleElement.ets",
        ],
        extractors=[
            (extract_dollar_json_keys,    "property"),
            (extract_growing_keys,        "property"),
            (extract_circle_message_keys, "property"),
        ],
        rules_files=ATOMIC_SERVICE_RULES_FILES,
        label="GrowingAnalyticsAtomicService · 圈选 JSON key",
    ),

    # ── GrowingAnalyticsAtomicService Protobuf 全局名 ─────────────────────────
    MonitorRule(
        path_patterns=[
            "GrowingAnalyticsAtomicService/src/main/ets/components/utils/protobuf/event_pb.d.ts",
        ],
        extractors=[(extract_protobuf_globals, "global")],
        rules_files=ATOMIC_SERVICE_RULES_FILES,
        label="GrowingAnalyticsAtomicService · Protobuf 全局名",
    ),

    # ── Protobuf proto 文件变动（全量扫描三个模块）────────────────────────────
    MonitorRule(
        path_patterns=[
            "resources/event_v3.proto",
        ],
        extractors=[(extract_protobuf_globals, "global")],
        rules_files=ANALYTICS_RULES_FILES + TOOLS_RULES_FILES + ATOMIC_SERVICE_RULES_FILES,
        label="Protobuf Schema (.proto 全局名)",
    ),
]


# ──────────────────────────────────────────────────────────────────────────────
# 文件 → 适用规则匹配
# ──────────────────────────────────────────────────────────────────────────────
def match_monitor_rules(changed_file: Path) -> list[MonitorRule]:
    """给定一个变更文件，返回所有命中的监控规则"""
    import fnmatch
    rel = str(changed_file.relative_to(ROOT))
    matched = []
    for rule in MONITOR_RULES:
        for pattern in rule.path_patterns:
            if fnmatch.fnmatch(rel, pattern):
                matched.append(rule)
                break
    return matched


# ──────────────────────────────────────────────────────────────────────────────
# 主检查逻辑
# ──────────────────────────────────────────────────────────────────────────────
def check(base_branch: str, strict: bool, target_files: list[Path] | None = None) -> list[Finding]:
    """
    运行检查，返回所有发现的缺失保留规则。
    target_files=None 时自动从 git diff 获取变更文件。
    """
    if target_files is None:
        changed = get_changed_files(base_branch)
    else:
        changed = target_files

    # 按模块缓存已解析的规则集，避免重复读取
    _rules_cache: dict[str, RuleSet] = {}

    def get_rules(paths: list[Path]) -> RuleSet:
        key = "|".join(str(p) for p in paths)
        if key not in _rules_cache:
            _rules_cache[key] = parse_rules(paths)
        return _rules_cache[key]

    findings: list[Finding] = []

    for filepath in changed:
        matched_rules = match_monitor_rules(filepath)
        if not matched_rules:
            continue

        try:
            content = filepath.read_text(encoding="utf-8")
        except Exception:
            continue

        for rule in matched_rules:
            ruleset = get_rules(rule.rules_files)

            for extractor_fn, kind in rule.extractors:
                extracted = extractor_fn(content, filepath)
                for symbol, reason in extracted:
                    already_kept = (
                        symbol in ruleset.global_names   if kind == "global"
                        else symbol in ruleset.property_names
                    )
                    if not already_kept:
                        findings.append(Finding(
                            symbol=symbol,
                            kind=kind,
                            source_file=str(filepath.relative_to(ROOT)),
                            reason=reason,
                            rules_files=[str(p.relative_to(ROOT)) for p in rule.rules_files],
                        ))

    # 去重（同一个符号可能被多个提取器发现）
    seen: set[tuple] = set()
    unique: list[Finding] = []
    for f in findings:
        key = (f.symbol, f.kind, "|".join(f.rules_files))
        if key not in seen:
            seen.add(key)
            unique.append(f)

    return unique


# ──────────────────────────────────────────────────────────────────────────────
# 输出格式
# ──────────────────────────────────────────────────────────────────────────────
def print_report(findings: list[Finding], changed_count: int, strict: bool) -> None:
    sep = "─" * 70

    if not findings:
        print(green(f"✓ 混淆规则检查通过（扫描了 {changed_count} 个变更文件）"))
        return

    print()
    print(bold(yellow("⚠  混淆规则检查发现潜在问题")))
    print(dim(sep))
    print(f"  在 {changed_count} 个变更文件中，发现 {bold(str(len(findings)))} 个符号"
          f"{'可能' if not strict else ''}需要加入混淆保留规则。")
    print()

    # 按目标规则文件分组输出
    by_rules: dict[str, list[Finding]] = {}
    for f in findings:
        key = " + ".join(f.rules_files)
        by_rules.setdefault(key, []).append(f)

    for rules_key, group in by_rules.items():
        print(bold(cyan(f"  规则文件：{rules_key}")))
        print()

        # 按 kind 分子组
        globals_  = [f for f in group if f.kind == "global"]
        props     = [f for f in group if f.kind == "property"]

        if globals_:
            print(f"    {bold('-keep-global-name')}")
            for f in globals_:
                print(f"    {yellow(f.symbol)}")
                print(dim(f"      ↳ 来自 {f.source_file}"))
                print(dim(f"      ↳ 原因：{f.reason}"))
            print()

        if props:
            print(f"    {bold('-keep-property-name')}")
            for f in props:
                print(f"    {yellow(f.symbol)}")
                print(dim(f"      ↳ 来自 {f.source_file}"))
                print(dim(f"      ↳ 原因：{f.reason}"))
            print()

    print(dim(sep))

    if strict:
        print(red("✗ --strict 模式：检测到缺失的混淆规则，推送已阻止。"))
        print()
        print("  请检查以上符号是否需要加入对应规则文件的 -keep 列表，")
        print("  确认后重新 push。如确认不需要保留，可在命令后加 --no-verify 跳过。")
    else:
        print(yellow("  这是警告，不阻止推送。请人工确认上述符号是否需要加入保留规则。"))
        print(dim("  提示：以 --strict 运行可在规则缺失时阻止推送。"))

    print()


# ──────────────────────────────────────────────────────────────────────────────
# Hook 模式：输出 Claude Code PreToolUse hook 所需的 JSON
# ──────────────────────────────────────────────────────────────────────────────
def format_findings_text(findings: list[Finding]) -> str:
    """将 findings 格式化为纯文本（供终端输出或 /check-obfuscation skill 使用）"""
    if not findings:
        return ""

    lines = [f"混淆规则检查发现 {len(findings)} 个潜在缺失的保留规则：\n"]

    by_rules: dict[str, list[Finding]] = {}
    for f in findings:
        key = " + ".join(f.rules_files)
        by_rules.setdefault(key, []).append(f)

    for rules_key, group in by_rules.items():
        lines.append(f"【规则文件】{rules_key}")
        globals_ = [f for f in group if f.kind == "global"]
        props    = [f for f in group if f.kind == "property"]
        if globals_:
            lines.append("  -keep-global-name")
            for f in globals_:
                lines.append(f"    {f.symbol}  ← {f.source_file}")
                lines.append(f"      原因：{f.reason}")
        if props:
            lines.append("  -keep-property-name")
            for f in props:
                lines.append(f"    {f.symbol}  ← {f.source_file}")
                lines.append(f"      原因：{f.reason}")
        lines.append("")

    lines.append(
        "请判断上述符号是否确实需要保留（会被动态/反射访问、参与序列化、\n"
        "或作为 JSON/SQL 字符串 key 使用），如需保留请先更新规则文件再推送。\n"
        "如确认无需保留，可继续推送。"
    )
    return "\n".join(lines)


def run_hook_mode(base: str) -> None:
    """
    Claude Code PreToolUse hook 模式。

    设计原则：零 token 开销。
    - 无问题：静默退出（exit 0，不输出任何内容，hook 完全透明）
    - 有发现：只输出 systemMessage（UI 层通知条，不经过 LLM）
             push 照常放行，用户看到通知后可手动运行 /check-obfuscation 处理

    不使用 additionalContext / permissionDecision:ask，避免触发 LLM 响应。
    """
    import json

    findings = check(base_branch=base, strict=False)

    if not findings:
        # 静默放行，零输出
        sys.exit(0)

    symbols_brief = ", ".join(f.symbol for f in findings[:4])
    if len(findings) > 4:
        symbols_brief += f" 等共 {len(findings)} 个"

    # 只用 systemMessage：纯 UI 通知，完全不经过 LLM，零 token
    response = {
        "systemMessage": (
            f"⚠  混淆规则检查：{len(findings)} 个符号可能需要加入保留规则"
            f"（{symbols_brief}）。"
            f"运行 /check-obfuscation 查看详情。"
        ),
    }
    print(json.dumps(response, ensure_ascii=False))
    sys.exit(0)


# ──────────────────────────────────────────────────────────────────────────────
# CLI 入口
# ──────────────────────────────────────────────────────────────────────────────
def parse_args():
    import argparse
    parser = argparse.ArgumentParser(
        description="检查混淆规则是否与代码同步",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent("""
            示例：
              python3 scripts/check_obfuscation_rules.py
              python3 scripts/check_obfuscation_rules.py --base main
              python3 scripts/check_obfuscation_rules.py --strict
              python3 scripts/check_obfuscation_rules.py --hook-mode       # Claude Code hook 专用
              python3 scripts/check_obfuscation_rules.py --file GrowingAnalytics/src/main/ets/components/event/Event.ets
        """),
    )
    parser.add_argument(
        "--base", default="master",
        help="对比基准分支（默认：master）",
    )
    parser.add_argument(
        "--strict", action="store_true",
        help="发现缺失规则时以非零退出码退出（用于 git pre-push hook 阻止推送）",
    )
    parser.add_argument(
        "--hook-mode", action="store_true",
        help="Claude Code PreToolUse hook 模式：输出 JSON 供 hook 系统消费",
    )
    parser.add_argument(
        "--file", metavar="PATH", action="append", dest="files",
        help="手动指定要检查的文件（可多次使用，默认扫描 git diff）",
    )
    parser.add_argument(
        "--all", action="store_true",
        help="扫描所有受监控文件，而不是只看 git diff",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    base = args.base

    # ── Hook 模式：直接输出 JSON，不打印任何终端格式内容 ──
    if args.hook_mode:
        run_hook_mode(base)
        return  # run_hook_mode 内部会 sys.exit

    branch = get_current_branch()

    print(dim(f"  GrowingIO 混淆规则检查器  |  当前分支：{branch}  |  对比基准：{base}"))
    print()

    # 确定要扫描的文件
    if args.all:
        # 扫描所有受监控目录下的文件
        all_files: list[Path] = []
        for rule in MONITOR_RULES:
            for pattern in rule.path_patterns:
                for p in ROOT.glob(pattern):
                    if p.exists() and p not in all_files:
                        all_files.append(p)
        target_files = all_files
        print(dim(f"  模式：全量扫描（{len(target_files)} 个受监控文件）"))
    elif args.files:
        target_files = [Path(f) if Path(f).is_absolute() else ROOT / f for f in args.files]
        print(dim(f"  模式：手动指定文件（{len(target_files)} 个）"))
    else:
        # 只调用一次 git diff，复用结果避免重复 subprocess
        target_files = get_changed_files(base)
        print(dim(f"  模式：git diff {base}...HEAD（{len(target_files)} 个变更文件）"))

    print()

    findings = check(base_branch=base, strict=args.strict, target_files=target_files)

    changed_count = len(target_files)

    print_report(findings, changed_count, args.strict)

    if args.strict and findings:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
