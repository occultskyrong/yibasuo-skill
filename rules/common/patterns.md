# Common Patterns

> 通用规范路由入口。每个规范标注适配场景和审查触发条件，确保阶段 4 审查可逐项核对。

## Skeleton Projects

When implementing new functionality:

1. Search for battle-tested skeleton projects
2. Use parallel agents to evaluate options (security, extensibility, relevance, implementation)
3. Clone best match as foundation
4. Iterate within proven structure

## Design Patterns

### Repository Pattern

Encapsulate data access behind a consistent interface (findAll, findById, create, update, delete). Business logic depends on the abstract interface, not the storage mechanism.

## 规范路由

### 接口与协议

| 规范 | 文件 | 适配场景 | 审查触发条件 | 关键检查点 | 触发判定问句 | 产出物 |
| ------ | ------ | --------- | ------------ | ----------- | ------------ | ------ |
| API 响应格式 | `api-response.md` | 所有 HTTP 项目 | 新增/修改接口时 | `code` 类型、`requestId`=traceId、`metadata` 必填字段 | 本次是否新增/修改 HTTP 接口响应？ | 响应结构定义 |
| RESTful API | `restful-api.md` | 所有 HTTP 项目 | 新增路由/Controller 时 | 名词复数、无动词、≤2 层嵌套、标准查询参数 | 本次是否新增/修改 HTTP 路由或 DTO？ | URL/方法/DTO |
| API 版本控制 | `api-versioning.md` | 所有 HTTP 项目 | 不兼容接口变更时 | `/v2/xxx` 新旧并存、旧版 `@Deprecated` | 本次是否有不兼容接口变更？ | 版本方案 / `@Deprecated` 标注 |
| gRPC 分层 | `grpc-layering.md` | gRPC 微服务 | 新增 proto/Service 时 | 无 ApiResponse、无端侧 JWT/RBAC、服务身份默认拒绝、StatusRuntimeException | 本次是否新增/修改 proto/service？ | proto + service + 调用方授权设计 |

### 数据存储

| 规范 | 文件 | 适配场景 | 审查触发条件 | 关键检查点 | 触发判定问句 | 产出物 |
| ------ | ------ | --------- | ------------ | ----------- | ------------ | ------ |
| 表结构 | `table-structure.md` | MySQL 项目 | 建表/改表时 | 命名小写+下划线、INT 主键、DECIMAL 金额、`COMMENT` 必写、审计字段 | 本次是否新建表或改字段？ | 字段映射/建表语句 |
| 数据库迁移 | `database-migration.md` | MySQL 项目 | DDL 变更时 | `V{YYYYMMDD}__{描述}.sql`、一文件一事、已部署禁改、回滚脚本 | 本次是否有 DDL 变更（建表/加列/改类型/加索引）？ | `V{YYYYMMDD}__{描述}.sql` |
| MongoDB | `mongodb.md` | MongoDB 项目 | 新增集合/字段时 | camelCase 字段、ObjectId、混合文档设计、删前归档 | 本次是否新增/修改 MongoDB 集合或字段？ | 集合/字段设计 |
| ES 索引 | `elasticsearch.md` | ES 项目 | 新建索引时 | `{dataset}-{namespace}` 格式、读写别名、template | 本次是否新建/修改 ES 索引？ | 索引设计 / template |

### 通用机制

| 规范 | 文件 | 适配场景 | 审查触发条件 | 关键检查点 | 触发判定问句 | 产出物 |
| ------ | ------ | --------- | ------------ | ----------- | ------------ | ------ |
| 定时任务 | `scheduled-tasks.md` | 所有后端项目 | 新增定时任务时 | 任务名 `{领域}:{动作}:{对象}`、cron 外置、分布式锁、幂等 | 本次是否新增/修改定时任务？ | 任务定义 / cron 配置 |
| 安全 | `security.md` | 所有项目 | 每次提交 | 硬编码密钥、输入校验、注入防护、HTTPS | 本次是否涉及认证/授权/输入/文件/API 调用？ | 安全检查清单 |
| 并发 | `concurrency.md` | Java 项目 | 涉及线程/锁/异步时 | 语言无关原则（线程安全、锁粒度、超时、原子操作）；Java 细节见 `java/concurrency.md` | 本次是否涉及线程/锁/异步？ | 并发检查清单 |
| 时间格式 | `time-format.md` | 所有后端项目 | 新增/修改代码时 | `yyyy-MM-dd HH:mm:ss.SSS`、Asia/Shanghai、禁止 ISO | 本次是否新增/修改时间字段？ | 时间格式约定 |
| 日志 | `logging.md` | 所有后端项目 | 每次审查 | TraceId 注入、敏感数据脱敏、占位符非拼接、生产 JSON | 本次是否新增/修改日志？ | 日志规范检查 |
| 命名规范 | `naming-convention.md` | 所有项目 | 新增接口/参数/DTO 时 | JSON camelCase、Query camelCase、URL kebab-case、DTO 后缀、DB snake_case | 本次是否新增接口/参数/DTO/DB 字段？ | 命名检查清单 |
| 编码规范 | `coding-style.md` | 所有项目 | 每次审查 | 不可变性、注释规范、命名、函数 <50 行 | 本次是否新增/修改业务代码？ | 编码规范检查 |
| 测试 | `testing.md` | 所有后端项目 | 新增功能时 | 覆盖率 ≥80%、RED→GREEN→IMPROVE、AAA 模式 | 本次是否新增功能或修复 bug？ | 测试计划 |
| 开发流程 | `development-workflow.md` | 所有项目 | 新功能开发时 | 研究复用、TDD 强制、code-reviewer、CI 通过 | 本次是否新功能开发？ | 流程检查清单 |
| ESLint | `web/eslint-checklist.md` | 前端项目 | 阶段 4 审查每轮 → 阶段 5 复核 | Error 规则 = CRITICAL（代码缺陷，非格式）、`--max-warnings 0` | 本次是否前端代码变更？ | ESLint 检查 |
| 前端安全 | `web/security.md` | 前端项目 | 前端新增功能/依赖时 | XSS 防护、Token 存储权衡、CSP、依赖安全 | 本次是否前端新增功能/依赖？ | 前端安全检查 |
| Git 工作流 | `git-workflow.md` | 所有项目 | 提交/push 时 | 分支命名 `feat/YYMMDD_desc`、commit message、PR 模板 | 本次是否提交代码？ | Git 检查清单 |
