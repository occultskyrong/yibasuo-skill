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

# Default repo URL
REPO_URL="${YIBASUO_REPO:-git@git.mypacelab.com:tools/yibasuo-skill.git}"

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
  check "codex/SKILL  " "$SCRIPT_DIR/codex/SKILL.md" "version:"
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
echo "[1/4] Installing rules..."

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
echo "[2/4] Installing skill: $SKILL_NAME..."

SKILL_DEST="$BASE/skills/$SKILL_NAME"

if [[ -d "$SKILL_DEST" ]]; then
  echo "  [-] skills/$SKILL_NAME already exists, skipping (use --force to overwrite)"
else
  mkdir -p "$SKILL_DEST"
  cp -r "$SCRIPT_DIR/$SKILL_SRC"/* "$SKILL_DEST/"
  echo "  [+] skills/$SKILL_NAME installed ($TARGET)"
fi

# --- Optional tools ---
echo ""
echo "[3/4] Installing optional tools..."

install_tool() {
  local name="$1"
  local pkg="$2"
  echo -n "  $name ... "
  if command -v "$name" &>/dev/null || npx "$name" --version &>/dev/null 2>&1; then
    echo "already available"
  elif npm install -g "$pkg" 2>/dev/null; then
    echo "installed"
  else
    echo "skipped (install manually: npm install -g $pkg)"
  fi
}

install_tool ts-prune ts-prune

# codegraph: requires Node 18-24 → wrapper auto-switches via nvm
install_codegraph() {
  local wrapper_dest

  # Find writable bin dir (prefer ~/.local/bin for portability)
  for d in "$HOME/.local/bin" "/usr/local/bin"; do
    if [[ -d "$d" ]] && [[ -w "$d" ]]; then wrapper_dest="$d"; break; fi
  done
  [[ -z "$wrapper_dest" ]] && wrapper_dest="$HOME/.local/bin"
  mkdir -p "$wrapper_dest"

  # Write portable wrapper: auto-detect nvm, switch to 22, exec codegraph
  cat > "$wrapper_dest/codegraph" << 'CGWRAP'
#!/usr/bin/env bash
set -e
# find nvm
for nvm_dir in "${NVM_DIR:-}" "$HOME/.nvm"; do
  [[ -s "$nvm_dir/nvm.sh" ]] && . "$nvm_dir/nvm.sh" && break
done
# switch to node 22
nvm use 22 >/dev/null 2>&1 || {
  echo "[codegraph] Node 22 not found. Install: nvm install 22" >&2
  exit 1
}
exec codegraph "$@"
CGWRAP
  chmod +x "$wrapper_dest/codegraph"

  echo -n "  codegraph wrapper -> $wrapper_dest/codegraph ... "
  if "$wrapper_dest/codegraph" --version &>/dev/null; then
    echo "ok ($("$wrapper_dest/codegraph" --version 2>/dev/null))"
  else
    echo "wrapper created (install codegraph: nvm use 22 && npx @colbymchenry/codegraph)"
  fi
}
install_codegraph

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

  echo "  [+] agents/* (force overwritten)"
fi

# --- Agents ---
echo ""
echo "[4/4] Installing agents..."
AGENT_DEST="$BASE/agents"

if [[ -d "$SCRIPT_DIR/agents" ]]; then
  mkdir -p "$AGENT_DEST"
  installed=0 skipped=0
  for agent in "$SCRIPT_DIR/agents"/*.md; do
    agent_name=$(basename "$agent")
    if [[ -f "$AGENT_DEST/$agent_name" ]] && [[ "$FORCE" != "--force" ]]; then
      ((skipped++))
    else
      cp "$agent" "$AGENT_DEST/"
      ((installed++))
    fi
  done
  echo "  [+] agents: $installed installed, $skipped skipped (use --force to overwrite)"
fi

if [[ "$FORCE" == "--force" ]] && [[ -d "$SCRIPT_DIR/agents" ]]; then
  cp "$SCRIPT_DIR/agents"/*.md "$AGENT_DEST/"
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
  echo "  - java-reviewer / typescript-reviewer"
fi
echo ""
echo "命令:"
echo "  ./install.sh            首次安装 (Claude Code)"
echo "  ./install.sh --codex    安装到 Codex"
echo "  ./install.sh --force    强制覆盖"
echo "  ./install.sh --version  查看版本"
echo "  ./install.sh --verify   版本一致性检查"
