#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="yibasuo"
TARGET="claude"
FORCE=""
for arg in "$@"; do
  case "$arg" in
    --codex) TARGET="codex" ;;
    --force) FORCE="--force" ;;
  esac
done

if [[ "$TARGET" == "codex" ]]; then
  BASE="${XDG_CONFIG_HOME:-$HOME/.agents}"
  SKILL_SRC="codex"
else
  BASE="${XDG_CONFIG_HOME:-$HOME/.claude}"
  SKILL_SRC="skills/$SKILL_NAME"
fi

# Default repo URL (update when publishing to GitHub)
REPO_URL="${YIBASUO_REPO:-https://github.com/YOUR_USER/yibasuo-skill.git}"

# --- --version ---
if [[ "${1:-}" == "--version" ]] || [[ "${1:-}" == "-v" ]]; then
  if [[ -f "$BASE/skills/$SKILL_NAME/.installed-version" ]]; then
    echo "yibasuo-skill v$(cat "$BASE/skills/$SKILL_NAME/.installed-version")"
  else
    echo "yibasuo-skill (not installed)"
  fi
  exit 0
fi

# --- --verify ---
if [[ "${1:-}" == "--verify" ]]; then
  ERRORS=0
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  VER="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "MISSING")"
  echo "=== yibasuo-skill v$VER 一致性检查 ==="

  check() {
    local label="$1" file="$2" pattern="$3"
    local actual
    actual="$(grep "$pattern" "$file" 2>/dev/null | head -1 || echo '')"
    if echo "$actual" | grep -q "$VER"; then
      echo "  [OK] $label: $VER"
    else
      echo "  [FAIL] $label: 期望 $VER, 实际 $(echo $actual | head -c 80)"
      ((ERRORS++))
    fi
  }

  check "VERSION      " "$SCRIPT_DIR/VERSION" "$VER"
  check "SKILL.md     " "$SCRIPT_DIR/skills/$SKILL_NAME/SKILL.md" "version:"
  check "README       " "$SCRIPT_DIR/README.md" "v[0-9]"
  check "git tag      " <(cd "$SCRIPT_DIR" && git tag --points-at HEAD 2>/dev/null || echo "NO_TAG") "v[0-9]"

  echo ""
  if [[ $ERRORS -eq 0 ]]; then
    echo "全部通过 ✓"
    exit 0
  else
    echo "$ERRORS 处不一致，请修复后重新发布 ✗"
    exit 1
  fi
fi

# --- Detect standalone mode (piped via curl, no repo alongside) ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -d "$SCRIPT_DIR/rules" ]] || [[ ! -d "$SCRIPT_DIR/skills/$SKILL_NAME" ]]; then
  # Standalone: clone repo to temp dir
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT
  echo "[*] Cloning yibasuo-skill from $REPO_URL..."
  git clone --depth 1 "$REPO_URL" "$TMPDIR/yibasuo-skill" 2>/dev/null || {
    echo "ERROR: Failed to clone $REPO_URL"
    echo "Set YIBASUO_REPO env var to your repo URL, or install manually:"
    echo "  git clone $REPO_URL /tmp/yibasuo-skill && cd /tmp/yibasuo-skill && ./install.sh"
    exit 1
  }
  SCRIPT_DIR="$TMPDIR/yibasuo-skill"
fi

VERSION="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "unknown")"

echo "========================================"
echo "  一把梭 Skill 安装器 v$VERSION"
echo "========================================"
echo ""

# --- Check previous install ---
PREV_VERSION_FILE="$BASE/skills/$SKILL_NAME/.installed-version"
if [[ -f "$PREV_VERSION_FILE" ]]; then
  PREV_VERSION="$(cat "$PREV_VERSION_FILE")"
  if [[ "$VERSION" != "unknown" ]] && [[ "$PREV_VERSION" == "$VERSION" ]]; then
    echo "[i] 当前已是最新版本 v$VERSION，无需更新。"
    echo "    强制覆盖: ./install.sh --force"
    exit 0
  fi
  echo "[i] 当前版本: v$PREV_VERSION → 新版本: v$VERSION"
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

for lang in common java typescript web; do
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
  cp -r "$SCRIPT_DIR/$SKILL_SRC"/* "$SKILL_DEST/"
  echo "  [+] skills/$SKILL_NAME installed ($TARGET)"
fi

# --- Force mode ---
if [[ "$FORCE" == "--force" ]]; then
  echo ""
  echo "[force] Overwriting all existing files..."
  for lang in common java typescript web; do
    mkdir -p "$BASE/rules/$lang"
    cp -r "$SCRIPT_DIR/rules/$lang"/* "$BASE/rules/$lang/"
    echo "  [+] rules/$lang (force overwritten)"
  done
  mkdir -p "$SKILL_DEST"
  cp -r "$SCRIPT_DIR/$SKILL_SRC"/* "$SKILL_DEST/"
  echo "  [+] skills/$SKILL_NAME (force overwritten, $TARGET)"
fi

# --- Write installed version marker ---
echo "$VERSION" > "$SKILL_DEST/.installed-version"

echo ""
echo "========================================"
echo "  安装完成 — yibasuo v$VERSION"
echo "========================================"
echo ""
if [[ "$TARGET" == "codex" ]]; then
  echo "在 Codex 中说 \"一把梭\" 即可使用。"
else
  echo "重启 Claude Code 后，说 \"一把梭\" 即可使用。"
  echo ""
  echo "依赖的 agent（Claude Code 内置）："
  echo "  - planner / architect / tdd-guide / code-reviewer / security-reviewer"
fi
echo ""
echo "命令:"
echo "  ./install.sh            首次安装 (Claude Code)"
echo "  ./install.sh --codex    安装到 Codex"
echo "  ./install.sh --force    强制覆盖"
echo "  ./install.sh --version  查看版本"
echo "  ./install.sh --verify   版本一致性检查"
