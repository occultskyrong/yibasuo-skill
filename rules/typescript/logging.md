---
paths:
  - "**/*.ts"
  - "**/*.js"
  - "**/package.json"
---

# Node.js 日志规范

> 适用于 NestJS/Express 等 Node.js 服务端项目，日志框架统一使用 pino（或 winston）。

## 日志库选择

| 库 | 适用场景 |
|----|---------|
| **pino** | 首选，极致性能，原生结构化 JSON，NestJS 内置集成 |
| **winston** | 需要复杂 transports 组合时使用 |

无特殊原因时，默认使用 pino。

## 日志级别

### 环境分级

| 环境 | Root 级别 | 业务代码 | 数据库查询 |
|------|-----------|---------|-----------|
| local | debug | debug | debug |
| dev | debug | debug | debug |
| staging | info | info | debug |
| prod | **info** | info | info 或关闭 |

生产环境避免 debug 级别，因为 ORM/驱动层的大量 debug 日志会淹没业务日志。

### 配置方式

```typescript
// NestJS — main.ts
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'debug'].filter(level => {
      // 生产环境去掉 debug 和 verbose
      if (process.env.NODE_ENV === 'production' && ['debug', 'verbose'].includes(level)) {
        return false;
      }
      return true;
    }),
    bufferLogs: true,
  });

  // 注入自定义 logger（pino adapter）
  app.useLogger(app.get(Logger));
}
```

```typescript
// 通用 Node.js — pino
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL ?? (process.env.NODE_ENV === 'production' ? 'info' : 'debug'),
});
```

## 日志格式

### 本地/dev — 可读格式

```typescript
const logger = pino({
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'yyyy-mm-dd HH:MM:ss.l',
      ignore: 'pid,hostname',
      messageFormat: '[{traceId}] {levelLabel} {caller} - {msg}',
    },
  },
  // traceId 从请求上下文注入
  mixin() {
    return { traceId: getTraceIdFromAsyncContext() ?? '-' };
  },
});
```

输出效果：
```
2026-05-11 14:30:01.234 [abc123] INFO  UsersService:42 - User created: id=1
```

与 Java 格式对齐：`时间 [traceId] 级别 来源:行号 - 消息`（Java 多 `[线程]` 字段）

### staging/prod — 结构化 JSON

```typescript
const logger = pino({
  level: 'info',
  // 不配置 transport，pino 默认输出 JSON
});
```

每行一条 JSON，便于 ELK / Loki / Datadog 采集：
```json
{"level":"info","time":"2026-05-11T14:30:01.234Z","traceId":"abc123","msg":"User created: id=1"}
```

### 嵌套字段说明

| 字段 | 必要性 | 说明 |
|------|--------|------|
| `level` | 必须 | error / warn / info / debug |
| `time` | 必须 | ISO 8601，pino 自动注入 |
| `traceId` | **强烈推荐** | 链路追踪入口，无 APM 时手动塞入 |
| `msg` | 必须 | 日志消息 |
| `context` | 推荐 | NestJS: 类名，便于定位来源 |
| `err` | 错误时 | pino 自动序列化 Error 对象（message + stack） |

## 请求日志

### NestJS — 全局中间件或拦截器

```typescript
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(ctx: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = ctx.switchToHttp().getRequest();
    const { method, url } = request;
    const start = Date.now();

    return next.handle().pipe(
      tap(() => {
        const response = ctx.switchToHttp().getResponse();
        const elapsed = Date.now() - start;
        this.logger.log(`${method} ${url} ${response.statusCode} ${elapsed}ms`);
      }),
    );
  }
}
```

### 通用中间件

```typescript
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    logger.info({
      method: req.method,
      url: req.url,
      status: res.statusCode,
      ms: Date.now() - start,
    });
  });
  next();
});
```

## 日志文件与滚动

Node.js 生态通常依赖容器/平台收集日志（stdout → Docker → ELK/Loki），但如需本地文件：

```typescript
import pino from 'pino';
import { pino } from 'pino';
import { createWriteStream } from 'fs';
import { createRotatingFileStream } from 'rotating-file-stream';

// 按天滚动
const stream = createRotatingFileStream('app.log', {
  interval: '1d',
  maxFiles: 30,
  path: '/var/log/myapp/',
});

const logger = pino(stream);
```

容器化部署时**推荐直接写 stdout**，由容器日志驱动接管滚动和采集。

## 输出目标

| 目标 | local/dev | staging | prod |
|------|-----------|---------|------|
| 控制台（stdout） | pino-pretty 彩色 | pino-pretty 彩色 | **纯 JSON** |
| 文件 | 可选 | 可选 | 容器 stdout |
| 外部平台 | — | — | ELK / Loki / Datadog |

## 关键业务日志规范

### 必须记录的内容

| 场景 | 级别 | 内容 |
|------|------|------|
| 请求进入 | debug | method、URL、来源 IP |
| 请求完成 | info | method、URL、耗时（ms）、响应状态码 |
| 外部 API 调用 | info | 目标 URL、耗时、响应码 |
| 数据库慢查询 | warn | SQL 摘要、耗时 |
| 业务异常 | warn | 业务描述 + 关键参数（如"订单不存在: id=123"） |
| 系统异常 | error | 完整 Error 对象 |
| 认证/鉴权失败 | warn | 用户标识、尝试的操作、失败原因 |
| 定时任务 | info | 任务名、耗时、处理条数 |

### 禁止记录的内容

- **密码、Token、密钥** — 绝对不能出现在日志中
- **完整手机号/身份证** — 脱敏（如 `138****1234`）
- **大对象** — 超过 1KB 的 JSON 应截断
- **纯字符串 Error** — 必须传 Error 对象，保留完整堆栈

### 日志方法选择

```typescript
// GOOD — 传 Error 对象，保留完整堆栈
logger.error({ err: error, userId }, 'Failed to process order');

// BAD — 只打印消息，堆栈丢失
logger.error('Failed to process order: ' + error.message);

// GOOD — 结构化字段，便于检索
logger.info({ userId, ip }, 'User login');

// BAD — 字符串拼接，字段丢失
logger.info('User login: userId=' + userId + ', ip=' + ip);
```

NestJS 内置 Logger：
```typescript
// GOOD — 对象作为第二个参数
this.logger.error({ userId, orderId }, 'Order creation failed', error.stack);

// BAD
this.logger.error('Order creation failed: ' + error.message);
```

## 配置巡检清单

- [ ] 生产环境是否使用结构化 JSON 输出
- [ ] 是否包含 traceId / correlationId
- [ ] 敏感信息是否已脱敏
- [ ] 错误日志是否传递了 Error 对象（非 message 字符串）
- [ ] 请求日志是否记录了 method、URL、status、耗时
- [ ] 生产环境日志级别是否为 info 或以上
- [ ] 是否通过 pino-abstract-transport 或类似方式异步写日志
- [ ] 容器化部署时是否输出到 stdout 而非本地文件
