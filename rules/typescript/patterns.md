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

Strict separation of concerns — never skip a layer:

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

All business logic here. Never expose entities directly — map to response DTOs:

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

Encapsulate data access. Use Prisma, TypeORM, or raw DB driver behind a clean interface:

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

Configure once in `main.ts`:

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

Validate env at startup, not at first request:

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

## API Response Envelope

统一返回体，Java / NestJS 使用相同结构：

```typescript
interface ApiResponse<T = unknown> {
  code: number       // 0=成功, 1=成功有消息, >=2=错误
  message?: string   // 错误描述或成功提示
  data?: T           // 业务数据
  requestId?: string  // traceId，用于链路追踪
}
```

- `code: 0` — 成功，data 有效
- `code: 1` — 成功但有提示信息
- `code: >=2` — 错误，message 描述原因

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
