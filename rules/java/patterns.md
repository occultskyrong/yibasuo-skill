---
paths:
  - "**/*.java"
---
# Java Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Java-specific content.

## Repository Pattern

将数据访问封装在接口后面：

```java
public interface OrderRepository {
    Optional<Order> findById(Long id);
    List<Order> findAll();
    Order save(Order order);
    void deleteById(Long id);
}
```

具体实现处理存储细节（JPA、JDBC、测试用内存实现）。

## gRPC 微服务分层

> 语言无关规范见 [common/patterns.md](../common/patterns.md) gRPC 微服务分层。本文档补充 Java/Spring Boot 特定实现。

```
gRPC Client → {Service}Impl (@GrpcService) → Service → Mapper → Database
                │                               │          │
                ▼                               ▼          ▼
              Proto 序列化                    业务逻辑    数据访问
```

| 层 | 注解/组件 | 职责 |
|----|----------|------|
| `{Service}Impl` | `@GrpcService` | gRPC 入口，proto message↔Entity 转换，委托 Service |
| Service | `@Service` | 纯业务逻辑，**不含鉴权代码**（信任 BFF 传来的身份） |
| Mapper | MyBatis-Plus `BaseMapper` | 数据访问（轻量微服务可省略，直接调用其他服务） |
| Interceptor | `ServerInterceptor` | traceId 透传（metadata→MDC）、异常日志 |

### 与 HTTP/BFF 的关键差异

- **无 `@RestController`、无 `@Controller`** — 入口是 `@GrpcService` 注解的实现类
- **无 `ApiResponse`** — gRPC 用 `StatusRuntimeException` 报告错误，不在 proto message 中包 code/message
- **无 `@RestControllerAdvice`** — 异常处理走 `ServerInterceptor` 或 `StatusRuntimeException`
- **无 Spring Security** — 不鉴权，从 gRPC metadata 读取 `x-user-id` 等身份信息（BFF 填入）
- **web-application-type: none** — 不启动 HTTP 端口
- **参数校验** — proto3 自带类型约束，业务校验在 Service 中做

### gRPC Status → HTTP 映射（BFF 层）

BFF 层捕获 gRPC 异常后按以下规则映射为 HTTP `ApiResponse`：

| gRPC Status | HTTP | 说明 |
|-------------|:----:|------|
| `NOT_FOUND` | 404 | 资源不存在 |
| `INVALID_ARGUMENT` | 400 | 参数错误 |
| `ALREADY_EXISTS` | 409 | 唯一约束冲突 |
| `PERMISSION_DENIED` | 403 | 权限不足 |
| `UNAUTHENTICATED` | 401 | 未认证 |
| `INTERNAL` | 500 | 内部错误 |
| `UNAVAILABLE` | 502 | 服务不可用 |
| `DEADLINE_EXCEEDED` | 504 | 超时 |

## Service Layer

业务逻辑放在 Service 层，Controller 和 Repository 保持轻薄：

```java
public class OrderService {
    private final OrderRepository orderRepository;
    private final PaymentGateway paymentGateway;

    public OrderService(OrderRepository orderRepository, PaymentGateway paymentGateway) {
        this.orderRepository = orderRepository;
        this.paymentGateway = paymentGateway;
    }

    public OrderSummary placeOrder(CreateOrderRequest request) {
        var order = Order.from(request);
        paymentGateway.charge(order.total());
        var saved = orderRepository.save(order);
        return OrderSummary.from(saved);
    }
}
```

## Constructor Injection

始终使用构造器注入，禁止字段注入：

```java
// GOOD — constructor injection (testable, immutable)
public class NotificationService {
    private final EmailSender emailSender;

    public NotificationService(EmailSender emailSender) {
        this.emailSender = emailSender;
    }
}

// BAD — field injection (untestable without reflection, requires framework magic)
public class NotificationService {
    @Inject // or @Autowired
    private EmailSender emailSender;
}
```

## DTO Mapping

使用 Record 作为 DTO，在 Service/Controller 边界做映射：

```java
public record OrderResponse(Long id, String customer, BigDecimal total) {
    public static OrderResponse from(Order order) {
        return new OrderResponse(order.getId(), order.getCustomerName(), order.getTotal());
    }
}
```

## Builder Pattern

适用于有很多可选参数的对象：

```java
public class SearchCriteria {
    private final String query;
    private final int page;
    private final int size;
    private final String sortBy;

    private SearchCriteria(Builder builder) {
        this.query = builder.query;
        this.page = builder.page;
        this.size = builder.size;
        this.sortBy = builder.sortBy;
    }

    public static class Builder {
        private String query = "";
        private int page = 0;
        private int size = 20;
        private String sortBy = "id";

        public Builder query(String query) { this.query = query; return this; }
        public Builder page(int page) { this.page = page; return this; }
        public Builder size(int size) { this.size = size; return this; }
        public Builder sortBy(String sortBy) { this.sortBy = sortBy; return this; }
        public SearchCriteria build() { return new SearchCriteria(this); }
    }
}
```

## Sealed Types for Domain Models

```java
public sealed interface PaymentResult permits PaymentSuccess, PaymentFailure {
    record PaymentSuccess(String transactionId, BigDecimal amount) implements PaymentResult {}
    record PaymentFailure(String errorCode, String message) implements PaymentResult {}
}

// Exhaustive handling (Java 21+)
String message = switch (result) {
    case PaymentSuccess s -> "Paid: " + s.transactionId();
    case PaymentFailure f -> "Failed: " + f.errorCode();
};
```

## API Response Envelope

遵循《阿里巴巴 Java 开发手册（黄山版）》前后端规约：

```json
{
  "code": 0,
  "message": "操作成功",
  "data": {...},
  "requestId": "a1b2c3d4e5f6",
  "metadata": {
    "timestamp": "2026-05-21 19:00:00.111",
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
| `code` | String | 成功=`"0"`，失败=业务枚举名（如 `"BAD_REQUEST"`）。**不是 Integer**：`BusinessCode` 枚举输出 String 错误码，与 NestJS 层的 `number \| string` 互通 |
| `message` | String | 用户提示信息 |
| `data` | T | 业务数据。空列表返回 `[]`，单条查询无结果可返回 `null`，错误响应 `data` 为 `null` |
| `requestId` | String | **= traceId**，Gateway 生成后全链路透传，前端报错时回传此值即可定位日志 |
| `metadata` | Object | 请求上下文 + 分页，非分页接口仅含 timestamp/method/endpoint |

### requestId = traceId

requestId 不是独立 UUID，而是 traceId（Gateway 生成，经 `X-Trace-Id` 头透传）。一条链路一个值，日志中 `[traceId=xxx]` 和响应中 `requestId=xxx` 是同一个。

### traceId 生成规则

| 角色 | 行为 |
|------|------|
| **Gateway** | 生成 traceId（UUID 去横线），写入 MDC + `X-Trace-Id` 响应头 |
| **BFF / 微服务** | 从 `X-Trace-Id` 请求头提取 → MDC；无则自生成 |
| **所有服务** | traceId 写入日志 `[%X{traceId}]`，设置给 `ApiResponse.requestId` |

```java
// Gateway Filter 或全局 Interceptor
String traceId = request.getHeader("X-Trace-Id");
if (traceId == null || traceId.isEmpty()) {
    traceId = UUID.randomUUID().toString().replace("-", "");
}
MDC.put("traceId", traceId);
response.setHeader("X-Trace-Id", traceId);
```

```java
public record ApiResponse<T>(Object code, String message, T data, String requestId, Metadata metadata) {
    public record Metadata(String timestamp, String method, String endpoint,
                           Long count, Integer totalPages, Integer currentPage, Integer pageSize) {}

    public static <T> ApiResponse<T> ok(T data, String method, String endpoint) {
        return new ApiResponse<>(0, "操作成功", data,
            MDC.get("traceId"),
            new Metadata(formatNow(), method, endpoint, null, null, null, null));
    }
    public static <T> ApiResponse<T> fail(String code, String message) {
        return new ApiResponse<>(code, message, null, MDC.get("traceId"), null);
    }
}
```

### RESTful 版本化

不兼容的接口变更使用 URL 版本号，新旧并存，等消费者迁移完成后删除旧版：

```java
// 新版
@RestController
@RequestMapping("/v2/auth")
public class AuthControllerV2 { ... }

// 旧版保留，@Deprecated 待下线
@RestController
@RequestMapping("/auth")
public class AuthController { ... }
```

| 变更类型 | 处理 |
|---------|------|
| 加字段 | 直接加，消费者忽略未知字段 |
| 改字段名/类型/含义 | 新建 `/v2/xxx`，新旧并存 |
| 删字段 | 同上 |
| 消费者未对接 | 不兼容变更可直接改 |

## 时间格式

**统一传输格式：** `yyyy-MM-dd HH:mm:ss.SSS`（精确到毫秒）

API 输入/输出、JSON 序列化、数据库 DateTime、日志时间戳均使用此格式。

```java
// Jackson 全局配置
@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss.SSS", timezone = "Asia/Shanghai")
private LocalDateTime createdAt;

// DateTimeFormatter（天然线程安全，Java 8+ 推荐）
DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS");
```

- 时区统一 `Asia/Shanghai`
- 禁止使用 `yyyy-MM-dd'T'HH:mm:ss`（ISO 8601 无毫秒不完整）、禁止仅到秒（`yyyy-MM-dd HH:mm:ss`）

## 数据库规范

遵循《阿里巴巴 Java 开发手册》数据库规约。

### 命名

- 数据库名/表名/列名：全小写+下划线，禁止大写字母
- 表名不使用复数
- 索引命名：`pk_`/`uk_`/`idx_` 前缀

### 审计字段

| 表类型 | id | created_by/updated_by | created_at/updated_at | deleted_at | 删除策略 |
|--------|:---:|:---:|:---:|:---:|------|
| 业务主表 | ✅ | ✅ | ✅ | ✅ | 逻辑删除（`deleted_at` + `@TableLogic`） |
| 关联表（中间表） | ✅ | ❌ | ❌ | ❌ | 物理删除 |
| 日志表 | ✅ | ❌ | ✅ | ❌ | 物理删除 |

**业务表**模板（6 个审计字段）：

```sql
id         BIGINT   NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
created_by INT      COMMENT '创建人 ID',
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
updated_by INT      COMMENT '更新人 ID',
updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
deleted_at DATETIME COMMENT '逻辑删除（NULL=未删除）'
```

**关联表**模板（无审计字段，仅自增主键）：

```sql
id      BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
-- 关联字段...
```

**日志表**模板（仅 created_at，物理删除）：

```sql
id         BIGINT   NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
-- 日志字段...
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
```

### 核心约束

- **禁止使用外键** — 一切外键约束在应用层解决
- 逻辑删除：`deleted_at` + MyBatis-Plus `@TableLogic`；关联表物理删除；日志表物理删除
- 数据库用户：`{库名}_{环境}`，禁止 root

### 索引

遵循《阿里巴巴 Java 开发手册》MySQL 数据库规约 §3-4。

#### 命名

索引命名格式：`{前缀}_{表名}_{列名缩写}`

| 前缀 | 类型 | 示例 |
|------|------|------|
| `pk_` | 主键索引 | `pk_order_id` |
| `uk_` | 唯一索引 | `uk_user_phone` |
| `idx_` | 普通索引 | `idx_order_user_status` |

- 表名可缩写（如 `order_item` → `oi`），同一库内保持一致
- 联合索引列名用下划线连接，按列顺序排列：`idx_order_user_id_status`
- 名称不超过 64 字符，过长时缩写中间列名

#### 设计规则

**1. 防重双保险**

业务层校验 + 数据库唯一索引缺一不可。业务校验返回友好提示，唯一索引防止并发写入绕过。

```sql
-- 业务层：先查后插（SELECT → INSERT）
-- 数据库：唯一索引兜底
ALTER TABLE `order` ADD UNIQUE INDEX `uk_order_trade_no` (`trade_no`);
```

**2. 最左前缀原则**

联合索引按定义顺序从最左列开始匹配。

```sql
-- 联合索引 (a, b, c)
-- 走索引：WHERE a=1、WHERE a=1 AND b=2、WHERE a=1 AND c=2（仅 a 走索引）
-- 不走：  WHERE b=2、WHERE c=3
```

将区分度高、查询频繁的列放在联合索引最左侧。

**3. 禁止索引列上使用函数、计算、类型转换**

```sql
-- BAD — 函数包裹
SELECT * FROM `order` WHERE DATE(created_at) = '2026-01-01';
-- BAD — 列参与运算
SELECT * FROM `order` WHERE amount * 100 > 50000;
-- BAD — 隐式类型转换（phone 是 VARCHAR，传了 INT）
SELECT * FROM `user` WHERE phone = 13800138000;

-- GOOD — 值侧做转换
SELECT * FROM `order` WHERE created_at >= '2026-01-01 00:00:00' AND created_at < '2026-01-02 00:00:00';
-- GOOD — 运算移到值侧
SELECT * FROM `order` WHERE amount > 50000 / 100;
-- GOOD — 显式字符串
SELECT * FROM `user` WHERE phone = '13800138000';
```

**4. 单表索引数建议 ≤5**

每个索引占用磁盘空间，增删改时需维护 B+Tree。不是越多越好。

**5. 覆盖索引优先，避免回表**

查询列全部在索引中时，直接从索引树取数据，无需回聚集索引。

```sql
-- 联合索引 idx_user_status_created (status, created_at)
-- 覆盖索引：查询列都在索引中，Extra = Using index
SELECT status, created_at FROM `user` WHERE status = 1 ORDER BY created_at;
-- 需回表：SELECT 含非索引列
SELECT id, status, name, created_at FROM `user` WHERE status = 1;
```

**6. LIKE 仅右模糊走索引**

```sql
-- 走索引
SELECT * FROM `user` WHERE name LIKE '张%';
-- 不走
SELECT * FROM `user` WHERE name LIKE '%张' OR name LIKE '%张%';
```

全模糊搜索场景使用 Elasticsearch 等全文检索引擎。

**7. 区分度低的列不适合单独建索引**

区分度 = `SELECT COUNT(DISTINCT col) / COUNT(*) FROM table`。区分度 < 0.1（如性别、布尔值）不单独建索引，可放在联合索引非最左位置。

```sql
-- BAD — 性别区分度极低
ALTER TABLE `user` ADD INDEX `idx_user_gender` (`gender`);
-- OK — 放在联合索引后面
ALTER TABLE `user` ADD INDEX `idx_user_gender_status` (`gender`, `status`);
```

**8. 外键列建索引**

项目禁止物理外键，但业务关联查询频繁。引用列必须建索引。

```sql
-- order.user_id 关联 user.id
ALTER TABLE `order` ADD INDEX `idx_order_user_id` (`user_id`);
```

**9. JOIN 列字符集/排序规则一致**

两列 CHARACTER SET 和 COLLATION 必须一致，否则索引失效。

```sql
SHOW FULL COLUMNS FROM `order` WHERE Field = 'trade_no';
SHOW FULL COLUMNS FROM `order_item` WHERE Field = 'order_trade_no';
-- 确保两者 COLLATION 完全一致
```

**10. 索引失效的常见写法**

| 写法 | 走索引 | 说明 |
|------|:---:|------|
| `WHERE col IS NULL` | 是 | — |
| `WHERE col IS NOT NULL` | 否 | 负向条件 |
| `WHERE col != value` | 否 | 负向条件 |
| `WHERE col NOT IN (...)` | 否 | 负向条件 |
| `WHERE col IN (1, 2, 3)` | 是 | IN 实质是等值查询 |
| `WHERE col1 = 1 OR col2 = 2` | 否 | 改写为 UNION ALL |
| `WHERE col LIKE 'abc%'` | 是 | 右模糊 |
| `WHERE col LIKE '%abc'` | 否 | 左模糊 |
| `WHERE func(col) = x` | 否 | 函数包裹 |

#### EXPLAIN 验证

所有新增或修改的查询 SQL 必须通过 EXPLAIN 验证。

```sql
EXPLAIN SELECT * FROM `order` WHERE user_id = 100 AND status = 'PAID';
```

| 指标 | 最低要求 | 理想值 |
|------|---------|--------|
| `type` | `range` 及以上 | `const` / `eq_ref` / `ref` |
| `rows` | 与数据量级匹配 | 尽可能小 |
| `Extra` | 无 `Using filesort` / `Using temporary`（大数据量） | `Using index`（覆盖索引） |

`type` 从优到劣：

```
system > const > eq_ref > ref > range > index > ALL
```

- `ALL`（全表扫描）：必须优化，表数据量 < 1000 行除外
- `index`（全索引扫描）：数据量小时可接受，大表必须优化
- `range` 及以上：可接受

#### 反模式

- 无脑加索引，以为索引越多查询越快
- 区分度极低（<0.1）的列单独建索引（如 `is_deleted`、`gender`）
- 联合索引列顺序随意，不考虑实际查询模式
- 索引列上使用函数、计算或隐式类型转换
- `SELECT *` 导致无法利用覆盖索引
- `!=` / `NOT IN` / `OR` 不拆分改写
- JOIN 列字符集不一致不检查
- 不写 EXPLAIN，凭感觉认为"这个查询应该走索引"
- 生产环境对大表直接加索引（应使用 `pt-online-schema-change` 或低峰期操作）

#### 审查清单

- [ ] 每个索引是否有明确对应的业务查询
- [ ] 联合索引列顺序是否符合最左前缀原则
- [ ] 唯一约束是否有业务层校验 + 数据库唯一索引双保险
- [ ] 查询 SQL 是否避免在索引列上使用函数、计算、类型转换
- [ ] 负向条件（`!=`/`NOT IN`）和 `OR` 是否已改写
- [ ] LIKE 查询是否仅使用右模糊
- [ ] JOIN 关联列字符集/排序规则是否一致
- [ ] 外键列（关联查询列）是否已建索引
- [ ] 单表索引数是否 ≤ 5
- [ ] 核心查询是否通过 EXPLAIN 验证（`type` ≥ `range`）
- [ ] 是否优先使用覆盖索引避免回表
- [ ] 区分度 < 0.1 的列是否未单独建索引

### 迁移

详见 `rules/common/patterns.md` 数据库迁移规范。

## Redis 规范

- **禁止使用 `KEYS` 命令** — 生产环境必须用 `SCAN` 替代
- **所有 Key 必须设置 TTL** — Token 类 1h-7d，缓存 5min-30min
- **拒绝大 Key** — String 不超过 10KB，集合元素不超过 5000
- **BigKey 删除用 `UNLINK`** — 替代 `DEL`，避免阻塞主线程
- **降级** — 所有 Redis 操作加 try-catch，不可用时降级运行（跳过黑名单、权限查库）

```java
private static final String PREFIX = System.getenv().getOrDefault("REDIS_KEY_PREFIX", "yms:admin:dev");
public static final String TOKEN_KEY = PREFIX + ":token:";
```

## 操作日志

- AOP 切面拦截 `@RequirePerm` 注解
- `@Async` 异步写入 `admin_operate_log`
- 请求参数中 password/secret 字段脱敏，截断至 2048 字符

## 定时任务

> 语言无关的核心规范见 [common/patterns.md](../common/patterns.md) 定时任务章节。本文档补充 Java/Spring Boot 特定实现。
>
> **框架选型**：生产环境统一使用 **XXL-Job** 作为分布式任务调度平台。`@Scheduled` 仅限本地开发调试或单机部署的简单场景。

### XXL-Job 集成

**依赖**：`pom.xml` 添加 `xxl-job-core`（版本由 infra 模板统一管理）。

**调度中心配置**（`application.yml`）：

```yaml
xxl:
  job:
    admin:
      addresses: ${XXL_JOB_ADMIN_ADDRESSES}   # 调度中心地址
    executor:
      appname: ${XXL_JOB_EXECUTOR_APPNAME}     # 执行器名称
      port: ${XXL_JOB_EXECUTOR_PORT:9999}
      logpath: ${XXL_JOB_EXECUTOR_LOG_PATH:/data/applogs/xxl-job}
```

**执行器**：

```java
@Component
public class OrderExpireHandler {

    @XxlJob("orderExpireHandler")
    public void execute() {
        // 分片广播模式：通过分片参数确定当前实例处理的数据范围
        int shardIndex = XxlJobHelper.getShardIndex();
        int shardTotal = XxlJobHelper.getShardTotal();
        orderExpireService.expireOrders(shardIndex, shardTotal);
    }
}
```

| 规则 | 说明 |
|------|------|
| Handler 命名 | `@XxlJob` 注解值在调度中心全局唯一，命名：`{领域}{动作}Handler`（如 `orderExpireHandler`） |
| 路由策略 | 多实例优先"故障转移"（单实例执行），大数据量用"分片广播"（多实例并行，各处理不同分片） |
| 阻塞策略 | 默认"单机串行"（`ExecutorBlockStrategyEnum.SERIAL_EXECUTION`），防止重复执行 |
| 调度与业务分离 | Handler 只做分片参数解析 + 委托调用，业务逻辑在独立 Service |
| 幂等保护 | 配合 Redis 分布式锁（见下方），防止调度中心网络抖动时重复触发 |

### @Scheduled（仅限开发调试）

`@Scheduled` 仅用于本地开发快速验证，生产环境必须迁移到 XXL-Job。

```java
// 仅限本地开发调试，生产禁止使用
@Scheduled(cron = "${task.order-expire.cron}")
public void execute() {
    taskExecutor.execute(() -> service.expireOrders());
}
```

| 规则 | 说明 |
|------|------|
| cron 外置 | 通过 `@Scheduled(cron = "${...}")` 从配置文件读取 |
| 生产禁用 | 提交到 staging/prod 前必须替换为 XXL-Job Handler |

### 自定义调度线程池

```java
@Configuration
@EnableScheduling
public class SchedulingConfig implements SchedulingConfigurer {

    @Override
    public void configureTasks(ScheduledTaskRegistrar registrar) {
        registrar.setScheduler(taskScheduler());
    }

    @Bean
    public TaskScheduler taskScheduler() {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(Runtime.getRuntime().availableProcessors());
        scheduler.setThreadNamePrefix("scheduled-");
        scheduler.setAwaitTerminationSeconds(60);
        scheduler.setWaitForTasksToCompleteOnShutdown(true);
        return scheduler;
    }
}
```

- `setWaitForTasksToCompleteOnShutdown(true)` — 优雅关闭时等待任务完成
- `setAwaitTerminationSeconds(60)` — 最多等待 60 秒

### 分布式锁实现（Redis）

多实例环境下，使用 Redis SET NX PX 保证任务互斥：

```java
@Component
public class TaskLockManager {
    private final StringRedisTemplate redis;

    private static final String LOCK_PREFIX =
        System.getenv().getOrDefault("REDIS_KEY_PREFIX", "app:dev") + ":task:lock:";

    /**
     * 尝试获取锁，返回是否获取成功。
     * @param taskName 任务名
     * @param ttlSeconds 锁超时时间（必须 > 任务最大执行时间）
     */
    public boolean tryLock(String taskName, long ttlSeconds) {
        String key = LOCK_PREFIX + taskName;
        String value = hostname();
        return Boolean.TRUE.equals(
            redis.opsForValue()
                .setIfAbsent(key, value, Duration.ofSeconds(ttlSeconds))
        );
    }

    /** 释放锁（Lua 原子操作，校验持有者）。 */
    public void unlock(String taskName) {
        String key = LOCK_PREFIX + taskName;
        String value = hostname();
        String script = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end";
        redis.execute(new DefaultRedisScript<>(script, Long.class), List.of(key), value);
    }

    private String hostname() {
        try {
            return InetAddress.getLocalHost().getHostName()
                + ":" + ProcessHandle.current().pid();
        } catch (UnknownHostException e) {
            return "unknown:" + ProcessHandle.current().pid();
        }
    }
}
```

关键点：
- `setIfAbsent` = `SET NX`，原子操作
- Lua 脚本释放：先校验持有者再删除，防止误删他人锁
- 锁 TTL 必须大于任务最大执行时间；无法预估时使用看门狗续期（定期 `EXPIRE` 延长 TTL，间隔 = TTL/3）

### 使用示例

```java
@Component
public class OrderExpireTask {
    private final OrderExpireService service;
    private final TaskLockManager lockManager;

    private static final String TASK_NAME = "order:expire:cancel";
    private static final long LOCK_TTL = 300;

    @Scheduled(cron = "${task.order-expire.cron}")
    public void execute() {
        if (!lockManager.tryLock(TASK_NAME, LOCK_TTL)) {
            log.warn("Task skipped: another instance is running. task={}", TASK_NAME);
            return;
        }
        try {
            service.expireOrders();
        } finally {
            lockManager.unlock(TASK_NAME);
        }
    }
}
```

### Quartz / XXL-Job 集成

框架自带集群协调时，优先使用框架能力而非自建锁：

- **Quartz**：启用集群模式（`org.quartz.jobStore.isClustered=true`），框架自动管理任务互斥
- **XXL-Job**：路由策略选"故障转移"（单实例执行）或"分片广播"（多实例并行，各自处理不同分片）

额外约束：
- 任务处理器（JobHandler）中同样需要幂等性保护
- 分片广播模式：通过分片参数确定当前实例处理的数据范围
- 调度中心的任务参数通过环境变量或配置中心注入，禁止硬编码

### 审查清单

- [ ] cron 表达式是否外置到配置文件
- [ ] 是否配置了自定义 `TaskScheduler` 线程池（池大小 >= 任务数）
- [ ] `@Scheduled` 方法是否简洁（只做锁 + 委托，不超过 10 行）
- [ ] 多实例部署时是否有分布式锁保护
- [ ] 锁 TTL 是否大于任务最大执行时间
- [ ] 锁释放是否在 `finally` 块中
- [ ] 业务逻辑是否有幂等性保护
- [ ] 是否有超时控制（外部调用、整体任务）
- [ ] 是否记录了任务执行日志（任务名、耗时、处理条数）

## References

See skill: `springboot-patterns` for Spring Boot architecture patterns.
See skill: `jpa-patterns` for entity design and query optimization.
