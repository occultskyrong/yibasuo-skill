---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript 安全指南

> 本文件扩展 [common/security.md](../common/security.md) 的 TypeScript/JavaScript 特定内容。

## 密钥管理

**生产密钥**（支付、生产数据库密码、生产 JWT Secret）禁止硬编码，必须走环境变量。

**开发默认值**允许以 fallback 形式存在，但必须：

1. 注明是开发/测试密钥，不是生产密钥
2. 仅用于低风险场景（LLM provider、内网服务调用）
3. 生产环境通过环境变量覆盖

```typescript
// OK: 开发默认值，env 可覆盖
const apiKey = process.env.LLM_API_KEY || 'sk-dev-default-xxx'; // 开发环境 Bailian

// BAD: 生产密钥硬编码
const stripeKey = 'sk_live_xxx';

// 必须校验：关键密钥缺失直接报错
if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET not configured');
}
```

- 用 Zod 或 class-validator 在启动时校验所有 env 变量
- `process.env` 值始终是字符串，数字/布尔值需显式转换

## 进程退出策略

`unhandledRejection`：记录错误，不主动退出（编排层决定重启）。`uncaughtException`：进程处于不确定状态，记录错误后应退出（`process.exit(1)`），让编排层重启。

```typescript
process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled rejection', reason instanceof Error ? reason.stack : String(reason));
  // 不调用 process.exit(1)
});
```

## NestJS 安全配置

### Helmet

启用 Helmet 设置安全响应头：

```typescript
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(helmet());
  await app.listen(3000);
}
```

### CORS

严格限制来源，带凭证时不要用 `origin: '*'`：

```typescript
app.enableCors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') ?? ['http://localhost:3000'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
});
```

### 速率限制

使用 `@nestjs/throttler` 保护公开端点：

```typescript
imports: [ThrottlerModule.forRoot([{ ttl: 60000, limit: 20 }])]

// 敏感端点
@UseGuards(ThrottlerGuard)
@Post('login')
async login() { ... }
```

- 认证端点: 5 次/分钟/IP
- 公开 API: 20-60 次/分钟
- 内部 BFF→微服务: 跳过速率限制

### CSRF

基于 cookie 的会话需要 CSRF 保护（推荐 `csrf-csrf` 或 `@fastify/csrf-protection`，**禁止使用已废弃的 `csurf`**）。

JWT API（Bearer token）不需要 CSRF — 浏览器不会自动附加 `Authorization` 头。如果项目仅使用 JWT 鉴权，可不配置 CSRF。

## 输入验证

优先使用 Zod 做运行时校验。NestJS 用 `class-validator` 配合 `ValidationPipe`：

```typescript
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,              // 剥除未知字段
    forbidNonWhitelisted: true,   // 拒绝未知字段
    transform: true,
  }),
);
```

所有系统边界必须验证：

- [ ] HTTP 请求体（DTO 通过 ValidationPipe）
- [ ] URL 参数（`ParseUUIDPipe`、`ParseIntPipe`）
- [ ] Query 参数（class-validator on query DTO）
- [ ] 外部 API 响应（Zod schema）
- [ ] 文件上传（类型、大小、数量限制）

## SQL / NoSQL 注入

### 参数化查询

```typescript
// BAD — 字符串拼接
const rows = await db.query(`SELECT * FROM users WHERE name = '${name}'`);

// GOOD — 参数化
const rows = await db.query('SELECT * FROM users WHERE name = $1', [name]);
```

### ORM 原生查询

ORM 不防止所有注入 — 原生查询仍需注意：

```typescript
// BAD
await prisma.$queryRawUnsafe(`SELECT * FROM users WHERE name = '${name}'`);

// GOOD
await prisma.$queryRaw`SELECT * FROM users WHERE name = ${name}`;
```

### NoSQL 注入（MongoDB）

```typescript
// BAD — 用户输入直接作为查询条件
await collection.find({ username: req.body.username });

// GOOD — 类型校验后传入
if (typeof req.body.username !== 'string') {
  throw new BadRequestException('username must be a string');
}
const username = req.body.username;
await collection.find({ username });
```

## 认证

- 不要自研加密算法 — 使用成熟库（bcrypt、Argon2）
- 密码用 bcrypt 存储（cost factor = 12）：

```typescript
import * as bcrypt from 'bcrypt';
const hash = await bcrypt.hash(password, 12);
const match = await bcrypt.compare(password, hash);
```

- JWT Secret 必须 >= 256-bit 随机值，存于 env
- JWT 过期时间: access token 15-60 分钟，refresh token 7-14 天

## 错误消息

不在 API 响应中暴露内部信息（NestJS 用 number 数字 status 作为错误码，见 [api-response.md](../common/api-response.md)）：

```typescript
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();

    if (exception instanceof HttpException) {
      return response.status(exception.getStatus()).json({
        code: 2, // NestJS 数字 status（非 0 即为错误），非 200 场景
        message: '请求错误',
        data: null,
        requestId: getTraceId(),
        metadata: null,
      });
    }

    logger.error('Unhandled error', exception);
    return response.status(500).json({
      code: 99, // 未分类的内部错误
      message: 'Internal server error',
      data: null,
      requestId: getTraceId(),
      metadata: null,
    });
  }
}
```

- 不要返回 `error.stack` 给客户端
- 不要暴露数据库错误、文件路径、库内部信息

## 依赖安全

```bash
npm audit          # 或 pnpm audit
npm audit --audit-level=high   # CI 中: 遇到 HIGH/CRITICAL 直接失败
```

- CI 中运行 audit，HIGH 或 CRITICAL 级别失败
- 使用 Dependabot 或 Renovate 自动更新
- lockfile（`package-lock.json` / `pnpm-lock.yaml`）必须提交

## Agent 支持

- 使用 **security-reviewer** agent 进行综合安全审计
- 参见 skill: `security-review`
