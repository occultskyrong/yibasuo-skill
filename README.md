# 一把梭 (yibasuo) — Claude Code 全流程开发 Skill

> 输入需求 → 规划 → 架构 → TDD 实现 → 审查 → 提交，一条龙。

## 安装

### 方式一：一句话让 Claude 装（推荐）

在 Claude Code 里直接说：

> 从 git@git.mypacelab.com:tools/yibasuo-skill.git clone 到 /tmp，执行 install.sh，完成后删掉临时目录

### 方式二：手动安装

```bash
git clone git@git.mypacelab.com:tools/yibasuo-skill.git /tmp/yibasuo-skill
cd /tmp/yibasuo-skill
./install.sh
rm -rf /tmp/yibasuo-skill

# 如需强制覆盖已有配置
./install.sh --force
```

重启 Claude Code 后，说 **"一把梭"** 即可触发。

## 更新

### 方式一：一句话让 Claude 更新（推荐）

在 Claude Code 里直接说：

> 从 git@git.mypacelab.com:tools/yibasuo-skill.git clone 到 /tmp，执行 install.sh --force 覆盖更新，完成后删掉临时目录

### 方式二：手动更新

```bash
git clone git@git.mypacelab.com:tools/yibasuo-skill.git /tmp/yibasuo-skill
cd /tmp/yibasuo-skill
./install.sh --force
rm -rf /tmp/yibasuo-skill
```

### 检查当前版本

```bash
cat ~/.claude/skills/yibasuo/.installed-version
```

## 依赖

### 内置 Agent（Claude Code 自带，无需安装）

| Agent | 阶段 | 用途 |
|-------|------|------|
| planner | 阶段1 规划 | 生成实现计划和任务分解 |
| architect | 阶段2 架构 | 设计技术方案、产出 ADR |
| tdd-guide | 阶段3 TDD | 测试驱动开发，先测试后实现 |
| code-reviewer | 阶段4 审查 | 代码质量和模式审查 |
| security-reviewer | 阶段4 安全 | 安全漏洞扫描 |

### Rules（随安装脚本自动安装）

| Rules | 适用场景 |
|-------|---------|
| `rules/common/` | 通用编码规范（必装） |
| `rules/java/` | Java / Spring Boot 项目 |
| `rules/typescript/` | Node.js / NestJS 项目 |
| `rules/web/` | 前端静态网站项目 |

## 工作流

### 两种运行模式

| 模式 | 触发词 | 行为 | 适用场景 |
| --- | --- | --- | --- |
| 交互模式 | `一把梭` `全流程` `梭哈` | 每阶段暂停等确认 | 复杂需求、新项目 |
| 自动模式 | `自动梭` `全自动` `一路梭到底` | 阶段 0-4 连续走，提交前确认 | 熟悉项目、简单需求 |

中途随时可切换：说"自动走完剩下的"或"停一下"。

### 6 阶段管线

```
需求确认 → 规划 → 架构 → TDD 实现 → 审查 → 提交
   ▲                              ▲          ▲
   │                              │          │
 两种模式                       自动      两种模式
 都需确认                       跳过      都需确认
```

CRITICAL 和 HIGH 级别审查问题两种模式都强制拦截。

## 适用判断

| 任务类型 | 建议 |
|----------|------|
| 新功能开发 | 走完整 6 阶段 |
| Bug 修复 | 跳过规划/架构，直接 TDD + 审查 + 提交 |
| 重构 | 走完整流程，阶段 2 侧重风险评估 |
| 单文件小改 | 不建议，直接改 + 审查即可 |

## 目录结构

```
yibasuo-skill/
├── rules/
│   ├── common/         # 通用规范
│   │   ├── coding-style.md
│   │   ├── testing.md
│   │   ├── patterns.md
│   │   ├── security.md
│   │   ├── hooks.md
│   │   ├── performance.md
│   │   ├── agents.md
│   │   ├── code-review.md
│   │   ├── development-workflow.md
│   │   └── git-workflow.md
│   ├── java/           # Java 规范
│   │   ├── coding-style.md
│   │   ├── testing.md
│   │   ├── patterns.md
│   │   ├── security.md
│   │   ├── hooks.md
│   │   └── logging.md
│   ├── typescript/     # TypeScript/Node.js 规范
│   │   ├── coding-style.md
│   │   ├── testing.md
│   │   ├── patterns.md
│   │   ├── security.md
│   │   ├── hooks.md
│   │   └── logging.md
│   └── web/             # 前端静态网站规范
│       └── static-website-checklist.md
├── skills/
│   └── yibasuo/
│       └── SKILL.md
├── install.sh
└── README.md
```
