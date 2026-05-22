# 一把梭 (yibasuo) — 全流程开发管线 v2.8.5

> 需求 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交。7 个内置 Agent 强制执行，消除 AI 编码的随机性。

## 安装

```bash
# Claude Code
git clone git@github.com:occultskyrong/yibasuo-skill.git /tmp/yibasuo-skill
cd /tmp/yibasuo-skill && bash install.sh

# Codex
git clone git@github.com:occultskyrong/yibasuo-skill.git /tmp/yibasuo-skill
cd /tmp/yibasuo-skill && bash install.sh --codex
```


## 快速开始

重启后说 **"一把梭"** 触发自动模式（阶段 0-4 连续执行，仅提交前确认）。说 **"一步步梭"** 走交互模式（每阶段确认）。

## 6 阶段

| 阶段 | 做什么 |
|------|--------|
| 0. 需求确认 | 澄清问题、2-3 方案对比、输出需求卡片 |
| 1. 规划 | planner agent：任务分解、依赖关系、风险点 |
| 2. 架构 | architect agent：ADR、接口契约、数据变更 |
| 3. 测试驱动开发 | tdd-guide agent：RED→GREEN→IMPROVE、覆盖率≥80% |
| 4. 审查 | code-reviewer + security-reviewer 并行，CRITICAL/HIGH 拦截 |
| 5. 提交 | 格式检查→构建验证→Conventional Commit→SemVer Tag→Push |

## ⚠️ Token 消耗说明

一把梭会显著增加 API 调用量——每个阶段都会调用内置 Agent 进行独立分析，这些额外消耗换来的是架构评审、强制 TDD、代码审查、安全审查、提交前验证。

| 场景 | 直接对话 | 一把梭 | 倍数 |
|------|---------|--------|------|
| 新功能（中等复杂度） | ~25K | ~90K | **~3.5x** |
| Bug 修复 | ~12K | ~40K | **~3x** |
| 简单改动 | ~5K | ~8K | ~1.5x |

> 多的 50-70K tokens 成本买的是 4 道质检 + 确定性流程。如果只是改一行文字，不建议使用。

## 支持的技术栈

| 技术栈 | 测试框架 | 格式检查 |
|--------|---------|---------|
| Java / Spring Boot | JUnit5 + AssertJ + Mockito + Testcontainers | p3c (阿里巴巴) |
| Node.js / NestJS | Vitest + supertest + Playwright | Prettier + ESLint |
| Vue / React | Vitest + Testing Library + Playwright | Prettier + ESLint |

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 / 重构 | 完整 6 阶段 |
| Bug 修复 | 跳过 1-2，TDD + 审查 + 提交 |
| 单文件小改 | 不建议用 |
| 生成说明文档 | 收集项目信息 → 调用 ui-ux-pro-max 生成 HTML |

## 更新

```bash
cd /tmp/yibasuo-skill && git pull && bash install.sh --force
```

查看版本：`cat ~/.claude/skills/yibasuo/.installed-version`

## 自包含

安装后即用，无需外部依赖：7 个 Agent + 4 套 Rules（common/java/typescript/web）+ git-workflow 技能，`install.sh` 一键安装。
