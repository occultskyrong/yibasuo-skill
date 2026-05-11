#!/usr/bin/env bash
set -euo pipefail

BASE="${XDG_CONFIG_HOME:-$HOME/.claude}"
SKILL_NAME="yibasuo"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Read version ---
VERSION="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "unknown")"

# --- --version ---
if [[ "${1:-}" == "--version" ]] || [[ "${1:-}" == "-v" ]]; then
  echo "yibasuo-skill v$VERSION"
  exit 0
fi

echo "========================================"
echo "  一把梭 Skill 安装器 v$VERSION"
echo "========================================"
echo ""

# --- Check previous install ---
PREV_VERSION_FILE="$BASE/skills/$SKILL_NAME/.installed-version"
if [[ -f "$PREV_VERSION_FILE" ]]; then
  PREV_VERSION="$(cat "$PREV_VERSION_FILE")"
  echo "[i] 当前已安装版本: v$PREV_VERSION, 即将安装: v$VERSION"
  echo ""
fi

# --- Rules ---
echo "[1/2] Installing rules..."

install_rules() {
  local lang="$1"
  local src="$SCRIPT_DIR/rules/$lang"
  local dest="$BASE/rules/$lang"

  if [[ -d "$src" ]]; then
    if [[ -d "$dest" ]]; then
      echo "  [-] rules/$lang already exists, skipping (use --force to overwrite)"
    else
      mkdir -p "$dest"
      cp -r "$src"/* "$dest/"
      echo "  [+] rules/$lang installed"
    fi
  fi
}

for lang in common java typescript; do
  install_rules "$lang"
done

# --- Skill ---
echo ""
echo "[2/2] Installing skill: $SKILL_NAME..."

SKILL_DEST="$BASE/skills/$SKILL_NAME"

if [[ -d "$SKILL_DEST" ]]; then
  echo "  [-] skills/$SKILL_NAME already exists, skipping (use --force to overwrite)"
else
  mkdir -p "$SKILL_DEST"
  cp -r "$SCRIPT_DIR/skills/$SKILL_NAME"/* "$SKILL_DEST/"
  echo "  [+] skills/$SKILL_NAME installed"
fi

# --- Force mode ---
if [[ "${1:-}" == "--force" ]]; then
  echo ""
  echo "[force] Overwriting all existing files..."
  for lang in common java typescript; do
    mkdir -p "$BASE/rules/$lang"
    cp -r "$SCRIPT_DIR/rules/$lang"/* "$BASE/rules/$lang/"
    echo "  [+] rules/$lang (force overwritten)"
  done
  mkdir -p "$SKILL_DEST"
  cp -r "$SCRIPT_DIR/skills/$SKILL_NAME"/* "$SKILL_DEST/"
  echo "  [+] skills/$SKILL_NAME (force overwritten)"
fi

# --- Write installed version marker ---
echo "$VERSION" > "$SKILL_DEST/.installed-version"

echo ""
echo "========================================"
echo "  安装完成 — yibasuo v$VERSION"
echo "========================================"
echo ""
echo "重启 Claude Code 后，说 \"一把梭\" 即可使用。"
echo ""
echo "版本检查: install.sh --version"
echo ""
echo "依赖的 agent（内置，无需安装）："
echo "  - planner      (阶段1: 规划)"
echo "  - architect    (阶段2: 架构)"
echo "  - tdd-guide    (阶段3: TDD)"
echo "  - code-reviewer (阶段4: 审查)"
echo "  - security-reviewer (阶段4: 安全审查)"
