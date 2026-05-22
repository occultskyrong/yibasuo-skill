# CLAUDE.md — yibasuo-skill

一把梭 (yibasuo) 全流程开发技能的 Git 仓库和分发管理。

## 仓库

- 远端: `git@github.com:occultskyrong/yibasuo-skill.git`
- 默认分支: `master`
- 发布分支: `main`（GitHub 公开版，干净单 commit）

## 产物结构

```
yibasuo-skill/
├── VERSION / CHANGELOG.md / README.md / CLAUDE.md
├── install.sh             # 一键安装 (--force, --codex, --verify)
├── .codex-plugin/plugin.json
├── codex/SKILL.md         # Codex 版（纯内联指令，无 agent 依赖）
├── .gitignore
├── agents/ (7 files)      # planner / architect / tdd-guide / java-reviewer
│                          # typescript-reviewer / code-reviewer / security-reviewer
├── rules/
│   ├── common/  (10 files)
│   ├── java/    (6 files)
│   ├── typescript/ (6 files)
│   └── web/     (5 files)
└── skills/
    ├── yibasuo/
    │   ├── SKILL.md                       # 核心技能（~160 行）
    │   └── references/commit-conventions.md
    └── git-workflow/
        └── SKILL.md                       # Git 提交规范（独立可用）
```

## 自包含性

所有引用均为项目内路径，安装后无需外部依赖。`install.sh` 一键安装 agents + rules + skills。

## 版本管理

遵循 SemVer + Conventional Commits。

| 提交前缀 | 版本升级 |
|---------|:--:|
| `fix:` `fix!:` | PATCH |
| `feat:` | MINOR |
| `feat!:` `BREAKING CHANGE:` | MAJOR |
| `docs:` `chore:` `style:` `refactor:` `perf:` `test:` `ci:` | 不升级 |

**标签不可变**：`push --tags` 后永不 `tag -d` 重打，错误发新版本。

### 发布流程

1. 定版本号 → 2. 同步 `VERSION` + `SKILL.md`(3个) + `README.md` → 3. 追加 `CHANGELOG.md`
4. `git add -A && git commit -m "<type>[!]: <desc> (vX.Y.Z)"`
5. `git tag -a vX.Y.Z -m "yibasuo-skill vX.Y.Z — <summary>"`
6. `git push origin master --tags`
7. `bash install.sh --verify` 确认 5 处一致 + tag 在 HEAD
8. 更新 `github-release` 分支并推送 GitHub

## 技能设计

### CC vs Codex

| | Claude Code 版 | Codex 版 |
|---|--------------|---------|
| 分工 | 委托内置 agent 做重活 | 主会话内联执行 |
| 文件 | `skills/yibasuo/SKILL.md` | `codex/SKILL.md` |
| 安装 | `./install.sh` | `./install.sh --codex` |

逻辑等价：6 阶段管线、行为红线、语言适配完全一致。

### Rules 加载机制

- 阶段 1-2 (planner/architect)：不接触代码文件，需手动在 agent prompt 中注入 rules 上下文
- 阶段 3-4 (tdd-guide/reviewer)：直接操作文件，rules 按 `paths:` 自动匹配

### 其他发布技能

- `skills/git-workflow/SKILL.md` — Git 提交操作规范（独立可用，`install.sh` 同时安装）
- `skills/yibasuo/references/commit-conventions.md` — Conventional Commits + SemVer 标签规则

## GitHub 发布前脱敏清单

每次公开推送前扫描：

| # | 检查项 | 排除区域 |
|---|--------|---------|
| 1 | 私有 Git 地址 | README, install.sh |
| 2 | 项目名称映射 | 全仓库 |
| 3 | 内网 IP/域名 | rules 示例代码 |
| 4 | 用户名/本地路径 | 全仓库 |
| 5 | 硬编码密钥/密码 | 全仓库 |

**脱敏后**：GitHub URL 占位、`example.com`/`localhost` 示例、本地配置外部加载。
