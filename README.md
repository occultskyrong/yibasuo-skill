# 一把梭 (yibasuo) — 全流程开发管线 v2.17.1

> 需求 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交。7 个内置 Agent + 4 套 Rules，流程化消除 AI 编码的随机性。

### 触发词速查

| 想要什么 | 说什么 |
|---------|--------|
| 全流程开发 | `一把梭` `全流程` `梭哈` |
| 每步确认 | `一步步梭` `交互梭` `确认梭` |
| 只补注释不写代码 | `注释` |
| 初始化项目 | [yibasuo-infra](https://github.com/occultskyrong/yibasuo-infra) |

## 1. 安装

```bash
git clone git@github.com:occultskyrong/yibasuo-skill.git /tmp/yibasuo-skill
cd /tmp/yibasuo-skill && bash install.sh        # Claude Code
cd /tmp/yibasuo-skill && bash install.sh --codex # Codex
```

## 2. 快速开始

| 模式 | 触发词 | 行为 |
|------|--------|------|
| 自动（默认） | `一把梭` `全流程` `梭哈` | 阶段 0 确认后，1-4 连续执行，提交前确认 |
| 交互 | `一步步梭` `交互梭` `确认梭` | 每阶段确认后继续 |

中途 `停一下` 切交互，`继续梭` 回自动。

## 3. 6 阶段

### 3.0 需求确认

| 步骤 | 动作 |
|------|------|
| 0.1 | 研究复用：搜索项目内已有实现、GitHub 开源项目、包注册表（npm/Maven）。hotfix/配置变更/文档更新可跳过 |
| 0.2 | 澄清需求，一次聚焦一个主题；跨模块复杂需求可一次提 2-3 个关联问题 |
| 0.3 | 确认技术栈和影响范围 |
| 0.4 | 提出 2-3 种实现方案，含 trade-off 和推荐理由 |
| 0.5 | 输出需求卡片（标题/类型/范围/验收标准） |

**门禁**：需求卡片必须含标题、类型、范围、验收标准（≥1 条）。

### 3.1 规划

| 步骤 | 动作 |
|------|------|
| 1.1 | CodeGraph 获取项目结构摘要；检查项目 CLAUDE.md 是否存在，有则增量更新（架构/模块/端口/命令） |
| 1.2 | 调用 `planner` agent：输入需求卡片 + 项目结构 + 语言规范 |
| 1.3 | 产出：任务分解、依赖关系图、风险点列表 |

**门禁**：任务≥2 个，风险点≥1 个。自动模式直接继续，交互模式确认。

### 3.2 架构

| 步骤 | 动作 |
|------|------|
| 2.1 | 调用 `architect` agent：输入需求 + 计划 + 语言规范 |
| 2.2 | 产出：ADR（决策/后果/替代方案）、接口契约、数据变更 |
| 2.3 | 自检 P0 问题（缺关键决策/接口遗漏/数据变更缺失），至少 3 轮、最多 5 轮 |

**门禁**：P0 清零。5 轮后仍有 P0 → 暂停等用户决定。

### 3.3 测试驱动开发

| 步骤 | 动作 |
|------|------|
| 3.1 | 调用 `tdd-guide` agent：先读项目 `rules/<lang>/testing.md`，再动手 |
| 3.2 | RED → GREEN → IMPROVE：Java→JUnit5+Mockito+Testcontainers / Node→Vitest+supertest / 前端→Vitest+Testing Library；Bug 修复时关键代码处加注释说明根因 |
| 3.3 | 展示覆盖率报告 |

**门禁**：覆盖率 ≥ 80% 且所有测试通过。不达标不进入阶段 4。

### 3.4 审查

| 步骤 | 动作 |
|------|------|
| 4.1 | 按技术栈并行启动：Java→`java-reviewer`，Node/前端→`typescript-reviewer` + `security-reviewer` |
| 4.2 | CRITICAL/HIGH → 必须修复（两种模式都拦截），修复前先写复现测试 |
| 4.3 | 修复后重审，至少 3 轮、最多 5 轮 |
| 4.4 | 基础设施配置审查（硬编码密钥、配置文件一致性等） |

**门禁**：CRITICAL=0 且 HIGH=0。

### 3.5 提交

| 步骤 | 动作 |
|------|------|
| 5.1 | 启动验证：Java→`mvn spring-boot:run` / NestJS→`npm start`，确认无启动错误后停进程 |
| 5.2 | 环境检查：非 git 仓库警告，`git diff --stat` |
| 5.3 | 格式检查：Node/前端→prettier+eslint+ts-prune / Java→p3c(pmd) |
| 5.4 | 构建验证（Node/前端）：`<pkg> build` |
| 5.5 | 完成前验证：测试通过 + 无 CRITICAL/HIGH + 格式已执行 + 构建通过 + 无调试残留 + 接口含 requestId/metadata + DDL 变更含迁移文件 |
| 5.6 | 文档更新：全量梳理 CLAUDE.md（架构/模块/端口/命令）+ README.md |
| 5.7 | 生成 commit message（Conventional Commits） |
| 5.8 | 展示确认（两种模式都必确认） |
| 5.9 | `git add <具体文件>` + `git commit` |
| 5.10 | 创建 SemVer tag（标签不可变） |
| 5.11 | 询问是否 push（含 `--tags`） |

## 4. 支持的技术栈

| 技术栈 | 测试框架 | 格式检查 |
|--------|---------|---------|
| Java / Spring Boot | JUnit5 + Mockito + Testcontainers | p3c (阿里巴巴) |
| Node.js / NestJS | Vitest + supertest + Playwright | Prettier + ESLint |
| Vue / React | Vitest + Testing Library + Playwright | Prettier + ESLint |

覆盖 HTTP/BFF 和 gRPC 微服务两种架构模式。

## 5. 规范规则

安装后按文件 `paths:` 匹配语言自动加载。

### 5.1 Common（通用，所有语言）

| 文件 | 覆盖内容 |
|------|---------|
| `patterns.md` | 统一返回结构、API 版本控制、RESTful API 设计、HTTP/gRPC 分层、定时任务 |
| `table-structure.md` | MySQL 表结构：命名、字段类型（p3c）、审计字段矩阵、自增 ID 随机起始、3 种 DDL 模板、10 项审查清单 |
| `database-migration.md` | 数据库迁移 6 步流程、幂等、回滚、大表变更策略、反模式 |
| `security.md` | OWASP Top 10：访问控制、注入防护（SQL/NoSQL/XSS/XXE/SSRF）、反序列化、密码存储、安全头、依赖安全、令牌失效 |
| `concurrency.md` | 线程池规范、CompletableFuture 超时、ThreadLocal 清理、锁使用、并发集合、Virtual Threads |
| `elasticsearch.md` | 索引命名 `{dataset}-{namespace}`、读写别名、index template、ILM 策略 |
| `mongodb.md` | 集合命名 `snake_case` 复数、字段 `camelCase`、混合文档设计、删前归档、索引策略 |
| `testing.md` | 覆盖率≥80%、TDD: RED→GREEN→IMPROVE、AAA 模式、Mock 策略 |
| `development-workflow.md` | 研究复用→规划→TDD→审查→提交 全流程 |
| `git-workflow.md` | 分支命名 `feat/YYMMDD_desc`、Conventional Commits、SemVer Tag、敏感文件检查 |
| `coding-style.md` | 不可变性、命名规范、**注释规范**（何时加/禁止项/TODO-FIXME）、文件组织、错误处理 |
| `code-review.md` | 审查清单、严重级别（CRITICAL/HIGH/MEDIUM/LOW）、Agent 选择、安全审查触发条件 |
| `agents.md` | 7 个 Agent 的职责定义和调用时机 |
| `performance.md` | 模型选择策略、Context Window 管理 |

### 5.2 Java（Spring Boot 4.0+ / Java 21）

| 文件 | 覆盖内容 |
|------|---------|
| `patterns.md` | Repository/Service/Controller 分层、构造器注入、DTO 映射、API 返回结构、时间格式、数据库索引规范（p3c）、定时任务、gRPC 分层 |
| `security.md` | Spring Security 配置、AES-256 PII 加密、JWT HS256 签名、Redis Token 黑名单、数据权限 DataScopeHelper、BCrypt cost=12 |
| `testing.md` | JUnit5+AssertJ+Mockito、Testcontainers（禁止 H2）、JaCoCo、AIR 原则、测试命名 |
| `coding-style.md` | POJO 规范、equals/hashCode、集合处理、控制语句、Virtual Threads、**Javadoc 强制范围**、@Transactional/@Async 注释要求 |
| `logging.md` | SLF4J+Logback、AsyncAppender、traceId(MDC)、JSON 格式(prod)、敏感数据脱敏 |

### 5.3 TypeScript（NestJS 11+ / Node 24 LTS）

| 文件 | 覆盖内容 |
|------|---------|
| `patterns.md` | Controller→Service→Repository 分层、DTO/Guard/Interceptor/ExceptionFilter、API 返回结构、定时任务+BullMQ、gRPC 分层 |
| `security.md` | Helmet/CORS/CSRF(禁止 csurf)、速率限制(@nestjs/throttler)、NoSQL 注入、JWT、bcrypt cost=12 |
| `testing.md` | Vitest+supertest+Playwright、Mock 策略、异步状态覆盖（loading/skeleton/empty/error） |
| `coding-style.md` | `satisfies`、泛型约束、Branded Types、**JSDoc 强制范围**、类型注释边界、NestJS 注释、**依赖管理**（禁止手动编辑 package.json） |
| `logging.md` | pino、traceId(AsyncLocalStorage)、结构化日志、时间格式 `yyyy-MM-dd HH:mm:ss.SSS` |

### 5.4 Web（Vue / React）

| 文件 | 覆盖内容 |
|------|---------|
| `patterns.md` | 组件模式、Custom Hooks、状态管理（Pinia/Zustand） |
| `testing.md` | Vitest+Testing Library、Playwright E2E |
| `coding-style.md` | 组件命名、文件组织、CSS 方案 |
| `static-website-checklist.md` | CDN 国内替换、ICP/公安备案、SEO(hreflang/OG/Sitemap)、域名品牌检查、模板残留清理 |

## 6. 任务适配

| 任务类型 | 行为 |
|---------|------|
| 新功能 | 完整 6 阶段 |
| 重构 | 阶段 0→范围确认，阶段 2→影响分析，阶段 3→回归测试 |
| Bug 修复 | 跳过 0-2，阶段 3(TDD)→4(审查)→5(提交) |
| 依赖升级 | 跳过 0-1，阶段 2→兼容分析，阶段 3→全量回归，阶段 4→breaking change 审查 |
| 数据库迁移 | 阶段 0→确认迁移范围+大表风险评估，阶段 5→迁移文件不可变检查 |
| 单文件小改 | 不建议用一把梭，直接手改 + code-reviewer |
| 注释 | 扫描缺少注释的 public 方法/复杂逻辑，按规范补充 Javadoc/JSDoc，不修改业务逻辑 |
| 纯研究/调研 | 不适用，用 planner agent 出调研报告 |

## 7. Token 消耗

| 场景 | 直接对话 | 一把梭 | 倍数 |
|------|---------|--------|:--:|
| 新功能（中等复杂度） | ~25K | ~90K | 3.5x |
| Bug 修复 | ~12K | ~40K | 3x |
| 简单改动 | ~5K | ~8K | 1.5x |

> 多出的成本换取 4 道质检（架构评审 + 强制 TDD + 代码审查 + 安全审查）+ 确定性流程。改一行文字不建议使用。

## 8. 更新

```bash
cd /tmp/yibasuo-skill && git pull && bash install.sh --force
cat ~/.claude/skills/yibasuo/.installed-version  # 查看版本
```

## 9. 生态

- [yibasuo-infra](https://github.com/occultskyrong/yibasuo-infra) — 项目骨架初始化（Spring Boot / NestJS / gRPC）
- [yibasuo-skill](https://github.com/occultskyrong/yibasuo-skill) — 全流程开发管线

## 协议

[MIT License](LICENSE) — 允许任何人随意使用、复制、修改、分发、出售。
