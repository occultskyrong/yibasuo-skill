# gRPC 微服务分层

与 HTTP/BFF 分层不同，gRPC 微服务不需要 Controller 或 ApiResponse，也不承载端侧登录态/JWT/RBAC；服务身份校验由全局 gRPC Interceptor 统一执行：

| 层 | 职责 | HTTP/BFF 对应 |
| ---- | ------ | -------------- |
| Service Impl | gRPC 入口，替代 Controller | Controller |
| Service（业务） | 纯业务逻辑，不重复端侧鉴权或服务身份校验 | Service |
| Provider / Mapper | 数据访问（轻量微服务可省略） | Repository |
| Interceptor（gRPC） | traceId、服务身份与方法授权、日志、异常转换 | HTTP Filter / Middleware |

## 核心差异

- **无 ApiResponse** — gRPC 有原生错误通道（Status + trailers），不在 response message 里塞 code/message
- **不承载端侧 JWT/RBAC** — 端用户身份和权限由 BFF 处理；微服务仍须验证 `x-caller-service` + `x-internal-token`
- **服务身份默认拒绝** — 配置使用 `callers.<service>.{token,role,allowed-methods}`；未知调用方、空 token、未知角色一律拒绝
- **受限调用方按方法授权** — `RESTRICTED` 只允许完整 gRPC 方法名白名单；健康检查/反射只能按完整方法名显式豁免
- **不信任网络可达性** — Nacos 可发现、内网地址或 BFF 注入的 `x-user-id` 都不能替代服务身份校验
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
