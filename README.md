# 一把梭 (yibasuo) — Claude Code 全流程开发 Skill v1.6.0

> 需求 → 规划 → 架构 → TDD → 审查 → 提交，一条龙。

## 安装

### 方式一：一句话让 Claude 装（推荐）

> 从 git@git.mypacelab.com:tools/yibasuo-skill.git clone 到 /tmp，执行 install.sh，完成后删掉临时目录

### 方式二：手动

```bash
git clone git@git.mypacelab.com:tools/yibasuo-skill.git /tmp/yibasuo-skill
cd /tmp/yibasuo-skill
./install.sh          # 首次安装
./install.sh --force  # 覆盖更新
rm -rf /tmp/yibasuo-skill
```

重启 Claude Code 后说 **"一把梭"** 即可触发。

## 更新

> 从 git@git.mypacelab.com:tools/yibasuo-skill.git clone 到 /tmp，执行 install.sh --force 覆盖更新，完成后删掉临时目录

查看已安装版本：`cat ~/.claude/skills/yibasuo/.installed-version`

## 运行模式

**默认自动**：阶段 0-4 自动连续执行，只阶段 5（提交）暂停确认。

| 模式 | 触发词 | 阶段 0 | 阶段 1-4 | 阶段 5 |
|------|--------|--------|---------|--------|
| 自动（默认） | `一把梭` `全流程` `梭哈` | 确认 | 连续 | 确认 |
| 交互（显式） | `一步步梭` `交互梭` `确认梭` | 确认 | 每阶段确认 | 确认 |

中途说"停一下"切交互，说"继续梭"回自动。

## 阶段管线

```
0.需求确认 → 1.规划 → 2.架构 → 3.TDD → 4.审查 → 5.提交（格式→构建→commit）
```

## 语言适配

| 技术栈 | 规范 + 工具链 |
|--------|------------|
| Java / Spring Boot | 阿里巴巴 p3c + JUnit5 + AssertJ + Mockito + Testcontainers |
| Node.js / NestJS | Vitest/Jest + supertest + pino + `__` 私有前缀 |
| Vue / React 前端 | Composition API / Hooks + Playwright E2E + Prettier + ESLint + Vite |

## 提交阶段（阶段 5）

所有项目统一流程：

1. `git diff --stat`
2. **格式化**：Prettier（前端/Node.js）/ p3c pmd:check（Java）
3. **构建验证**（前端/Node.js）：`pnpm build`。**缺少 build 命令时明确警告并暂停**
4. Conventional commit（`<type>: <description>`）
5. 展示确认
6. `git add` + `git commit`

## 依赖

### Agent（Claude Code 内置）

planner / architect / tdd-guide / java-reviewer / typescript-reviewer / security-reviewer

### Rules（随 install.sh 安装）

| Rules | 适用 |
|-------|------|
| `rules/common/` | 通用规范（必装） |
| `rules/java/` | Java / Spring Boot |
| `rules/typescript/` | Node.js / NestJS |
| `rules/web/` | Vue / React 前端 |

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 / 重构 | 完整 6 阶段 |
| Bug 修复 | 跳过 1-2，直接 TDD + 审查 + 提交 |
| 单文件小改 | 不建议用，直接改 + 审查 |

## 目录结构

```
yibasuo-skill/
├── VERSION
├── CHANGELOG.md
├── README.md
├── CLAUDE.md
├── install.sh
├── rules/
│   ├── common/   (11 files)
│   ├── java/     (6 files)
│   ├── typescript/ (6 files)
│   └── web/      (5 files: coding-style, testing, patterns, hooks, static-checklist)
└── skills/
    └── yibasuo/
        └── SKILL.md
```
