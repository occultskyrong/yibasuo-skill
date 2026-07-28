---
paths:
  - "**/*.ts"
  - "**/*.js"
  - "**/package.json"
---

# Node.js 日志——pino 实现

> 通用规范见 [common/logging.md](../common/logging.md)。NestJS 项目统一使用 `nestjs-pino`，禁止模板依赖 pino 却复制 winston 实现。

## 依赖与原则

- 依赖：`nestjs-pino`、`pino`、`pino-http`；`pino-pretty` 仅作为开发依赖
- dev 可用单行 pretty 输出；test/staging/prod 输出 JSON
- 容器只写 stdout/stderr；宿主机文件日志交给进程管理器和 logrotate，应用不自行创建全局日志目录
- `traceId` 从 AsyncLocalStorage 注入；请求头只接受 `[A-Za-z0-9._-]{1,64}`
- authorization、cookie、token、password、secret 等字段必须在 logger 层统一脱敏

## TraceId 上下文

```typescript
import { AsyncLocalStorage } from 'node:async_hooks';

type TraceStore = { traceId: string };

export const traceContext = new AsyncLocalStorage<TraceStore>();

export function getTraceId(): string {
  return traceContext.getStore()?.traceId ?? '';
}
```

```typescript
import { randomUUID } from 'node:crypto';

const VALID_TRACE_ID = /^[A-Za-z0-9._-]{1,64}$/;

const incoming = req.get('x-trace-id');
const traceId = incoming && VALID_TRACE_ID.test(incoming)
  ? incoming
  : randomUUID().replaceAll('-', '');

res.setHeader('X-Trace-Id', traceId);
traceContext.run({ traceId }, () => next());
```

Trace middleware 必须早于鉴权、请求日志和 Controller 注册。禁止直接信任任意长度或任意字符的外部 TraceId。

## LoggerModule

```typescript
import { LoggerModule } from 'nestjs-pino';
import { getTraceId } from './common/trace/trace.context';

const shanghaiFormatter = new Intl.DateTimeFormat('sv-SE', {
  timeZone: 'Asia/Shanghai',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  fractionalSecondDigits: 3,
  hourCycle: 'h23',
});

export function shanghaiTimestamp(): string {
  const parts = Object.fromEntries(
    shanghaiFormatter.formatToParts(new Date())
      .map(({ type, value }) => [type, value]),
  );
  const value = `${parts.year}-${parts.month}-${parts.day} `
    + `${parts.hour}:${parts.minute}:${parts.second}.${parts.fractionalSecond}`;
  return `,"timestamp":"${value}"`;
}

LoggerModule.forRoot({
  pinoHttp: {
    level: process.env.NODE_ENV === 'development' ? 'debug' : 'info',
    timestamp: shanghaiTimestamp,
    mixin: () => ({ traceId: getTraceId() }),
    redact: {
      paths: [
        'req.headers.authorization',
        'req.headers.cookie',
        'req.body.password',
        'req.body.token',
        'req.body.apiKey',
        'req.body.secret',
      ],
      censor: '***',
    },
    transport: process.env.NODE_ENV === 'development'
      ? {
          target: 'pino-pretty',
          options: {
            translateTime: false,
            singleLine: true,
          },
        }
      : undefined,
  },
});
```

在 `main.ts` 启动时接管 Nest logger：

```typescript
const app = await NestFactory.create(AppModule, { bufferLogs: true });
app.useLogger(app.get(Logger));
```

## 请求与业务日志

`pino-http` 自动记录请求完成事件。业务代码通过构造器注入 `PinoLogger`，使用结构化字段：

```typescript
this.logger.info(
  { userId, operation: 'CreateOrder', elapsedMs },
  'Order created',
);
```

- 禁止字符串拼接 JSON 或把整个 request/body 打入日志
- 未知异常记录完整 Error/stack，但客户端只返回安全消息
- staging 如需数据库 DEBUG，单独配置 ORM query logger；不要把全局日志级别降为 DEBUG

## 文件日志

容器环境只输出 JSON 到 stdout/stderr，由采集器负责持久化。非容器部署若必须写文件，使用 pino transport 写入明确路径，并由 systemd/PM2 + logrotate 管理大小与保留期；不得在业务进程中实现一套不受运维管理的滚动策略。
