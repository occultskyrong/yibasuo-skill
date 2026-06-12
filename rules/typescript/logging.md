---
paths:
  - "**/*.ts"
  - "**/*.js"
  - "**/package.json"
---

# Node.js 日志——pino 实现

> 通用规范见 [common/logging.md](../common/logging.md)。本文档为 NestJS/Node.js 特定实现。

## 框架

首选 pino（极致性能，NestJS 内置集成），备选 winston。

## 日志格式

### 本地/dev — pino-pretty 可读

```typescript
const logger = pino({
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'yyyy-mm-dd HH:MM:ss.l',
      messageFormat: '[{traceId}] {levelLabel} {caller} - {msg}',
    },
  },
  mixin() {
    return { traceId: getTraceIdFromAsyncContext() ?? '-' };
  },
});
```

### staging/prod — 结构化 JSON

```typescript
const logger = pino({
  level: 'info',
  // 不配置 transport，默认输出 JSON
});
```

## TraceId 注入

```typescript
import { AsyncLocalStorage } from 'async_hooks';
const traceContext = new AsyncLocalStorage<{ traceId: string }>();

// middleware 中设置
traceContext.run({ traceId }, () => next());

// pino mixin 中取出
mixin() {
  return { traceId: traceContext.getStore()?.traceId ?? '-' };
}
```

## 环境配置

```typescript
// NestJS — main.ts
const app = await NestFactory.create(AppModule, {
  logger: ['error', 'warn', 'log', 'debug'].filter(level => {
    if (process.env.NODE_ENV === 'production' && ['debug'].includes(level)) {
      return false;
    }
    return true;
  }),
  bufferLogs: true,
});
```

## 容器部署

直接写 stdout，由容器日志驱动接管滚动和采集。
