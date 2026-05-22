---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript Patterns

> This file extends [common/patterns.md](../common/patterns.md) with TypeScript/JavaScript specific content.

## NestJS Layered Architecture

严格分层，绝不越层调用：

```
Controller → Service → Repository → Database
   │            │          │
   ▼            ▼          ▼
  HTTP       Business    Data
  parsing    logic       access
```

### Controller

Thin. Parse HTTP input, delegate to service, return DTO:

```typescript
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get(':id')
  async getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.getById(id);
  }

  @Post()
  async create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto);
  }
}
```

### Service

所有业务逻辑放这里。不直接暴露 Entity，通过 DTO 映射：

```typescript
@Injectable()
export class UsersService {
  constructor(private readonly usersRepo: UsersRepository) {}

  async getById(id: string): Promise<UserResponse> {
    const user = await this.usersRepo.findById(id);
    if (!user) throw new NotFoundException(`User not found: ${id}`);
    return UserResponse.from(user);
  }
}
```

### Repository

封装数据访问。用 Prisma、TypeORM 或原生 DB 驱动，对外暴露干净接口：

```typescript
@Injectable()
export class UsersRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }
}
```

## Dependency Injection

Always **constructor injection**. Never property/field injection:

```typescript
// GOOD — constructor injection (testable, immutable, explicit)
@Injectable()
export class OrdersService {
  constructor(
    private readonly ordersRepo: OrdersRepository,
    private readonly paymentGateway: PaymentGateway,
  ) {}
}

// BAD — property injection (untestable, hidden dependencies)
@Injectable()
export class OrdersService {
  @Inject() private ordersRepo: OrdersRepository;
}
```

## DTO Patterns

### Request DTOs — class-validator

```typescript
export class CreateUserDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(2, 80)
  name!: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}
```

### Response DTOs — plain objects or classes with static factory

```typescript
export class UserResponse {
  id: string;
  email: string;
  name: string;

  static from(entity: User): UserResponse {
    return { id: entity.id, email: entity.email, name: entity.name };
  }
}
```

- Request DTOs use `class-validator` decorators for automatic validation
- Response DTOs strip internal fields (password hashes, tokens, audit columns)
- Never return ORM entities directly from controllers

## Global Validation Pipe

在 `main.ts` 中一次配置：

```typescript
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,              // strip unknown properties
    forbidNonWhitelisted: true,   // reject unknown properties
    transform: true,              // auto-transform primitives
    transformOptions: { enableImplicitConversion: true },
  }),
);
```

## Guards and Interceptors

### Auth Guard

```typescript
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController { ... }
```

### Response Interceptor — wrap all responses in ApiResponse envelope

```typescript
@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  intercept(ctx: ExecutionContext, next: CallHandler): Observable<ApiResponse> {
    return next.handle().pipe(
      map(data => ({ status: 0, data })),
    );
  }
}
```

### Exception Filter — catch all, log internally, return safe envelope

```typescript
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();

    if (exception instanceof HttpException) {
      return response.status(exception.getStatus()).json({
        status: 2,
        message: exception.message,
      });
    }

    // Unexpected error — log detail, return generic
    this.logger.error('Unhandled exception', exception);
    return response.status(500).json({
      status: 99,
      message: 'Internal server error',
    });
  }
}
```

## Configuration

启动时校验环境变量，不在首次请求时才检查：

```typescript
// config/configuration.ts
export default () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  database: {
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT, 10) || 5432,
  },
});

// config/validation.ts
export function validateEnv(config: Record<string, unknown>) {
  const schema = z.object({
    PORT: z.string().default('3000'),
    DB_HOST: z.string(),
    DB_PORT: z.string().regex(/^\d+$/).default('5432'),
    JWT_SECRET: z.string().min(32),
  });
  return schema.parse(config);
}
```

Fail fast: if required env vars are missing, crash at boot — don't limp along.

## 时间格式

**统一传输格式：** `yyyy-MM-dd HH:mm:ss.SSS`（精确到毫秒）

API 输入/输出、JSON 序列化、数据库 DateTime、日志时间戳均使用此格式。

```typescript
// dayjs 格式化
dayjs().format('YYYY-MM-DD HH:mm:ss.SSS');

// 原生 Date → 字符串
new Date().toISOString(); // 不推荐：ISO格式
// 推荐手写 formatter:
const pad = (n: number, len = 2) => String(n).padStart(len, '0');
const d = new Date();
`${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}.${pad(d.getMilliseconds(), 3)}`;
```

- 时区统一 `Asia/Shanghai`
- 禁止使用 `toISOString()`（ISO 8601 格式为 `T` 分隔、带时区后缀，与统一格式不兼容）
- 禁止仅到秒（`HH:mm:ss` 无毫秒）

## API Response Envelope

遵循《阿里巴巴 Java 开发手册》前后端规约，Java / NestJS 使用相同结构：

```json
{
  "code": 0,
  "message": "操作成功",
  "data": {...},
  "requestId": "a1b2c3d4e5f6",
  "metadata": {
    "timestamp": "2026-05-21 19:00:00.111",
    "method": "POST",
    "endpoint": "/api/users",
    "count": 100,
    "currentPage": 1
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | `number \| string` | 成功=0，失败=String 业务错误码 |
| `message` | `string` | 用户提示信息 |
| `data` | `T \| null` | 业务数据，空列表返回 `[]` |
| `requestId` | `string` | **= traceId**，Gateway 生成后全链路透传 |
| `metadata` | `object` | 请求上下文 + 分页（非分页接口仅含 timestamp/method/endpoint） |

```typescript
interface ApiResponse<T = unknown> {
  code: number | string
  message: string
  data: T | null
  requestId: string              // = traceId
  metadata: {
    timestamp: string            // yyyy-MM-dd HH:mm:ss.SSS
    method: string
    endpoint: string
    count?: number
    totalPages?: number
    currentPage?: number
    pageSize?: number
  }
}
```

### requestId = traceId

requestId 不是独立 UUID，而是 traceId。Gateway 生成 → 经 `X-Trace-Id` 头透传 → 写入日志 + 返回给客户端。一条链路一个值。

```typescript
const traceId = req.headers['x-trace-id'] as string
  || crypto.randomUUID().replace(/-/g, '');
res.setHeader('X-Trace-Id', traceId);
```

**强制项：** 空列表返回 `[]`，禁止 `null`。JSON key 使用 lowerCamelCase。

## 数据库迁移

详见 `rules/common/patterns.md` 数据库迁移规范。

## Custom Hooks (React)

```typescript
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay)
    return () => clearTimeout(handler)
  }, [value, delay])

  return debouncedValue
}
```

## Repository Pattern (Generic)

```typescript
interface Repository<T> {
  findAll(filters?: Filters): Promise<T[]>
  findById(id: string): Promise<T | null>
  create(data: CreateDto): Promise<T>
  update(id: string, data: UpdateDto): Promise<T>
  delete(id: string): Promise<void>
}
```

## References

See skill: `nestjs-patterns` for full NestJS architecture patterns.
See skill: `backend-patterns` for general backend patterns.
