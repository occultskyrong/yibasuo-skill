# 日志规范

> 通用日志规范。语言特定实现见 `rules/java/logging.md`（Logback）和 `rules/typescript/logging.md`（pino）。

## 日志级别

### 环境分级

| 环境 | 业务代码 | 数据库查询 |
| ------ | --------- | ----------- |
| local/dev | DEBUG | DEBUG |
| staging | INFO | DEBUG |
| prod | INFO | INFO 或关闭 |

Java 生产环境 Root 设为 WARN（屏蔽框架噪音），业务代码通过自定义 logger 单独设 INFO。

## 日志格式

### 字段要求

| 字段 | 必要性 | 说明 |
| ------ | :---: | ------ |
| 时间戳 | 必须 | `yyyy-MM-dd HH:mm:ss.SSS`（精确到毫秒） |
| TraceId | **必须** | `[%X{traceId}]`（Java MDC）或 `{traceId}`（TS AsyncLocalStorage），无 APM 时手动塞入 |
| 日志级别 | 必须 | ERROR / WARN / INFO / DEBUG |
| Logger/上下文 | 必须 | Java 类名:行号；TS logger context（行号仅在采集器可靠提供时记录） |
| 消息 | 必须 | 占位符格式，禁止字符串拼接 |

### 本地/dev — 可读格式

```text
2026-05-11 14:30:01.234 [abc123] INFO  UsersService:42 - User created: id=1
```

### staging/prod — 结构化 JSON

```json
{"level":"info","timestamp":"2026-05-11 14:30:01.234","traceId":"abc123","logger":"UsersService","line":42,"msg":"User created: id=1"}
```

- 生产环境禁用彩色输出（ELK/Loki 不识别 ANSI 颜色码）
- 容器部署直接写 stdout，由容器日志驱动接管滚动和采集

## 业务日志规范

### 必须记录

| 场景 | 级别 | 内容 |
| ------ | ------ | ------ |
| 请求进入 | DEBUG | method、URL、来源 IP |
| 请求完成 | INFO | method、URL、耗时（ms）、响应状态码 |
| 外部 API 调用 | INFO | 目标 URL、耗时、响应码 |
| 数据库慢查询 | WARN | SQL 摘要、耗时 |
| 业务异常 | WARN | 业务描述 + 关键参数（如"订单不存在: id=123"） |
| 系统异常 | ERROR | 完整 Error 对象（传异常对象，禁止只传 message） |
| 认证/鉴权失败 | WARN | 用户标识、尝试的操作、失败原因 |
| 定时任务 | INFO | 任务名、耗时、处理条数 |

### 禁止记录

- 密码、Token、密钥 — 绝对不能出现在日志中
- 完整手机号/身份证 — 脱敏（如 `138****1234`）
- 大对象 — 超过 1KB 的 JSON 应截断
- 只传 `e.getMessage()` — 必须传 Error 对象保留完整堆栈

### 占位符

```java
// GOOD — 占位符，避免字符串拼接
log.info("User login: userId={}, ip={}", userId, ip);

// BAD — 字符串拼接，即使级别关闭也会执行
log.info("User login: userId=" + userId + ", ip=" + ip);
```

## 输出目标

| 目标 | local/dev | staging | prod |
| ------ | ----------- | --------- | ------ |
| 控制台 | 彩色可读 | JSON | JSON |
| 文件 | 可选 | 非容器部署由进程管理器负责 | 容器 stdout；非容器由进程管理器负责 |
| 链路追踪 | — | — | ELK / Loki / Datadog |

## 审查清单

- [ ] 日志格式包含 TraceId
- [ ] 生产环境禁用彩色输出
- [ ] 敏感信息已脱敏
- [ ] 异常传 Error 对象，非 `e.getMessage()`
- [ ] 使用占位符，非字符串拼接
- [ ] 定时任务输出汇总日志（任务名/耗时/条数）
