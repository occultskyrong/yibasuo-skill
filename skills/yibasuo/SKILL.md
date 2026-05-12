---
name: yibasuo
version: "1.3.1"
description: "一把梭 — 全流程开发管线。交互模式触发词：一把梭、全流程、梭哈。自动模式触发词：自动梭、全自动、一路梭到底、不问我。"
requires:
  agents: [planner, architect, tdd-guide, code-reviewer, security-reviewer]
  rules: [common, "java (Java 项目)", "typescript (Node.js 项目)", "web (前端静态网站项目)"]
---

# 一把梭

> 需求 → 规划 → 架构 → TDD → 审查 → 提交

## 模式

| 模式 | 触发词 | 阶段 0-4 | 阶段 5 提交 |
|------|--------|---------|------------|
| 交互 | `一把梭` `全流程` `梭哈` | 每阶段暂停等确认 | 确认 |
| 自动 | `自动梭` `全自动` `一路梭到底` `不问我` | 连续不暂停 | 确认 |

中途说"停一下"回交互，说"自动走完剩下的"切自动。

## 语言适配

阶段 0 确认技术栈后，在调用 agent 的 prompt 中注入对应 rules：

| 技术栈 | 注入内容 |
|--------|---------|
| Java / Spring Boot | JUnit 5 + AssertJ + Mockito + Testcontainers，构造器注入，Logback 日志规范 |
| Node.js / NestJS | Vitest/Jest + supertest，NestJS 分层架构，pino 日志，`__` 私有方法前缀 |
| Web 前端 | 静态网站检查清单（安全/CDN/备案/SEO） |

阶段 3-4 的 agent 直接操作代码文件，rules 通过 `paths:` 匹配自动加载，无需手动注入。

## 阶段

### 0. 需求确认
分析需求 → 提澄清问题 → 确认技术栈和影响范围 → 输出卡片：

```
标题: <一句话>
类型: feat / fix / refactor
范围: <受影响模块>
验收标准:
  1. <可验证条件>
  2. ...
约束: <性能/兼容/安全>
```

**两种模式都暂停确认。** 用户说"继续"才进入阶段 1。

### 1. 规划
调用 `Agent({ subagent_type: "planner" })`，传入需求卡片和项目上下文。展示规划结果（任务分解、依赖、风险）。
- **交互**：询问"计划是否 OK？"，暂停等确认
- **自动**：直接继续

### 2. 架构
调用 `Agent({ subagent_type: "architect" })`，传入需求 + 计划，要求产出 ADR 格式。展示架构决策、接口契约、数据变更。
- **交互**：询问"方案是否 OK？"，暂停等确认
- **自动**：直接继续

### 3. TDD
调用 `Agent({ subagent_type: "tdd-guide" })`，传入需求 + 计划 + 架构方案。走 RED→GREEN→IMPROVE。确认测试通过且覆盖率 ≥ 80%。展示结果。
- **交互**：暂停等确认
- **自动**：直接继续

### 4. 审查
**并行启动** `code-reviewer` + `security-reviewer`。汇总问题，分级处理：
- CRITICAL / HIGH → **必须修复**（两种模式都拦截），修复后重新审查
- MEDIUM → 展示建议，不强制
- 展示审查结论
- **交互**：暂停等确认
- **自动**：无 CRITICAL/HIGH 则继续

### 5. 提交
1. `git diff --stat` 确认变更范围
2. 按 conventional commits 生成 commit message
3. **展示确认（两种模式都必确认）**
4. `git add` + `git commit`
5. 询问是否 push

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 / 重构 | 完整 6 阶段 |
| Bug 修复 | 跳过阶段 1-2，直接 TDD + 审查 + 提交 |
| 单文件小改 | 不建议用此流程 |
