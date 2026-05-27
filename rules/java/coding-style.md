---
paths:
  - "**/*.java"
---
# Java Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Java-specific content.

## Formatting

- **阿里巴巴 Java 开发手册 (p3c)** for enforcement — use `p3c-pmd` or Alibaba Checkstyle config
- `mvn pmd:check` or `mvn checkstyle:check` with Alibaba rules
- One public top-level type per file
- Consistent indent: 2 or 4 spaces (match project standard)
- Member order: constants, fields, constructors, public methods, protected, private

## Immutability

- Prefer `record` for value types (Java 16+)
- Mark fields `final` by default — use mutable state only when required
- Return defensive copies from public APIs: `List.copyOf()`, `Map.copyOf()`, `Set.copyOf()`
- Copy-on-write: return new instances rather than mutating existing ones

```java
// GOOD — immutable value type
public record OrderSummary(Long id, String customerName, BigDecimal total) {}

// GOOD — final fields, no setters
public class Order {
    private final Long id;
    private final List<LineItem> items;

    public List<LineItem> getItems() {
        return List.copyOf(items);
    }
}
```

## Naming

| 对象 | 规则 | 示例 |
|------|------|------|
| 类/接口/Record | PascalCase | `AdminUserService` |
| 方法/变量 | camelCase | `findByPhone()` |
| 常量 | UPPER_SNAKE_CASE | `DATA_SCOPE_ALL` |
| 包名 | 全小写，反域名 | `com.jiachen.api.admin.service` |
| 抽象类 | `Abstract` 或 `Base` 开头 | `BaseController` |
| 异常类 | `Exception` 结尾 | `UserNotFoundException` |
| 测试类 | `Test` 结尾 | `UserServiceTest` |
| Service 接口 | 不加 `I` 前缀 | `UserService` |
| Service 实现 | 接口名 + `Impl` | `UserServiceImpl` |
| Mapper | `Mapper` 结尾（MyBatis-Plus） | `UserMapper` |
| 数据库表 | snake_case | `admin_user_school` |
| 数据库列 | snake_case | `created_at` |

## POJO 约束

- POJO 属性**禁止使用基本类型**：`int`→`Integer`、`long`→`Long`、`boolean`→`Boolean`
- POJO 布尔变量**禁止 `is` 前缀**（避免序列化框架误解析）
- **禁止滥用 `@Data`**：关联对象多的实体改用 `@Getter`/`@Setter` 单独指定，防止 `toString` 泄漏关联数据或循环引用。密码字段加 `@JsonIgnore` 排除序列化

## Modern Java Features

优先使用现代语言特性提升代码清晰度：
- **Records** for DTOs and value types (Java 16+)
- **Sealed classes** for closed type hierarchies (Java 17+)
- **Pattern matching** with `instanceof` — no explicit cast (Java 16+)
- **Text blocks** for multi-line strings — SQL, JSON templates (Java 15+)
- **Switch expressions** with arrow syntax (Java 14+)
- **Pattern matching in switch** — exhaustive sealed type handling (Java 21+)

```java
// Pattern matching instanceof
if (shape instanceof Circle c) {
    return Math.PI * c.radius() * c.radius();
}

// Sealed type hierarchy
public sealed interface PaymentMethod permits CreditCard, BankTransfer, Wallet {}

// Switch expression
String label = switch (status) {
    case ACTIVE -> "Active";
    case SUSPENDED -> "Suspended";
    case CLOSED -> "Closed";
};
```

## Optional Usage

- Return `Optional<T>` from finder methods that may have no result
- Use `map()`, `flatMap()`, `orElseThrow()` — never call `get()` without `isPresent()`
- Never use `Optional` as a field type or method parameter

```java
// GOOD
return repository.findById(id)
    .map(ResponseDto::from)
    .orElseThrow(() -> new OrderNotFoundException(id));

// BAD — Optional as parameter
public void process(Optional<String> name) {}
```

## Error Handling

- Prefer unchecked exceptions for domain errors
- Create domain-specific exceptions extending `RuntimeException`
- Avoid broad `catch (Exception e)` unless at top-level handlers
- Include context in exception messages

```java
public class OrderNotFoundException extends RuntimeException {
    public OrderNotFoundException(Long id) {
        super("Order not found: id=" + id);
    }
}
```

## Streams

- Use streams for transformations; keep pipelines short (3-4 operations max)
- Prefer method references when readable: `.map(Order::getTotal)`
- Avoid side effects in stream operations
- For complex logic, prefer a loop over a convoluted stream pipeline

## equals / hashCode

遵循 p3c OOP 规约：

- 重写 `equals` 必须重写 `hashCode`（否则作为 Map key 时行为不可预测）
- `equals` 必须满足自反性、对称性、传递性、一致性
- `compareTo` 返回 0 的元素必须与 `equals` 一致
- POJO 作为 Map key 时必须确保 `hashCode` 稳定（不依赖可变字段）

```java
// GOOD — Record 自动生成 equals/hashCode
public record OrderId(Long value) {}

// GOOD — 手动实现时两者一致
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Order other)) return false;
    return Objects.equals(id, other.id);
}

@Override
public int hashCode() {
    return Objects.hash(id);
}
```

## 集合处理

遵循 p3c 集合处理规约：

- `ArrayList.subList()` 返回的是视图而非副本，修改会直接影响原列表
- 判断集合为空用 `isEmpty()` 而非 `size() == 0`
- `ConcurrentHashMap` 的 key/value 禁止为 null
- `foreach` 中禁止 `remove/add`，必须用 `Iterator` 或 `removeIf`
- `Arrays.asList()` 返回固定大小列表，不能 `add/remove`

```java
// GOOD
if (list.isEmpty()) { ... }
list.removeIf(item -> item.isExpired());

// BAD — foreach 中修改
for (Item item : list) {
    if (item.isExpired()) list.remove(item); // ConcurrentModificationException
}
```

## 控制语句

遵循 p3c 控制语句规约：

- `switch` 必须有 `default` 分支（即使只是 break）
- `if/else/for/while/do` 必须使用大括号，即使只有一行
- 三目运算符注意自动拆箱 NPE
- `if-else` 嵌套不超过 3 层，优先使用卫语句

```java
// GOOD — 卫语句
public BigDecimal calculate(Order order) {
    if (order == null) return BigDecimal.ZERO;
    if (order.isCancelled()) return BigDecimal.ZERO;
    // 主逻辑...
}

// BAD — 深层嵌套
if (order != null) {
    if (!order.isCancelled()) {
        if (order.getItems() != null) {
            // 主逻辑...
        }
    }
}
```

## Virtual Threads (Java 21+)

Spring Boot 4.0 支持 `spring.threads.virtual.enabled=true`：

- **适用场景**：IO 密集型（HTTP 调用、数据库查询）、大量并发连接
- **不适用场景**：CPU 密集型计算、需要精确控制线程数的场景
- **`synchronized` 导致 pinning** — Virtual Thread 持有 `synchronized` 锁时会 pin 到平台线程，改用 `ReentrantLock`
- **ThreadLocal 内存开销** — 每个 Virtual Thread 都会创建 ThreadLocal 前本，大量 VT + 大 ThreadLocal = 内存爆炸

```java
// GOOD — Virtual Thread 下用 ReentrantLock
private final ReentrantLock lock = new ReentrantLock();

lock.lock();
try {
    // 临界区
} finally {
    lock.unlock();
}

// BAD — Virtual Thread 下用 synchronized 导致 pinning
synchronized (this) {
    // 临界区
}
```

## References

See skill: `java-coding-standards` for full coding standards with examples.
See skill: `jpa-patterns` for JPA/Hibernate entity design patterns.
