# 一把梭 (yibasuo) — 全流程开发管线 + 项目初始化/兼容性升级 v3.0.2

> 需求 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交。
> 7 个内置 Agent + 4 套 Rules，流程化消除 AI 编码的随机性。

---

## 触发词

| 入口 | 触发词 | 行为 |
|------|--------|------|
| **开发流程** | `一把梭` `全流程` `梭哈` | 阶段 0 确认后连续执行，提交前确认 |
| **项目初始化** | `初始化项目` `创建项目` `init project` | 创建骨架 + 模板 + 构建验证 + 本地 Git |
| **项目升级** | `项目升级` `升级项目` `upgrade project` | 解析兼容矩阵 + 增量升级 + 构建验证 |
| **交互模式** | `一步步梭` `交互梭` `确认梭` | 每阶段确认后继续 |

中途切换：`停一下` → 交互模式 · `继续梭` → 自动模式

---

## 安装

```bash
git clone git@github.com:occultskyrong/yibasuo-skill.git /tmp/yibasuo-skill
cd /tmp/yibasuo-skill && bash install.sh        # Claude Code
cd /tmp/yibasuo-skill && bash install.sh --codex # Codex
```

**更新**：`cd /tmp/yibasuo-skill && git pull && bash install.sh --force`
**版本**：`cat ~/.claude/skills/yibasuo/.installed-version`
**发布校验**：`bash install.sh --verify`（要求版本一致、Claude/Codex 模板一致、工作区干净且 HEAD 有精确版本标签）

---

## 开发流程（5 阶段）

不达标不推进。阶段 0 和阶段 5 不论模式都必须确认。

### 阶段 0 · 需求确认

1. 研究复用 — 搜索已有实现、开源项目、包注册表；hotfix/配置变更/文档更新可跳过
2. 澄清需求 — 一次聚焦一个主题；跨模块可一次提 2-3 个关联问题
3. 确认技术栈和影响范围
4. 提出 2-3 种方案，含 trade-off 和推荐理由
5. 输出需求卡片（标题 / 类型 / 范围 / 验收标准）

**门禁**：需求卡片必须含标题、类型、范围、验收标准（≥1 条）

### 阶段 1 · 规划

1. 项目已有 `.codegraph/` 时用 CodeGraph 获取结构摘要；否则用 Read/rg/Glob。初始化索引须先取得用户明确同意
2. 调用 `planner` agent — 输入需求卡片 + 项目结构 + 语言规范 + 适用规范清单
3. 产出：任务分解、依赖关系图、风险点列表

**门禁**：任务≥2，风险点≥1

### 阶段 2 · 架构

1. 调用 `architect` agent — 输入需求 + 计划 + 语言规范
2. 产出：ADR（决策/后果/替代方案）、接口契约（实现级精度）、数据变更
3. 三段式规范自检 — 触发条件 → checklist → 产出物
4. 自检 P0 问题 — 至少 3 轮、最多 5 轮

**门禁**：P0 清零。5 轮后仍有 P0 → 暂停等用户决定

### 阶段 3 · 测试驱动开发

1. 调用 `tdd-guide` agent — 先读 `rules/<lang>/testing.md`；以接口契约为唯一事实来源
2. RED → GREEN → IMPROVE — Bug 修复时关键代码加注释说明根因
3. 展示覆盖率报告（全量业务生产代码覆盖率、本次新增/修改业务生产代码覆盖率、未覆盖的关键业务分支及原因）

**门禁**：全量业务生产代码覆盖率 ≥ 80% 且本次新增/修改业务生产代码覆盖率 ≥ 80%，且所有测试通过。配置绑定、依赖注入、权限校验、异常分支等影响实际运行的代码，不得仅因文件类型豁免

### 阶段 4 · 审查

1. ESLint 自动检测（Error 规则 = CRITICAL）→ agent 并行审查 → 规范逐条核对 → 基础设施审查
2. 输出分级清单（CRITICAL > HIGH > MEDIUM > LOW），ESLint 错误单独标注
3. CRITICAL 必修，HIGH 默认修；修复后重跑 ESLint 验证
4. 至少 3 轮、最多 5 轮。5 轮后仍有 CRITICAL/HIGH → 暂停等用户决定

**门禁**：CRITICAL = 0 且 HIGH = 0

### 阶段 5 · 提交

1. 启动验证（确认无启动错误后停进程）
2. 环境检查 + `git diff --stat`
3. 格式复核 + 构建验证
4. 完成前验证（测试/审查/格式/构建/requestId/迁移文件/Codex 同步）
5. 文档更新（CLAUDE.md + README.md）
6. Conventional Commits → 同步 Codex 变体 → commit + SemVer tag → 询问是否 push

---

## 项目初始化与升级（第 6 章）

### 初始化流程

1. **确认参数** — 先选择 Java HTTP/BFF、Java gRPC、NestJS HTTP 或 NestJS gRPC，再确认项目名、包名、端口、Java/Node 版本；NestJS gRPC 还需确认 proto package、service 与权威 proto（暂停等确认）
2. **创建骨架 + 写入模板** — 按技术栈读 `references/` 生成代码 + 软基建文件；NestJS HTTP/gRPC 分别路由到各自模板，YMS 使用 `deploy/.env.example`
3. **生成物验证** — Java 执行 test + package；NestJS 锁文件安装后执行 test + build + lint。外部依赖未就绪时明确区分“构建通过”和“启动/业务链路未验证”
4. **本地 Git 初始化** — 仅新仓库执行 `git init -b master`，精确暂存生成文件；从同一个初始提交创建环境分支。远端添加和逐分支推送必须另行确认
5. **CodeGraph 索引（可选）** — 仅经用户明确同意后初始化；未安装时继续使用 Read/rg/Glob
6. **完成** — 只报告实际通过的构建、测试与启动证据

### 升级流程

1. **分析** — 读 pom.xml/package.json 确认实际版本，并从官方兼容矩阵解析目标组合，不把“最新版本”当成默认目标
2. **变更清单** — 版本变更 + 代码变更点 + 风险点（暂停等确认）
3. **增量升级** — 按路径分步升级，每步暂停确认
4. **构建验证** — `mvn clean package` / `<pkg> build && test`
5. **升级报告** — 版本变更表 + 代码变更统计 + 后续建议

---

## 任务适配

| 任务类型 | 流程 | 说明 |
|---------|------|------|
| 新功能 | 0 → 5 | 完整 5 阶段 |
| 重构 | 0 → 2 → 3 → 4 → 5 | 阶段 0 范围确认，阶段 2 影响分析，阶段 3 回归测试 |
| Bug 修复 | 3 → 4 → 5 | TDD → 审查 → 提交 |
| 依赖升级 | 2 → 3 → 4 → 5 | 兼容分析 → 全量回归 → breaking change 审查 |
| 数据库迁移 | 0 → 5 | 阶段 0 确认范围+大表风险，阶段 5 迁移文件不可变检查 |
| 注释 | 3 → 4 | 补充 Javadoc/JSDoc，不修改业务逻辑 |
| 单文件小改 | — | 不建议用一把梭，直接手改 + code-reviewer |
| 项目初始化 | 6.0 → 6.1 | 创建骨架 → 模板 → 构建验证 → 本地 Git；远端与 CodeGraph 均需单独确认 |
| 升级项目 | 6.0 → 6.2 | 分析 → 变更清单 → 增量升级 → 报告 |
| 审查项目整体架构 | 6.2 阶段 0 | 评估技术栈版本 / 依赖状态 / 升级路径 |

---

## 技术栈

| 技术栈 | 测试框架 | 格式检查 |
|------|--------|--------|
| Java / Spring Boot 4.0+ | JUnit5 + Mockito + Testcontainers | p3c |
| Node.js / NestJS 11+ | Vitest + supertest + Playwright | Prettier + ESLint |
| Vue / React | Vitest + Testing Library + Playwright | Prettier + ESLint |

覆盖 HTTP/BFF 和 gRPC 微服务两种架构模式。

---

## 内置 Agent 矩阵

| Agent | 职责 | 调用阶段 |
| --- | --- | --- |
| planner | 任务分解、依赖关系、风险点 | 阶段 1 |
| architect | ADR、接口契约、数据变更 | 阶段 2 |
| tdd-guide | RED→GREEN→IMPROVE、全量≥80%+增量≥80% | 阶段 3 |
| code-reviewer | 通用代码质量审查 | 阶段 4 |
| java-reviewer | Java/Spring Boot 专项审查 | 阶段 4（Java 项目） |
| typescript-reviewer | TypeScript/Node.js 专项审查 | 阶段 4（TS 项目） |
| security-reviewer | OWASP Top 10、注入、密钥泄露 | 阶段 4 |

---

## 规范规则

安装后按文件 `paths:` 匹配语言自动加载。规范路由入口 `patterns.md` 按场景路由到具体文件，各阶段渐进式暴露：

- 阶段 1 规划期：读 patterns.md 路由表 → 确定适用规范清单 → 注入 planner
- 阶段 2 架构期：按适用规范对照自检（三段式触发门）
- 阶段 4 审查期：全量规范逐条核对，清单按规范分组标注来源

### Common（通用，所有语言）

| 规范 | 覆盖内容 |
|------|---------|
| patterns | 统一返回结构 · API 版本控制 · RESTful 设计 · HTTP/gRPC 分层 · 定时任务 |
| table-structure | MySQL 表结构命名 · 字段类型(INT 主键) · 审计字段 · DDL 模板 |
| database-migration | 迁移 6 步流程 · 幂等 · 回滚 · 大表策略 |
| security | OWASP Top 10 · 访问控制 · 注入防护 · 密码存储 · 安全头 |
| concurrency | 线程安全 · 锁粒度 · 超时 · 原子操作 |
| elasticsearch | 索引命名 · 读写别名 · index template · ILM |
| mongodb | 集合命名 · 字段命名 · 混合文档 · 删前归档 |
| testing | 全量≥80%+增量≥80% · TDD: RED→GREEN→IMPROVE · AAA 模式 |
| coding-style | 不可变性 · 命名 · 注释规范 · 文件组织 |
| git-workflow | 分支命名 · Conventional Commits · SemVer Tag |
| logging | TraceId · 占位符 · JSON 格式(prod) · 敏感脱敏 |
| api-response · api-versioning · restful-api · grpc-layering · time-format · scheduled-tasks · code-review · performance · agents · hooks · development-workflow | 各专题独立文件，由 patterns.md 路由 |

### Java（Spring Boot 4.0+ / Java 21）

| 规范 | 覆盖内容 |
|------|---------|
| patterns | Repository/Service/Controller 分层 · 构造器注入 · DTO 映射 · YMS Gateway/BFF/gRPC 架构覆盖层 |
| security | Spring Security · JWT HS256 · Redis Token 黑名单 · BCrypt cost=12 |
| testing | JUnit5+AssertJ+Mockito · Testcontainers(禁止 H2) · JaCoCo |
| coding-style | POJO 规范 · Virtual Threads · Javadoc 强制范围 |
| logging | SLF4J+Logback · AsyncAppender · traceId(MDC) |

### TypeScript（NestJS 11+ / Node 24 LTS）

| 规范 | 覆盖内容 |
|------|---------|
| patterns | Controller→Service→Repository · DTO/Guard/Interceptor · BullMQ |
| security | Helmet/CORS · 速率限制 · JWT · bcrypt cost=12 |
| testing | Vitest+supertest+Playwright · Mock 策略 |
| coding-style | `satisfies` · Branded Types · JSDoc 强制范围 |
| logging | pino · traceId(AsyncLocalStorage) · 结构化日志 |

### Web（Vue / React）

| 规范 | 覆盖内容 |
|------|---------|
| patterns | 组件模式 · Custom Hooks · 状态管理(Pinia/Zustand) |
| testing | Vitest+Testing Library · Playwright E2E |
| coding-style | 组件命名 · 文件组织 · CSS 方案 |
| static-website-checklist | CDN 国内替换 · ICP/公安备案 · SEO · 模板残留清理 |

---

## References（技能内置模板）

| 文件 | 用途 | 适用场景 |
| --- | --- | --- |
| commit-conventions.md | Conventional Commits + SemVer | 阶段 5 提交 |
| codegraph.md | CodeGraph 集成 | 阶段 1/3/4 |
| frontend-flows.md | 前端开发规范 | Vue/React 项目 |
| infrastructure-review.md | 基础设施配置审查 | 阶段 4 |
| java-templates.md | Java HTTP/BFF 项目模板 | 项目初始化（Java HTTP） |
| java-grpc-templates.md | Java gRPC 微服务模板 | 项目初始化（Java gRPC） |
| nestjs-templates.md | NestJS HTTP 模板 | 项目初始化（NestJS HTTP） |
| nestjs-grpc-templates.md | NestJS gRPC 微服务模板 | 项目初始化（NestJS gRPC） |

---

## Token 消耗

| 场景 | 直接对话 | 一把梭 | 倍数 |
| --- | --- | --- | ---: |
| 新功能（中等复杂度） | ~25K | ~70K | ~2.8x |
| Bug 修复 | ~12K | ~30K | ~2.5x |
| 简单改动 | ~5K | ~7K | ~1.4x |

> 额外成本换取：架构评审 + 强制 TDD（全量≥80%+增量≥80%）+ 代码审查 + 安全审查 + 基础设施审查 + 规范对照检查。启用 CodeGraph 可减少 ~62% 工具调用和 ~25% 总 token。

---

## 协议

[MIT License](LICENSE) — 允许任何人随意使用、复制、修改、分发、出售。
