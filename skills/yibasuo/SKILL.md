---
name: yibasuo
description: "一把梭 — 全流程开发管线 + 项目初始化/兼容性升级。触发词：一把梭、全流程、梭哈（开发）；初始化项目、创建项目、init project、项目升级、upgrade project（基建）。默认自动模式：阶段1-4连续执行，阶段0与提交前确认。"
metadata:
  version: "3.0.1"
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
4. **循环验证** — 每阶段定义成功标准，不达标不回；全量业务生产代码覆盖率≥80%且增量≥80%、CRITICAL=0 是底线
5. **破坏性变更需确认** — 删除文件/代码块/接口签名/数据库表或字段等操作，必须先说明删除什么、为什么、影响范围。**用户同意后方可执行**，执行后在 `.yibasuo-deletions.log` 追加记录
6. **前端校验不替代后端** — 前端做参数校验是 UX 优化（即时反馈、减少无效请求），**后端绝不信任前端传来的任何数据**。所有入参必须在后端重新完整校验（类型、长度、范围、格式、业务规则），即使前端已经校验过。防止绕过前端直接调 API 的攻击行为
7. **List 查询必须分页** — 所有列表查询必须含分页参数（`page`, `pageSize`），默认 20 上限 100。响应 metadata 必须含 `currentPage`, `pageSize`, `totalPages`, `count`

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

前端项目（Vue/React）使用独立流程规范：[references/frontend-flows.md](references/frontend-flows.md) — 场景路由（着陆页→taste-skill / 仪表盘→ui-ux-pro-max / 通用→frontend-design）→ 6 步迭代内环（方向确认→编码→审查→回退→浏览器验证）→ 8 条铁律（T1/T2/T3 分级门禁）。

**命名规范**：Git 分支 `feat/YYMMDD_desc`（见 `rules/common/git-workflow.md`）、Java 文件 PascalCase、NestJS 文件 snake_case、文档 `YYYYMMDD - 标题.md`。

## CodeGraph 集成

仅当项目根目录已经存在 `.codegraph/` 时启用 CodeGraph，并优先使用 `codegraph context/query/affected` 理解内部代码。没有索引时使用项目已有的 Read/rg/Glob；初始化或安装 CodeGraph 必须先取得用户明确同意。详见 [references/codegraph.md](references/codegraph.md)。

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
3. 确认技术栈和影响范围。**Read `rules/common/patterns.md`** 确定项目技术栈匹配的规范清单（如 MySQL→table-structure.md、ES→elasticsearch.md）
4. **头脑风暴**：展开发散思考，探索多种可能的实现方向。不急于收敛——先列出所有可行的技术路线和设计模式，再讨论各自的适用场景和边界条件。只有澄清过的简单需求可跳过此步
5. **收敛为 2-3 种实现方案**，含 trade-off 和推荐理由
6. 输出需求卡片（标题/类型/范围/验收标准/约束）
7. **暂停，等用户确认。**

**门禁**：需求卡片必须含标题、类型、范围、验收标准（≥1 条）。缺任何一项不进入阶段 1。

### 1. 规划

1. **有 CodeGraph 则先执行**：
   - 检查项目根目录是否存在 `.codegraph/`
   - 已存在 → `codegraph context "<需求>"` 获取项目结构摘要（替代手工扫描）
   - 不存在 → 使用 Read/rg/Glob 检查结构；如索引会显著改善后续工作，只提出可选建议，未经确认不得执行 `codegraph init/index`
   - 检查项目是否已有 `CLAUDE.md`，若有则读取并增量更新（架构/模块/端口/命令等章节）
2. **加载规范路由**：Read `rules/common/patterns.md` + 语言特定 `rules/<lang>/patterns.md`，确定本次涉及的规范清单
3. `Agent({ subagent_type: "planner" })`，prompt 含：需求卡片 + 项目结构摘要 + 语言规范 + 适用规范清单。要求输出任务分解、依赖关系图、风险点列表
4. Agent 失败 → **展示错误，暂停**（两种模式都停）
5. 默认（自动）直接继续。交互模式问"计划 OK？"

**门禁**：计划必须含任务分解（≥2 个子任务）、依赖关系、风险点（≥1 个）。缺项不进入阶段 2。

### 2. 架构

1. `Agent({ subagent_type: "architect" })`，prompt 含：需求 + 计划 + 语言规范 + **适用规范清单**。要求产出 ADR（决策/后果/替代方案）+ 接口契约 + 数据变更
   - **接口契约必须达到实现级精度**（根据场景取舍）：
     - 类全名（含 package）
     - 方法签名（参数类型 / 返回值 / 抛出的异常）
     - 常量定义位置（类名 + 字段名，如 `MqConstants.SCHOOL_EXCHANGE`）
     - exchange / routingKey / queue 名（MQ 场景）
     - payload JSON 结构（字段名、类型、必填性）
     - 接口返回结构（ApiResponse / gRPC message / HTTP status）
2. **按适用规范自检**（三段式）：
   1. **判定触发条件**：回答 `rules/common/patterns.md` 中该规范的「触发判定问句」。触发条件不成立 → 跳过该规范的 checklist 和产出物。
   2. **触发成立 → 逐条对照规范 checklist**：
      - 涉及 API → 对照 `restful-api.md`（URL、HTTP 方法、状态码）+ `naming-convention.md`（参数命名、DTO 后缀、JSON camelCase）
      - 涉及 gRPC → 对照 `grpc-layering.md`（分层、无端侧 JWT/RBAC、服务身份默认拒绝、Status 映射）
      - 涉及数据库 → 对照 `table-structure.md`（命名、字段类型、审计字段）
      - 涉及 ES/MongoDB → 对照对应命名规范
   3. **触发成立且需要产出物 → 产出对应物**：
      - 数据库有 DDL 变更 → 产出迁移文件 `V{YYYYMMDD}__{描述}.sql`（含回滚脚本或 `[IRREVERSIBLE]` 标记）
      - 数据库无 DDL 变更 → 只对照 `table-structure.md` 做字段映射检查，**不产出迁移文件**
      - API/gRPC 触发成立 → 产出 URL/方法/DTO 或 proto + service 设计
3. 自检 P0 问题，**至少 3 轮、最多 5 轮**。5 轮后仍有 P0 → 暂停等用户决定
4. Agent 失败 → **展示错误，暂停**
5. 默认（自动）直接继续。交互模式问"方案 OK？"

### 3. 测试驱动开发

**铁律**：没有失败测试 → 没有生产代码。先行代码 = 删除。

1. `Agent({ subagent_type: "tdd-guide" })`，prompt 含需求 + 计划 + 架构 + **阶段 2 产出的接口契约文档** + 按技术栈指定测试命令：
   - Java → `mvn test`，JUnit5+AssertJ+Mockito，Testcontainers，JaCoCo
   - Node.js → `<pkg> test`，Vitest+supertest，Playwright E2E，v8
   - 前端 → `<pkg> test`，Vitest+Testing Library，Playwright E2E
   - **强制 agent 先 Read 项目的 `rules/<lang>/testing.md` 再动手**
   - 有 CodeGraph 时：`codegraph affected <改动文件>` 自动定位受影响测试，加速 RED 阶段
2. RED → GREEN → IMPROVE。**覆盖率门禁**：以业务生产代码为统计范围，整体覆盖率不得低于 80%，且不得因本次变更下降；本次新增或修改的业务生产代码覆盖率也不得低于 80%。如项目已有更严格门禁，按更严格规则执行。Bug 修复时，在修复关键代码处加注释说明**为什么这样修**
3. Agent 失败 → **展示错误，暂停**
4. 展示覆盖率报告，必须分别呈现：全量业务生产代码覆盖率、本次新增/修改业务生产代码覆盖率、未覆盖的关键业务分支及原因。任一项未达 80% → 暂停修复

**门禁**：全量业务生产代码覆盖率 ≥ 80% 且本次新增/修改业务生产代码覆盖率 ≥ 80%，且所有测试通过。任一项不达标不进入阶段 4。凡影响实际运行的代码（配置绑定、依赖注入、权限校验、异常分支等），不得仅因文件类型豁免，须有适当测试验证

### 4. 审查

每轮审查执行以下循环，**至少 3 轮、最多 5 轮**：

**规范加载**（每轮开始）：
Read `rules/common/patterns.md` → 根据项目技术栈，确定本次适用的规范清单。

**Round N**：
1. **ESLint 自动检查**（前端/Node.js 项目）：`<pkg> eslint . --max-warnings 0`，Error 规则 = 代码缺陷（如 `no-floating-promises`、`no-loop-func`），发现即阻断，计入审查清单 CRITICAL
2. 按技术栈 **并行**启动审查 agent：Java→`java-reviewer`，Node.js/前端→`typescript-reviewer` + `security-reviewer`
3. **通用规范审查**（主会话执行，逐条对照规范路由表）：
   - 接口与协议：对照 `api-response.md`、`restful-api.md`、`api-versioning.md`、`grpc-layering.md`（如适用）
   - 数据存储：对照 `table-structure.md`、`database-migration.md`、`mongodb.md`、`elasticsearch.md`（如适用）
   - 通用机制：对照 `logging.md`、`security.md`、`coding-style.md`、`testing.md`、`time-format.md`、`naming-convention.md`
4. NestJS 项目额外：`src/` 1 层 / 无 `src/modules/` / 相对路径 import / `synchronize: false` / 无 Entity `@Index()`
5. **基础设施配置审查**，详见 [references/infrastructure-review.md](references/infrastructure-review.md)
6. **输出审查清单**：CRITICAL > HIGH > MEDIUM > LOW 分级，每项附文件路径和修复建议。清单按规范分组，标注来源规范文件。ESLint 错误单独列出，标记为自动化检测
7. **暂停，等用户确认**。用户确认后自动修复（CRITICAL 必修，HIGH 默认修，MEDIUM/LOW 用户选择）。修复后输出修复清单。ESLint 错误修复后重跑 `eslint --max-warnings 0` 验证
8. 开始下一轮审查。即使全部通过也跑满 3 轮。每轮 ESLint 必须在 agent reviewer 之前先跑，避免审查完又改代码
9. 5 轮后仍有 CRITICAL/HIGH → 暂停等用户决定

有 CodeGraph 时每轮末尾 `codegraph query "<变更符号>"` 验证引用点。

**门禁**：CRITICAL = 0 且 HIGH = 0。不达标不进入阶段 5。

### 5. 提交

1. **启动验证**：
   - Java：`./mvnw spring-boot:run` 或 `mvn spring-boot:run`，确认无 Bean 创建失败、端口冲突
   - NestJS：`<pkg> start:dev` 或 `npm start`，确认无 DI 错误、无 crash
   - 验证通过后停掉进程再继续
2. **环境检查**：非 git 仓库警告暂停，`git diff --stat`
3. **格式复核**（按技术栈）：
   - Node.js/前端：`<pkg>` prettier → `<pkg>` eslint `--max-warnings 0`（阶段 4 已过，此处复核，不该有新错误）→ ts-prune（僵尸代码扫描，列清单不自动删）
   - Java：检测 pom.xml 是否含 `maven-pmd-plugin` → 有则 `mvn pmd:check`，无则跳过
   - 格式失败 → 暂停。优先复用项目已有 formatter/linter 配置
4. **构建验证**（Node.js/前端）：`<pkg> build`，构建失败或缺 build 命令 → 暂停
5. **完成前验证**：
   - [x] 测试通过 + 全量业务生产代码覆盖率 ≥ 80% + 本次新增/修改业务生产代码覆盖率 ≥ 80%
   - [x] 无 CRITICAL/HIGH 审查问题
   - [x] 格式已执行（prettier+eslint / p3c）
   - [x] 构建通过（或已处理缺失警告）
   - [x] 无 console.log / 调试残留
   - [x] 接口返回含 `requestId`（= traceId）和 `metadata`（timestamp/method/endpoint），格式符合 `rules/java/patterns.md` 规范
   - [x] DDL 变更已创建对应的迁移文件（`V{n}__{描述}.sql` 或 `V{YYYYMMDD}__{描述}.sql`），含回滚脚本或 `[IRREVERSIBLE]` 标记
   - [x] Codex 变体已同步（若本次变更涉及流程内容，`codex/SKILL.md` version + 流程变更已同步）
6. **Migration 确认**（存在迁移文件时必须执行）：
   - 列出本次提交包含的所有迁移文件及内容摘要
   - 告知用户：**Flyway 在应用启动时自动执行**，已部署的迁移不可修改（改错发新迁移）
   - **暂停，等用户确认。**（两种模式都必确认）
7. **文档更新**（提交前全量梳理）：
   - `CLAUDE.md`：架构图、模块清单、端口分配、常用命令、环境对照 — 确保与代码现状一致
   - `README.md`：功能说明、使用方式 — 确保与实际变更匹配
8. **生成 commit message**：遵循 [Conventional Commits](references/commit-conventions.md)（`<type>[!]: <desc>`），破坏性变更加 `!`
9. **展示确认**（两种模式都必确认）
10. **同步 Codex 变体**：若本次变更涉及工作流/规范/红线等流程内容（非 agent 调度逻辑），同步到 `codex/SKILL.md`：
    - 更新 `version` 字段与主 `SKILL.md` 一致
    - 同步行为红线、工作流各阶段、反模式、任务适配等流程变更
    - **不同步** agent 调度逻辑（Codex 版为内联执行，无 subagent 分发）
    - 同步后展示 diff 供确认
11. `git add <具体文件>`（精确添加，禁止 `git add -A`）+ `git commit`
12. **创建 tag**：遵循 [SemVer](references/commit-conventions.md#semver-tag)，根据 type 确定 MAJOR/MINOR/PATCH。**标签不可变**
13. 询问是否 push（含 `--tags`）。引导 PR/合并策略

## 中断与恢复

- 随时可中断，重说"继续梭"恢复
- 说"回到阶段 X"重做，说"从阶段 X 开始梭"或"梭到审查就行"
- **阶段 3 中断恢复**：先运行测试命令，根据结果判断当前所处 RED/GREEN/IMPROVE 阶段再继续
- **跨会话恢复**：每个阶段结束写入 `.yibasuo-state.json`（字段: stage/mode/requirement/decisions/coverage），新会话读取恢复
- **模式切换**：说"停一下"在当前最小步骤完成后暂停，不强制回滚
- **跳过约束**：阶段 0-2 可按需跳过，阶段 3(TDD) 和阶段 4(审查) **原则上不可跳过**；紧急 hotfix 场景可跳过阶段 3，但需显式声明风险并记入 commit message（如 `TDD skipped: hotfix for production incident`）

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
| **注释** | 扫描项目中缺少注释的 public 方法（Javadoc/JSDoc）、复杂逻辑、非直观业务规则，按 `rules/common/coding-style.md` 注释规范补充。不修改业务逻辑，仅补注释 |
| **生成说明文档** | 收集项目信息（README/CLAUDE/package.json/pom.xml）→ 整理为结构化文档 → 调用 `ui-ux-pro-max` skill 生成 HTML |
| **项目初始化** | 走 6.0 检测分流 → 6.1 初始化流程（骨架+模板+验证+本地 Git；远端/CodeGraph 单独确认） |
| **升级项目** | 走 6.0 检测分流 → 6.2 升级流程（分析+变更清单+增量升级+构建验证） |
| **审查项目整体架构** | 调用 6.2 阶段 0 分析能力，评估技术栈版本/依赖状态/升级路径 |

## 六、项目初始化与升级

> **触发词**：`初始化项目` `创建项目` `init project` `项目升级` `升级项目` `upgrade project`
>
> **与开发流程的关系**：初始化/升级是独立入口，完成后进入阶段 0 开始正常开发流程。在开发流程中若需**审查项目整体架构**（如存量项目首次接入、技术栈升级评估），可调用升级流程的阶段 0 分析能力。

### 6.0 检测与分流

1. 用户明确说"升级" → 升级流程（6.2）
2. 目录为空（无 pom.xml / package.json / src/）→ 初始化流程（6.1）
3. 存在 pom.xml → Java 项目
   - pom.xml 含 `spring-grpc-spring-boot-starter`、源码含 `@GrpcService`，或用户说"gRPC"/"微服务" → **gRPC 微服务**（按 [references/java-grpc-templates.md](references/java-grpc-templates.md)）
   - 使用 `spring-cloud-starter-gateway-server-webflux` 或用户明确 Gateway → **Gateway**（复用 `yms-gateway`，不能套用 BFF 模板）
   - 其他 → **HTTP/BFF**（按 [references/java-templates.md](references/java-templates.md)）
4. 存在 package.json 且 dependencies 含 @nestjs/core → NestJS 升级流程
5. 以上都不匹配 → 询问用户（Java HTTP / Java gRPC / NestJS / 取消）

### 6.1 初始化流程

#### 阶段 0：确认参数

| 参数 | Java HTTP/BFF | Java gRPC 微服务 | NestJS |
|------|-------------|-----------------|--------|
| 项目名 | 目录名 | 目录名 | 目录名 |
| 基础包名 | `com.example.{project}` | `com.jiachen.{service}` | — |
| 端口 | 8080 | 48200+（微服务段） | 3000 |
| Java / Node 版本 | 21 | 21 | 24 LTS |

YMS 项目额外确认：项目类型（Gateway / BFF / gRPC）、服务名、环境端口（BFF `APP_PORT`；gRPC `GRPC_PORT` + `HTTP_PORT`），以及实际需要的 DB/Redis/MQ/XXL-Job。YMS 分层、Nacos、健康检查和部署规则以 `rules/java/patterns.md` 的「YMS 架构覆盖层」为准。

**暂停，等待用户确认。**

#### 阶段 1：创建骨架 + 写入模板

按技术栈读取 `references/` 下的对应模板规格生成代码：

| 技术栈 | 模板规格 |
|--------|---------|
| YMS Gateway | 以 `yms-gateway` 的 WebFlux、路由、粗鉴权、TraceId 和 Nacos 配置为唯一参考；不得使用 BFF 或 gRPC 模板 |
| Java HTTP/BFF | [references/java-templates.md](references/java-templates.md) — Spring MVC、Gateway 内部请求校验、ApiResponse、gRPC client、Nacos、JSON logback、application.yml |
| Java gRPC 微服务 | [references/java-grpc-templates.md](references/java-grpc-templates.md) — pom.xml(gRPC+Web health+Nacos)、TraceId/InternalAuth interceptor、proto、`/healthy`、JSON logback |
| NestJS | [references/nestjs-templates.md](references/nestjs-templates.md) — package.json, main.ts, filter, interceptor, dto, tsconfig |

**软基建文件**（Java / NestJS 通用）：`README.md`（项目名/技术栈/启动命令）、`CLAUDE.md`（项目类型、分层边界、路径/端口/命令/配置来源/编码约定）、环境变量示例（YMS 使用 `deploy/.env.example`，通用项目可使用根目录 `.env.example`；无真实值且只列实际消费变量）、`.gitignore`、`.dockerignore`。`.gitignore` 必须包含 `.yibasuo-state.json`、`.yibasuo-deletions.log` 和默认不跟踪的 `.codegraph/`；YMS 私密仓库明确要求跟踪的 `deploy/.env.test` / `.env.prod` 不得被宽泛忽略。

**遵循的规则**：`rules/{lang}/coding-style.md`、`rules/{lang}/patterns.md`、`rules/{lang}/logging.md`、`rules/common/security.md`

#### 阶段 2：生成项目验证

在创建 Git 提交前验证生成结果：

```bash
# Java
./mvnw test && ./mvnw clean package

# NestJS（按锁文件选择包管理器）
<pkg> install --frozen-lockfile
<pkg> test
<pkg> build
<pkg> lint
```

- 命令必须按生成项目实际提供的 script/wrapper 调整，不得虚构通过结果
- 依赖数据库、Redis、Nacos 等外部资源而无法启动时，明确区分“编译/测试通过”和“未完成依赖支撑的启动验证”
- 任一必需命令失败 → 展示错误并暂停，不得进入 Git 初始化或宣称“项目已就绪”

#### 阶段 3：Git 本地初始化

```bash
# 仅适用于尚未处于任何 Git worktree 的新项目。
# 若已是 Git 仓库，先展示 status/diff/stash 并暂停，禁止把初始化流程套到存量仓库。
git -C <path> init -b master

# <generated-files...> 必须是阶段 1 实际创建的精确文件清单，禁止 git add -A / git add .
git -C <path> add -- <generated-files...>
git -C <path> diff --cached --name-status
# 展示暂存清单并取得提交确认后：
git -C <path> commit -m "feat(init): 项目初始化 — {Java SB4 / NestJS 11}"

init_sha="$(git -C <path> rev-parse HEAD)"
git -C <path> branch production "$init_sha"
git -C <path> branch staging "$init_sha"
git -C <path> branch development "$init_sha"
git -C <path> switch -c feat/YYMMDD_init-project development
```

分支层级：`production → staging → master → development → feat/xxx`

**远端操作不属于初始化默认动作**。需要 push 时先展示 remote、分支、提交和将要写入的远端分支；取得明确确认后逐分支执行。`production`、`staging` 与其他分支分别确认，不得使用 `push --all`，不得吞掉 pull/push 错误。

#### 阶段 3.5：CodeGraph 索引（可选）

```bash
nvm use 22 && codegraph init -i && codegraph index
```

- 仅在用户明确同意初始化索引后执行
- 若项目环境无兼容 Node.js 或 CodeGraph，跳过并记录；后续阶段继续使用 Read/rg/Glob

#### 阶段 4：完成提示

```
项目骨架已通过上述构建/测试验证。若外部依赖启动验证尚未完成，先配置数据库/Redis/Nacos 后补做；随后可说"一把梭"开始开发。
```

### 6.2 升级流程

#### 阶段 0：分析

**先读项目文件确认实际版本**：`pom.xml`（Java）或 `package.json`（NestJS），不要假设版本。再查对应官方兼容矩阵确定目标版本；“升级”不等于无条件追最新，YMS 必须同时满足 Spring Boot、Spring Cloud、Spring Cloud Alibaba 与 Spring gRPC 的兼容组合。

**Java 升级路径**：

| 当前 SB | 当前 Java | 升级路径 |
|---------|----------|---------|
| 2.7.x | 8/11 | 2.7→3.0→当前受支持的 3.x→经兼容验证的 4.x；Java→17→21 |
| 3.0.x-3.4.x | 17 | 3.x→当前受支持的 3.x→经兼容验证的 4.x；Java 17→21 |
| 3.5.x | 17/21 | 3.5→经兼容验证的 4.x |

破坏性变更: javax.*→jakarta.*, RestTemplate→HTTP Service Client, @Autowired字段→构造器注入, spring.factories→AutoConfiguration.imports, WebSecurityConfigurerAdapter→SecurityFilterChain

**NestJS 升级路径**：v9→10→11

#### 阶段 1：变更清单（暂停确认）

展示版本变更 + 代码变更点 + 风险点。**暂停，等用户确认。**

#### 阶段 2：增量升级

```
Java:  ①确认官方兼容矩阵与目标版本 → ②逐主版本升级并运行测试 → ③Java 版本升级 → ④javax→jakarta → ⑤@Autowired→构造器 → ⑥按实际弃用项迁移 HTTP client
NestJS: ①v9→10 → ②v10→11 → ③Node升级 → ④依赖修复
```

每步后**暂停确认**。

#### 阶段 3：构建验证

```bash
# Java:  ./mvnw clean package -DskipTests && ./mvnw test
# NestJS: <pkg> build && <pkg> test && <pkg> lint
```

#### 阶段 4：升级报告

版本变更表 + 代码变更统计 + 构建状态 + 后续建议（回归测试/CI更新/staging验证）

### 6.3 反模式

- **不要跳过确认** — 项目名/包名/端口错误 → 大量返工
- **不要擅自升级** — 不经变更清单+确认不执行升级
- **不要忽略日志规范** — logback-spring.xml 必须完整
- **不要用字段注入** — Java/NestJS 统一构造器注入
- **不要硬编码敏感信息** — 密码/密钥一律环境变量

## 示例

用户说：`自动梭 修复登录超时没提示`

| 阶段 | 行为 |
|------|------|
| 0 | 澄清：超时多少秒？提示文案？确认 NestJS → 注入 typescript rules |
| 1 | （Bug 修复跳过） |
| 2 | （Bug 修复跳过） |
| 3 | tdd-guide：`pnpm test`，Vitest+supertest，全量≥80%+增量≥80%，关键代码加注释 |
| 4 | typescript-reviewer ∥ security-reviewer 并行 |
| 5 | prettier→eslint→ts-prune→build→commit `fix: 登录超时增加用户提示`→tag `v1.2.1`

## 反模式

- **不要跳过门禁** — 确认是安全阀
- **不要忽略审查** — CRITICAL 必须修
- **不要模糊需求直接梭** — 阶段 0 没搞清楚就往下走，5 阶段白跑
- **不要并行依赖阶段** — 架构没出来就编码无意义
