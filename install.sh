#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="yibasuo"
TARGET="claude"
FORCE=0
MODE="install"

for arg in "$@"; do
  case "$arg" in
    --codex) TARGET="codex" ;;
    --force) FORCE=1 ;;
    --verify) MODE="verify" ;;
    --version|-v) MODE="version" ;;
    *)
      echo "ERROR: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "$TARGET" == "codex" ]]; then
  BASE="${XDG_CONFIG_HOME:-$HOME/.agents}"
  SKILL_SRC="codex"
else
  BASE="${XDG_CONFIG_HOME:-$HOME/.claude}"
  SKILL_SRC="skills/$SKILL_NAME"
fi
SKILL_DEST="$BASE/skills/$SKILL_NAME"

if [[ "$MODE" == "version" ]]; then
  if [[ -f "$SKILL_DEST/.installed-version" ]]; then
    echo "yibasuo-skill v$(<"$SKILL_DEST/.installed-version")"
  else
    echo "yibasuo-skill (not installed)"
  fi
  exit 0
fi

verify_release() {
  local errors=0
  local version
  version="$(<"$SCRIPT_DIR/VERSION")"

  echo "=== yibasuo-skill v$version 发布一致性检查 ==="

  check_equal() {
    local label="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$actual" == "$expected" ]]; then
      echo "  [OK] $label: $actual"
    else
      echo "  [FAIL] $label: 期望 $expected, 实际 ${actual:-MISSING}"
      errors=$((errors + 1))
    fi
  }

  check_contains() {
    local label="$1"
    local file="$2"
    local expected="$3"
    if grep -Fq -- "$expected" "$file"; then
      echo "  [OK] $label"
    else
      echo "  [FAIL] $label: 缺少 $expected"
      errors=$((errors + 1))
    fi
  }

  local skill_version codex_version plugin_version readme_version
  skill_version="$(sed -n 's/^  version: *"\([^"]*\)".*/\1/p' \
    "$SCRIPT_DIR/skills/$SKILL_NAME/SKILL.md" | head -1)"
  codex_version="$(sed -n 's/^  version: *"\([^"]*\)".*/\1/p' \
    "$SCRIPT_DIR/codex/SKILL.md" | head -1)"
  plugin_version="$(sed -n 's/^  "version": *"\([^"]*\)".*/\1/p' \
    "$SCRIPT_DIR/.codex-plugin/plugin.json" | head -1)"
  readme_version="$(sed -n '1s/.* v\([0-9][0-9.]*\)$/\1/p' \
    "$SCRIPT_DIR/README.md")"

  check_equal "VERSION" "$version" "$(<"$SCRIPT_DIR/VERSION")"
  check_equal "skills/yibasuo/SKILL.md" "$version" "$skill_version"
  check_equal "codex/SKILL.md" "$version" "$codex_version"
  check_equal ".codex-plugin/plugin.json" "$version" "$plugin_version"
  check_equal "README.md" "$version" "$readme_version"

  check_contains \
    "skills/yibasuo NestJS gRPC 初始化分流" \
    "$SCRIPT_DIR/skills/$SKILL_NAME/SKILL.md" \
    "Java HTTP / Java gRPC / NestJS HTTP / NestJS gRPC / 取消"
  check_contains \
    "skills/yibasuo NestJS gRPC 模板路由" \
    "$SCRIPT_DIR/skills/$SKILL_NAME/SKILL.md" \
    "[references/nestjs-grpc-templates.md](references/nestjs-grpc-templates.md)"
  check_contains \
    "codex NestJS gRPC 初始化分流" \
    "$SCRIPT_DIR/codex/SKILL.md" \
    "Java HTTP / Java gRPC / NestJS HTTP / NestJS gRPC / 取消"
  check_contains \
    "codex NestJS gRPC 模板路由" \
    "$SCRIPT_DIR/codex/SKILL.md" \
    "[references/nestjs-grpc-templates.md](references/nestjs-grpc-templates.md)"

  local reference
  for reference in \
    java-grpc-templates.md \
    java-templates.md \
    nestjs-grpc-templates.md \
    nestjs-templates.md; do
    if cmp -s \
      "$SCRIPT_DIR/skills/$SKILL_NAME/references/$reference" \
      "$SCRIPT_DIR/codex/references/$reference"; then
      echo "  [OK] references/$reference: Claude/Codex 一致"
    else
      echo "  [FAIL] references/$reference: Claude/Codex 内容不一致"
      errors=$((errors + 1))
    fi
  done

  if git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
    local dirty_count tag_match
    dirty_count="$(git -C "$SCRIPT_DIR" status --porcelain \
      --untracked-files=all | wc -l | tr -d ' ')"
    if [[ "$dirty_count" == "0" ]]; then
      echo "  [OK] git worktree: clean"
    else
      echo "  [FAIL] git worktree: $dirty_count 个未提交条目"
      errors=$((errors + 1))
    fi

    tag_match="$(git -C "$SCRIPT_DIR" tag --points-at HEAD \
      | awk -v expected="v$version" '$0 == expected { print; exit }')"
    check_equal "HEAD tag" "v$version" "$tag_match"
  else
    echo "  [FAIL] git repository: 无法验证工作区与发布标签"
    errors=$((errors + 1))
  fi

  echo
  if [[ "$errors" -eq 0 ]]; then
    echo "全部通过 ✓"
    return 0
  fi
  echo "$errors 处不一致；工作区、版本、镜像与标签全部就绪后才可发布 ✗"
  return 1
}

if [[ "$MODE" == "verify" ]]; then
  verify_release
  exit $?
fi

# curl/单文件执行时，脚本旁边没有完整仓库；克隆到独立临时目录。
REPO_URL="${YIBASUO_REPO:-git@github.com:occultskyrong/yibasuo-skill.git}"
if [[ ! -d "$SCRIPT_DIR/rules" ]] \
  || [[ ! -d "$SCRIPT_DIR/skills/$SKILL_NAME" ]]; then
  INSTALL_TMP="$(mktemp -d)"
  trap 'rm -rf "$INSTALL_TMP"' EXIT
  echo "[*] Cloning yibasuo-skill from $REPO_URL..."
  if ! git clone --depth 1 "$REPO_URL" "$INSTALL_TMP/yibasuo-skill"; then
    echo "ERROR: Failed to clone $REPO_URL" >&2
    echo "Set YIBASUO_REPO to an accessible repository URL." >&2
    exit 1
  fi
  SCRIPT_DIR="$INSTALL_TMP/yibasuo-skill"
fi

VERSION="$(<"$SCRIPT_DIR/VERSION")"

echo "========================================"
echo "  一把梭 Skill 安装器 v$VERSION"
echo "========================================"
echo

PREV_VERSION_FILE="$SKILL_DEST/.installed-version"
if [[ -f "$PREV_VERSION_FILE" ]]; then
  PREV_VERSION="$(<"$PREV_VERSION_FILE")"
  if [[ "$PREV_VERSION" == "$VERSION" ]] && [[ "$FORCE" -ne 1 ]]; then
    echo "[i] 当前已安装 v$VERSION。需要修复本地副本时使用 --force。"
    exit 0
  fi
  echo "[i] 当前版本: v$PREV_VERSION → 安装版本: v$VERSION"
  echo
fi

# 对由本安装器独占的目录做同父目录原子替换，防止升级后残留已删除文件。
replace_owned_dir() {
  local src="$1"
  local dest="$2"
  local parent name stage backup=""

  parent="$(dirname "$dest")"
  name="$(basename "$dest")"
  mkdir -p "$parent"
  stage="$(mktemp -d "$parent/.${name}.new.XXXXXX")"
  cp -R "$src"/. "$stage"/

  if [[ -e "$dest" || -L "$dest" ]]; then
    backup="$(mktemp -d "$parent/.${name}.old.XXXXXX")"
    rmdir "$backup"
    mv "$dest" "$backup"
  fi

  if mv "$stage" "$dest"; then
    if [[ -n "$backup" ]]; then
      rm -rf "$backup"
    fi
  else
    if [[ -n "$backup" && ! -e "$dest" ]]; then
      mv "$backup" "$dest"
    fi
    echo "ERROR: failed to replace $dest" >&2
    return 1
  fi
}

# rules/* 是共享目录，只覆盖本包提供的同名文件，不删除其他技能的规则。
echo "[1/4] Installing rules..."
for lang in common java typescript web; do
  src="$SCRIPT_DIR/rules/$lang"
  dest="$BASE/rules/$lang"
  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    cp -R "$src"/. "$dest"/
    count="$(find "$src" -type f | wc -l | tr -d ' ')"
    echo "  [+] rules/$lang: $count files"
  fi
done

echo
echo "[2/4] Installing skills..."
replace_owned_dir "$SCRIPT_DIR/$SKILL_SRC" "$SKILL_DEST"
replace_owned_dir \
  "$SCRIPT_DIR/skills/git-workflow" \
  "$BASE/skills/git-workflow"
echo "  [+] skills/$SKILL_NAME ($TARGET)"
echo "  [+] skills/git-workflow"

echo
echo "[3/4] Checking optional tools..."
for tool in ts-prune codegraph; do
  if command -v "$tool" &>/dev/null; then
    echo "  [OK] $tool: available"
  else
    echo "  [i] $tool: not installed (optional; installer will not modify global tools)"
  fi
done

if [[ "$TARGET" == "codex" ]]; then
  echo
  echo "[4/4] Skipping Claude-only agents"
else
  echo
  echo "[4/4] Installing Claude agents..."
  AGENT_DEST="$BASE/agents"
  mkdir -p "$AGENT_DEST"
  installed=0
  skipped=0
  shopt -s nullglob
  for agent in "$SCRIPT_DIR/agents"/*.md; do
    agent_name="$(basename "$agent")"
    if [[ -f "$AGENT_DEST/$agent_name" ]] && [[ "$FORCE" -ne 1 ]]; then
      skipped=$((skipped + 1))
    else
      cp "$agent" "$AGENT_DEST/$agent_name"
      installed=$((installed + 1))
    fi
  done
  shopt -u nullglob
  echo "  [+] agents: $installed installed, $skipped preserved"
fi

echo "$VERSION" > "$SKILL_DEST/.installed-version"

echo
echo "========================================"
echo "  安装完成 — yibasuo v$VERSION"
echo "========================================"
if [[ "$TARGET" == "codex" ]]; then
  echo "在 Codex 中说“一把梭”即可使用。"
else
  echo "重启 Claude Code 后，说“一把梭”即可使用。"
fi
echo
echo "命令:"
echo "  ./install.sh             安装到 Claude Code"
echo "  ./install.sh --codex     安装到 Codex"
echo "  ./install.sh --force     覆盖同版本的技能副本"
echo "  ./install.sh --version   查看已安装版本"
echo "  ./install.sh --verify    发布一致性检查"
