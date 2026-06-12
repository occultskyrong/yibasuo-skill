---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript Patterns

> TypeScript/NestJS 特定规范路由。通用规范见 `rules/common/patterns.md`。

## 架构

| 规范 | 文件 | 覆盖 |
|------|------|------|
| API 响应格式 | `rules/common/api-response.md` | 信封、traceId |
| RESTful API | `rules/common/restful-api.md` | URL 设计、HTTP 方法、状态码 |
| API 版本控制 | `rules/common/api-versioning.md` | `/v2/xxx` 新旧并存 |
| 时间格式 | `rules/common/time-format.md` | `yyyy-MM-dd HH:mm:ss.SSS` |

### NestJS 分层

```
Controller → Service → Repository → Database
```

分别位于：Controller（HTTP 解析）→ Service（业务逻辑）→ Repository（数据访问）。不越层调用。

### 依赖注入

始终构造器注入：

```typescript
@Injectable()
export class OrdersService {
  constructor(
    private readonly ordersRepo: OrdersRepository,
    private readonly paymentGateway: PaymentGateway,
  ) {}
}
```

### DTO 模式

Request DTO 用 `class-validator`，Response DTO 用 plain objects + static factory。Response 不暴露内部字段（password、salt、审计列）。

### 管道/守卫/拦截器

```typescript
app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
```

ResponseInterceptor 统一包装 `{code, message, data, requestId, metadata}`。

## gRPC

| 规范 | 文件 | 覆盖 |
|------|------|------|
| gRPC 分层 | `rules/common/grpc-layering.md` | 通用分层、Status 映射 |
| NestJS gRPC | 本文档 | @GrpcMethod(), RpcException, Transport.GRPC |

```typescript
const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
  transport: Transport.GRPC,
  options: { package: ['service.v1'], protoPath: [join(__dirname, '../proto/service/v1/service.proto')] },
});
```

- 无 `@Get`/`@Post`，无 `ApiResponse`，无 JWT Guard
- 用 `RpcException` 报告错误

## 数据库

| 规范 | 文件 | 覆盖 |
|------|------|------|
| 表结构 | `rules/common/table-structure.md` | 命名、审计字段、DDL |
| 迁移 | `rules/common/database-migration.md` | 6 步流程 |
| Schema 管理 | 本文档 | synchronize 禁止、@Index 禁止 |

### Schema 管理

- ❌ `synchronize: true`
- ❌ Entity 中 `@Index()` / `@Unique()` — 索引必须走 migration
- ✅ 所有 DDL 通过 migration 管理

## 定时任务

| 规范 | 文件 | 覆盖 |
|------|------|------|
| 通用 | `rules/common/scheduled-tasks.md` | 生命周期、幂等、分布式协调 |
| NestJS | 本文档 | @Cron, BullMQ, SchedulerRegistry |

### BullMQ（重试/延迟/优先级场景）

```typescript
await this.reportQueue.add('generate', { userId }, {
  attempts: 3,
  backoff: { type: 'exponential', delay: 2000 },
  removeOnComplete: true,
});
```

`@Cron` 用于简单定时触发，BullMQ 用于需要重试/延迟/进度追踪的任务。

## Module 设计

| 原则 | 说明 |
|------|------|
| 单一权责 | 一 Module 一领域，禁止 `UserOrderModule` |
| 跨 Module 通过 `imports` | NestJS imports/exports 机制 |
| 子模块嵌套 | 仅父模块内部使用时允许，外部引用时提升为顶层 |
| `src/` 下只允许 1 层 | 禁止 `src/modules/` 中间层 |

## React / 前端

- Custom Hooks：`use` 前缀，提取复用逻辑
- Repository 泛型接口：`findAll/findById/create/update/delete`
