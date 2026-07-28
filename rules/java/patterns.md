---
paths:
  - "**/*.java"
---
# Java Patterns

> Java/Spring Boot 特定规范路由。通用规范见 `rules/common/patterns.md`。

## 架构

| 规范 | 文件 | 覆盖 |
| ------ | ------ | ------ |
| Repository Pattern | `rules/common/patterns.md#repository-pattern` | 接口抽象 |
| 命名规范 | `rules/common/naming-convention.md` | JSON camelCase、DTO 后缀、DB snake_case |
| 构造器注入 | 本文档 | 禁止字段注入 |
| Service 层 | 本文档 | 业务逻辑分层 |
| DTO 映射 | 本文档 | Record + static factory |
| 并发编程 | `rules/java/concurrency.md` | 线程池、CompletableFuture、ThreadLocal、锁、并发集合、VT |

### YMS 架构覆盖层

当项目名以 `yms-` 开头，或需求明确属于幼立方（YMS）时，本节优先于通用 Java 模板。初始化前必须先确定项目类型；不能把 Gateway、BFF 和领域微服务当作同一类 HTTP 项目。

| 项目类型 | 服务名 | 对外协议 | 必须具备 | 禁止事项 |
| --- | --- | --- | --- | --- |
| Gateway | `yms-gateway` | WebFlux HTTP | 路由、粗鉴权、TraceId、内部头注入、访问日志 | 业务库、领域写入、BFF 业务聚合 |
| BFF/API | `yms-xxx-api` | Spring MVC HTTP | Gateway 内部请求校验、端侧登录态/RBAC、`ApiResponse`、gRPC client 编排 | 跨库写领域事实、直接暴露 gRPC 原始响应 |
| 领域微服务 | `yms-xxx-service` | gRPC + HTTP `/healthy` | 自有数据边界、proto、Nacos gRPC 注册、TraceId 与内部调用拦截器 | HTTP 业务 Controller、端侧 JWT/RBAC、跨库访问 |

YMS 初始化还必须满足：

1. `application.yml` 只提供 dev 默认值；test/prod 通过 `spring.config.import` 加载 `application-common.yaml` 与 `${spring.application.name}.yaml`。
2. Nacos 中只保存连接地址和 `${ENV_VAR}` 占位符；密码、token、JWT secret 仅来自受控 `deploy/.env.test` / `.env.prod`。
3. gRPC 微服务同时监听 `GRPC_PORT` 与仅用于 Actuator `/healthy` 的 `HTTP_PORT`；Nacos `instance.port` 必须是 `GRPC_PORT`，HTTP 端口只写 metadata。
4. BFF 的 `requestId` 必须等于经白名单校验后的 `traceId`，统一响应固定为 `code/message/data/requestId/metadata`；Gateway 是 TraceId 权威来源。
5. 新业务表使用 `INT NOT NULL AUTO_INCREMENT`，显式随机 `AUTO_INCREMENT=1000~3000`；新表用 `deleted_at` + `now()`/`null`。多服务共库时 Flyway history 表按服务隔离。
6. Redis key 使用 `yms:{service}:{env}:{module}:{key}`，全部设置 TTL；MQ、XXL-Job 只在实际业务需要时接入，不写空环境变量占位。

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
| ------ | ------ | ------ |
| gRPC 分层 | `rules/common/grpc-layering.md` | 通用分层 |
| Java gRPC 实现 | 本文档 | @GrpcService, ServerInterceptor, StatusRuntimeException |

### Java gRPC 分层

```text
gRPC Client → {Service}Impl (@GrpcService) → Service → Mapper → Database
```

| 层 | 注解/组件 | 职责 |
| ---- | ---------- | ------ |
| `{Service}Impl` | `@GrpcService` | gRPC 入口，proto↔Entity 转换 |
| Service | `@Service` | 纯业务逻辑，不含鉴权 |
| Mapper | MyBatis-Plus `BaseMapper` | 数据访问 |

- 无 `@RestController`、无 `ApiResponse`、无端侧 Spring Security
- 非 YMS 的纯 gRPC 项目可使用 `web-application-type: none`；YMS gRPC 微服务必须遵循上方覆盖层，启动最小 HTTP server 仅暴露 `/healthy`
- gRPC Status→HTTP 映射见 `rules/common/grpc-layering.md`

## 数据库

| 规范 | 文件 | 覆盖 |
| ------ | ------ | ------ |
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
| ------ | ------ | ------ |
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
| ------ | ------ |
| Builder Pattern | 多可选参数对象 |
| Sealed Types | 领域模型穷举 |
| Virtual Threads | `ReentrantLock` 替代 `synchronized` |

语言无关规范见 `rules/common/` 下的独立文件。
