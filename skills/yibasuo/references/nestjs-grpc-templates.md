# NestJS gRPC 微服务模板规格 (v11 + Node 24 LTS)

适用场景：微服务层（不鉴权，信任 BFF，gRPC 通信）。

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
│   │   │   └── trace-id.interceptor.ts   # gRPC metadata→AsyncLocalStorage
│   │   └── filters/
│   │       └── grpc-exception.filter.ts  # StatusRuntimeException 规范化
│   └── <feature>/                        # .gitkeep 占位，module 直接铺在 src 下
│       └── <feature>/
│           ├── <feature>.module.ts
│           ├── <feature>.controller.ts   # @GrpcMethod() 实现
│           ├── <feature>.service.ts      # 业务逻辑
│           └── dto/                      # proto 生成的 TS 类型
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
| JWT/Security | `@nestjs/jwt` + Guard | 不鉴权，信任 BFF |
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
import { ServerUnaryCall, Metadata } from '@grpc/grpc-js';

@Injectable()
export class TraceIdInterceptor {
  getTraceId(metadata: Metadata): string {
    const [value] = metadata.get('x-trace-id');
    return value?.toString()
      || `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;
  }
}
```

## package.json

核心依赖：

```json
{
  "dependencies": {
    "@nestjs/core": "^11.1",
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
```

## tsconfig.json

- `strict: true`, `target: ES2023`, `module: NodeNext`, `moduleResolution: NodeNext`
- `experimentalDecorators: true`, `emitDecoratorMetadata: true`
- 如需使用 `ts-proto` 生成的类型，确保 `esModuleInterop: true`
