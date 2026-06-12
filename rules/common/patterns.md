# Common Patterns

> 通用规范的路由入口。详细内容拆分到独立文件，按需查阅。

## Skeleton Projects

When implementing new functionality:
1. Search for battle-tested skeleton projects
2. Use parallel agents to evaluate options:
   - Security assessment
   - Extensibility analysis
   - Relevance scoring
   - Implementation planning
3. Clone best match as foundation
4. Iterate within proven structure

## Design Patterns

### Repository Pattern

Encapsulate data access behind a consistent interface:
- Define standard operations: findAll, findById, create, update, delete
- Concrete implementations handle storage details (database, API, file, etc.)
- Business logic depends on the abstract interface, not the storage mechanism
- Enables easy swapping of data sources and simplifies testing with mocks

### API Response Format

遵循《阿里巴巴 Java 开发手册》前后端规约。所有 API 响应使用统一信封：

```json
{
  "code": 0,
  "message": "操作成功",
  "data": {...},
  "requestId": "a1b2c3d4e5f6",
  "metadata": {
    "timestamp": "2026-05-26 10:00:00.000",
    "method": "POST",
    "endpoint": "/api/users",
    "count": 100,
    "totalPages": 10,
    "currentPage": 1,
    "pageSize": 10
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | `number \| string` | 成功=0（number），失败=业务错误码（string）。Java `BusinessCode` 枚举为 String，NestJS 用数字 status |
| `message` | `string` | 用户提示信息 |
| `data` | `T` | 业务数据。空列表返回 `[]`，单条查询无结果可返回 `null`，错误响应 `data` 为 `null` |
| `requestId` | `string` | **= traceId**，Gateway 生成，全链路透传 |
| `metadata` | `object` | 请求上下文 + 分页。必填：timestamp/method/endpoint。分页专属：count/totalPages/currentPage/pageSize |

- JSON key 使用 lowerCamelCase
- 语言特定实现见 `rules/java/patterns.md` 和 `rules/typescript/patterns.md`

### gRPC 微服务分层

与 HTTP/BFF 分层不同，gRPC 微服务不需要 Controller、ApiResponse、鉴权层：

| 层 | 职责 | HTTP/BFF 对应 |
|----|------|--------------|
| Service Impl | gRPC 入口，替代 Controller | Controller |
| Service（业务） | 纯业务逻辑，无鉴权 | Service |
| Provider / Mapper | 数据访问（轻量微服务可省略） | Repository |
| Interceptor（gRPC） | traceId 透传、日志、异常转换 | HTTP Filter / Middleware |

核心差异：无 ApiResponse（gRPC 有原生错误通道）、不鉴权（信任 BFF）、`StatusRuntimeException` / `RpcException` 报告错误。
语言特定实现见 `rules/java/patterns.md` 和 `rules/typescript/patterns.md`。

### API 版本控制

不兼容的接口变更使用 URL 版本号，新旧并存：

| 变更类型 | 处理 |
|---------|------|
| 加字段 | 直接加，消费者忽略未知字段 |
| 改字段名/类型/含义 | 新建 `/v2/xxx`，新旧并存 |
| 删字段 | 同上 |
| 消费者未对接 | 不兼容变更可直接改 |

## 独立规范（按需查阅）

| 规范 | 文件 | 覆盖 |
|------|------|------|
| 表结构 | `table-structure.md` | 命名、字段类型（p3c）、审计字段、DDL 模板 |
| RESTful API | `restful-api.md` | URL 设计、HTTP 方法、查询参数、状态码 |
| 数据库迁移 | `database-migration.md` | 6 步流程、Flyway 命名、幂等、大表变更 |
| 定时任务 | `scheduled-tasks.md` | 生命周期、幂等、分布式协调、反模式 |
| ES 索引 | `elasticsearch.md` | 命名、别名、template、ILM |
| MongoDB | `mongodb.md` | 集合命名、文档设计、字段 camelCase、归档 |
