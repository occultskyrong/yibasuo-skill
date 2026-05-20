---
name: yibasuo
version: "2.6.3"
description: "一把梭 — 全流程开发管线。默认自动模式（触发词：一把梭、全流程、梭哈）：阶段1-4连续执行，阶段0与提交前确认。交互模式需显式触发：一步步梭、交互梭、确认梭。"
requires:
  agents: [planner, architect, tdd-guide, code-reviewer, security-reviewer, java-reviewer, typescript-reviewer]
  rules: [common, "java (Java 项目)", "typescript (Node.js 项目)", "web (Vue/React 前端项目)"]
---

# 一把梭

> 需求 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交

## 运行模式

| 模式 | 触发词 | 阶段 0 | 阶段 1-4 | 阶段 5 |
|------|--------|--------|---------|--------|
| 自动（默认） | `一把梭` `全流程` `梭哈` | 确认 | 连续 | 确认 |
| 交互（显式） | `一步步梭` `交互梭` `确认梭` | 确认 | 每阶段确认 | 确认 |

中途说"停一下"切交互，说"继续梭"回自动。

## 行为红线

1. **编码前思考** — 不确定时提 2-3 种解释，不默默假设
2. **简洁优先** — 最少代码解决问题，不添加未请求的功能
3. **手术刀改动** — 只改任务相关代码，不顺手重构；死代码只提不删
4. **循环验证** — 每阶段定义成功标准，不达标不回；覆盖率≥80%、CRITICAL=0 是底线

## 语言适配

| 技术栈 | 注入要点 |
|--------|---------|
| Java | JUnit5+AssertJ+Mockito+Testcontainers，p3c，构造器注入，Logback |
| Node.js / NestJS | Vitest+supertest，NestJS分层，pino，`__`私有前缀，Zod |
| Vue / React | Vitest+Testing Library，Pinia/Zustand，Playwright E2E，Prettier+ESLint |

**包管理器检测**（Node.js / 前端项目）：根据锁文件自动选择 — `pnpm-lock.yaml`→pnpm、`yarn.lock`→yarn、`package-lock.json`→npm。优先级：pnpm > yarn > npm。以下文档用 `<pkg>` 指代检测到的包管理器。

阶段 3-4 的 agent 直接操作文件，rules 按 `paths:` 自动加载。阶段 1-2 需手动在 agent prompt 中注入。

**命名规范**：Git 分支 `feat/YYMMDD_desc`（见 `rules/common/git-workflow.md`）、Java 文件 PascalCase、NestJS 文件 snake_case、文档 `YYYYMMDD - 标题.md`。

## CodeGraph 集成（可选）

[CodeGraph](https://github.com/colbymchenry/codegraph) 预索引代码库，替代 agent 手工扫描文件，大幅减少 token 消耗。

### 环境要求

| 组件 | 版本 | 安装 |
|------|------|------|
| Node.js | **22**（`>=18.0.0 <25.0.0`） | `nvm install 22` |
| codegraph | latest | `nvm use 22 && npx @colbymchenry/codegraph` |

调用前必须 `nvm use 22`（或通过 wrapper 自动切换）。

### 项目初始化（一次性）

```bash
nvm use 22 && codegraph init -i && codegraph index
```

### 阶段注入点

| 阶段 | CodeGraph 命令 | 替代行为 |
|------|------|------|
| 1 规划 | `codegraph context "<需求描述>"` → markdown 注入 planner prompt | 替代 agent 手工 Read/grep 扫项目结构 |
| 2 架构 | `codegraph query -k class "<关键类名>"` | 替代 agent 盲目搜调用链 |
| 3 TDD | `codegraph affected src/改动的文件.ts` | 自动定位受影响测试文件 |
| 4 审查 | `codegraph query "<变更的符号名>"` | 验证所有引用点已更新 |
| 持续 | `codegraph sync` | 增量更新索引 |

## 工作流

```
需求确认 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交(格式→构建→commit→tag)
  ▲                            ▲                                 ▲
  │                            │                                 │
 两种模式                    自动:跳过                         两种模式
 都需确认                    交互:确认                         都需确认
```

### 0. 需求确认

1. 理解输入，识别模糊点。多子系统**先拆解**，逐个处理
2. 一次只问一个问题澄清（功能边界、交互细节、异常情况）
3. 确认技术栈和影响范围
4. **提出 2-3 种实现方案**，含 trade-off 和推荐理由
5. 输出需求卡片（标题/类型/范围/验收标准/约束）
6. **暂停，等用户确认。**

### 1. 规划

1. **先读项目代码**（有 CodeGraph 则用 `nvm use 22 && codegraph context "<需求>"` 替代手工读代码）
2. `Agent({ subagent_type: "planner" })`，prompt 含：需求卡片 + 项目结构摘要（CodeGraph 输出） + 语言规范。要求输出任务分解、依赖关系图、风险点列表
3. Agent 失败 → **展示错误，暂停**（两种模式都停）
4. 默认（自动）直接继续。交互模式问"计划 OK？"

### 2. 架构

1. `Agent({ subagent_type: "architect" })`，prompt 含：需求 + 计划 + 语言规范。要求产出 ADR（决策/后果/替代方案）+ 接口契约 + 数据变更
2. 自检 P0 问题（缺关键决策/接口遗漏/数据变更缺失），**至少 3 轮、最多 5 轮**。即使无 P0 也跑满 3 轮以充分打磨。5 轮后仍有 P0 → 暂停等用户决定
3. Agent 失败 → **展示错误，暂停**
4. 默认（自动）直接继续。交互模式问"方案 OK？"

### 3. 测试驱动开发

**铁律**：没有失败测试 → 没有生产代码。先行代码 = 删除。

1. `Agent({ subagent_type: "tdd-guide" })`，prompt 含需求 + 计划 + 架构 + 按技术栈指定测试命令：
   - Java → `mvn test`，JUnit5+AssertJ+Mockito，Testcontainers，JaCoCo
   - Node.js → `<pkg> test`，Vitest+supertest，Playwright E2E，v8
   - 前端 → `<pkg> test`，Vitest+Testing Library，Playwright E2E
   - **强制 agent 先 Read 项目的 `rules/<lang>/testing.md` 再动手**
   - 有 CodeGraph 时：`codegraph affected <改动文件>` 自动定位受影响测试，加速 RED 阶段
2. RED → GREEN → IMPROVE，**目标覆盖率 ≥ 80%**（与 `rules/common/testing.md` 一致）
3. Agent 失败 → **展示错误，暂停**
4. 展示覆盖率。未达 80% → 暂停修复。达标则继续。

### 4. 审查

1. 按技术栈 **并行**启动：Java→`java-reviewer`，Node.js/前端→`typescript-reviewer` + `security-reviewer`
2. 任一 agent 失败 → **展示错误，暂停**
3. CRITICAL/HIGH → **必须修复**（两种模式都拦截），修复前先写复现测试
4. **基础设施配置审查**（主会话执行，agent 不负责）：
   - 扫描 `src/config/` 或 `src/main/resources/` 目录，识别同概念重复配置文件
   - NestJS 项目：检查 `nest-cli.json` 的 `assets` 是否覆盖 `src/config/` 下所有 JSON 文件
   - 检查 `.env.example` 变量与代码中 `process.env.*` 引用是否一一对应
   - 检查是否存在硬编码的 API Key/Token/Password
5. 修复后重审，**至少 3 轮、最多 5 轮**。即使无 CRITICAL/HIGH 也跑满 3 轮以充分审查。5 轮后仍有 → 暂停等用户决定
6. MEDIUM/LOW → 展示建议，不强制
7. 默认（自动）无 CRITICAL/HIGH 则继续
8. 有 CodeGraph 时：`codegraph query "<变更符号>"` 验证所有引用点已更新

### 5. 提交

1. **启动验证**（NestJS 项目）：运行 `<pkg> start:dev` 或 `npm start`，确认服务能正常启动（无 DI 错误、无 crash），验证通过后停掉进程再继续
2. **环境检查**：非 git 仓库警告暂停，`git diff --stat`
3. **格式检查**（按技术栈）：
   - Node.js/前端：`<pkg>` prettier → `<pkg>` eslint → ts-prune（僵尸代码扫描，列清单不自动删）
   - Java：检测 pom.xml 是否含 `maven-pmd-plugin` → 有则 `mvn pmd:check`，无则跳过
   - 格式失败 → 暂停。优先复用项目已有 formatter/linter 配置
4. **构建验证**（Node.js/前端）：`<pkg> build`，构建失败或缺 build 命令 → 暂停
5. **完成前验证**：
   - [x] 测试通过 + 覆盖率达标
   - [x] 无 CRITICAL/HIGH 审查问题
   - [x] 格式已执行（prettier+eslint / p3c）
   - [x] 构建通过（或已处理缺失警告）
   - [x] 无 console.log / 调试残留
   - [x] 日志含 `[traceId]`（Logback `%X{traceId}` / pino mixin），日志格式符合规范
   - [x] ApiResponse 含 `requestId`（UUID 去横线）
6. **生成 commit message**：遵循 [Conventional Commits](references/commit-conventions.md)（`<type>[!]: <desc>`），破坏性变更加 `!`
7. **展示确认**（两种模式都必确认）
8. `git add` + `git commit`
9. **创建 tag**：遵循 [SemVer](references/commit-conventions.md#semver-tag)，根据 type 确定 MAJOR/MINOR/PATCH。非功能变更（docs/chore/refactor）不创建 tag。**标签不可变**
10. 询问是否 push（含 `--tags`）。引导 PR/合并策略

## 中断与恢复

- 随时可中断，重说"继续梭"恢复
- 说"回到阶段 X"重做，说"跳过阶段 X"跳过
- 说"从阶段 X 开始梭"或"梭到审查就行"

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 / 重构 | 完整 6 阶段 |
| Bug 修复 | 跳过 1-2，直接 测试驱动开发 + 审查 + 提交 |
| 单文件小改 | 不建议用 |
| 纯研究 / 调研 | 不适用 |

## 示例

用户说：`自动梭 修复登录超时没提示` → 阶段0澄清→跳过1-2→阶段3 TDD→阶段4审查→阶段5 commit `fix: 登录超时增加用户提示`→tag `v1.2.1`

## 反模式

- **不要跳过门禁** — 确认是安全阀
- **不要忽略审查** — CRITICAL 必须修
- **不要模糊需求直接梭** — 阶段 0 没搞清楚就往下走，5 阶段白跑
- **不要并行依赖阶段** — 架构没出来就编码无意义
