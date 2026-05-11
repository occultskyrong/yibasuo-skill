---
paths:
  - "**/logback*.xml"
  - "**/application*.yml"
  - "**/application*.yaml"
---

# 微服务日志规范

> 适用于 Spring Boot 微服务项目，日志框架统一使用 Logback。

## 日志级别

### 环境分级

| 环境 | Root 级别 | 业务代码 | SQL 日志 |
|------|-----------|---------|----------|
| local | INFO | DEBUG | DEBUG |
| dev | INFO | DEBUG | DEBUG |
| staging | INFO | INFO | DEBUG（mapper 包） |
| prod | **WARN** | INFO | INFO 或关闭 |

生产环境 Root 设为 WARN 的目的是屏蔽框架和中间件（Spring、Netty、Lettuce 等）的 INFO/DEBUG 噪音，业务代码通过自定义 logger 单独设为 INFO。

### 配置方式

```xml
<!-- logback-spring.xml -->
<root level="WARN">
    <appender-ref ref="ASYNC"/>
</root>

<logger name="com.yourproject" level="INFO" additivity="false">
    <appender-ref ref="ASYNC"/>
</logger>
```

不要直接在 application.yml 中配置 logging.level，统一在 logback-spring.xml 中管理，利用 Spring Profile 区分环境。

## 日志格式

### 控制台格式

```xml
<property name="CONSOLE_LOG_PATTERN"
    value="%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] [%X{traceId}] %highlight(%-5level) %cyan(%logger{50}:%L) - %msg%n"/>
```

### 文件格式

```xml
<property name="FILE_LOG_PATTERN"
    value="%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] [%X{traceId}] %-5level %logger{50}:%L - %msg%n"/>
```

### 字段说明

| 字段 | 格式 | 必要性 | 说明 |
|------|------|--------|------|
| 时间戳 | `%d{yyyy-MM-dd HH:mm:ss.SSS}` | 必须 | 精确到毫秒 |
| 线程 | `[%thread]` | 必须 | 排查并发问题 |
| TraceId | `[%X{traceId}]` | **强烈推荐** | 链路追踪入口，无 APM 时手动塞入 MDC |
| 日志级别 | `%-5level` | 必须 | 左对齐 5 字符 |
| Logger + 行号 | `%logger{50}:%L` | 必须 | 50 是包名截断长度，行号仅在本地/dev 使用 |
| 消息 | `%msg` | 必须 | — |
| 换行 | `%n` | 必须 | 携带异常堆栈 |

### 注意事项

- **生产环境控制台用纯文本**（不加 `%highlight`、`%cyan`），容器日志采集工具（如 ELK、Loki）不识别 ANSI 颜色码
- **本地/dev 可用彩色格式**，方便开发调试
- `%logger{50}` 会把 `com.jiachen.module.system.service.impl.UserServiceImpl` 截断为 `c.j.m.system.service.impl.UserServiceImpl`
- `%L` 有性能损耗，生产环境可去掉或用 `%M`（方法名）替代

## 文件滚动策略

```xml
<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
        <fileNamePattern>${LOG_FILE}.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
        <maxFileSize>10MB</maxFileSize>
        <maxHistory>30</maxHistory>
        <totalSizeCap>3GB</totalSizeCap>
    </rollingPolicy>
    <encoder>
        <pattern>${FILE_LOG_PATTERN}</pattern>
    </encoder>
</appender>
```

| 参数 | 值 | 说明 |
|------|-----|------|
| 单文件上限 | 10 MB | `maxFileSize` |
| 保留天数 | 30 天 | `maxHistory` |
| 总容量上限 | 3 GB | `totalSizeCap`，可选 |
| 滚动方式 | 按天 + 按大小 | `SizeAndTimeBasedRollingPolicy` |
| 文件命名 | `{appName}.log.{日期}.{序号}.log` | — |

## 异步写入

所有文件输出必须用异步 Appender，避免日志 I/O 阻塞业务线程：

```xml
<appender name="ASYNC" class="ch.qos.logback.classic.AsyncAppender">
    <appender-ref ref="FILE"/>
    <queueSize>512</queueSize>
    <discardingThreshold>0</discardingThreshold>
    <neverBlock>false</neverBlock>
</appender>
```

| 参数 | 值 | 说明 |
|------|-----|------|
| queueSize | 512 | 队列容量，默认 256，微服务建议 512 |
| discardingThreshold | **0** | 关键：不丢弃日志，队列满时阻塞而非丢 |
| neverBlock | false | 队列满时阻塞调用线程，确保不丢日志 |

## 输出目标

| 目标 | local/dev | staging | prod |
|------|-----------|---------|------|
| 控制台（STDOUT） | 彩色格式 | 彩色格式 | **纯文本** |
| 文件 | 可选 | 必须 | 必须 |
| 链路追踪 | — | SkyWalking 或其他 APM | 必须接入 |

### 日志文件路径

```yaml
# application.yml
logging:
  file:
    name: ${user.home}/logs/${spring.application.name}.log
```

不要在代码中硬编码路径。容器化部署时可通过环境变量覆盖：`LOGGING_FILE_NAME=/var/log/app.log`。

## 关键业务日志规范

### 必须记录的内容

| 场景 | 级别 | 内容 |
|------|------|------|
| 请求进入 | DEBUG | URL、HTTP 方法、来源 IP |
| 请求完成 | INFO | URL、耗时（ms）、响应状态码 |
| 数据库操作 | DEBUG | SQL 语句、参数、耗时（仅 staging/dev） |
| 外部 API 调用 | INFO | 目标 URL、耗时、响应码 |
| 业务异常 | WARN | 业务描述 + 关键参数（如"订单不存在: id=123"） |
| 系统异常 | ERROR | 完整堆栈 |
| 认证/鉴权失败 | WARN | 用户标识、尝试的操作、失败原因 |
| 定时任务 | INFO | 任务名、耗时、处理条数 |

### 禁止记录的内容

- **密码、Token、密钥** — 绝对不能在日志中出现明文
- **完整手机号/身份证** — 脱敏处理（如 `138****1234`）
- **大对象** — 超过 1KB 的 JSON 应截断
- **无意义的堆栈** — 不要 `log.error(e.getMessage())`，应该传异常对象 `log.error("...", e)`

### 日志方法选择

```java
// GOOD — 传异常对象，保留完整堆栈
log.error("Failed to process order: id={}", orderId, exception);

// BAD — 只打印消息，堆栈丢失
log.error("Failed to process order: " + exception.getMessage());

// GOOD — 用占位符，避免字符串拼接
log.info("User login: userId={}, ip={}", userId, ip);

// BAD — 字符串拼接，即使日志级别关闭也会执行
log.info("User login: userId=" + userId + ", ip=" + ip);
```

## 配置巡检清单

- [ ] logback-spring.xml 是否存在
- [ ] Root 级别是否按环境设定（prod=WARN）
- [ ] 是否配置了 AsyncAppender
- [ ] 文件格式是否包含 TraceId 占位符
- [ ] 生产环境控制台是否关闭彩色输出
- [ ] 文件滚动策略是否合理（10MB/30天）
- [ ] 是否设置了 `discardingThreshold=0`
- [ ] 敏感信息是否已脱敏
