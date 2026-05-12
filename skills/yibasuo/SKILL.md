---
name: yibasuo
version: "1.6.0"
description: "一把梭 — 全流程开发管线。默认自动模式（触发词：一把梭、全流程、梭哈）：阶段0-4连续执行，仅提交前确认。交互模式需显式触发：一步步梭、交互梭、确认梭。"
requires:
  agents: [planner, architect, tdd-guide, code-reviewer, security-reviewer]
  rules: [common, "java (Java 项目)", "typescript (Node.js 项目)", "web (Vue/React 前端项目)"]
---

# 一把梭

> 需求 → 规划 → 架构 → TDD → 审查 → 提交

## 运行模式

**默认自动**：除非用户明确说"一步步梭"/"交互梭"/"确认梭"，否则阶段 0-4 全部自动连续执行，只在阶段 5（提交）暂停确认。

| 模式 | 触发词 | 阶段 0 | 阶段 1-4 | 阶段 5 |
|------|--------|--------|---------|--------|
| 自动（默认） | `一把梭` `全流程` `梭哈` | 确认 | 连续不暂停 | 确认 |
| 交互（显式） | `一步步梭` `交互梭` `确认梭` | 确认 | 每阶段确认 | 确认 |

中途说"停一下"切交互，说"继续梭"恢复自动。

## 设计哲学

1. **Agent 做重活** — 规划/架构/TDD/审查交给 agent，主会话只管编排
2. **用户决断** — 产出你来审，不合意回退重来
3. **失败不蔓延** — 任阶段不通过，停当前修复，不继续
4. **安全闸** — 无论什么模式，commit 前必须确认

## 语言适配

阶段 0 确认技术栈后，向 agent prompt 注入对应规范：

| 技术栈 | 注入要点 |
|--------|---------|
| Java / Spring Boot | JUnit5 + AssertJ + Mockito + Testcontainers，构造器注入，阿里巴巴 Java 开发手册 (p3c)，Logback，sealed types |
| Node.js / NestJS | Vitest/Jest + supertest，NestJS 分层，pino 日志，`__` 私有前缀，Zod 校验 |
| Vue / React 前端 | Vue3 Composition API / React Hooks，Pinia/Zustand，Vite 构建，Playwright E2E，Prettier + ESLint |

阶段 3-4 的 agent 直接操作文件，rules 按 `paths:` 自动加载，不需手动注入。

## 工作流

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ 0.需求   │──▶│ 1.规划   │──▶│ 2.架构   │──▶│ 3.TDD    │──▶│ 4.审查   │──▶│ 5.提交   │
│   确认   │   │          │   │          │   │   实现   │   │          │   │          │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
     ▲              ▲              ▲              ▲              ▲              ▲
     │              │              │              │              │              │
  两种模式       默认:自动      默认:自动      默认:自动      默认:自动      两种模式
  都需确认       交互:确认      交互:确认      交互:确认      交互:确认      都需确认
```

### 0. 需求确认

1. 理解输入，识别模糊点
2. 提出澄清问题（功能边界、交互细节、异常情况）
3. 确认技术栈和影响范围
4. 输出需求卡片：

```markdown
标题: <一句话>
类型: feat / fix / refactor
范围: <受影响模块>
验收标准:
  1. <可验证条件>
  2. ...
约束: <性能/兼容/安全>
```

5. **暂停，等用户确认。** 两种模式都需确认。

### 1. 规划

1. `Agent({ subagent_type: "planner" })`，prompt 含需求卡片 + 项目上下文 + 语言规范
2. 展示：任务分解、依赖关系、风险点
3. 默认（自动）直接继续。如触发交互模式，问"计划 OK？"等确认。

### 2. 架构

1. `Agent({ subagent_type: "architect" })`，prompt 含需求 + 计划 + 语言规范，要求 ADR 格式
2. 展示：架构决策、接口契约、数据变更
3. 默认（自动）直接继续。如触发交互模式，问"方案 OK？"等确认。

### 3. TDD

1. `Agent({ subagent_type: "tdd-guide" })`，prompt 含需求 + 计划 + 架构方案
2. 走 RED → GREEN → IMPROVE，覆盖率 ≥ 80%
3. 展示结果和测试报告
4. 默认（自动）直接继续。如触发交互模式，暂停等确认。

### 4. 审查

1. 按技术栈选择 reviewer，**并行**启动两个 agent：
   - Java → `java-reviewer`，Node.js → `typescript-reviewer`，前端 → `typescript-reviewer`
   - 安全（所有项目）→ `security-reviewer`
2. 汇总，按级处理：
   - CRITICAL / HIGH → **必须修复**（两种模式都拦截），修复后重审
   - MEDIUM / LOW → 展示建议，不强制
3. 默认（自动）无 CRITICAL/HIGH 则继续。如触发交互模式，暂停等确认。

### 5. 提交

遵循 `rules/common/git-workflow.md` 规范：

1. `git diff --stat` 确认变更
2. **格式化**（根据技术栈）：
   - 前端 / Node.js → `pnpm prettier --write "src/**/*.{vue,tsx,jsx,ts,js,css,scss}"`
   - Java → `mvn pmd:check`（p3c 阿里巴巴 Java 开发手册），修复用 IDE 插件
   - 优先检测项目已有 formatter 并复用
3. **构建验证**（前端 / Node.js 项目）：
   - 检测 `package.json` 的 `scripts.build`
   - 存在 → 执行 `pnpm build`（或 `npm run build`）
   - **不存在 → 明确警告**：「项目未配置 build 命令。请在 package.json 中配置 `"build": "..."`，或手动构建确认通过。在 build 命令可用前，不应提交。」**暂停等用户处理**。
4. 按 `conventional commits` 生成 message（格式：`<type>: <description>`）
5. **展示确认**（两种模式都必确认）
6. `git add` + `git commit`
7. 询问是否 push

## 中断与恢复

- **随时可中断**：每个阶段都有检查点，重说"继续梭"恢复
- **阶段回退**：说"回到阶段 X"重做
- **跳过阶段**：Bug 修复不需要架构设计可说"跳过阶段 2"
- **指定起止**：说"从阶段 2 开始梭"或"梭到审查就行"

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 / 重构 | 完整 6 阶段 |
| Bug 修复 | 跳过 1-2，直接 TDD + 审查 + 提交 |
| 单文件小改 | 不建议用，直接改 + 审查 |

## 反模式

- **不要跳过门禁** — 确认是安全阀
- **不要忽略审查** — CRITICAL 必须修，不能"先提交后面改"
- **不要模糊需求直接梭** — 阶段 0 没搞清楚就往下走，5 阶段白跑
- **不要并行依赖阶段** — 架构没出来就 TDD 无意义
