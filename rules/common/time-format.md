# 时间格式

**统一传输格式：** `yyyy-MM-dd HH:mm:ss.SSS`（精确到毫秒）

API 输入/输出、JSON 序列化、数据库 DateTime、日志时间戳均使用此格式。

- 时区统一 `Asia/Shanghai`
- 禁止使用 `yyyy-MM-dd'T'HH:mm:ss`（ISO 8601 不完整）、禁止仅到秒（`yyyy-MM-dd HH:mm:ss`）

## Java

```java
// Jackson 全局配置
@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss.SSS", timezone = "Asia/Shanghai")
private LocalDateTime createdAt;

// 格式化
DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS");
```

## TypeScript

```typescript
// dayjs 格式化
dayjs().format('YYYY-MM-DD HH:mm:ss.SSS');

// pino 自定义 timestamp（完整实现见 rules/typescript/logging.md）
timestamp: shanghaiTimestamp,
```
