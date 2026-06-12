# Common Patterns

> 通用规范路由入口。详细内容拆分到独立文件，按需查阅。

## Skeleton Projects

When implementing new functionality:
1. Search for battle-tested skeleton projects
2. Use parallel agents to evaluate options (security, extensibility, relevance, implementation)
3. Clone best match as foundation
4. Iterate within proven structure

## Design Patterns

### Repository Pattern

Encapsulate data access behind a consistent interface (findAll, findById, create, update, delete). Business logic depends on the abstract interface, not the storage mechanism.

## 独立规范

| 规范 | 文件 | 覆盖 |
|------|------|------|
| API 响应格式 | `api-response.md` | `{code,message,data,requestId,metadata}` 信封 + traceId |
| RESTful API | `restful-api.md` | URL 设计、HTTP 方法、查询参数、状态码 |
| API 版本控制 | `api-versioning.md` | `/v2/xxx` 新旧并存、弃用策略 |
| gRPC 分层 | `grpc-layering.md` | Service Impl→Service→Mapper 分层、Status→HTTP 映射 |
| 表结构 | `table-structure.md` | 命名、字段类型（p3c）、审计字段、DDL 模板 |
| 数据库迁移 | `database-migration.md` | 6 步流程、Flyway 命名、幂等、大表变更 |
| 定时任务 | `scheduled-tasks.md` | 生命周期、幂等、分布式协调、反模式 |
| ES 索引 | `elasticsearch.md` | 命名 `{dataset}-{namespace}`、别名、template、ILM |
| MongoDB | `mongodb.md` | 集合命名、camelCase 字段、混合文档设计、归档 |
