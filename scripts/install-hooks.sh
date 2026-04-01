#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# install-hooks.sh
# 将 scripts/pre-push 安装到 .git/hooks/pre-push
# 每位开发者 clone 项目后运行一次即可。
# ──────────────────────────────────────────────────────────────────────────────

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"
SRC="$REPO_ROOT/scripts/pre-push"
DST="$HOOKS_DIR/pre-push"

if [ ! -f "$SRC" ]; then
  echo "❌  找不到 scripts/pre-push，请先确认文件存在。"
  exit 1
fi

# 如果已有 hook，备份
if [ -f "$DST" ]; then
  BACKUP="${DST}.bak.$(date +%s)"
  echo "⚠  已存在 pre-push hook，备份到 $BACKUP"
  mv "$DST" "$BACKUP"
fi

cp "$SRC" "$DST"
chmod +x "$DST"

echo "✅  pre-push hook 安装完成：$DST"
echo "    每次 git push 时将自动检查混淆规则是否需要更新。"
echo "    如需跳过检查：git push --no-verify"
