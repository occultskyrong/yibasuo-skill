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
├── install.sh                # 一键安装 (--force, --codex, --verify)
├── .codex-plugin/plugin.json # Codex 插件描述
├── .markdownlint.json        # Markdown 格式配置
├── AGENTS.md                 # Agent 职责说明
├── .gitignore
├── agents/ (7 files)         # planner/architect/tdd-guide/java-reviewer
│                             # typescript-reviewer/code-reviewer/security-reviewer
├── rules/
│   ├── common/  (17 files)   # 渐进式拆分，patterns.md 为路由入口
│   ├── java/    (6 files)    # patterns+security+testing+coding-style+logging+hooks
│   ├── typescript/ (6 files) # patterns+security+testing+coding-style+logging+hooks
│   └── web/     (6 files)    # patterns/testing/coding-style/hooks/static-website-checklist/security
├── skills/
│   ├── yibasuo/
│   │   ├── SKILL.md          # 核心技能（开发 5 阶段 + 基建第 6 章）
│   │   └── references/ (8)   # commit-conventions/codegraph/frontend-flows/
│   │                         # infrastructure-review/java-templates/
│   │                         # java-grpc-templates/nestjs-templates/nestjs-grpc-templates
│   └── git-workflow/
│       └── SKILL.md          # Git 提交规范（独立可用）
├── codex/
│   ├── SKILL.md              # Codex 版（纯内联指令）
│   └── references/ (4)       # 与 skills/yibasuo/references/ 同步的子集
└── docs/                     # 文档图片（pipeline.png, tdd-loop.png, review-loop.png）
```

## 自包含性

所有引用均为项目内路径，安装后无需外部依赖。`install.sh` 一键安装 agents + rules + skills。

## 版本管理

遵循 SemVer + Conventional Commits。

| 提交前缀 | 版本升级 |
| --- | ---: |
| `feat!:` `fix!:` `BREAKING CHANGE:` | MAJOR |
| `feat:` | MINOR |
| `fix:` `docs:` `chore:` `style:` `refactor:` `perf:` `test:` `ci:` | PATCH |

**标签不可变**：标签推送后永不 `tag -d` 重打，错误发新版本。

### 发布流程

1. 定版本号
2. 同步 `VERSION` + `SKILL.md` + `README.md` + `codex/SKILL.md` + `.codex-plugin/plugin.json`
3. **README 标题版本号（最容易漏）**
4. 追加 `CHANGELOG.md`
5. `git add -- <本次发布的具体文件...>`，核对 `git diff --cached` 后再 commit
6. `git tag -a vX.Y.Z -m "yibasuo-skill vX.Y.Z — <summary>"`
7. 在干净工作区运行 `./install.sh --verify`
8. 用户确认后分别推送目标分支和当前标签，禁止用 `push --all` 或无范围的 `push --tags`
9. **通过安装器同步本地副本**：

   ```bash
   ./install.sh --force
   ./install.sh --codex --force
   ```

10. 脱敏检查

## 技能设计

### CC vs Codex

| | Claude Code 版 | Codex 版 |
| --- | --- | --- |
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

```text
common/patterns.md (路由) → {topic}.md (细节)
java/patterns.md (路由)  → 引用 common + Java 特有
ts/patterns.md (路由)    → 引用 common + TS 特有
```

## 发布前脱敏清单

| # | 检查项 | 排除区域 |
| --- | --- | --- |
| 1 | 内网 IP/域名 | rules 示例代码 |
| 2 | 用户名/本地路径 | 全仓库 |
| 3 | 硬编码密钥/密码 | 全仓库 |
