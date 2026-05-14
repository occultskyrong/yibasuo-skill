---
paths:
  - "**/*.java"
---
# Java Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Java-specific content.

## Repository Pattern

Encapsulate data access behind an interface:

```java
public interface OrderRepository {
    Optional<Order> findById(Long id);
    List<Order> findAll();
    Order save(Order order);
    void deleteById(Long id);
}
```

Concrete implementations handle storage details (JPA, JDBC, in-memory for tests).

## Service Layer

Business logic in service classes; keep controllers and repositories thin:

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

Always use constructor injection — never field injection:

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

Use records for DTOs. Map at service/controller boundaries:

```java
public record OrderResponse(Long id, String customer, BigDecimal total) {
    public static OrderResponse from(Order order) {
        return new OrderResponse(order.getId(), order.getCustomerName(), order.getTotal());
    }
}
```

## Builder Pattern

Use for objects with many optional parameters:

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

统一返回体，Java / NestJS 使用相同结构：

```java
public record ApiResponse<T>(
    int code,          // 0=成功, 1=成功有消息, >=2=错误
    String message,    // 错误描述或成功提示
    T data,            // 业务数据，错误时为 null
    String requestId   // traceId，用于链路追踪
) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(0, null, data, MDC.get("traceId"));
    }
    public static <T> ApiResponse<T> ok(T data, String message) {
        return new ApiResponse<>(1, message, data, MDC.get("traceId"));
    }
    public static <T> ApiResponse<T> error(int code, String message) {
        return new ApiResponse<>(code, message, null, MDC.get("traceId"));
    }
}
```

## References

See skill: `springboot-patterns` for Spring Boot architecture patterns.
See skill: `jpa-patterns` for entity design and query optimization.
