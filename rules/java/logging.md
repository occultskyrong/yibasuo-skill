---
paths:
  - "**/logback*.xml"
  - "**/application*.yml"
  - "**/application*.yaml"
---

# Java 日志——Logback 实现

> 通用规范见 [common/logging.md](../common/logging.md)。本文档为 Java/Spring Boot 特定实现。

## 框架

统一使用 Logback + SLF4J。禁止 `System.out.println` 和 `java.util.logging`。

## 日志格式（Logback XML）

### 控制台（dev）

```xml
<property name="CONSOLE_LOG_PATTERN"
    value="%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] [%X{traceId}] %highlight(%-5level) %cyan(%logger{50}:%L) - %msg%n"/>
```

### 文件（prod）

```xml
<property name="FILE_LOG_PATTERN"
    value="%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] [%X{traceId}] %-5level %logger{50}:%L - %msg%n"/>
```

生产环境去掉 `%highlight` 和 `%cyan`，容器日志工具不识别 ANSI 颜色码。

## 环境配置

```xml
<root level="WARN">          <!-- prod=WARN 屏蔽框架/中间件噪音 -->
    <appender-ref ref="ASYNC"/>
</root>
<logger name="com.yourproject" level="INFO" additivity="false">
    <appender-ref ref="ASYNC"/>
</logger>
```

## 异步写入

```xml
<appender name="ASYNC" class="ch.qos.logback.classic.AsyncAppender">
    <queueSize>512</queueSize>
    <discardingThreshold>0</discardingThreshold>
</appender>
```

| 参数 | 值 | 说明 |
|------|-----|------|
| queueSize | 512 | 队列容量 |
| discardingThreshold | **0** | 不丢弃，队列满时阻塞 |

## 文件滚动

```xml
<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
        <fileNamePattern>${LOG_FILE}.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
        <maxFileSize>10MB</maxFileSize>
        <maxHistory>30</maxHistory>
    </rollingPolicy>
</appender>
```

## 日志文件路径

```yaml
logging:
  file:
    name: ${user.home}/logs/${spring.application.name}.log
```

## 巡检清单

- [ ] Root 级别 prod=WARN，业务代码单独 INFO
- [ ] AsyncAppender + discardingThreshold=0
- [ ] 生产格式无彩色标记
- [ ] TraceId `%X{traceId}` 注入
