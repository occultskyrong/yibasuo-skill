---
paths:
  - "**/*.java"
---
# Java Testing

> This file extends [common/testing.md](../common/testing.md) with Java-specific content.

## Test Framework

- **JUnit 5** (`@Test`, `@ParameterizedTest`, `@Nested`, `@DisplayName`)
- **AssertJ** for fluent assertions (`assertThat(result).isEqualTo(expected)`)
- **Mockito** for mocking dependencies
- **Testcontainers** for integration tests requiring databases or services

## Test Organization

```
src/test/java/com/example/app/
  service/           # Unit tests for service layer
  controller/        # Web layer / API tests
  repository/        # Data access tests
  integration/       # Cross-layer integration tests
```

Mirror the `src/main/java` package structure in `src/test/java`.

## Unit Test Pattern

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    private OrderService orderService;

    @BeforeEach
    void setUp() {
        orderService = new OrderService(orderRepository);
    }

    @Test
    @DisplayName("findById returns order when exists")
    void findById_existingOrder_returnsOrder() {
        var order = new Order(1L, "Alice", BigDecimal.TEN);
        when(orderRepository.findById(1L)).thenReturn(Optional.of(order));

        var result = orderService.findById(1L);

        assertThat(result.customerName()).isEqualTo("Alice");
        verify(orderRepository).findById(1L);
    }

    @Test
    @DisplayName("findById throws when order not found")
    void findById_missingOrder_throws() {
        when(orderRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> orderService.findById(99L))
            .isInstanceOf(OrderNotFoundException.class)
            .hasMessageContaining("99");
    }
}
```

## Parameterized Tests

```java
@ParameterizedTest
@CsvSource({
    "100.00, 10, 90.00",
    "50.00, 0, 50.00",
    "200.00, 25, 150.00"
})
@DisplayName("discount applied correctly")
void applyDiscount(BigDecimal price, int pct, BigDecimal expected) {
    assertThat(PricingUtils.discount(price, pct)).isEqualByComparingTo(expected);
}
```

## Integration Tests

Use Testcontainers for real database integration:

```java
@Testcontainers
class OrderRepositoryIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    private OrderRepository repository;

    @BeforeEach
    void setUp() {
        var dataSource = new PGSimpleDataSource();
        dataSource.setUrl(postgres.getJdbcUrl());
        dataSource.setUser(postgres.getUsername());
        dataSource.setPassword(postgres.getPassword());
        repository = new JdbcOrderRepository(dataSource);
    }

    @Test
    void save_and_findById() {
        var saved = repository.save(new Order(null, "Bob", BigDecimal.ONE));
        var found = repository.findById(saved.getId());
        assertThat(found).isPresent();
    }
}
```

For Spring Boot integration tests, see skill: `springboot-tdd`.

## Test Naming

Use descriptive names with `@DisplayName`:
- `methodName_scenario_expectedBehavior()` for method names
- `@DisplayName("human-readable description")` for reports

## Coverage

- Target 80%+ line coverage
- Use JaCoCo for coverage reporting
- Focus on service and domain logic — skip trivial getters/config classes

## TDD 流程与 AIR 原则

1. 写测试（RED）→ 2. 确认失败 → 3. 最小实现（GREEN）→ 4. 确认通过 → 5. 重构（IMPROVE）→ 6. JaCoCo ≥ 80%

**AIR 原则**（阿里手册强制）：

- **A（Automatic）自动**：全自动执行，不能有人工交互
- **I（Independent）独立**：每个测试独立，不依赖执行顺序
- **R（Repeatable）可重复**：每次结果一致，不依赖外部环境。涉及时间的用 `Clock` 注入

## 测试命名

方法名使用 `methodName_scenario_expectedBehavior` 格式，配合 `@DisplayName` 中文描述：

```java
@Test
@DisplayName("findByPhone 手机号存在时返回用户")
void findByPhone_existingPhone_returnsUser() { ... }
```

## 测试结构（AAA）

所有测试遵循 Arrange-Act-Assert。

## Mock 约束

- Service 单测只 Mock Mapper 和外部服务，不 Mock 被测 Service 自身
- `BaseMapper.insert(T)` 和 `insert(Collection)` 重载冲突，Mock 时用 `any(XxxEntity.class)` 而非 `any()`
- `updateById` 同理
- 避免 UnnecessaryStubbing：只 stub 被实际调用的方法
- BCrypt 测试用 cost=4 或更低加速
- **不应 Mock**：实体/DTO、值对象、配置值、日志

## 集成测试

涉及数据库必须用 **Testcontainers** 真实 MySQL，**禁止 H2** 内存库替代：

```java
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@Testcontainers
class UserControllerIT {
    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0");

    @DynamicPropertySource
    static void configure(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
    }
}
```

原则：H2 的 SQL 方言差异会导致测试通过但上线挂。

## 测试组织

```
src/test/java/com/example/app/
├── service/            # Service 层单元测试
├── controller/         # Controller 集成测试
├── repository/         # Mapper 集成测试
└── util/               # 工具类测试
```

与 `src/main/java` 包结构一一对应。

## References

See skill: `springboot-tdd` for Spring Boot TDD patterns with MockMvc and Testcontainers.
