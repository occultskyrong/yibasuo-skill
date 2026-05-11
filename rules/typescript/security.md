---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript Security

> This file extends [common/security.md](../common/security.md) with TypeScript/JavaScript specific content.

## Secret Management

```typescript
// NEVER: Hardcoded secrets
const apiKey = "sk-proj-xxxxx"

// ALWAYS: Environment variables, validated at startup
const apiKey = process.env.OPENAI_API_KEY

if (!apiKey) {
  throw new Error('OPENAI_API_KEY not configured')
}
```

- Use Zod or class-validator to validate all env vars at boot
- `process.env` values are always strings — parse numbers/booleans explicitly

## NestJS Security

### Helmet

Enable Helmet for secure HTTP headers:

```typescript
// main.ts
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(helmet());
  await app.listen(3000);
}
```

### CORS

Restrict origins explicitly — never use `origin: '*'` with credentials:

```typescript
app.enableCors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') ?? ['http://localhost:3000'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
});
```

### Rate Limiting

Use `@nestjs/throttler` on public endpoints:

```typescript
// app.module.ts
imports: [
  ThrottlerModule.forRoot([{ ttl: 60000, limit: 20 }]),
]

// On sensitive endpoints
@UseGuards(ThrottlerGuard)
@Post('login')
async login() { ... }
```

- Auth endpoints: 5 req/min per IP
- Public APIs: 20-60 req/min default
- Internal BFF → Service calls: skip rate limiting

### CSRF

If using cookie-based sessions:

```typescript
import * as csurf from 'csurf';
app.use(csurf({ cookie: true }));
```

For JWT-based APIs (Bearer token in `Authorization` header), CSRF is not needed — browsers don't auto-attach `Authorization` headers.

## Input Validation

Zod is preferred for runtime validation. For NestJS, use `class-validator` with `ValidationPipe`:

```typescript
// main.ts
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,              // strip unknown properties
    forbidNonWhitelisted: true,   // reject unknown properties
    transform: true,
  }),
);
```

Validate at all system boundaries:
- [ ] HTTP request body (DTO validation via ValidationPipe)
- [ ] URL params (`ParseUUIDPipe`, `ParseIntPipe`)
- [ ] Query strings (class-validator on query DTOs)
- [ ] External API responses (Zod schema)
- [ ] File uploads (file type, size, count limits)

## SQL / NoSQL Injection

### Parameterized queries (raw SQL)

```typescript
// BAD — string interpolation
const rows = await db.query(`SELECT * FROM users WHERE name = '${name}'`);

// GOOD — parameterized
const rows = await db.query('SELECT * FROM users WHERE name = $1', [name]);
```

### ORM injection (Prisma / TypeORM)

ORMs don't prevent all injections — be careful with raw queries:

```typescript
// BAD — raw query with unsanitized input
await prisma.$queryRawUnsafe(`SELECT * FROM users WHERE name = '${name}'`);

// GOOD — parameterized
await prisma.$queryRaw`SELECT * FROM users WHERE name = ${name}`;
```

### NoSQL injection (MongoDB)

```typescript
// BAD — user input directly in query object
await collection.find({ username: req.body.username });

// GOOD — type-check and sanitize
const username = String(req.body.username);
await collection.find({ username });
```

## Authentication

- Never implement custom crypto — use established libraries (bcrypt, Argon2)
- Store passwords with bcrypt (cost factor >= 10):

```typescript
import * as bcrypt from 'bcrypt';

const hash = await bcrypt.hash(password, 10);
const match = await bcrypt.compare(password, hash);
```

- JWT secrets must be >= 256-bit random, stored in env vars
- Set reasonable JWT expiry (access token: 15-60 min, refresh token: 7-14 days)

## Error Messages

Never expose internals in API responses:

```typescript
// Exception filter — log detail, return safe message
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();

    if (exception instanceof HttpException) {
      return response.status(exception.getStatus()).json({
        status: 2,
        message: exception.message,  // safe — these are intentional
      });
    }

    // Unexpected — log full detail, return generic
    logger.error('Unhandled error', exception);
    return response.status(500).json({
      status: 99,
      message: 'Internal server error',
    });
  }
}
```

- Never return `error.stack` to clients
- Never expose database errors, file paths, or library internals

## Dependency Security

```bash
# Audit dependencies
npm audit
# OR
pnpm audit

# For CI: fail on high/critical
npm audit --audit-level=high
```

- Run audit in CI, fail on HIGH or CRITICAL
- Use Dependabot or Renovate for automated updates
- Lockfiles (`package-lock.json` / `pnpm-lock.yaml`) must be committed

## Agent Support

- Use **security-reviewer** agent for comprehensive security audits
- See skill: `security-review` for general security checklists

## References

See skill: `nestjs-patterns` for NestJS auth guards and exception filter patterns.
