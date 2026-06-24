---
paths:
  - "**/*.java"
---
# Java Patterns

> Java/Spring Boot 特定规范路由。通用规范见 `rules/common/patterns.md`。

## 架构

| 规范 | 文件 | 覆盖 |
|------|------|------|
| Repository Pattern | `rules/common/patterns.md#repository-pattern` | 接口抽象 |
| 命名规范 | `rules/common/naming-convention.md` | JSON camelCase、DTO 后缀、DB snake_case |
| 构造器注入 | 本文档 | 禁止字段注入 |
| Service 层 | 本文档 | 业务逻辑分层 |
| DTO 映射 | 本文档 | Record + static factory |

### 构造器注入

始终使用构造器注入，禁止字段注入：

```java
// GOOD — constructor injection (testable, immutable)
public class NotificationService {
    private final EmailSender emailSender;
    public NotificationService(EmailSender emailSender) { this.emailSender = emailSender; }
}

// BAD — field injection
@Autowired private EmailSender emailSender;
```

### DTO 映射

```java
public record OrderResponse(Long id, String customer, BigDecimal total) {
    public static OrderResponse from(Order order) { ... }
}
```

## gRPC

| 规范 | 文件 | 覆盖 |
|------|------|------|
| gRPC 分层 | `rules/common/grpc-layering.md` | 通用分层 |
| Java gRPC 实现 | 本文档 | @GrpcService, ServerInterceptor, StatusRuntimeException |

### Java gRPC 分层

```
gRPC Client → {Service}Impl (@GrpcService) → Service → Mapper → Database
```

| 层 | 注解/组件 | 职责 |
|----|----------|------|
| `{Service}Impl` | `@GrpcService` | gRPC 入口，proto↔Entity 转换 |
| Service | `@Service` | 纯业务逻辑，不含鉴权 |
| Mapper | MyBatis-Plus `BaseMapper` | 数据访问 |

- 无 `@RestController`、无 `ApiResponse`、无 Spring Security
- `web-application-type: none`
- gRPC Status→HTTP 映射见 `rules/common/grpc-layering.md`

## 数据库

| 规范 | 文件 | 覆盖 |
|------|------|------|
| 表结构 | `rules/common/table-structure.md` | 命名、审计字段、DDL 模板 |
| 索引 | 本文档 | p3c 索引规则 |
| 迁移 | `rules/common/database-migration.md` | 6 步流程 |
| Redis | 本文档 | Key 规范、禁止 KEYS |

### 索引（p3c）

**所有索引必须在 Flyway migration SQL 中创建，禁止在代码中通过注解声明索引。** MyBatis-Plus 实体类上不可使用任何索引相关注解。

详见 `rules/common/table-structure.md` 命名规范。以下为 Java 特有：

- 唯一索引 + 业务层校验双保险
- 联合索引最左前缀
- 禁止索引列上函数/计算/类型转换
- 单表索引 ≤5，EXPLAIN 验证
- 覆盖索引优先，外键列建索引

### Redis

- 禁止 `KEYS`，用 `SCAN`；所有 Key 带 TTL
- BigKey 删除用 `UNLINK`；降级运行
- Key 前缀：`{prefix}:{module}:{type}`

```java
private static final String PREFIX = System.getenv().getOrDefault("REDIS_KEY_PREFIX", "app:dev");
public static final String TOKEN_KEY = PREFIX + ":token:";
```

## 定时任务

| 规范 | 文件 | 覆盖 |
|------|------|------|
| 通用 | `rules/common/scheduled-tasks.md` | 生命周期、幂等、分布式协调 |
| Java XXL-Job | 本文档 | Handler、路由策略、@Scheduled |

### XXL-Job（生产唯一方案）

```yaml
xxl.job.admin.addresses: ${XXL_JOB_ADMIN_ADDRESSES}
xxl.job.executor.appname: ${XXL_JOB_EXECUTOR_APPNAME}
```

```java
@XxlJob("orderExpireHandler")
public void execute() {
    int shardIndex = XxlJobHelper.getShardIndex();
    int shardTotal = XxlJobHelper.getShardTotal();
    orderExpireService.expireOrders(shardIndex, shardTotal);
}
```

`@Scheduled` 仅限本地开发调试，生产禁止。

## Java 特有模式

| 模式 | 简述 |
|------|------|
| Builder Pattern | 多可选参数对象 |
| Sealed Types | 领域模型穷举 |
| Virtual Threads | `ReentrantLock` 替代 `synchronized` |

语言无关规范见 `rules/common/` 下的独立文件。
