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

严格分层，绝不越层调用。默认使用 Express 驱动；如使用 Fastify（`@nestjs/platform-fastify`），注意以下差异：

| 差异 | Express | Fastify |
|------|---------|---------|
| 请求/响应类型 | `Request` / `Response` | `FastifyRequest` / `FastifyReply` |
| 中间件 | `app.use()` | 需用 `@fastify/*` 插件 |
| Helmet | `helmet()` | `@fastify/helmet` |
| CSRF | `csrf-csrf` | `@fastify/csrf-protection` |

其余分层规则（Controller→Service→Repository）与驱动无关。

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
      map(data => ({
        code: 0,
        message: '操作成功',
        data,
        requestId: getTraceId(),
        metadata: {
          timestamp: dayjs().format('YYYY-MM-DD HH:mm:ss.SSS'),
          method: ctx.switchToHttp().getRequest().method,
          endpoint: ctx.switchToHttp().getRequest().url,
        },
      })),
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
        code: 2,
        message: '请求错误',
        data: null,
        requestId: getTraceId(),
        metadata: null,
      });
    }

    this.logger.error('Unhandled exception', exception);
    return response.status(500).json({
      code: 99,
      message: 'Internal server error',
      data: null,
      requestId: getTraceId(),
      metadata: null,
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

## 定时任务

> 语言无关的核心规范见 [common/patterns.md](../common/patterns.md) 定时任务章节。本文档补充 TypeScript/NestJS 特定实现。

### @nestjs/schedule

```typescript
// GOOD — cron 外置，调度与业务分离
@Injectable()
export class OrderExpireTask {
  private readonly logger = new Logger(OrderExpireTask.name);

  constructor(private readonly orderExpireService: OrderExpireService) {}

  @Cron(CronExpression.EVERY_HOUR, { name: 'order:expire:cancel' })
  async handleCron() {
    const start = Date.now();
    try {
      const result = await this.orderExpireService.expireOrders();
      this.logger.log({
        task: 'order:expire:cancel',
        duration_ms: Date.now() - start,
        processed: result.processed,
        success: result.success,
        failed: result.failed,
      });
    } catch (error) {
      this.logger.error({ task: 'order:expire:cancel', err: error }, 'Task failed');
    }
  }
}
```

| 规则 | 说明 |
|------|------|
| cron 外置 | 通过 `ConfigService` 读取 cron，禁止硬编码字符串 |
| 调度与业务分离 | `@Cron` 方法只做日志 + 委托，业务逻辑在独立 Service |
| `name` 参数 | 必须设置，用于日志标识和运行时管理 |
| `disabled` 参数 | 通过配置控制启用/禁用，方便紧急关闭 |

### 动态 Cron（从配置读取）

推荐在 `onModuleInit` 中通过 `SchedulerRegistry` 动态注册：

```typescript
@Injectable()
export class DynamicTaskRegister implements OnModuleInit {
  constructor(
    private readonly schedulerRegistry: SchedulerRegistry,
    private readonly config: ConfigService,
    private readonly orderExpireTask: OrderExpireTask,
  ) {}

  onModuleInit() {
    const cron = this.config.get<string>('TASK_ORDER_EXPIRE_CRON');
    const job = new CronJob(cron, () => this.orderExpireTask.handleCron());
    this.schedulerRegistry.addCronJob('order:expire:cancel', job);
    job.start();
  }
}
```

### Bull / BullMQ 任务队列

对于需要重试、延迟、优先级、进度追踪的任务，使用 BullMQ 而非 `@Cron`：

```typescript
// 生产者 — 在业务需要时入队
@Injectable()
export class ReportService {
  constructor(@InjectQueue('report') private reportQueue: Queue) {}

  async generate(userId: string) {
    await this.reportQueue.add('generate', { userId }, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 2000 },
      removeOnComplete: true,
      removeOnFail: 100,
    });
  }
}

// 消费者
@Processor('report')
export class ReportProcessor {
  @Process('generate')
  async handleGenerate(job: Job<{ userId: string }>) {
    // 业务逻辑
  }
}
```

| 配置 | 推荐值 | 说明 |
|------|--------|------|
| `attempts` | 3 | 最大重试次数 |
| `backoff.type` | `exponential` | 指数退避 |
| `backoff.delay` | 2000 | 初始延迟 2 秒 |
| `removeOnComplete` | `true` | 完成即清理，节省 Redis 内存 |
| `removeOnFail` | 100 | 保留最近 100 条失败，便于排查 |

### 分布式锁实现（Redis）

```typescript
@Injectable()
export class TaskLockService {
  constructor(@Inject('REDIS_CLIENT') private readonly redis: Redis) {}

  private lockPrefix(): string {
    return `${process.env.REDIS_KEY_PREFIX ?? 'app:dev'}:task:lock:`;
  }

  async tryLock(taskName: string, ttlSeconds: number): Promise<boolean> {
    const key = `${this.lockPrefix()}${taskName}`;
    const result = await this.redis.set(key, os.hostname(), 'EX', ttlSeconds, 'NX');
    return result === 'OK';
  }

  async unlock(taskName: string): Promise<void> {
    const key = `${this.lockPrefix()}${taskName}`;
    const script = `
      if redis.call('get', KEYS[1]) == ARGV[1] then
        return redis.call('del', KEYS[1])
      else
        return 0
      end
    `;
    await this.redis.eval(script, 1, key, os.hostname());
  }
}
```

使用示例：

```typescript
@Injectable()
export class OrderExpireTask {
  private readonly logger = new Logger(OrderExpireTask.name);
  private static readonly TASK_NAME = 'order:expire:cancel';
  private static readonly LOCK_TTL = 300;

  constructor(
    private readonly lock: TaskLockService,
    private readonly service: OrderExpireService,
  ) {}

  async execute(): Promise<void> {
    if (!(await this.lock.tryLock(OrderExpireTask.TASK_NAME, OrderExpireTask.LOCK_TTL))) {
      this.logger.warn({ task: OrderExpireTask.TASK_NAME }, 'Task skipped: another instance running');
      return;
    }
    try {
      await this.service.expireOrders();
    } finally {
      await this.lock.unlock(OrderExpireTask.TASK_NAME);
    }
  }
}
```

### 审查清单

- [ ] cron 表达式是否从配置读取（非硬编码）
- [ ] `@Cron` 方法是否简洁（只做日志 + 委托，不超过 15 行）
- [ ] 是否设置了 `name` 参数
- [ ] 多实例部署时是否有分布式锁保护
- [ ] 锁 TTL 是否大于任务最大执行时间
- [ ] 锁释放是否在 `finally` 块中
- [ ] 业务逻辑是否有幂等性保护
- [ ] 是否有超时控制（外部 HTTP 调用、DB 查询）
- [ ] 是否记录了结构化任务执行日志
- [ ] BullMQ 队列是否配置了 `removeOnComplete: true`（避免 Redis 内存堆积）
- [ ] 长任务是否使用 BullMQ 而非 `@Cron`

## References

See skill: `nestjs-patterns` for full NestJS architecture patterns.
See skill: `backend-patterns` for general backend patterns.
