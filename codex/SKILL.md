---
name: yibasuo
description: "一把梭 — 全流程开发管线 + 项目初始化/兼容性升级。触发词：一把梭、全流程、梭哈（开发）；初始化项目、创建项目、init project、项目升级、upgrade project（基建）。每阶段暂停等用户确认后继续。"
metadata:
  version: "3.0.2"
---

# 一把梭 — 全流程开发管线

> 需求 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交

Codex 版：主会话内联执行，每阶段暂停等用户确认。

## 行为红线

1. **编码前思考** — 不确定时提 2-3 种解释，不默默假设
2. **简洁优先** — 最少代码解决问题，不添加未请求的功能
3. **手术刀改动** — 只改任务相关代码，不顺手重构；死代码只提不删
4. **循环验证** — 每阶段定义成功标准，不达标不回；全量业务生产代码覆盖率≥80%且增量≥80%、CRITICAL=0 是底线
5. **破坏性变更需确认** — 删除文件/代码块/接口签名/数据库表或字段等操作，必须先说明删除什么、为什么、影响范围。**用户同意后方可执行**，执行后在 `.yibasuo-deletions.log` 追加记录
6. **前端校验不替代后端** — 后端必须重新完整校验所有入参，即使前端已校验
7. **List 查询必须分页** — 所有列表查询含分页参数（`page`, `pageSize`），默认 20 上限 100

## 语言适配

| 技术栈 | 注入要点 |
|--------|---------|
| Java | JUnit5+AssertJ+Mockito+Testcontainers，p3c，构造器注入，Logback |
| Node.js / NestJS | Vitest+supertest，NestJS分层，pino，`__`私有前缀，Zod |
| Vue / React | Vitest+Testing Library，Pinia/Zustand，Playwright E2E，Prettier+ESLint |

**包管理器检测**：Node.js/前端项目根据锁文件自动选择 — `pnpm-lock.yaml`→pnpm、`yarn.lock`→yarn、`package-lock.json`→npm。优先级：pnpm > yarn > npm。用 `<pkg>` 指代检测到的包管理器。

**统一接口返回**：`{ code, message, data, requestId, metadata }` — requestId=traceId 全链路透传。

## 前端项目差异

前端分两类，流程不同，详见 rules/web 规范。**静态网站**侧重备案/SEO/无障碍/CDN；**管理后台**侧重权限矩阵/Token策略/富文本XSS/文件上传校验。

## CodeGraph 集成（可选）

仅当项目根目录已有 `.codegraph/` 时使用 CodeGraph。没有索引时使用 Read/rg/Glob；安装或执行 `codegraph init/index` 必须先取得用户明确同意。

| 阶段 | CodeGraph 用法 |
|------|-------|
| 1 规划 | `codegraph context "<需求>"` 获取项目结构摘要 |
| 3 TDD | `codegraph affected <文件>` 定位受影响测试 |
| 4 审查 | `codegraph query "<符号>"` 验证引用点已更新 |

## 文档同步

每个阶段结束时，若变更影响项目架构/模块/端口/技术栈，增量更新 `CLAUDE.md`。阶段 5 提交前全量梳理 `CLAUDE.md` + `README.md`。

---

## 工作流

### 0. 需求确认

**前置步骤（研究复用）**：确认需求前先搜索项目内已有实现、GitHub 相关开源项目、包注册表。紧急 hotfix/配置变更/文档更新可跳过。

1. 理解输入，识别模糊点。多子系统**先拆解**，逐个处理
2. 一次聚焦一个主题澄清；跨模块复杂需求可一次提 2-3 个关联问题
3. 确认技术栈和影响范围
4. **提出 2-3 种实现方案**，含 trade-off 和推荐理由
5. 输出需求卡片（标题/类型/范围/验收标准）
6. **暂停，等用户确认。**

**门禁**：需求卡片必须含标题、类型、范围、验收标准（≥1 条）。缺任何一项不进入阶段 1。

### 1. 规划

1. **有 CodeGraph 则先执行**：检查 `.codegraph/` 是否存在；存在则执行 `codegraph context` 获取项目结构，不存在则使用 Read/rg/Glob，未经确认不得初始化索引；检查 CLAUDE.md 是否有则增量更新
2. 读项目代码（Read/Bash 确认结构、模块、版本）
3. 读取项目的 `rules/` 了解语言规范
4. 基于需求卡片 + 项目结构，输出任务分解、依赖关系图、风险点列表
5. **暂停，等用户确认。**

**门禁**：计划必须含任务分解（≥2 个子任务）、依赖关系、风险点（≥1 个）。

### 2. 架构

1. 基于需求 + 计划，设计方案
2. 产出 ADR（决策/后果/替代方案）+ 接口契约 + 数据变更
   - **接口契约必须达到实现级精度**（根据场景取舍）：类全名 / 方法签名 / 常量定义位置 / exchange&routingKey / payload JSON 结构 / 返回结构
   - **复现优先原则**：当任务是「为某服务复现另一服务已有模式」时，架构 = 已验证实现的精确拷贝 + 差异点 ADR；禁止臆测补 P0
3. 按 `rules/common/patterns.md` 的「触发判定问句」自检：
   - 触发条件成立 → 逐条对照规范 checklist 并产出对应物
   - 数据库有 DDL 变更 → 产出迁移文件 `V{YYYYMMDD}__{描述}.sql`
   - 数据库无 DDL 变更 → 只对照 `table-structure.md` 做字段映射检查，**不产出迁移文件**
4. 自检 P0 问题（缺关键决策/接口遗漏/数据变更缺失），至少 3 轮、最多 5 轮
5. **暂停，等用户确认。**

**门禁**：P0 清零。5 轮后仍有 P0 → 暂停等用户决定。

### 3. 测试驱动开发

**铁律**：没有失败测试 → 没有生产代码。先行代码 = 删除。

1. 先 Read 阶段 2 产出的接口契约文档 + 项目的 `rules/<lang>/testing.md` 了解测试规范（**必须执行**）
2. 以接口契约为唯一事实来源编写测试，不得自行发明字段名、exchange 名、常量位置、方法签名
3. RED 阶段编译失败时先分类：
   - 「符号不存在 / 名字不符」→ 回阶段 2 校准契约
   - 「逻辑未实现」→ 继续 GREEN 阶段
4. 按技术栈编写测试并运行：
   - Java → `mvn test`，JUnit5+AssertJ+Mockito，Testcontainers，JaCoCo
   - Node.js → `<pkg> test`，Vitest+supertest，Playwright E2E
   - 前端 → `<pkg> test`，Vitest+Testing Library，Playwright E2E
5. RED → GREEN → IMPROVE。**覆盖率门禁**：以业务生产代码为统计范围，整体覆盖率不得低于 80%，且不得因本次变更下降；本次新增或修改的业务生产代码覆盖率也不得低于 80%。如项目已有更严格门禁，按更严格规则执行。Bug 修复时在关键代码处加注释说明根因
6. 展示覆盖率报告，必须分别呈现：全量业务生产代码覆盖率、本次新增/修改业务生产代码覆盖率、未覆盖的关键业务分支及原因。任一项未达 80% → 暂停修复
5. **暂停，等用户确认。**

**门禁**：全量业务生产代码覆盖率 ≥ 80% 且本次新增/修改业务生产代码覆盖率 ≥ 80%，且所有测试通过。任一项不达标不进入阶段 4。凡影响实际运行的代码（配置绑定、依赖注入、权限校验、异常分支等），不得仅因文件类型豁免，须有适当测试验证

### 4. 审查

1. 按技术栈执行审查：
   - **代码质量**：函数 <50 行、文件 <800 行、无深度嵌套（>4 层）、错误处理显式、命名规范、无死代码/console.log
   - **安全性**：无硬编码密钥/密码/Token、SQL 注入防护、XSS 防护、输入校验完整
   - **基础设施配置审查**：扫描配置文件识别重复、检查 .env.example 变量与代码 `process.env.*` 引用是否对应、检查硬编码 API Key
2. CRITICAL 和 HIGH 级别问题**必须修复**，修复前先写复现测试
3. 修复后重新审查确认（至少 3 轮、最多 5 轮）
4. 展示审查结论
5. **暂停，等用户确认。**

**门禁**：CRITICAL=0 且 HIGH=0。不达标不进入阶段 5。

### 5. 提交

1. **启动验证**：
   - Java：`./mvnw spring-boot:run`，确认无 Bean 创建失败、端口冲突
   - NestJS：`<pkg> start:dev`，确认无 DI 错误、无 crash
   - 验证通过后停掉进程
2. **环境检查**：非 git 仓库警告暂停，`git diff --stat`
3. **格式检查**：
   - Node.js/前端：`<pkg>` prettier → `<pkg>` eslint → ts-prune
   - Java：检测 pom.xml 含 `maven-pmd-plugin` → 则 `mvn pmd:check`
4. **构建验证**（Node.js/前端）：`<pkg> build`
5. **完成前验证**：
   - [x] 测试通过 + 全量业务生产代码覆盖率 ≥ 80% + 本次新增/修改业务生产代码覆盖率 ≥ 80%
   - [x] 无 CRITICAL/HIGH 审查问题
   - [x] 格式已执行 + 构建通过
   - [x] 无 console.log / 调试残留
   - [x] 接口返回含 `requestId`（=traceId）和 `metadata`（timestamp/method/endpoint）
   - [x] DDL 变更已创建对应迁移文件，含回滚脚本或 `[IRREVERSIBLE]` 标记
   - [x] Codex 变体已同步（若本次变更涉及流程内容，`codex/SKILL.md` version + 流程变更已同步）
6. **文档更新**：全量梳理 `CLAUDE.md`（架构/模块/端口/命令）+ `README.md`
7. 按 Conventional Commits 格式生成 commit message，展示给用户确认
8. **同步 Codex 变体**：若本次变更涉及工作流/规范/红线等流程内容（非 agent 调度逻辑），同步到 `codex/SKILL.md`：
   - 更新 `version` 字段与主 `SKILL.md` 一致
   - 同步行为红线、工作流各阶段、反模式、任务适配等流程变更
   - **不同步** agent 调度逻辑（Codex 版为内联执行，无 subagent 分发）
   - 同步后展示 diff 供确认
9. `git add <具体文件>`（精确添加，禁止 `-A`）+ `git commit`
10. 创建 SemVer tag（标签不可变）
11. 询问是否 push（含 `--tags`）。引导 PR/合并策略

---

## 中断与恢复

- 随时可中断，重说"继续梭"恢复
- 说"回到阶段 X"重做，说"从阶段 X 开始梭"
- **阶段 3 中断恢复**：先运行测试命令，根据 RED/GREEN/IMPROVE 阶段再继续
- **跨会话恢复**：每个阶段结束写入 `.yibasuo-state.json`（字段: stage/mode/requirement/decisions/coverage），新会话读取恢复
- **跳过约束**：阶段 0-2 可按需跳过，阶段 3(TDD) 和阶段 4(审查) **不可跳过**（跳过 TDD 需显式声明风险并记入 commit）

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 | 完整 6 阶段 |
| 重构 | 阶段 0→范围确认，阶段 2→影响分析，阶段 3→回归测试 |
| Bug 修复 | 跳过 0-2，阶段 3(TDD)→4→5 |
| 依赖升级 | 跳过 0-1，阶段 2→兼容分析，阶段 3→全量回归，阶段 4→breaking change 审查 |
| 数据库迁移 | 阶段 0→范围+大表风险，阶段 5→迁移文件不可变检查 |
| 单文件小改 | 不建议用一把梭，直接手改 + code-reviewer |
| 注释 | 扫描项目缺少注释的 public 方法/复杂逻辑，按规范补充 Javadoc/JSDoc，不修改业务逻辑 |
| 纯研究 | 不适用，用 Read/Bash 手动调研 |
| 生成说明文档 | 收集项目信息（README/CLAUDE/package.json/pom.xml）→ 整理为结构化文档 |
| **项目初始化** | 走 6.0 检测分流 → 6.1 初始化流程（骨架+模板+验证+本地 Git；远端/CodeGraph 单独确认） |
| **升级项目** | 走 6.0 检测分流 → 6.2 升级流程（分析+变更清单+增量升级+构建验证） |
| **审查项目整体架构** | 调用 6.2 阶段 0 分析能力，评估技术栈版本/依赖状态/升级路径 |

## 示例

用户说：`一把梭 修复登录超时没提示`

| 阶段 | 行为 |
|------|------|
| 0 | 澄清：超时多少秒？提示文案？确认 NestJS → 注入 typescript rules |
| 1 | （Bug 修复跳过） |
| 2 | （Bug 修复跳过） |
| 3 | RED→GREEN→IMPROVE，Vitest+supertest，全量≥80%+增量≥80%，关键代码加注释 |
| 4 | 代码质量审查 + 安全审查 |
| 5 | prettier→eslint→ts-prune→build→commit `fix: 登录超时增加用户提示`→tag→push |

## 六、项目初始化与升级

> **触发词**：`初始化项目` `创建项目` `init project` `项目升级` `升级项目` `upgrade project`
>
> Codex 版为内联执行，每阶段暂停等用户确认。模板文件位于 `references/`。

### 6.0 检测与分流

1. 用户明确说"升级" → 升级流程（6.2）
2. 目录为空（无 pom.xml / package.json / src/）→ 初始化流程（6.1）
3. 存在 pom.xml → Java 项目：含 gRPC 依赖或 `@GrpcService` → gRPC 微服务模板；使用 Gateway WebFlux starter 或明确 Gateway → 复用 `yms-gateway`；其他 → HTTP/BFF 模板
4. 存在 package.json 且含 @nestjs/core → 识别 NestJS 子类型后进入升级流程：
   - 同时含 `@nestjs/microservices`、`@grpc/grpc-js`，源码含 `@GrpcMethod` / `Transport.GRPC`，或用户明确说 "NestJS gRPC" / "NestJS 微服务" → NestJS gRPC（读 [references/nestjs-grpc-templates.md](references/nestjs-grpc-templates.md)）
   - 其他 → NestJS HTTP（读 [references/nestjs-templates.md](references/nestjs-templates.md)）
5. 以上都不匹配 → 询问用户（Java HTTP / Java gRPC / NestJS HTTP / NestJS gRPC / 取消）

### 6.1 初始化流程

1. **确认参数**：项目类型（Java HTTP/BFF / Java gRPC / NestJS HTTP / NestJS gRPC）、项目名、包名、端口、Java/Node 版本；NestJS gRPC 额外确认 proto package、service 名、proto 路径及是否存在权威 proto；YMS 额外确认 Gateway/BFF/gRPC 类型、服务名及实际 DB/Redis/MQ/XXL-Job 依赖（暂停等确认）
2. **创建骨架 + 写入模板**：按技术栈读 `references/` 对应模板生成代码 + 软基建文件（README/CLAUDE/环境变量示例/.gitignore/.dockerignore）；NestJS HTTP 读 [references/nestjs-templates.md](references/nestjs-templates.md)，NestJS gRPC 读 [references/nestjs-grpc-templates.md](references/nestjs-grpc-templates.md)；YMS 使用 `deploy/.env.example`，通用项目可使用根目录 `.env.example`；`.gitignore` 加入 `.yibasuo-state.json`、`.yibasuo-deletions.log`、`.codegraph/`，但不得忽略 YMS 明确跟踪的 `deploy/.env.test` / `.env.prod`。YMS Gateway 复用 `yms-gateway`，BFF 与 gRPC 分别使用对应模板
3. **生成项目验证**：Java 运行 test+package；NestJS 运行 install+test+build+lint。外部依赖不可用时明确标记未完成启动验证
4. **Git 本地初始化**：仅限新仓；精确暂存生成文件并展示确认后 commit；4 个环境分支从固定 init SHA 创建，禁止 `git add -A`
5. **远端操作**：默认不 push；展示 remote/branch/commit 并分别确认后才能写入，禁止 `push --all`
6. **CodeGraph 索引**（可选）：仅在用户明确同意后执行 `nvm use 22 && codegraph init -i && codegraph index`
7. **完成提示**：只有构建/测试通过后才称项目骨架已就绪；列明仍缺少的依赖支撑启动验证

### 6.2 升级流程

1. **分析**：读 pom.xml/package.json 确认实际版本，并查官方兼容矩阵确定目标版本；不无条件追最新（暂停等确认）
2. **增量升级**：按路径逐步升级，每步暂停确认
3. **构建验证**：`mvn clean package` / `<pkg> build && test`
4. **升级报告**：版本变更表 + 代码变更统计 + 构建状态 + 后续建议

### 6.3 反模式

- **不要跳过确认** — 项目名/包名/端口错误 → 大量返工
- **不要擅自升级** — 不经变更清单+确认不执行升级
- **不要用字段注入** — Java/NestJS 统一构造器注入
- **不要硬编码敏感信息** — 密码/密钥一律环境变量

## 反模式

- **不要跳过门禁** — 确认是安全阀
- **不要忽略审查** — CRITICAL 必须修
- **不要模糊需求直接梭** — 阶段 0 没搞清楚就往下走，5 阶段白跑
- **不要并行依赖阶段** — 架构没出来就编码无意义
