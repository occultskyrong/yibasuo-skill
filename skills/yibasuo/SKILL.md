---
name: yibasuo
version: "2.10.0"
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
5. **破坏性变更需确认** — 删除文件/代码块/接口签名/数据库表或字段等操作，必须先说明删除什么、为什么、影响范围。**用户同意后方可执行**，执行后在 `.yibasuo-deletions.log` 追加记录
6. **前端校验不替代后端** — 前端做参数校验是 UX 优化（即时反馈、减少无效请求），**后端绝不信任前端传来的任何数据**。所有入参必须在后端重新完整校验（类型、长度、范围、格式、业务规则），即使前端已经校验过。防止绕过前端直接调 API 的攻击行为
7. **List 查询必须分页** — 所有列表查询必须含 `PageRequest`（page, page_size），默认 20 上限 100。响应必须含 `PageResponse`（page, page_size, total）

## 语言适配

| 技术栈 | 注入要点 |
|--------|---------|
| Java | JUnit5+AssertJ+Mockito+Testcontainers，p3c，构造器注入，Logback |
| Node.js / NestJS | Vitest+supertest，NestJS分层，pino，`__`私有前缀，Zod |
| Vue / React | Vitest+Testing Library，Pinia/Zustand，Playwright E2E，Prettier+ESLint |

**包管理器检测**（Node.js / 前端项目）：根据锁文件自动选择 — `pnpm-lock.yaml`→pnpm、`yarn.lock`→yarn、`package-lock.json`→npm。优先级：pnpm > yarn > npm。以下文档用 `<pkg>` 指代检测到的包管理器。

阶段 3-4 的 agent 直接操作文件，rules 按 `paths:` 自动加载。阶段 1-2 需手动在 agent prompt 中注入。

**统一接口返回**：`{ code, message, data, requestId, metadata }` — requestId 即 traceId 全链路透传，metadata 含 timestamp/method/endpoint + 分页。详见 `rules/java/patterns.md` 或 `rules/typescript/patterns.md`。

## 前端项目差异

前端项目（Vue/React）在标准流程上有差异化阶段，详见 [references/frontend-flows.md](references/frontend-flows.md)。

**命名规范**：Git 分支 `feat/YYMMDD_desc`（见 `rules/common/git-workflow.md`）、Java 文件 PascalCase、NestJS 文件 snake_case、文档 `YYYYMMDD - 标题.md`。

## CodeGraph 集成（可选）

详见 [references/codegraph.md](references/codegraph.md) — 预索引代码库，替代 agent 扫描文件。初始化：`nvm use 22 && codegraph init -i && codegraph index`。

## 工作流

```
需求确认 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交(格式→构建→commit→tag)
  ▲                            ▲                                 ▲
  │                            │                                 │
 两种模式                    自动:跳过                         两种模式
 都需确认                    交互:确认                         都需确认
```

**文档同步**：每个阶段结束时，若变更影响项目架构/模块/端口/技术栈，增量更新 `CLAUDE.md` 对应章节。阶段 5 提交前全量梳理 `CLAUDE.md` + `README.md`，确保与代码现状一致。

### 0. 需求确认

**前置步骤（研究复用）**：确认需求前，先检查是否有现成方案可复用 — 搜索项目内已有实现、GitHub 相关开源项目、包注册表（npm/Maven）。紧急 hotfix、配置变更、文档更新可跳过此步。

1. 理解输入，识别模糊点。多子系统**先拆解**，逐个处理
2. 一次聚焦一个主题澄清（功能边界、交互细节、异常情况）；跨模块复杂需求可一次提 2-3 个关联问题
3. 确认技术栈和影响范围
4. **提出 2-3 种实现方案**，含 trade-off 和推荐理由
5. 输出需求卡片（标题/类型/范围/验收标准/约束）
6. **暂停，等用户确认。**

**门禁**：需求卡片必须含标题、类型、范围、验收标准（≥1 条）。缺任何一项不进入阶段 1。

### 1. 规划

1. **先读项目代码**（有 CodeGraph 则用 `nvm use 22 && codegraph context "<需求>"` 替代手工读代码）
2. `Agent({ subagent_type: "planner" })`，prompt 含：需求卡片 + 项目结构摘要（CodeGraph 输出） + 语言规范。要求输出任务分解、依赖关系图、风险点列表
3. Agent 失败 → **展示错误，暂停**（两种模式都停）
4. 默认（自动）直接继续。交互模式问"计划 OK？"

**门禁**：计划必须含任务分解（≥2 个子任务）、依赖关系、风险点（≥1 个）。缺项不进入阶段 2。

### 2. 架构

1. `Agent({ subagent_type: "architect" })`，prompt 含：需求 + 计划 + 语言规范。要求产出 ADR（决策/后果/替代方案）+ 接口契约 + 数据变更
2. 自检 P0 问题（缺关键决策/接口遗漏/数据变更缺失），**至少 3 轮、最多 5 轮**。即使无 P0 也跑满 3 轮以充分打磨。5 轮后仍有 P0 → 暂停等用户决定
3. 若数据变更涉及 DDL（建表/加列/改列/加索引等），架构产出必须包含对应的 Flyway 迁移文件（`YYYYMMDD-{描述}.sql`），遵循 `rules/common/patterns.md` 迁移规范。Java 项目在 `src/main/resources/db/migration/` 下，NestJS 项目在 `migrations/` 下
4. Agent 失败 → **展示错误，暂停**
5. 默认（自动）直接继续。交互模式问"方案 OK？"

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

**门禁**：覆盖率 ≥ 80% 且所有测试通过。不达标不进入阶段 4。

### 4. 审查

1. 按技术栈 **并行**启动：Java→`java-reviewer`，Node.js/前端→`typescript-reviewer` + `security-reviewer`
2. 任一 agent 失败 → **展示错误，暂停**
3. CRITICAL/HIGH → **必须修复**（两种模式都拦截），修复前先写复现测试
4. **基础设施配置审查**（主会话执行，agent 不负责），详见 [references/infrastructure-review.md](references/infrastructure-review.md)
5. 修复后重审，**至少 3 轮、最多 5 轮**。即使无 CRITICAL/HIGH 也跑满 3 轮以充分审查。5 轮后仍有 → 暂停等用户决定
6. MEDIUM/LOW → 展示建议，不强制
7. 默认（自动）无 CRITICAL/HIGH 则继续
8. 有 CodeGraph 时：`codegraph query "<变更符号>"` 验证所有引用点已更新

**门禁**：CRITICAL = 0 且 HIGH = 0。不达标不进入阶段 5。

### 5. 提交

1. **启动验证**：
   - Java：`./mvnw spring-boot:run` 或 `mvn spring-boot:run`，确认无 Bean 创建失败、端口冲突
   - NestJS：`<pkg> start:dev` 或 `npm start`，确认无 DI 错误、无 crash
   - 验证通过后停掉进程再继续
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
   - [x] 接口返回含 `requestId`（= traceId）和 `metadata`（timestamp/method/endpoint），格式符合 `rules/java/patterns.md` 规范
   - [x] DDL 变更已创建对应的迁移文件（`YYYYMMDD-{描述}.sql`），含回滚脚本或 `[IRREVERSIBLE]` 标记
6. **文档更新**（提交前全量梳理）：
   - `CLAUDE.md`：架构图、模块清单、端口分配、常用命令、环境对照 — 确保与代码现状一致
   - `README.md`：功能说明、使用方式 — 确保与实际变更匹配
7. **生成 commit message**：遵循 [Conventional Commits](references/commit-conventions.md)（`<type>[!]: <desc>`），破坏性变更加 `!`
8. **展示确认**（两种模式都必确认）
9. `git add <具体文件>`（精确添加，禁止 `git add -A`）+ `git commit`
10. **创建 tag**：遵循 [SemVer](references/commit-conventions.md#semver-tag)，根据 type 确定 MAJOR/MINOR/PATCH。**标签不可变**
11. 询问是否 push（含 `--tags`）。引导 PR/合并策略

## 中断与恢复

- 随时可中断，重说"继续梭"恢复
- 说"回到阶段 X"重做，说"从阶段 X 开始梭"或"梭到审查就行"
- **阶段 3 中断恢复**：先运行测试命令，根据结果判断当前所处 RED/GREEN/IMPROVE 阶段再继续
- **跨会话恢复**：每个阶段结束写入 `.yibasuo-state.json`（字段: stage/mode/requirement/decisions/coverage），新会话读取恢复
- **模式切换**：说"停一下"在当前最小步骤完成后暂停，不强制回滚
- **跳过约束**：阶段 0-2 可按需跳过，阶段 3(TDD) 和阶段 4(审查) **不可跳过**（跳过 TDD 需显式声明风险并记入 commit message）

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 | 完整 6 阶段 |
| 重构 | 阶段 0 简化为范围确认，阶段 2 侧重影响分析，阶段 3 侧重回归测试（确保现有测试不 break） |
| Bug 修复 | 跳过 0-2，阶段 3(TDD)→4→5 |
| 依赖升级 | 跳过 0-1，阶段 2 做兼容性分析，阶段 3 跑全量回归，阶段 4 增加 breaking change 审查 |
| 数据库迁移 | 阶段 0 确认迁移范围 + 大表风险评估，阶段 5 迁移文件不可变检查 |
| 单文件小改 | 不建议用一把梭，直接手改 + code-reviewer |
| 纯研究 / 调研 | 不适用一把梭，用 planner agent 出调研报告 |
| **生成说明文档** | 收集项目信息（README/CLAUDE/package.json/pom.xml）→ 整理为结构化文档 → 调用 `ui-ux-pro-max` skill 生成 HTML |

## 示例

用户说：`自动梭 修复登录超时没提示`

| 阶段 | 行为 |
|------|------|
| 0 | 澄清：超时多少秒？提示文案？确认 NestJS → 注入 typescript rules |
| 1 | （Bug 修复跳过） |
| 2 | （Bug 修复跳过） |
| 3 | tdd-guide：`pnpm test`，Vitest+supertest，覆盖率≥80% |
| 4 | typescript-reviewer ∥ security-reviewer 并行 |
| 5 | prettier→eslint→ts-prune→build→commit `fix: 登录超时增加用户提示`→tag `v1.2.1`

## 反模式

- **不要跳过门禁** — 确认是安全阀
- **不要忽略审查** — CRITICAL 必须修
- **不要模糊需求直接梭** — 阶段 0 没搞清楚就往下走，5 阶段白跑
- **不要并行依赖阶段** — 架构没出来就编码无意义
