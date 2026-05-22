# CLAUDE.md — yibasuo-skill

一把梭 (yibasuo) 全流程开发技能的 Git 仓库和分发管理。

## 仓库

- 远端: `git@github.com:occultskyrong/yibasuo-skill.git`
- 默认分支: `master`

## 自包含性

一把梭是完全自包含的——安装后无需外部依赖即可运行：

| 组件 | 位置 | 说明 |
|------|------|------|
| SKILL.md | `skills/yibasuo/` | 核心技能定义（131 行） |
| 内置 Agent | `agents/`（7 个 .md） | planner/architect/tdd-guide/java-reviewer/typescript-reviewer/code-reviewer/security-reviewer |
| Rules 规范 | `rules/`（common/java/typescript/web） | 编码风格、测试、安全、日志、模式 |
| 提交规范 | `skills/yibasuo/references/commit-conventions.md` | Conventional Commits + SemVer 标签规则 |
| 安装脚本 | `install.sh` | 一键安装 agents + rules + skill |

所有引用均为项目内路径（`rules/...`、`references/...`），不依赖用户本地外部 skill 或配置。

## 版本管理

遵循 **SemVer v2.0**（[semver.org](https://semver.org)）+ **Conventional Commits**（[conventionalcommits.org](https://www.conventionalcommits.org)）。

### 版本号规则

| 提交前缀 | 版本升级 | 示例 |
|---------|:--:|------|
| `fix:` / `fix!:` | **PATCH** `1.0.0→1.0.1` | 修复 bug |
| `feat:` | **MINOR** `1.0.0→1.1.0` | 新增功能 |
| `feat!:` / `fix!:` / `BREAKING CHANGE:` | **MAJOR** `1.0.0→2.0.0` | 破坏性 API 变更 |
| `docs:` `chore:` `style:` `refactor:` `perf:` `test:` `ci:` | **不升级** | 非功能变更 |

破坏性变更用 `!` 标记：`feat!: 重构ApiResponse` 或 footer 写 `BREAKING CHANGE: ...`

### 标签铁律

**标签不可变**。一旦 `git push --tags`，标签永不动。发现错误不 `tag -d` 重打，而是发新版本。

### 版本一致性

以下 5 处版本号必须相同：

| 检查点 | 来源 | 字段 |
|--------|------|------|
| 1 | `VERSION` | 纯文本 |
| 2 | `skills/yibasuo/SKILL.md` | `version: "X.Y.Z"` |
| 3 | `codex/SKILL.md` | `version: "X.Y.Z"` |
| 4 | `README.md` | 标题中的 `vX.Y.Z` |
| 5 | `git tag` | `vX.Y.Z`（注释标签） |

### 发布流程

1. **先定版本号** — 根据 commit 前缀决定 semver 级别
2. **同步 4 份文件** — `VERSION` + `SKILL.md` + `codex/SKILL.md` + `README.md`
3. 追加 `CHANGELOG.md`
4. `git add -A && git commit -m "<type>: <desc> (vX.Y.Z)"`
5. `git tag -a vX.Y.Z -m "yibasuo-skill vX.Y.Z — <summary>"`
6. `git push origin master --tags`
7. **验证** — `bash install.sh --verify` 确认 5 处一致 + 标签打在 HEAD

Commit 格式: `<type>[!]: <description>` (feat/fix/docs/refactor/perf/chore/test/ci)

破坏性变更示例: `feat!: ApiResponse code类型改为Object` — 注意 `!` 在 `:` 之前

## 产物结构

```
yibasuo-skill/
├── VERSION              # 版本号
├── CHANGELOG.md          # 变更日志
├── README.md             # 安装说明
├── CLAUDE.md             # 本文件
├── install.sh            # 安装脚本 (--force 覆盖, --codex Codex, --verify 校验)
├── .gitignore
├── .codex-plugin/
│   └── plugin.json       # Codex 插件清单
├── codex/
│   └── SKILL.md          # Codex 版技能（无 agent 依赖，纯内联指令）
├── rules/
│   ├── common/   (10 files)  # 通用规范，所有项目适用
│   ├── java/     (6 files)   # Java/Spring Boot 规范 + logging.md
│   ├── typescript/ (6 files) # TypeScript/NestJS 规范 + logging.md
│   └── web/      (5 files)   # Vue/React 前端规范
└── skills/
    └── yibasuo/
        └── SKILL.md          # Claude Code 版技能（依赖内置 agent）
```

## 技能设计

### 运行模式

- **自动（默认）**: 触发词 `一把梭` `全流程` `梭哈`，阶段 0-4 连续，只提交确认
- **交互（显式）**: 触发词 `一步步梭` `交互梭` `确认梭`，每阶段确认

### 方法论栈

| 层面 | 来源 | 核心 |
|------|------|------|
| 编排层 | Ng Agentic AI | 6阶段管线 |
| 执行层 | Karpathy 4原则 | 不假设、简洁、手术刀、循环验证 |
| 约束层 | superpowers | brainstorming / TDD铁律 / systematic-debugging / verification |

### 6 阶段

| 阶段 | Claude Code (agent) | Codex (内联) |
|------|--------------------|-------------|
| 0. 需求确认 | 主会话 | 主会话 |
| 1. 规划 | planner agent | 主会话内联分析 |
| 2. 架构 | architect agent | 主会话内联设计 |
| 3. 测试驱动开发 | tdd-guide agent | 主会话内联执行 |
| 4. 审查 | java/typescript-reviewer + security-reviewer | 主会话内联审查 |
| 5. 提交 | 主会话 | 主会话 |

两个版本逻辑完全等价，差异仅在于 Claude Code 版委托 agent 做重活，Codex 版在主会话内完成所有阶段。

### Rules 加载机制

- 阶段 1-2 (planner/architect): 不接触代码，需手动在 agent prompt 注入 rules 上下文
- 阶段 3-4 (tdd-guide/reviewer): 直接操作文件，rules 按 `paths:` 自动匹配

### 提交前验证清单

1. [ ] 全部测试通过，覆盖率 ≥ 80%
2. [ ] 无 CRITICAL/HIGH 审查问题
3. [ ] 格式化已执行（Prettier / p3c）
4. [ ] 构建通过（或缺失已警告并处理）
5. [ ] **NestJS 项目**：`npm start` 启动确认无 DI 错误（`nest build` 不足）
6. [ ] 无 console.log / 调试残留

## GitHub 发布前脱敏清单

以下私人信息**禁止**出现在公开仓库中，每次发布前必须扫描：

| # | 检查项 | 示例 | 位置 |
|---|--------|------|------|
| 1 | 私有 Git 地址 | `git.company.com` | README, install.sh |
| 2 | 项目名/路径 | 特定项目名称映射 | 不在本仓库 |
| 3 | IP/域名 | 内网地址、数据库地址 | rules 示例代码 |
| 4 | 用户名/路径 | `~/code/project/`、真实姓名 | 全仓库 |

**脱敏后的存在形式**：
- `YOUR_USER` 占位（GitHub URL）
- `example.com` / `localhost` 示例
- 敏感配置 → 通过本地配置文件加载，不提交
