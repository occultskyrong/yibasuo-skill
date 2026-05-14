---
name: yibasuo
version: "2.2.1"
description: "一把梭 — 全流程开发管线。默认自动模式（触发词：一把梭、全流程、梭哈）：阶段0-4连续执行，仅提交前确认。交互模式需显式触发：一步步梭、交互梭、确认梭。"
requires:
  agents: [planner, architect, tdd-guide, code-reviewer, security-reviewer]
  rules: [common, "java (Java 项目)", "typescript (Node.js 项目)", "web (Vue/React 前端项目)"]
---

# 一把梭

> 需求 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交

## 运行模式

**默认自动**：除非用户明确说"一步步梭"/"交互梭"/"确认梭"，否则阶段 0-4 全部自动连续执行，只在阶段 5（提交）暂停确认。

| 模式 | 触发词 | 阶段 0 | 阶段 1-4 | 阶段 5 |
|------|--------|--------|---------|--------|
| 自动（默认） | `一把梭` `全流程` `梭哈` | 确认 | 连续不暂停 | 确认 |
| 交互（显式） | `一步步梭` `交互梭` `确认梭` | 确认 | 每阶段确认 | 确认 |

中途说"停一下"切交互，说"继续梭"恢复自动。

## 设计哲学

1. **Agent 做重活** — 规划/架构/测试驱动开发/审查交给 agent，主会话只管编排
2. **用户决断** — 产出你来审，不合意回退重来
3. **失败不蔓延** — 任阶段不通过，停当前修复，不继续
4. **安全闸** — 无论什么模式，commit 前必须确认

## 行为红线 (Karpathy 4 原则)

所有阶段和 agent 必须遵守：

1. **编码前思考** — 不确定时提 2-3 种解释再问，不默默假设；困惑时立即停下求澄清
2. **简洁优先** — 最少代码解决问题，100行能搞定不写300行；不添加未请求的功能和抽象
3. **手术刀改动** — 只改任务相关代码，不顺手重构相邻文件；死代码只提不删
4. **循环验证** — 每个阶段定义可验证成功标准，不达标不回；覆盖率≥80%、CRITICAL=0 是底线

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
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────────┐   ┌──────────┐   ┌──────────┐
│ 0.需求   │──▶│ 1.规划   │──▶│ 2.架构   │──▶│ 3.测试驱动开发 │──▶│ 4.审查   │──▶│ 5.提交   │
│   确认   │   │          │   │          │   │  (编码实现)   │   │          │   │          │
└──────────┘   └──────────┘   └──────────┘   └──────────────┘   └──────────┘   └──────────┘
     ▲              ▲              ▲              ▲              ▲              ▲
     │              │              │              │              │              │
  两种模式       默认:自动      默认:自动      默认:自动      默认:自动      两种模式
  都需确认       交互:确认      交互:确认      交互:确认      交互:确认      都需确认
```

### 0. 需求确认

> Inspired by superpowers/brainstorming

1. 理解输入，识别模糊点。若涉及多个独立子系统，**先拆解为子项目**，逐个处理
2. 提出澄清问题（功能边界、交互细节、异常情况），**一次只问一个问题**
3. 确认技术栈和影响范围
4. **提出 2-3 种实现方案**，含 trade-off 和推荐理由
5. 输出需求卡片：

```markdown
标题: <一句话>
类型: feat / fix / refactor
范围: <受影响模块>
验收标准:
  1. <可验证条件>
  2. ...
约束: <性能/兼容/安全>
```

6. **暂停，等用户确认。** 两种模式都需确认。

### 1. 规划

1. **先读项目代码**：用 `Read` / `Bash` 确认项目结构、现有模块、技术栈版本，再规划。
2. `Agent({ subagent_type: "planner" })`，prompt 必须包含：
   - 需求卡片
   - 项目结构摘要（读了什么、关键文件路径）
   - 技术栈 + 对应语言规范
   - **要求输出**：任务分解（Task List）、依赖关系图、风险点列表
3. Agent 调用失败 → **展示错误，暂停等用户决定**（两种模式都停）。
4. 展示结果后：默认（自动）直接继续。如触发交互模式，问"计划 OK？"等确认。

### 2. 架构

1. `Agent({ subagent_type: "architect" })`，prompt 必须包含：
   - 需求卡片 + 阶段1 计划
   - 技术栈 + 语言规范
   - **要求产出**：ADR（架构决策记录）含上下文/决策/后果/替代方案，接口契约（API 变更清单），数据变更（DDL/migration 路径）
2. Agent 调用失败 → **展示错误，暂停等用户决定**（两种模式都停）。
3. 展示结果后：默认（自动）直接继续。如触发交互模式，问"方案 OK？"等确认。

### 3. 测试驱动开发

> Inspired by superpowers/test-driven-development

**铁律**：没有失败测试 → 没有生产代码。测试之前写的任何生产代码 = 删除，从测试重新开始。没有"保留参考"。

1. `Agent({ subagent_type: "tdd-guide" })`，prompt 必须包含：
   - 需求 + 阶段1计划 + 阶段2架构方案
   - **按技术栈指定测试工具链和命令**：
     - Java → `mvn test`，框架 JUnit5 + AssertJ + Mockito，集成测试用 Testcontainers，覆盖用 JaCoCo
     - Node.js → `pnpm test`，框架 Vitest + supertest，E2E 用 Playwright，覆盖用 v8
     - 前端 → `pnpm test`，框架 Vitest + Vue Test Utils / React Testing Library，E2E 用 Playwright
   - **强制要求 agent 先 Read 项目的 `rules/<lang>/testing.md` 再动手**
   - **要求产出**：测试文件路径 + 覆盖率报告
2. 走 RED → GREEN → IMPROVE，覆盖率 ≥ 80%
3. Agent 调用失败 → **展示错误，暂停等用户决定**（两种模式都停）。
4. 展示结果和测试报告。默认（自动）直接继续。如触发交互模式，暂停等确认。

### 4. 审查

1. 按技术栈选择 reviewer，**并行**启动两个 agent：
   - Java → `java-reviewer`，Node.js/前端 → `typescript-reviewer`
   - 安全（所有项目）→ `security-reviewer`
2. **任一 agent 失败** → 展示错误，让用户决定是否继续（两种模式都停）。
3. 汇总，按级处理：
   - CRITICAL / HIGH → **必须修复**（两种模式都拦截）。修复前先写复现测试，确认测试因该 bug 而失败，再修代码让测试通过。修复后重审
   - MEDIUM / LOW → 展示建议，不强制
4. 默认（自动）无 CRITICAL/HIGH 则继续。如触发交互模式，暂停等确认。

### 5. 提交

遵循 `rules/common/git-workflow.md` 规范：

1. **环境检查**：
   - 非 git 仓库 → 警告"当前目录不是 git 仓库"，暂停
   - `git diff --stat` 确认变更范围
2. **格式检查**（根据技术栈）：
   - 前端 / Node.js：
     a. 检测 `prettier`（`npx prettier --version`），可用则 `pnpm prettier --write "src/**/*.{vue,tsx,jsx,ts,js,css,scss}"`
     b. 检测 `eslint`（`npx eslint --version`），可用则 `pnpm eslint --fix "src/**/*.{ts,tsx,js,jsx}"`
     c. 任一不可用 → 跳过并提示
   - Java → 检测 `mvn --version`，可用则 `mvn pmd:check`（p3c 阿里巴巴 Java 开发手册）。修复建议：`mvn com.alibaba.p3c:p3c-pmd:pmd` 或 IDE 插件（Alibaba Java Coding Guidelines）一键修复
   - **格式检查失败**（语法错误/冲突）→ 展示错误输出，暂停等用户处理
   - 优先检测项目已有 formatter/linter 配置并复用
3. **构建验证**（前端 / Node.js 项目）：
   - 检测 `package.json` 的 `scripts.build`
   - 存在 → 执行 `pnpm build`（或 `npm run build`），构建失败 → **暂停等用户处理**
   - **不存在 → 明确警告**：「项目未配置 build 命令。请在 package.json 中配置 `"build": "..."`，或手动构建确认通过。在 build 命令可用前，不应提交。」**暂停等用户处理**
4. **完成前验证** (superpowers/verification-before-completion)：
   - [x] 全部测试通过，覆盖率 ≥ 80%
   - [x] 无 CRITICAL/HIGH 审查问题
   - [x] 格式检查已执行（prettier + eslint / p3c）
   - [x] 构建通过（或已处理缺失警告）
   - [x] 无 console.log / 调试残留
5. 按 `conventional commits` 生成 message（格式：`<type>: <description>`）
6. **展示确认**（两种模式都必确认）
7. `git add` + `git commit`
8. 询问是否 push。若需要 PR，引导创建；若分支已完成，询问合并策略

## 中断与恢复

- **随时可中断**：每个阶段都有检查点，重说"继续梭"恢复
- **阶段回退**：说"回到阶段 X"重做
- **跳过阶段**：Bug 修复不需要架构设计可说"跳过阶段 2"
- **指定起止**：说"从阶段 2 开始梭"或"梭到审查就行"

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 / 重构 | 完整 6 阶段 |
| Bug 修复 | 跳过 1-2，直接 测试驱动开发 + 审查 + 提交 |
| 单文件小改 | 不建议用，直接改 + 审查 |

## 完整示例

用户说：`自动梭 修复 mch-prc 项目登录超时没提示的问题`

| 阶段 | 行为 |
|------|------|
| 0 | 澄清：超时是多少秒？期望提示文案？确认是 NestJS 项目 → 注入 typescript rules |
| 1 | （Bug 修复跳过） |
| 2 | （Bug 修复跳过） |
| 3 | 调用 tdd-guide，prompt："修复登录超时无提示，预期60s超时弹Toast，项目 NestJS + Vitest + supertest" |
| 4 | 并行调 typescript-reviewer + security-reviewer |
| 5 | prettier + eslint → build → commit message: `fix: 登录超时增加用户提示` → 确认 → commit |

## 反模式

- **不要跳过门禁** — 确认是安全阀
- **不要忽略审查** — CRITICAL 必须修，不能"先提交后面改"
- **不要模糊需求直接梭** — 阶段 0 没搞清楚就往下走，5 阶段白跑
- **不要并行依赖阶段** — 架构没出来就 测试驱动开发 无意义
