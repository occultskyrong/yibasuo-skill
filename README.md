# 一把梭 (yibasuo) — 全流程开发管线 v2.10.0

> 需求 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交。7 个内置 Agent + 4 套 Rules，流程化消除 AI 编码的随机性。

## 安装

```bash
git clone git@github.com:occultskyrong/yibasuo-skill.git /tmp/yibasuo-skill
cd /tmp/yibasuo-skill && bash install.sh        # Claude Code
cd /tmp/yibasuo-skill && bash install.sh --codex # Codex
```

## 快速开始

说 **"一把梭"** 走自动模式（阶段 0 确认后 1-5 连续执行），说 **"一步步梭"** 走交互模式（每阶段确认）。中途 `停一下` 切交互，`继续梭` 回自动。

| 触发词 | 模式 | 行为 |
|--------|------|------|
| `一把梭` `全流程` `梭哈` | 自动（默认） | 阶段 0 确认后 1-4 连续，提交前确认 |
| `一步步梭` `交互梭` `确认梭` | 交互 | 每阶段确认后继续 |

## 6 阶段

| # | 阶段 | Agent | 关键动作 | 门禁 |
|---|------|-------|---------|------|
| 0 | 需求确认 | — | 研究复用 → 澄清 → 2-3 方案 → 需求卡片 | 卡片含标题/类型/范围/验收标准 |
| 1 | 规划 | `planner` | 读项目代码 → 任务分解 + 依赖 + 风险 | 任务≥2，风险点≥1 |
| 2 | 架构 | `architect` | ADR + 接口契约 + 数据变更，≥3 轮自检 | P0 清零 |
| 3 | TDD | `tdd-guide` | RED→GREEN→IMPROVE，覆盖率≥80% | 测试全过 + 覆盖率达标 |
| 4 | 审查 | `code-reviewer` + `security-reviewer` | 并行审查，CRITICAL/HIGH 必须修，≥3 轮 | CRITICAL=0，HIGH=0 |
| 5 | 提交 | — | 启动验证→格式→构建→文档更新→commit→tag→push | — |

## 支持的技术栈

| 技术栈 | 测试 | 格式 |
|--------|------|------|
| Java / Spring Boot | JUnit5 + Mockito + Testcontainers | p3c |
| Node.js / NestJS | Vitest + supertest + Playwright | Prettier + ESLint |
| Vue / React | Vitest + Testing Library + Playwright | Prettier + ESLint |

覆盖 HTTP/BFF 和 gRPC 微服务全场景。

## 规范规则

安装后按语言自动加载。每套规则 5-8 个文件，覆盖编码、安全、测试、日志、并发。

| 规则集 | 核心文件 | 覆盖 |
|--------|---------|------|
| **common** | `patterns` `security` `concurrency` `testing` `development-workflow` `git-workflow` `coding-style` | 返回结构、迁移、定时任务、OWASP、并发、TDD |
| **java** | `patterns` `security` `testing` `coding-style` `logging` | Spring Boot 分层、JWT、索引、gRPC、Virtual Threads |
| **typescript** | `patterns` `security` `testing` `coding-style` `logging` | NestJS 分层、BullMQ、gRPC、Fastify、Branded Types |
| **web** | `patterns` `testing` `coding-style` `static-website-checklist` | 组件模式、CDN、备案、SEO、无障碍 |

## 任务适配

| 任务类型 | 行为 |
|---------|------|
| 新功能 | 完整 6 阶段 |
| 重构 | 阶段 0→范围确认，阶段 2→影响分析，阶段 3→回归测试 |
| Bug 修复 | 跳过 0-2，直接 TDD→审查→提交 |
| 依赖升级 | 跳过 0-1，阶段 2→兼容分析，阶段 3→全量回归 |
| 数据库迁移 | 阶段 0→范围+大表风险，阶段 5→迁移文件不可变 |
| 单文件小改 | 不建议，直接手改 + code-reviewer |
| 纯研究 | 不适用，用 planner agent 出调研报告 |

## ⚠️ Token 消耗

| 场景 | 直接对话 | 一把梭 | 倍数 |
|------|---------|--------|------|
| 新功能（中等复杂度） | ~25K | ~90K | ~3.5x |
| Bug 修复 | ~12K | ~40K | ~3x |
| 简单改动 | ~5K | ~8K | ~1.5x |

> 多的成本换来 4 道质检 + 确定性流程。改一行文字不建议用。

## 更新

```bash
cd /tmp/yibasuo-skill && git pull && bash install.sh --force
cat ~/.claude/skills/yibasuo/.installed-version  # 查看版本
```

## 生态

- [yibasuo-infra](https://github.com/occultskyrong/yibasuo-infra) — 项目骨架初始化（Spring Boot / NestJS / gRPC 微服务）
- [yibasuo-skill](https://github.com/occultskyrong/yibasuo-skill) — 全流程开发管线
