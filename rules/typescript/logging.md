---
paths:
  - "**/*.ts"
  - "**/*.js"
  - "**/package.json"
---

# Node.js 日志——winston 实现

> 通用规范见 [common/logging.md](../common/logging.md)。基于 ai-foundation 项目实现。

## 框架

使用 **winston**（NestJS 官方推荐，ai-foundation/pts-server 已验证）。

## LoggerService 实现

```typescript
import { Injectable, LoggerService } from '@nestjs/common';
import { createLogger, format, transports, Logger } from 'winston';
import { getTraceId } from 'src/common/trace/trace.context';

@Injectable()
export class AppLoggerService implements LoggerService {
  private logger: Logger;

  constructor() {
    const logDir = path.join(process.cwd(), 'logs');
    if (!fs.existsSync(logDir)) fs.mkdirSync(logDir, { recursive: true });

    const isDev = (process.env.NODE_ENV || 'development') === 'development';

    this.logger = createLogger({
      level: isDev ? 'debug' : 'info',
      format: format.combine(
        format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
        format.errors({ stack: true }),
        format((info) => { info.traceId = getTraceId(); return info; })(),
        format.json(),
      ),
      transports: [
        new transports.File({
          filename: path.join(logDir, 'error.log'), level: 'error',
          maxsize: 5242880, maxFiles: 5,
        }),
        new transports.File({
          filename: path.join(logDir, 'combined.log'),
          maxsize: 5242880, maxFiles: 5,
        }),
      ],
    });

    // 控制台：dev 彩色，prod 纯文本
    this.logger.add(new transports.Console({
      format: format.combine(
        format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
        ...(isDev ? [format.colorize()] : []),
        format((info) => {
          const { timestamp, level, context, traceId } = info;
          const ctx = context ? `[${context}] ` : '';
          const tid = traceId ? `[${traceId}] ` : '';
          const msg = typeof info.message === 'object' ? JSON.stringify(info.message) : info.message;
          const stack = info.stack ? `\n${info.stack}` : '';
          return `${timestamp} [${level}] ${tid}${ctx}${msg}${stack}`;
        })(),
      ),
    }));
  }

  log(message: any, context?: string) { this.logger.info({ message, context }); }
  error(message: any, trace?: string, context?: string) { this.logger.error({ message, context, stack: trace }); }
  warn(message: any, context?: string) { this.logger.warn({ message, context }); }
  debug(message: any, context?: string) { this.logger.debug({ message, context }); }
  verbose(message: any, context?: string) { this.logger.verbose({ message, context }); }
  setContext(context: string) { /* 用于 NestJS Logger 接口兼容 */ }
}
```

### 输出格式

```
2026-06-08 10:30:01.234 [info] [abc123] [HTTP] GET /api/users 200 45ms
```

## 请求日志中间件

```typescript
@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  constructor(private readonly logger: AppLoggerService) {
    logger.setContext('HTTP');
  }

  use(req: Request, res: Response, next: NextFunction) {
    const start = Date.now();
    const ip = req.ip;
    const { method, originalUrl: url } = req;

    res.on('finish', () => {
      const elapsed = Date.now() - start;
      const status = res.statusCode;
      this.logger.log(`${ip} - ${method} ${url} - Status: ${status} - ${elapsed}ms`);
    });
    next();
  }
}
```

## 敏感信息过滤

```typescript
private sanitizeBody(body: any): any {
  if (!body || typeof body !== 'object') return body;
  const sanitized = { ...body };
  for (const field of ['password', 'token', 'apiKey', 'secret']) {
    if (sanitized[field]) sanitized[field] = '***';
  }
  return sanitized;
}
```

## TraceId 注入

```typescript
import { AsyncLocalStorage } from 'async_hooks';
const traceContext = new AsyncLocalStorage<{ traceId: string }>();

// middleware 中设置
traceContext.run({ traceId: req.get('x-trace-id') || crypto.randomUUID() }, () => next());

// logger 中取出
function getTraceId(): string {
  return traceContext.getStore()?.traceId ?? '-';
}
```

## 文件滚动

winston `maxsize` + `maxFiles` 自动管理：单文件 5MB，最多 5 个文件。容器部署直接写 stdout，不写本地文件。
