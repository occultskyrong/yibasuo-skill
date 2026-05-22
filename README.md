# 一把梭 (yibasuo) — Claude Code / Codex 全流程开发 Skill v2.7.8

> 需求 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交

## 安装

### Claude Code

```bash
git clone https://github.com/YOUR_USER/yibasuo-skill.git /tmp/yibasuo-skill && cd /tmp/yibasuo-skill && bash install.sh
```

### Codex

```bash
git clone https://github.com/YOUR_USER/yibasuo-skill.git /tmp/yibasuo-skill && cd /tmp/yibasuo-skill && bash install.sh --codex
```

或让 Claude/Codex 帮你装：
> "从 https://github.com/YOUR_USER/yibasuo-skill.git clone 到 /tmp，执行 install.sh --codex"

安装后说 **"一把梭"** 即可触发。

## 更新

```bash
# Claude Code
cd /tmp/yibasuo-skill && git pull && bash install.sh --force

# Codex
cd /tmp/yibasuo-skill && git pull && bash install.sh --codex --force
```

查看版本：`cat ~/.claude/skills/yibasuo/.installed-version`

## 运行模式

| 模式 | 触发词 | 阶段 0 | 阶段 1-4 | 阶段 5 |
|------|--------|--------|---------|--------|
| 自动（默认） | `一把梭` `全流程` `梭哈` | 确认 | 连续 | 确认 |
| 交互（显式） | `一步步梭` `交互梭` `确认梭` | 确认 | 每阶段确认 | 确认 |

中途切换：说"停一下"或"继续梭"。

## 6 阶段管线

```
0.需求确认 → 1.规划 → 2.架构 → 3.测试驱动开发 → 4.审查 → 5.提交(验证→格式→构建→commit)
```

| 阶段 | 做什么 | 注入能力 |
|------|--------|---------|
| 需求确认 | 一次一问澄清、子项目拆解、2-3方案对比、输出需求卡片 | brainstorming |
| 规划 | 先读代码再规划，任务分解+依赖+风险 | writing-plans |
| 架构 | ADR含决策/后果/替代方案，接口契约，DDL | architect agent |
| 测试驱动开发 | 铁律：先行代码删除，RED→GREEN→IMPROVE，覆盖率≥80% | TDD iron law |
| 审查 | code-reviewer + security-reviewer 并行，修复前先写复现测试 | systematic-debugging |
| 提交 | 5项验证清单→格式化→构建→conventional commit→PR/合并确认 | verification + finishing |

## 语言适配

| 技术栈 | 工具链 |
|--------|--------|
| Java / Spring Boot | 阿里巴巴 p3c + JUnit5 + AssertJ + Mockito + Testcontainers |
| Node.js / NestJS | Vitest + supertest + Playwright + pino |
| Vue / React 前端 | Vitest + Testing Library + Playwright + Prettier |

**包管理器检测**（Node.js / 前端）：根据锁文件自动选择 — `pnpm-lock.yaml`→pnpm、`yarn.lock`→yarn、`package-lock.json`→npm。

## 方法论

| 层面 | 来源 | 核心 |
|------|------|------|
| 编排层 | Andrew Ng Agentic AI | 6阶段管线：规划→反思→工具→协作 |
| 执行层 | Karpathy 4 原则 | 不假设、简洁、手术刀、循环验证 |
| 约束层 | superpowers | 需求澄清、TDD铁律、系统调试、完成前验证 |

## Token 消耗

| 场景 | 直接调用 LLM | 一把梭 | 倍数 |
|------|------------|--------|------|
| 新功能（中等复杂度） | ~25K | ~93K | 3.7x |
| Bug 修复 | ~12K | ~40K | 3x |

多的 60-70K tokens 买的是架构评审 + 强制TDD + 代码审查 + 安全审查 + 提交前验证。

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 / 重构 | 完整 6 阶段 |
| Bug 修复 | 跳过 1-2，直接测试驱动开发 + 审查 + 提交 |
| 单文件小改 | 不建议用 |
| 纯研究 / 调研 | 不适用 |

## 依赖

**Agent**（内置）：planner / architect / tdd-guide / code-reviewer / security-reviewer / java-reviewer / typescript-reviewer

**Rules**（自动安装）：`common` / `java` / `typescript` / `web`
