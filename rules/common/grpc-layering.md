# gRPC 微服务分层

与 HTTP/BFF 分层不同，gRPC 微服务不需要 Controller、ApiResponse、鉴权层：

| 层 | 职责 | HTTP/BFF 对应 |
| ---- | ------ | -------------- |
| Service Impl | gRPC 入口，替代 Controller | Controller |
| Service（业务） | 纯业务逻辑，无鉴权 | Service |
| Provider / Mapper | 数据访问（轻量微服务可省略） | Repository |
| Interceptor（gRPC） | traceId 透传、日志、异常转换 | HTTP Filter / Middleware |

## 核心差异

- **无 ApiResponse** — gRPC 有原生错误通道（Status + trailers），不在 response message 里塞 code/message
- **不鉴权** — 信任 BFF 传来的身份（gRPC metadata `x-user-id` 等）
- **错误处理** — 用 `StatusRuntimeException`（Java）/ `RpcException`（NestJS），BFF 层映射为 HTTP ApiResponse

## gRPC Status → HTTP 映射（BFF 层）

| gRPC Status | HTTP | 说明 |
| ------------- | :----: | ------ |
| `NOT_FOUND` | 404 | 资源不存在 |
| `INVALID_ARGUMENT` | 400 | 参数错误 |
| `ALREADY_EXISTS` | 409 | 唯一约束冲突 |
| `PERMISSION_DENIED` | 403 | 权限不足 |
| `UNAUTHENTICATED` | 401 | 未认证 |
| `INTERNAL` | 500 | 内部错误 |
| `UNAVAILABLE` | 502 | 服务不可用 |
| `DEADLINE_EXCEEDED` | 504 | 超时 |

语言特定实现见 `rules/java/patterns.md` 和 `rules/typescript/patterns.md`。
