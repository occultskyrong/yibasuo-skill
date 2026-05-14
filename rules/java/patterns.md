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

统一返回体（对齐 ai-foundation），Java / NestJS 使用相同结构：

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(
    int status,             // 0=成功, >=2=错误
    String message,         // 成功提示或错误描述
    T data,                 // 业务数据，错误时为 null
    String requestId,       // traceId，从 MDC 获取
    Integer errorCode,      // 子错误码（业务分类），可选
    String errorMessage,    // 子错误详情，可选
    ResponseMetadata metadata // 请求元数据
) {
    public record ResponseMetadata(
        String timestamp,   // YYYY-MM-DD HH:mm:ss.SSS
        String method,      // HTTP 方法
        String endpoint,    // 请求路径
        Long count,         // 分页总数，可选
        Integer totalPages, // 总页数，可选
        Integer currentPage,// 当前页，可选
        Integer pageSize    // 每页数量，可选
    ) {}

    public static <T> ApiResponse<T> ok(T data, String method, String endpoint) {
        return new ApiResponse<>(0, "请求成功", data,
            MDC.get("traceId"), null, null,
            new ResponseMetadata(formatNow(), method, endpoint, null, null, null, null));
    }
    public static <T> ApiResponse<T> error(int status, String message, int errorCode, String errorMessage) {
        return new ApiResponse<>(status, message, null,
            MDC.get("traceId"), errorCode, errorMessage, null);
    }
}
```

### traceId 生成规则

| 角色 | 行为 |
|------|------|
| **Gateway** | 生成 traceId（UUID 去横线），写入 MDC 和响应头 `X-Trace-Id` |
| **BFF / 微服务** | 从请求头 `X-Trace-Id` 提取 traceId 写入 MDC；若请求头无此字段，自行生成（UUID 去横线） |
| **所有服务** | traceId 写入日志格式 `%X{traceId}`，并设置为 ApiResponse.requestId |

```java
// Gateway Filter 或全局 Interceptor
String traceId = request.getHeader("X-Trace-Id");
if (traceId == null || traceId.isEmpty()) {
    traceId = UUID.randomUUID().toString().replace("-", "");
}
MDC.put("traceId", traceId);
response.setHeader("X-Trace-Id", traceId);
```

## References

See skill: `springboot-patterns` for Spring Boot architecture patterns.
See skill: `jpa-patterns` for entity design and query optimization.
