# CLAUDE.md — yibasuo-skill

一把梭 (yibasuo) 全流程开发技能的 Git 仓库和分发管理。

## 仓库

- 远端: `git@github.com:occultskyrong/yibasuo-skill.git`
- 默认分支: `master`

## 产物结构

```
yibasuo-skill/
├── VERSION / CHANGELOG.md / README.md / CLAUDE.md
├── LICENSE (MIT)
├── install.sh             # 一键安装 (--force, --codex, --verify)
├── .codex-plugin/plugin.json
├── codex/SKILL.md         # Codex 版（纯内联指令）
├── .gitignore
├── agents/ (7 files)      # planner/architect/tdd-guide/java-reviewer
│                          # typescript-reviewer/code-reviewer/security-reviewer
├── rules/
│   ├── common/  (17 files)   # 渐进式拆分
│   │   ├── patterns.md       # 规范路由（5列：文件+适配场景+审查触发+检查点）
│   │   ├── api-response.md / api-versioning.md / restful-api.md
│   │   ├── grpc-layering.md / time-format.md
│   │   ├── table-structure.md / database-migration.md
│   │   ├── scheduled-tasks.md / logging.md / testing.md
│   │   ├── elasticsearch.md / mongodb.md
│   │   └── security.md / coding-style.md / concurrency.md / ...
│   ├── java/    (6 files)    # patterns(路由)+security+testing+coding-style+logging+hooks
│   ├── typescript/ (6 files) # patterns(路由)+security+testing+coding-style+logging+hooks
│   └── web/     (6 files)    # patterns/testing/coding-style/hooks/static-website-checklist/security
└── skills/
    ├── yibasuo/
    │   ├── SKILL.md                       # 核心技能（~220 行）
    │   └── references/
    │       ├── commit-conventions.md      # Conventional Commits + SemVer
    │       ├── codegraph.md              # CodeGraph 集成
    │       ├── frontend-flows.md         # 前端开发规范（场景路由+迭代内环）
    │       └── infrastructure-review.md  # 基础设施配置审查清单
    └── git-workflow/
        └── SKILL.md                       # Git 提交规范（独立可用）
```

## 自包含性

所有引用均为项目内路径，安装后无需外部依赖。`install.sh` 一键安装 agents + rules + skills。

## 版本管理

遵循 SemVer + Conventional Commits。

| 提交前缀 | 版本升级 |
|---------|:--:|
| `feat!:` `fix!:` `BREAKING CHANGE:` | MAJOR |
| `feat:` | MINOR |
| `fix:` `docs:` `chore:` `style:` `refactor:` `perf:` `test:` `ci:` | PATCH |

**标签不可变**：`push --tags` 后永不 `tag -d` 重打，错误发新版本。

### 发布流程

1. 定版本号 → 2. 同步 `VERSION` + `SKILL.md` + `README.md` + `codex/SKILL.md` + `.codex-plugin/plugin.json` → 3. **README 标题版本号（最容易漏）** → 4. 追加 `CHANGELOG.md`
5. `git add <具体文件> && git commit -m "<type>: <desc>"`
6. `git tag -a vX.Y.Z -m "yibasuo-skill vX.Y.Z — <summary>"`
7. `git push origin master --tags`
8. `echo vX.Y.Z > ~/.claude/skills/yibasuo/.installed-version`
9. **同步到本地安装目录**（install.sh 有增量遗漏风险，提交后手动补齐）：

   ```bash
   # rules
   cp -r rules/* ~/.claude/rules/
   # skills
   cp skills/yibasuo/SKILL.md ~/.claude/skills/yibasuo/
   cp -r skills/yibasuo/references/* ~/.claude/skills/yibasuo/references/
   # agents
   cp agents/*.md ~/.claude/agents/
   ```

   或等效 `rsync -av --delete rules/ ~/.claude/rules/ && rsync -av skills/ ~/.claude/skills/`

10. 脱敏检查

## 技能设计

### CC vs Codex

| | Claude Code 版 | Codex 版 |
|---|--------------|---------|
| 分工 | 委托内置 agent 做重活 | 主会话内联执行 |
| 文件 | `skills/yibasuo/SKILL.md` | `codex/SKILL.md` |
| 安装 | `./install.sh` | `./install.sh --codex` |

### Rules 加载机制（渐进式暴露）

- `rules/common/patterns.md` 为规范路由入口：5 列表格（文件 + 适配场景 + 审查触发条件 + 关键检查点）
- 阶段 1 规划期：Read patterns.md 路由表 → 确定本次适用规范清单 → 注入 planner
- 阶段 2 架构期：按适用规范对照自检（API→restful-api、DB→table-structure、gRPC→grpc-layering）
- 阶段 4 审查期：全量规范逐条核对，清单按规范文件分组标注来源
- Rules 按 `paths:` frontmatter 自动匹配语言

### 规范架构

```
common/patterns.md (路由) → {topic}.md (细节)
java/patterns.md (路由)  → 引用 common + Java 特有
ts/patterns.md (路由)    → 引用 common + TS 特有
```

## 发布前脱敏清单

| # | 检查项 | 排除区域 |
|---|--------|---------|
| 1 | 内网 IP/域名 | rules 示例代码 |
| 2 | 用户名/本地路径 | 全仓库 |
| 3 | 硬编码密钥/密码 | 全仓库 |
