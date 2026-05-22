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
| `code` | Object | 成功=0(Integer)，失败=String（业务错误码）|
| `message` | String | 用户提示信息 |
| `data` | T | 业务数据，空列表返回 `[]` |
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

// SimpleDateFormat（线程安全用 ThreadLocal）
new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");
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

每张业务表必须包含：

```sql
id         BIGINT   NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
created_by INT      COMMENT '创建人 ID',
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
updated_by INT      COMMENT '更新人 ID',
updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
deleted_at DATETIME COMMENT '逻辑删除（NULL=未删除）'
```

### 核心约束

- **禁止使用外键** — 一切外键约束在应用层解决
- 逻辑删除：`deleted_at` + MyBatis-Plus `@TableLogic`；关联表物理删除；日志表物理删除
- 数据库用户：`{库名}_{环境}`，禁止 root

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

## References

See skill: `springboot-patterns` for Spring Boot architecture patterns.
See skill: `jpa-patterns` for entity design and query optimization.
