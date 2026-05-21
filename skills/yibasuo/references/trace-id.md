# TraceId 规范

> 微服务全链路日志串联。新增/修改日志相关代码时必须遵守。

## 统一约定

| 项 | 值 |
|-----|----|
| HTTP Header | `X-Trace-Id` |
| MDC Key | `traceId` |
| Logback 格式 | `%X{traceId}` → `[abc12345]` |
| winston 格式 | `format((info) => { info.traceId = getTraceId(); return info; })()` → `[abc12345]` |
| 生成规则 | `UUID.randomUUID().toString().replace("-", "").substring(0, 8)` |
| 幂等 | 优先使用请求头已有值，没有才生成。下游不重复生成 |

## 各层实现模式

### Gateway（Spring Cloud Gateway / WebFlux）

**AuthFilter**（最先执行）：

```java
// 1. 优先读已有 header，没有则生成
String headerTraceId = exchange.getRequest().getHeaders().getFirst("X-Trace-Id");
String traceId = (headerTraceId != null && !headerTraceId.isEmpty())
        ? headerTraceId
        : UUID.randomUUID().toString().replace("-", "").substring(0, 8);

// 2. 写入响应头（关键！后续 filter 从这里读）
exchange.getResponse().getHeaders().set("X-Trace-Id", traceId);

// 3. 转发时注入下游请求头
builder.header("X-Trace-Id", traceId);

// 4. 写入 Reactor context（网关内部 log 用）
.contextWrite(ctx -> ctx.put("traceId", traceId));
```

**ResponseLogFilter / 其他 filter 如何拿到 traceId：**

> **不要**从 MDC 或 Reactor context 读。WebFlux 线程切换后两者都会丢。

```java
// ✅ 正确：直接读响应头（AuthFilter 已写入，不随线程切换丢失）
String traceId = exchange.getResponse().getHeaders().getFirst("X-Trace-Id");
if (traceId != null && !traceId.isEmpty()) {
    MDC.put("traceId", traceId);
}
```

**网关 Logback 注意：**

- `%X{traceId}` 只能从 MDC 读
- 必须在当前线程手动 `MDC.put/remove`（如 ResponseLogFilter）
- `contextWrite` 只存 Reactor context，不自动同步到 MDC
- 全局 MDC 传播方案（`Hooks.enableAutomaticContextPropagation`、`reactor-extra`）在 SB 4.0 下经实测均不生效

### BFF / Spring Boot（Servlet）

```java
// TraceIdFilter: 最先执行的 Filter（@Order(HIGHEST_PRECEDENCE)）
String traceId = httpRequest.getHeader("X-Trace-Id");
if (traceId == null || traceId.isEmpty()) {
    traceId = UUID.randomUUID().toString().replace("-", "").substring(0, 8);
}
MDC.put("traceId", traceId);
httpResponse.setHeader("X-Trace-Id", traceId);

// 转发到下游时（如 RestClient）
String traceId = MDC.get("traceId");
if (traceId != null && !traceId.isEmpty()) {
    spec.header("X-Trace-Id", traceId);  // null-safe：判空后再设
}
```

Logback pattern（同时适用于 gateway 和 BFF）：
```xml
<pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] [%X{traceId}] %-5level %logger{50}:%L - %msg%n</pattern>
```

### NestJS / ai-foundation

**TraceMiddleware**：

```typescript
// src/common/trace/trace.middleware.ts
const traceId = req.get('x-trace-id') || genTraceId();
res.setHeader('X-Trace-Id', traceId);
traceContext.run({ traceId }, () => next());
```

**traceContext**（AsyncLocalStorage）：

```typescript
// src/common/trace/trace.context.ts
export const traceContext = new AsyncLocalStorage<TraceContext>();
export function getTraceId(): string {
  return traceContext.getStore()?.traceId ?? '';
}
```

**AppLoggerService** 注入 traceId：

```typescript
// winston format 中注入
format((info) => {
  info.traceId = getTraceId();
  return info;
})(),

// console printf 中输出
const tid = traceId ? `[${traceId}] ` : '';
return `${timestamp} [${level}] ${tid}${ctx}${message}${stackTrace}`;
```

**中间件注册顺序**（TraceMiddleware 必须最先）：

```typescript
consumer.apply(TraceMiddleware, LoggerMiddleware, CorsMiddleware).forRoutes('*');
```

### 前端（pts-admin）

前端不生成 traceId，由 Gateway 统一生成。前端只需在 SSE 的 `createSSEConnection` 中透传 gateway 返回的响应头即可（浏览器自动带上后续请求的 cookie/header 不需要额外处理）。

## 审查检查清单

新增或修改服务间调用时，必须检查：

- [ ] Gateway AuthFilter 是否将 `X-Trace-Id` 写入**响应头**和**下游请求头**
- [ ] Gateway ResponseLogFilter 是否从**响应头**（非 MDC/context）读取 traceId
- [ ] Spring Boot TraceIdFilter 是否读取请求头 `X-Trace-Id`
- [ ] Spring Boot 转发 RestClient 是否带上 `X-Trace-Id` header（null-safe）
- [ ] NestJS TraceMiddleware 是否注册在最前面
- [ ] winston/Logback 日志格式是否包含 traceId
- [ ] 测试验证：`curl -sI` 看响应头是否有 `X-Trace-Id`
- [ ] 测试验证：三个服务日志中同一请求的 traceId 是否相同
