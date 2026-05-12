---
name: yibasuo
version: "1.3.0"
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
| 自动 | `自动梭` `全自动` `一路梭到底` `不问我` | 连续执行不暂停 | 确认（安全闸） |

中途切换：说"自动走完剩下的"或"停一下"。

## 阶段

### 0. 需求确认
澄清模糊点 → 确认技术栈和范围 → 输出需求卡片（标题/类型/范围/验收标准/约束）。
**两种模式都暂停确认。**

### 1. 规划
`Agent({ subagent_type: "planner", prompt: "需求 + 项目上下文" })`。展示结果后：交互模式确认，自动模式直接继续。

### 2. 架构
`Agent({ subagent_type: "architect", prompt: "需求 + 计划，产出 ADR 格式" })`。展示结果后：交互模式确认，自动模式直接继续。

### 3. TDD
`Agent({ subagent_type: "tdd-guide", prompt: "需求 + 计划 + 架构方案" })`。确认覆盖率 ≥ 80%。交互模式确认，自动模式直接继续。

### 4. 审查
并行启动 `code-reviewer` + `security-reviewer`。CRITICAL/HIGH 问题必须修复（两种模式都拦截）。交互模式确认，自动模式无问题则继续。

### 5. 提交
`git diff --stat` → 生成 conventional commit message → **展示确认（两种模式必确认）** → git commit → 询问是否 push。

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 / 重构 | 完整 6 阶段 |
| Bug 修复 | 跳过阶段 1-2，直接 TDD + 审查 + 提交 |
| 单文件小改 | 不建议用此流程 |
