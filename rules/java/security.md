---
paths:
  - "**/*.java"
---
# Java Security

> This file extends [common/security.md](../common/security.md) with Java-specific content.

## Secrets Management

- Never hardcode API keys, tokens, or credentials in source code
- Use environment variables: `System.getenv("API_KEY")`
- Use a secret manager (Vault, AWS Secrets Manager) for production secrets
- Keep local config files with secrets in `.gitignore`

```java
// BAD
private static final String API_KEY = "sk-abc123...";

// GOOD — environment variable
String apiKey = System.getenv("PAYMENT_API_KEY");
Objects.requireNonNull(apiKey, "PAYMENT_API_KEY must be set");
```

## SQL Injection Prevention

- Always use parameterized queries — never concatenate user input into SQL
- Use `PreparedStatement` or your framework's parameterized query API
- Validate and sanitize any input used in native queries

```java
// BAD — SQL injection via string concatenation
Statement stmt = conn.createStatement();
String sql = "SELECT * FROM orders WHERE name = '" + name + "'";
stmt.executeQuery(sql);

// GOOD — PreparedStatement with parameterized query
PreparedStatement ps = conn.prepareStatement("SELECT * FROM orders WHERE name = ?");
ps.setString(1, name);

// GOOD — JDBC template
jdbcTemplate.query("SELECT * FROM orders WHERE name = ?", mapper, name);
```

## Input Validation

- Validate all user input at system boundaries before processing
- Use Bean Validation (`@NotNull`, `@NotBlank`, `@Size`) on DTOs when using a validation framework
- Sanitize file paths and user-provided strings before use
- Reject input that fails validation with clear error messages

```java
// Validate manually in plain Java
public Order createOrder(String customerName, BigDecimal amount) {
    if (customerName == null || customerName.isBlank()) {
        throw new IllegalArgumentException("Customer name is required");
    }
    if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
        throw new IllegalArgumentException("Amount must be positive");
    }
    return new Order(customerName, amount);
}
```

## Authentication and Authorization

- Never implement custom auth crypto — use established libraries
- Store passwords with bcrypt or Argon2, never MD5/SHA1
- Enforce authorization checks at service boundaries
- Clear sensitive data from logs — never log passwords, tokens, or PII

## Dependency Security

- Run `mvn dependency:tree` or `./gradlew dependencies` to audit transitive dependencies
- Use OWASP Dependency-Check or Snyk to scan for known CVEs
- Keep dependencies updated — set up Dependabot or Renovate

## Error Messages

- Never expose stack traces, internal paths, or SQL errors in API responses
- Map exceptions to safe, generic client messages at handler boundaries
- Log detailed errors server-side; return generic messages to clients

```java
// Log the detail, return a generic message
try {
    return orderService.findById(id);
} catch (OrderNotFoundException ex) {
    log.warn("Order not found: id={}", id);
    return ApiResponse.error("Resource not found");  // generic, no internals
} catch (Exception ex) {
    log.error("Unexpected error processing order id={}", id, ex);
    return ApiResponse.error("Internal server error");  // never expose ex.getMessage()
}
```

## 敏感数据保护

- 手机号、身份证、银行卡等个人敏感信息**AES-256 加密存储**，不可明文落库
- 日志中脱敏：手机号 `138****1234`，身份证 `3201**********1234`
- 前端回显时按需脱敏

## Web 安全

### HTTPS

生产环境强制使用 HTTPS，Nginx/网关层做 SSL 终结。禁止生产环境 HTTP 明文传输。

### XSS 防护

所有用户输入输出转义。富文本场景用 **OWASP AntiSamy** 或 **Jsoup** 白名单过滤，禁止直接返回用户输入的 HTML。

### CSRF 防护

管理后台类服务开启 Spring Security CSRF 保护，或 Token 双写校验。

### 文件上传

校验扩展名 + MIME 白名单，禁止直接使用用户提供的文件名。文件大小限制，独立文件服务存储。

### SQL 注入

MyBatis 全部使用 `#{}` 参数化，禁止 `${}` 拼接用户输入（排序字段等场景需白名单校验后使用）。

## Spring Security

- BCrypt cost=12，通过 `SecurityConfig` Bean 注入，响应中 password 字段 `@JsonIgnore`
- JWT: HS256 签名，access_token 15-60min，refresh_token 7d
- **Algorithm Confusion 防护**：验证时显式指定允许的算法列表（`algorithms: ["HS256"]`），拒绝 `alg: none`，防止攻击者篡改算法
- Token 写入 Redis `{prefix}:token:{userId}:{jti}`，登出/强制下线时 JTI 加入黑名单

## 数据权限

通过 `DataScopeHelper` 控制：全部(1) / 自定义(2) / 仅自己(3)。Mapper XML 显式拼接条件，禁止拦截器隐式修改 SQL。

## References

See skill: `springboot-security` for Spring Security authentication and authorization patterns.
See skill: `security-review` for general security checklists.
