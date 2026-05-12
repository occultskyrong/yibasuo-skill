# 一把梭 (yibasuo) — Claude Code 全流程开发 Skill v1.7.4

> 需求 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交

## 安装

```bash
# 一行安装
curl -fsSL https://raw.githubusercontent.com/YOUR_USER/yibasuo-skill/main/install.sh | bash

# 或让 Claude 帮你装
# "从 https://github.com/YOUR_USER/yibasuo-skill.git clone 到 /tmp，执行 install.sh"
```
重启 Claude Code 后说 **"一把梭"** 即可触发。

## 更新

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USER/yibasuo-skill/main/install.sh | bash -s -- --force
```

查看版本：`cat ~/.claude/skills/yibasuo/.installed-version`

## 运行模式

| 模式 | 触发词 | 阶段 0 | 阶段 1-4 | 阶段 5 |
|------|--------|--------|---------|--------|
| 自动（默认） | `一把梭` `全流程` `梭哈` | 确认 | 连续 | 确认 |
| 交互（显式） | `一步步梭` `交互梭` `确认梭` | 确认 | 每阶段确认 | 确认 |

中途切换：说"停一下"或"继续梭"。

## 6 阶段

```
0.需求确认 → 1.规划 → 2.架构 → 3.测试驱动开发 → 4.审查 → 5.提交(格式→构建→commit)
```

| 阶段 | 做什么 |
|------|--------|
| 需求确认 | 澄清模糊点，输出需求卡片（标题/类型/范围/验收标准/约束） |
| 规划 | planner agent：任务分解、依赖关系、风险点 |
| 架构 | architect agent：ADR、接口契约、DDL |
| 测试驱动开发 | tdd-guide agent：RED→GREEN→IMPROVE，覆盖率≥80% |
| 审查 | code-reviewer + security-reviewer 并行，CRITICAL/HIGH 强制修复 |
| 提交 | 格式化→构建验证→conventional commit→确认 |

## 语言适配

| 技术栈 | 工具链 |
|--------|--------|
| Java / Spring Boot | 阿里巴巴 p3c + JUnit5 + AssertJ + Mockito + Testcontainers |
| Node.js / NestJS | Vitest + supertest + Playwright + pino |
| Vue / React 前端 | Vitest + Testing Library + Playwright + Prettier |

## 方法论

| 层面 | 来源 | 核心 |
|------|------|------|
| 编排层 | Andrew Ng Agentic AI | 六阶段管线：规划→反思→工具→协作 |
| 执行层 | Karpathy 4 原则 | 不假设、简洁、手术刀、循环验证 |

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 / 重构 | 完整 6 阶段 |
| Bug 修复 | 跳过 1-2，直接测试驱动开发 + 审查 + 提交 |
| 单文件小改 | 不建议用 |

## 依赖

**Agent**（内置）：planner / architect / tdd-guide / java-reviewer / typescript-reviewer / security-reviewer

**Rules**（自动安装）：`common` / `java` / `typescript` / `web`
