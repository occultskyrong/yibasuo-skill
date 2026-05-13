# CLAUDE.md — yibasuo-skill

一把梭 (yibasuo) 全流程开发技能的 Git 仓库和分发管理。

## 仓库

- 远端: `https://github.com/YOUR_USER/yibasuo-skill.git`
- 默认分支: `main`（或 `master`）

## 版本管理

**版本一致性铁律**：以下 4 处版本号必须相同，与 git tag 一致。任何一处不同即为 bug。

| 检查点 | 文件 | 字段 |
|--------|------|------|
| 1 | `VERSION` | 纯文本 |
| 2 | `skills/yibasuo/SKILL.md` | `version: "X.Y.Z"` |
| 3 | `README.md` | 标题中的 `vX.Y.Z` |
| 4 | `git tag` | `vX.Y.Z` |

发布流程：
1. **先定版本号** — 根据变更类型决定 semver（feat→minor, fix→patch, break→major）
2. **同步 3 个文件** — `VERSION` + `SKILL.md` version + `README.md` 标题
3. 追加 `CHANGELOG.md`
4. `git add -A && git commit -m "<type>: <desc> (vX.Y.Z)"`
5. `git tag -a vX.Y.Z -m "yibasuo-skill vX.Y.Z — <summary>"`
6. `git push origin main --tags`
7. **验证** — `git tag --points-at HEAD` 确认 tag 打在最新 commit 上

Commit 格式: `<type>: <description>` (feat/fix/docs/refactor/perf)

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
│   ├── common/   (11 files)  # 通用规范，所有项目适用
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
| 1. 规划 | planner agent | 内联分析 |
| 2. 架构 | architect agent | 内联生成 |
| 3. 测试驱动开发 | tdd-guide agent | 内联执行 |
| 4. 审查 | java/typescript-reviewer + security-reviewer | 内联审查 |
| 5. 提交 | 主会话 | 主会话 |

两个版本逻辑完全等价，差异仅在于 Claude Code 依赖内置 agent，Codex 用内联指令。

### Rules 加载机制

- 阶段 1-2 (planner/architect): 不接触代码，需手动在 agent prompt 注入 rules 上下文
- 阶段 3-4 (tdd-guide/reviewer): 直接操作文件，rules 按 `paths:` 自动匹配

### 提交前验证清单

1. [ ] 全部测试通过，覆盖率 ≥ 80%
2. [ ] 无 CRITICAL/HIGH 审查问题
3. [ ] 格式化已执行（Prettier / p3c）
4. [ ] 构建通过（或缺失已警告并处理）
5. [ ] 无 console.log / 调试残留

## GitHub 发布前脱敏清单

以下私人信息**禁止**出现在公开仓库中，每次发布前必须扫描：

| # | 检查项 | 示例 | 位置 |
|---|--------|------|------|
| 1 | 私有 GitLab 地址 | `git.mypacelab.com` | README, CLAUDE, install.sh |
| 2 | 项目名/路径 | 特定项目名称映射 | 不在本仓库 — 存 `~/.claude/config/git-base-branches.conf` |
| 3 | IP/域名 | 内网地址、数据库地址 | rules/logging.md 示例 |
| 4 | 用户名/路径 | `~/code/witkey/`、`zhangrz` | CLAUDE.md, CHANGELOG |

**脱敏后的存在形式**：
- `YOUR_USER` 占位（GitHub URL）
- `example.com` / `localhost` 示例
- 基准分支映射 → 不在此仓库，通过 `~/.claude/config/` 本地加载
