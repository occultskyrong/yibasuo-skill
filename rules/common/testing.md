# Testing Requirements

## Minimum Test Coverage: 80%

Test Types（后端服务项目 ALL required，其他项目类型按需选择）：

1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations
3. **E2E Tests** - Critical user flows (framework chosen per language)

## Test-Driven Development

MANDATORY for new features and bug fixes; MAY skip for config changes, docs, README updates:

1. Write test first (RED)
2. Run test - it should FAIL
3. Write minimal implementation (GREEN)
4. Run test - it should PASS
5. Refactor (IMPROVE)
6. Verify coverage (80%+)

## Troubleshooting Test Failures

1. Use **tdd-guide** agent
2. Check test isolation
3. Verify mocks are correct
4. Fix implementation, not tests (unless tests are wrong)

## Agent Support

- **tdd-guide** - Use PROACTIVELY for new features, enforces write-tests-first

## Test Structure (AAA Pattern)

Prefer Arrange-Act-Assert structure for tests:

```typescript
test('calculates similarity correctly', () => {
  // Arrange
  const vector1 = [1, 0, 0]
  const vector2 = [0, 1, 0]

  // Act
  const similarity = calculateCosineSimilarity(vector1, vector2)

  // Assert
  expect(similarity).toBe(0)
})
```

### Test Naming

Use descriptive names that explain the behavior under test. 格式：`方法名_场景_预期行为`：

```java
// Java
@Test
@DisplayName("findByPhone 手机号存在时返回用户")
void findByPhone_should_return_user_when_phone_exists() { }
```

```typescript
// TypeScript
test('returns empty array when no records match query', () => {})
test('throws NotFoundException when user does not exist', () => {})
```

### Test Organization

- 测试目录镜像 `src/` 结构：`src/user/user.service.ts` → `test/user/user.service.spec.ts`
- 一被测文件一测试文件

### Mock 原则

- Mock 外部依赖（数据库、API、消息队列），不 Mock 被测对象本身
- 集成测试使用**真实数据库**（Testcontainers / Docker），禁止内存数据库（H2、SQLite）
- 语言特定 Mock 实现见 `rules/java/testing.md` 和 `rules/typescript/testing.md`
