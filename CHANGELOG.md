# Changelog

## [2.28.1] - 2026-06-25

### Fixed

- typescript/testing.md 代码块结束栅栏被误改为 ` ```typescript `（v2.28.0 markdownlint 整理回归），导致代码块未闭合、后续内容渲染异常
- @Cron 生产可用性矛盾：typescript/patterns.md 明确 `@Cron`/`@Interval`/`@Timeout` 仅限本地开发，生产必须用 BullMQ；typescript-reviewer 审查清单新增 CRITICAL 级「生产环境使用 @Cron 裸跑 → 阻断」
- agents.md/code-review.md/performance.md/typescript-testing.md 引用不存在的 agent（build-error-resolver/e2e-runner/refactor-cleaner/doc-updater/python-reviewer/go-reviewer/rust-reviewer），对齐实际 7 个 agent 并补全 java-reviewer

## [2.28.0] - 2026-06-25

### Changed

- rules 全量 markdownlint 格式整理（41 文件）：表格分隔行统一 compact 风格、代码块补语言标识（text/typescript）、表格/代码块周围空行规范化
- 新增 `.markdownlint.json` 配置（禁 MD013 行长度、MD024 siblings_only、MD060=compact）

### Fixed

- logging.md 修正 typescript 实现引用 `pino`→`winston`（与实际 winston 实现一致）
- logging.md prod JSON 示例时间戳从 ISO 8601 改为 `yyyy-MM-dd HH:mm:ss.SSS`（与 time-format.md 统一）
- typescript/coding-style.md 目录树示例缺少代码块开启栅栏，导致后续表格分隔行解析错乱

## [2.27.0] - 2026-06-24

### Added

- 发布流程新增步骤 9：同步本地安装目录（install.sh 增量安装有遗漏风险，提交后手动补齐）

## [2.26.0] - 2026-06-17

### Fixed

- naming-convention.md 未注册到 SKILL.md 阶段 2/4 审查清单 + java/ts patterns.md 路由表，导致技能运行时不读取
- MongoDB 集合命名与 mongodb.md 冲突（naming-convention.md 写 camelCase，mongodb.md 写 snake_case）
- common/coding-style.md Boolean is 前缀建议与 java/coding-style.md POJO 约束冲突（加 Java 例外标注）

## [2.25.0] - 2026-06-17

### Changed

- java/coding-style.md POJO 布尔变量 is 前缀规则：明确只禁 boolean/Boolean，Integer/Long/String 不受约束，补充根因解释和正反例

## [2.24.0] - 2026-06-17

### Added

- naming-convention.md: 统一 HTTP/JSON(camelCase) 与 DB(snake_case) 分层命名规范，含 Request/Response/DTO/Query 命名约定

### Fixed

- SKILL.md 红线 7 page_size → pageSize（与 restful-api.md 统一为 camelCase）

## [2.23.0] - 2026-06-17

### Fixed

- install.sh install_rules/install_skill 只检查目录存在导致新增子规范文件永不安装（如 table-structure.md 等 12 个文件）
- --force 被同版本检查拦截，永远无法触发强制覆盖

## [2.22.0] - 2026-06-17

### Added

- 4 张流程机制图（3x retina）：管道全景、TDD 循环、审查循环、Agent 矩阵
- README ASCII 图全部替换为 PNG 图片

## [2.21.0] - 2026-06-17

### Changed

- ESLint Error 规则从阶段 5 提前到阶段 4：每轮审查先跑 `eslint --max-warnings 0`，Error = CRITICAL，修复后重跑验证，避免审查通过后格式检查又改代码
- 阶段 5 ESLint 降级为复核（不该有新错误）

## [2.20.0] - 2026-06-17

### Added

- TS coding-style 新增 `Async/Await vs .then()` (CRITICAL)：禁止 `.then()` 链式调用，统一 `async/await` + `try/catch`
- ESLint 清单新增 `max-nested-callbacks` Error 规则（>1 层阻断 CI），配合编码规范双重拦截

## [2.19.0] - 2026-06-15

### Added

- ESLint 检查清单（`rules/web/eslint-checklist.md`）：17 条 Error + 3 条 Warn + Flat Config 模板，覆盖闭包/then/匿名函数

## [2.18.1] - 2026-06-15

### Changed

- README 重构：触发词速查+各阶段详情合并+规范表简化
- VERSION 修正 2.12.1→2.18.0

## [2.18.0] - 2026-06-13

### Added

- CodeGraph 强制规则：内部代码查询禁止 grep/glob，必须使用 codegraph 命令
- Java 禁止代码中声明索引：所有索引必须在 migration SQL 创建

## [2.17.2] - 2026-06-12

### Changed

- SKILL.md 各阶段集成规范路由：规划加载+架构对照+审查全量
- README Token 消耗表更新（CodeGraph+规范路由后倍数降低）
- 语言适配 winston 替换 pino（对齐 ai-foundation 实现）
- CLAUDE.md 产物结构同步 + 渐进式暴露说明
- skill-review 评分 73→76/80 (PASS)

## [2.17.1] - 2026-06-12

### Changed

- patterns.md 拆分为渐进式路由：API响应/gRPC/版本控制/RESTful/迁移/定时任务 各独立文件
- patterns.md 新增适配场景+审查触发条件+关键检查点三列，方便阶段4审查逐项核对

## [2.17.0] - 2026-06-08

### Added

- NestJS 禁止 Entity 索引+synchronize：索引必须走 migration，`synchronize: false` 强制

## [2.16.0] - 2026-06-08

### Added

- RESTful API 设计规范（`rules/common/patterns.md`）：URL 命名+HTTP 方法+查询参数+状态码+反模式

## [2.15.0] - 2026-06-08

### Added

- MySQL 自增 ID 从 1000-3000 随机数开始（防止按 ID 遍历 + 泄露数据量 + 合并冲突）
- DDL 模板全部添加 `AUTO_INCREMENT={1000-3000随机值}`
- infra java/nestjs 模板同步更新 AUTO_INCREMENT 起始值

## [2.14.0] - 2026-06-08

### Added

- MongoDB 规范（`rules/common/mongodb.md`）：camelCase 字段+混合文档设计+删前归档+索引策略+8项反模式+10项审查清单
- ES 和 MongoDB 规范同步到 README 规则表

## [2.13.0] - 2026-06-08

### Added

- Elasticsearch 索引命名规范（`rules/common/elasticsearch.md`）：ECS 对齐 `{dataset}-{namespace}` 格式 + 别名 + index template + ILM

## [2.12.2] - 2026-06-07

### Changed

- 阶段 4 审查改为逐轮循环模式：审查→输出清单→用户确认→自动修复→输出修复清单→下一轮（3-5 轮）

## [2.12.1] - 2026-06-06

### Added

- 阶段 0 新增头脑风暴步骤：发散思考 → 收敛为方案

## [2.12.0] - 2026-06-06

### Added

- 前端开发规范 v2：场景路由（3 种项目类型）→ 6 步迭代内环（方向确认→编码→审查→回退→浏览器验证）→ 8 条铁律（T1/T2/T3 分级门禁）→ 10 个技能清单
- MIT License

## [2.11.3] - 2026-06-06

### Added

- 阶段 5 新增 Migration 确认步骤：列出迁移文件内容 → 告知 Flyway 自动执行 → 用户确认（必确认）
- infra Flyway 规范升级：明确依赖(flyway-mysql)+配置(flyway.table)+命名两种格式+启动顺序(ApplicationRunner 后于 Flyway)

## [2.11.2] - 2026-06-06

### Changed

- 目录嵌套规则从一刀切"禁止嵌套"改为"同领域判定"：子模块仅父模块内部使用时允许嵌套，外部引用时违规

## [2.11.1] - 2026-06-06

### Changed

- TS 目录结构规范提升为 CRITICAL 级：`##` 独立章节 + typescript-reviewer HIGH 检查 + SKILL.md 阶段 4 必检
- 目录规范从 `### Module Organization` 提升为 `## 目录结构 (CRITICAL)`

## [2.11.0] - 2026-06-05

### Added

- 注释规范体系：common/java/typescript 三级 + git-workflow commit body + PR 模板
- 新增「注释」任务类型：触发后按规范补充 Javadoc/JSDoc，不修改业务逻辑
- 阶段 1 规划新增 CodeGraph 检查 CLAUDE.md + init 前置检查
- TS coding-style 新增依赖管理规范（禁止手动编辑 package.json）
- SKILL.md 阶段 2/5 新增 DDL 迁移文件检查
- NestJS Module 设计原则：单一权责 + 跨 Module 通过 imports 关联
- TS 模块组织：src/ 下只允许 1 层，module 直接铺开
- 定时任务框架选型：Java→XXL-Job 生产唯一方案，@Scheduled 仅限开发调试
- Codex 兼容性：install.sh SKILL_DEST 修复 + Codex 版同步至 2.11.0 + plugin.json 占位符修复
- infra 新增 --codex 安装支持 + NestJS 模板移除 modules/ 中间层

### Fixed

- ApiResponse code 改回 number|string 并标注实际项目用法
- typescript/logging.md 重复 import 修复
- typescript/security.md csurf 废弃替换
- 注释规范：禁止单行 /**/ 块注释

## [2.10.1] - 2026-05-28

### Added

- SKILL.md 阶段2架构+阶段5验证 新增 DDL 迁移文件检查
- TS coding-style 新增依赖管理规范（禁止手动编辑 package.json）

### Changed

- CLAUDE.md 发布流程：`git add -A` 改为精确添加
- CLAUDE.md 脱敏清单：移除 GitLab 相关项，简化为 GitHub only

## [2.10.0] - 2026-05-28

### Added

- gRPC 微服务分层规范：common/java/typescript 三级定义
- common/patterns.md 新增 gRPC 分层定义（无 ApiResponse、不鉴权、BFF Status 映射）
- java/patterns.md 新增 gRPC 分层（@GrpcService、ServerInterceptor、Status→HTTP 映射表）
- typescript/patterns.md 新增 gRPC 分层（@GrpcMethod、RpcException、Transport.GRPC）
- yibasuo-infra 新增 NestJS gRPC 微服务模板（目录结构/proto/通信约定/main.ts）

### Changed

- SKILL.md 精简 236→195 行（前端差异提取+红线压缩+跳过约束合并）

### Fixed

- ApiResponse code 改为 `number|string` 并标注实际项目用法，防止反复修改

## [2.9.7] - 2026-05-28

### Fixed

- typescript/security.md ExceptionFilter 统一使用 `code` 字段（修复 `status`→`code`），补全 `data`/`requestId`/`metadata` 字段
- common/testing.md TDD 强制等级与 development-workflow.md 对齐（补例外：config/docs/README 可跳过）
- common/security.md 新增令牌失效规范（密码修改/用户禁用/密钥轮换时必须使 JWT 失效）

## [2.9.6] - 2026-05-26

### Added

- SKILL.md 跨会话恢复新增 `.yibasuo-state.json` schema 定义
- common/security.md 新增安全日志结构化规范（登录失败/权限拒绝/密码修改/角色变更/敏感操作）
- java/security.md 新增 JWT Algorithm Confusion 防护
- web/static-website-checklist.md 新增 SRI + CSP 检查项

### Fixed

- common/security.md CSRF 表述精确化（cookie 中存 token 才需要）
- typescript/security.md 进程退出策略区分 uncaughtException vs unhandledRejection
- java/patterns.md 分布式锁看门狗续期补充具体策略（TTL/3 间隔）
- common/git-workflow.md commit 类型表增加 `style:`
- CLAUDE.md 产物结构更新（rules 文件数 + references 清单）
- README.md 任务适配表与 SKILL.md 对齐（8 种场景）

## [2.9.5] - 2026-05-26

### Fixed

- ApiResponse `code` 类型统一为 `number`（common/java/ts 三处一致）
- ApiResponse `data` 类型澄清：空列表 `[]`，单条无结果可 `null`，错误响应 `null`
- ApiResponse `metadata` 必填/可选字段明确
- TS Interceptor/Filter 示例与 ApiResponse 接口对齐（`status`→`code`，补全字段）
- JWT 过期时间 24h→15-60min（java/security.md）
- bcrypt cost 统一为 12（ts/security.md 10→12）
- SSRF 增加 IPv6/DNS Rebinding 防护
- 反序列化增加 SnakeYAML SafeConstructor 提醒
- SemVer 规则三处统一（CLAUDE.md/commit-conventions.md：非功能变更=PATCH）
- Commit 类型表增加 `style:`
- Bug 修复行表述明确：跳过 0-2，阶段 3→4→5
- 阶段 3/4 新增显式门禁条件
- `git add` 精确添加约束
- `as any` 泛型示例改为 `as FindOptionsWhere<T>`
- SimpleDateFormat→DateTimeFormatter（Java 21 推荐）
- hostname() 锁持有者标识改为 hostname:PID
- 控制语句规则补充 `try` 块
- NoSQL 注入示例改为类型检查（替代 String 转换）
- testing.md "ALL required" 补充项目类型限定
- 测试命名格式统一为英文
- concurrency.md 标注 Java 为主，TS 见 patterns.md
- 移除 logging.md 未使用的 Logger import
- supertest import 改为默认导入
- 安全头增加 Permissions-Policy

## [2.9.4] - 2026-05-26

### Added

- common/patterns.md 新增 API 版本控制规范（从 java/patterns.md 提升到 common 层）
- java/coding-style.md 新增 equals/hashCode 规范、集合处理规范、控制语句规范、Virtual Threads 规范
- typescript/coding-style.md 新增 `satisfies` 操作符、泛型约束、Branded Types 规范
- typescript/patterns.md 新增 Fastify 驱动差异对照表

## [2.9.3] - 2026-05-26

### Added

- SKILL.md 阶段 0 新增研究复用前置步骤
- SKILL.md 阶段 0/1 新增门禁条件（需求卡片完整性、计划完整性）
- SKILL.md 中断与恢复增强：TDD 循环恢复机制、跨会话状态持久化（.yibasuo-state.json）、模式切换语义
- SKILL.md 跳过阶段约束：阶段 3/4 不可跳过，需显式声明风险
- SKILL.md 任务适配扩展：重构差异化、依赖升级、数据库迁移场景，单文件/纯研究给出替代方案

## [2.9.2] - 2026-05-26

### Fixed

- typescript/logging.md 修复重复 import 语句
- typescript/security.md 移除已废弃 `csurf` 推荐，改为 `csrf-csrf`
- typescript/coding-style.md 移除与 patterns.md 冲突的 ApiResponse 定义，改为引用 common 层

### Added

- common/security.md 大幅扩充：OWASP A01 访问控制、A08 反序列化、A10 SSRF、XXE、密码存储、安全头、依赖安全、敏感数据保护
- common/patterns.md ApiResponse 格式从四原则升级为完整定义（含字段/类型/requestId=traceId/metadata）
- common/concurrency.md 新建：p3c 并发编程规范（线程池、CompletableFuture、ThreadLocal、锁、并发集合、volatile）
- common/development-workflow.md TDD 步骤标注 MANDATORY 等级，明确可跳过场景

## [2.9.1] - 2026-05-26

### Changed

- 工作流新增文档同步规则：每阶段增量更新 CLAUDE.md，提交前全量梳理 CLAUDE.md + README.md
- 阶段 5 提交流程新增「文档更新」步骤（步骤 6）
- 阶段 5 tag 规则对齐 commit-conventions.md：所有类型均创建 tag
- README 阶段 5 流程描述补充「文档更新」

## [2.9.0] - 2026-05-26

### Added

- 定时任务规范：6步生命周期 + 幂等性 + 错误处理 + 分布式协调 + 日志可观测性（`rules/common/patterns.md`）
- 定时任务规范（Java）：@Scheduled 约束、自定义线程池、Redis 分布式锁、Quartz/XXL-Job 集成（`rules/java/patterns.md`）
- 定时任务规范（TypeScript）：@nestjs/schedule、BullMQ、Redis 分布式锁（`rules/typescript/patterns.md`）
- 定时任务审查项：Java reviewer (+8) + TypeScript reviewer (+10)
- MySQL 索引规范：基于 p3c §3-4，命名、10条设计规则、EXPLAIN 验证、反模式、审查清单（`rules/java/patterns.md`）
- 索引审查项：Java reviewer (+9)

### Changed

- Commit type 规范：非功能变更（docs/chore/refactor）改为 PATCH 创建 tag，不再跳过（`references/commit-conventions.md`）

## [2.8.6] - 2026-05-23

### Changed

- 需求澄清从"一次一个问题"改为"一次一个主题"，跨模块复杂需求允许多问
- 前端项目差异从语言适配中独立为 `##` 节

### Refactored

- 基础设施配置审查详情移至 `references/infrastructure-review.md`

## [2.8.5] - 2026-05-23

### Refactored

- 迁移规范从 Java 专属移至 `rules/common/patterns.md`，Java/TypeScript 各留引用

## [2.8.4] - 2026-05-22

### Added

- 数据库迁移规范：6步流程（编写→验证→提交→CI幂等→部署→记录）+ 幂等 + 回滚 + 大表策略 + 反模式

### Fixed

- 删除复活的 `trace-id.md` 僵尸文件

## [2.8.3] - 2026-05-22

### Refactored

- CodeGraph 集成详情抽出到 `references/codegraph.md`
- 示例恢复为表格格式

### Removed

- 清理僵尸文件（trace-id.md, meta.md）

## [2.8.2] - 2026-05-24

### Added

- `docs/index.html` — UI/UX Pro Max 生成的产品说明页

### Changed

- README 增加 Token 消耗警告（新功能 3.5x / Bug 修复 3x）
- README 移除"Claude 帮你装"链接行

## [2.8.1] - 2026-05-24

### Changed

- 生成说明文档改用 `ui-ux-pro-max` skill（替代 frontend-design）

## [2.8.0] - 2026-05-24

### Changed

- README 101→67 行重构：面向用户
- CLAUDE 150→90 行重构：面向开发者+AI
- 消除两文档重复：运行模式/方法论栈/6阶段详细表/提交前验证清单

## [2.7.7] - 2026-05-24

### Added

- 行为红线第5条：破坏性变更需确认+日志(.yibasuo-deletions.log)
- 行为红线第6条：前端校验不替代后端
- 前端项目差异：静态网站/管理后台分流
- git-workflow 独立技能

### Changed

- feat!: ApiResponse 合并 traceId+requestId
- SKILL.md 222→131 行重构
- 统一时间传输格式：yyyy-MM-dd HH:mm:ss.SSS
- 命名规范嵌入 rules

### Fixed

- 前端审查补全
- 全仓库脱敏

## [1.3.0] - 2026-05-12

### Changed

- 大幅精简 SKILL.md (193→50行)，遵循渐进式披露

## [1.2.0] - 2026-05-12

### Added

- 自动模式：触发词 `自动梭`、`全自动`、`一路梭到底`

## [1.1.0] - 2026-05-12

### Added

- `rules/web/static-website-checklist.md` 前端静态网站检查清单

## [1.0.1] - 2026-05-11

### Changed

- README 增加"一句话让 Claude 装"安装方式

## [1.0.0] - 2026-05-11

### Added

- 初始版本：一把梭 (yibasuo) 全流程开发技能
