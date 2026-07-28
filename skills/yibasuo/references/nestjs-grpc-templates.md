# NestJS gRPC 微服务模板规格 (v11 + Node 24 LTS)

适用场景：微服务层（不承载端侧 JWT/RBAC；所有业务 RPC 校验服务身份 metadata）。

## 目录结构

```
{project}/
├── README.md / CLAUDE.md / .env.example / .gitignore / .dockerignore
├── package.json / tsconfig.json / tsconfig.build.json / nest-cli.json
├── .prettierrc / .eslintrc.js
├── src/
│   ├── main.ts                           # NestFactory.createMicroservice (Transport.GRPC)
│   ├── app.module.ts
│   ├── common/
│   │   ├── interceptors/
│   │   │   ├── trace-id.interceptor.ts   # gRPC metadata→AsyncLocalStorage
│   │   │   └── internal-auth.interceptor.ts # 调用方 token/方法授权
│   │   └── filters/
│   │       └── grpc-exception.filter.ts  # StatusRuntimeException 规范化
│   └── <feature>/                        # module 直接铺在 src 下
│       ├── <feature>.module.ts
│       ├── <feature>.controller.ts       # @GrpcMethod() 实现
│       ├── <feature>.service.ts          # 业务逻辑
│       └── dto/                          # proto 生成的 TS 类型
├── proto/
│   ├── common.proto                      # 通用类型（分页/排序/时间戳）
│   └── {service}/
│       └── v1/
│           └── {service}_service.proto
└── test/
    ├── app.e2e-spec.ts / jest-e2e.json
```

### 与 HTTP NestJS 模板的关键差异

| 项目 | HTTP NestJS | gRPC 微服务 |
|------|------------|------------|
| 启动方式 | `NestFactory.create()` | `NestFactory.createMicroservice()` + `Transport.GRPC` |
| ApiResponse | `{ code, message, data, requestId, metadata }` | 无需 — gRPC 自带 status |
| 异常处理 | `HttpExceptionFilter` | `RpcException` / `status` from `@grpc/grpc-js` |
| TraceId | HTTP Middleware | gRPC Interceptor（metadata.get('x-trace-id')） |
| 参数校验 | `class-validator`（ValidationPipe） | proto 自带类型约束 + controller 手动校验 |
| JWT/Security | `@nestjs/jwt` + Guard | 不承载端侧 JWT；拦截器校验调用服务与方法权限 |
| ORM | TypeORM / Prisma | 按需，轻量微服务可不带 ORM |
| 目录 | `src/<feature>/` | `src/<feature>/`（配置驱动，非请求驱动） |
| Proto | 无 | `proto/`（用 `@grpc/proto-loader` 或 `ts-proto` 生成） |

---

## gRPC 通信约定

### 核心原则：成功返回数据，失败走 Status

gRPC 有原生错误通道（HTTP/2 trailers），**不需要在 response message 里塞 code/message**。

```
HTTP 反模式（gRPC 不要学）:              gRPC 正确做法:

message OrderResponse {                   message OrderResponse {
  int32 code = 1;  // ← 不需要              string order_id = 1;
  string message = 2;                       OrderStatus status = 2;
  Order data = 3;                         }
}                                           
                                           // 失败走 RpcException
```

### 错误处理

```typescript
import { status } from '@grpc/grpc-js';
import { RpcException } from '@nestjs/microservices';

// Controller 中
@GrpcMethod('OrderService', 'GetOrder')
async getOrder(data: GetOrderRequest): Promise<OrderResponse> {
  const order = await this.orderService.findById(data.orderId);
  if (!order) {
    throw new RpcException({
      code: status.NOT_FOUND,
      message: `Order not found: ${data.orderId}`,
    });
  }
  return order;
}
```

### gRPC Status → HTTP 映射（BFF 层）

BFF 捕获 gRPC 异常后映射为 HTTP ApiResponse：

| gRPC Status Code | HTTP Status | 说明 |
|-----------------|-------------|------|
| OK (0) | 200 | 正常 |
| INVALID_ARGUMENT (3) | 400 | 参数校验失败 |
| NOT_FOUND (5) | 404 | 资源不存在 |
| ALREADY_EXISTS (6) | 409 | 唯一约束冲突 |
| PERMISSION_DENIED (7) | 403 | 权限不足 |
| UNAUTHENTICATED (16) | 401 | 未认证 |
| INTERNAL (13) | 500 | 内部错误 |
| UNAVAILABLE (14) | 502 | 服务不可用 |
| DEADLINE_EXCEEDED (4) | 504 | 超时 |

其他码统一映射为 500。

### TraceId 透传

```typescript
// interceptor/trace-id.interceptor.ts
import { randomUUID } from 'node:crypto';
import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Metadata } from '@grpc/grpc-js';
import { Observable } from 'rxjs';
import { traceContext } from '../trace/trace.context';

const VALID_TRACE_ID = /^[A-Za-z0-9._-]{1,64}$/;

@Injectable()
export class TraceIdInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const metadata = context.switchToRpc().getContext<Metadata>();
    const [value] = metadata.get('x-trace-id');
    const incoming = value?.toString();
    const traceId = incoming && VALID_TRACE_ID.test(incoming)
      ? incoming
      : randomUUID().replaceAll('-', '');

    return new Observable((subscriber) =>
      traceContext.run({ traceId }, () => {
        const subscription = next.handle().subscribe(subscriber);
        return () => subscription.unsubscribe();
      }),
    );
  }
}
```

必须通过 `APP_INTERCEPTOR` 全局注册，不能只加 `@Injectable()`。AsyncLocalStorage 的 `trace.context.ts` 与 HTTP 模板一致。

### 服务身份鉴权

```typescript
// interceptor/internal-auth.interceptor.ts
import { timingSafeEqual } from 'node:crypto';
import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Metadata, status } from '@grpc/grpc-js';
import { RpcException } from '@nestjs/microservices';
import { Observable } from 'rxjs';

type CallerConfig = {
  token?: string;
  role?: 'ADMIN' | 'RESTRICTED';
  allowedMethods?: string[];
};

type GrpcServerCall = {
  getPath(): string;
};

const INFRASTRUCTURE_METHODS = new Set([
  'grpc.health.v1.Health/Check',
  'grpc.health.v1.Health/Watch',
  'grpc.reflection.v1.ServerReflection/ServerReflectionInfo',
  'grpc.reflection.v1alpha.ServerReflection/ServerReflectionInfo',
]);

@Injectable()
export class InternalAuthInterceptor implements NestInterceptor {
  constructor(private readonly config: ConfigService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const metadata = context.switchToRpc().getContext<Metadata>();
    const call = context.getArgByIndex<GrpcServerCall>(2);
    const method = call.getPath().replace(/^\//, '');
    if (INFRASTRUCTURE_METHODS.has(method)) {
      return next.handle();
    }

    const callerName = metadata.get('x-caller-service')[0]?.toString();
    const suppliedToken = metadata.get('x-internal-token')[0]?.toString();
    const callers = this.config.get<Record<string, CallerConfig>>(
      '{domain}.security.callers',
      {},
    );
    const caller = callerName ? callers[callerName] : undefined;

    if (!caller?.token || !suppliedToken
        || !this.constantTimeEquals(caller.token, suppliedToken)) {
      throw new RpcException({
        code: status.UNAUTHENTICATED,
        message: 'Invalid service credentials',
      });
    }

    const allowed = caller.role === 'ADMIN'
      || (caller.role === 'RESTRICTED'
          && (caller.allowedMethods ?? []).includes(method));
    if (!allowed) {
      throw new RpcException({
        code: status.PERMISSION_DENIED,
        message: 'Method is not allowed',
      });
    }
    return next.handle();
  }

  private constantTimeEquals(expected: string, actual: string): boolean {
    const left = Buffer.from(expected, 'utf8');
    const right = Buffer.from(actual, 'utf8');
    return left.length === right.length && timingSafeEqual(left, right);
  }
}
```

配置结构与 Java gRPC 模板一致：`{domain}.security.callers.<service>.{token,role,allowed-methods}`。token 只能从环境变量或 Nacos 注入，禁止写入仓库或日志。`ADMIN` 可调用全部业务方法，`RESTRICTED` 只允许完整 gRPC 方法名白名单；未知角色默认拒绝。

```typescript
// app.module.ts
import { ConfigModule } from '@nestjs/config';
import { APP_INTERCEPTOR } from '@nestjs/core';

imports: [ConfigModule.forRoot({ isGlobal: true })],
providers: [
  { provide: APP_INTERCEPTOR, useClass: TraceIdInterceptor },
  { provide: APP_INTERCEPTOR, useClass: InternalAuthInterceptor },
]
```

### 强制测试

生成项目的 Jest 测试必须覆盖：缺失/错误 token → `UNAUTHENTICATED`；未知角色、受限方法越权 → `PERMISSION_DENIED`；`ADMIN` 与白名单方法放行；只豁免列出的基础设施完整方法名。另测合法/非法 TraceId、异步 handler 内 AsyncLocalStorage 可见，以及请求结束后上下文不串到下一次 RPC。

## package.json

核心依赖：

```json
{
  "dependencies": {
    "@nestjs/core": "^11.1",
    "@nestjs/config": "^4.0",
    "@nestjs/microservices": "^11.1",
    "@grpc/grpc-js": "^1.12",
    "@grpc/proto-loader": "^0.7",
    "pino": "^9.0"
  }
}
```

## main.ts

```typescript
import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    transport: Transport.GRPC,
    options: {
      package: ['{service}.v1'],
      protoPath: [join(__dirname, '../proto/{service}/v1/{service}_service.proto')],
      url: '0.0.0.0:{port}',
    },
  });
  await app.listen();
}

void bootstrap();
```

## tsconfig.json

- `strict: true`, `target: ES2023`, `module: NodeNext`, `moduleResolution: NodeNext`
- `experimentalDecorators: true`, `emitDecoratorMetadata: true`
- 如需使用 `ts-proto` 生成的类型，确保 `esModuleInterop: true`
