# Common Patterns

## Skeleton Projects

When implementing new functionality:
1. Search for battle-tested skeleton projects
2. Use parallel agents to evaluate options:
   - Security assessment
   - Extensibility analysis
   - Relevance scoring
   - Implementation planning
3. Clone best match as foundation
4. Iterate within proven structure

## Design Patterns

### Repository Pattern

Encapsulate data access behind a consistent interface:
- Define standard operations: findAll, findById, create, update, delete
- Concrete implementations handle storage details (database, API, file, etc.)
- Business logic depends on the abstract interface, not the storage mechanism
- Enables easy swapping of data sources and simplifies testing with mocks

### API Response Format

遵循《阿里巴巴 Java 开发手册》前后端规约。所有 API 响应使用统一信封：

```json
{
  "code": 0,
  "message": "操作成功",
  "data": {...},
  "requestId": "a1b2c3d4e5f6",
  "metadata": {
    "timestamp": "2026-05-26 10:00:00.000",
    "method": "POST",
    "endpoint": "/api/users",
    "count": 100,
    "totalPages": 10,
    "currentPage": 1,
    "pageSize": 10
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | `number \| string` | 成功=0（number），失败=业务错误码（string）。**不是纯 number**：Java `BusinessCode` 枚举为 String，NestJS 项目用数字 status，两者统一为 `number \| string` |
| `message` | `string` | 用户提示信息 |
| `data` | `T` | 业务数据。空列表返回 `[]`，单条查询无结果可返回 `null`，错误响应 `data` 为 `null` |
| `requestId` | `string` | **= traceId**，Gateway 生成，全链路透传 |
| `metadata` | `object` | 请求上下文 + 分页。必填：timestamp/method/endpoint。分页专属：count/totalPages/currentPage/pageSize |

- requestId 不是独立 UUID，而是 traceId。Gateway 生成 → 经 `X-Trace-Id` 头透传 → 写入日志 + 返回给客户端
- JSON key 使用 lowerCamelCase
- 语言特定实现见 `rules/java/patterns.md` 和 `rules/typescript/patterns.md`

### RESTful API 设计

所有 HTTP 接口必须遵循 RESTful 规范。

#### URL 设计

```
{prefix}/v{n}/{resource}[/{id}[/{sub-resource}[/{sub-id}]]]
```

| 规则 | 正例 | 反例 |
|------|------|------|
| 资源名用**名词复数** | `/orders` | `/getOrder` |
| 资源名用 **kebab-case** | `/course-materials` | `/courseMaterials` |
| 单个资源用 `/{id}` | `GET /orders/{id}` | `GET /orders/get?id=1` |
| 子资源 ≤ 2 层 | `GET /orders/{id}/items` ✓ | `GET /orders/{id}/items/{iid}/comments` → 拆为 `GET /orders/{id}/comments?itemId={iid}` |
| 版本号 `v{n}` | `/admin-api/v1/roles` | `/roles`（无版本号） |
| 前缀自定 | 各项目自行决定 `{prefix}` | — |

#### HTTP 方法

| 方法 | 语义 | 幂等 | 示例 |
|------|------|:---:|------|
| `GET` | 查询 | ✅ | `GET /users/{id}` |
| `POST` | 创建 | ❌ | `POST /users` |
| `PUT` | 全量更新 | ✅ | `PUT /users/{id}` |
| `PATCH` | 部分更新 | ❌ | `PATCH /users/{id}`（仅传变更字段） |
| `DELETE` | 删除 | ✅ | `DELETE /users/{id}` |

非 CRUD 操作使用 `POST /{resource}/{id}/{action}`：

```
POST /orders/{id}/cancel      # 取消订单
POST /orders/{id}/refund      # 退款
```

禁止使用自定义 HTTP 方法或在 URL 中加动词描述 CRUD 操作。

#### 查询参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `page` | int | 页码，从 1 开始 |
| `pageSize` | int | 每页条数，默认 20，最大 100 |
| `sort` | string | `-` 前缀降序（`?sort=-createdAt`） |
| `q` | string | 全文搜索关键词 |

项目特定参数加在后面：`?page=1&pageSize=20&status=ACTIVE`。

#### 状态码

HTTP 状态码与 ApiResponse `code` 双重标识：

| HTTP | 场景 | `code` |
|------|------|:---:|
| 200 | 查询/更新/操作成功 | `0` |
| 201 | 创建成功 | `0` |
| 204 | 删除成功（无响应体） | — |
| 400 | 参数校验失败 | String 业务错误码 |
| 401 | 未认证 | String 业务错误码 |
| 403 | 无权限 | String 业务错误码 |
| 404 | 资源不存在 | String 业务错误码 |
| 409 | 冲突（唯一键重复） | String 业务错误码 |
| 500 | 服务器内部错误 | String 业务错误码 |

#### 反模式

| 反模式 | 正例 |
|--------|------|
| URL 包含动词 | `/users/{id}` 替代 `/getUserById?id={id}` |
| CRUD 操作写在 URL 末尾 | `DELETE /users/{id}` 替代 `POST /users/{id}/delete` |
| 嵌套超过 2 层 | 拆为独立路径 + query 参数 |
| 全部返回 200，body 里区分错误 | HTTP 状态码 + `code` 字段双重标识 |
| 单复数混用 | 全部统一为复数 |

### gRPC 微服务分层

与 HTTP/BFF 分层不同，gRPC 微服务不需要 Controller、ApiResponse、鉴权层：

| 层 | 职责 | HTTP/BFF 对应 |
|----|------|--------------|
| Service Impl | gRPC 入口，替代 Controller | Controller |
| Service（业务） | 纯业务逻辑，无鉴权 | Service |
| Provider / Mapper | 数据访问（轻量微服务可省略） | Repository |
| Interceptor（gRPC） | traceId 透传、日志、异常转换 | HTTP Filter / Middleware |

核心差异：
- **无 ApiResponse** — gRPC 有原生错误通道（Status + trailers），不在 response message 里塞 code/message
- **不鉴权** — 信任 BFF 传来的身份（gRPC metadata `x-user-id` 等）
- **错误处理** — 用 `StatusRuntimeException`（Java）/ `RpcException`（NestJS），BFF 层映射为 HTTP ApiResponse

语言特定实现见 `rules/java/patterns.md` 和 `rules/typescript/patterns.md`。

### API 版本控制

不兼容的接口变更使用 URL 版本号，新旧并存，等消费者迁移完成后删除旧版：

| 变更类型 | 处理 |
|---------|------|
| 加字段 | 直接加，消费者忽略未知字段 |
| 改字段名/类型/含义 | 新建 `/v2/xxx`，新旧并存 |
| 删字段 | 同上 |
| 消费者未对接 | 不兼容变更可直接改 |

旧版接口标注 `@Deprecated`，保留至所有消费者迁移完成。语言特定实现见 `rules/java/patterns.md`。

## 数据库迁移

```
编写脚本 → 本地验证 → 提交仓库 → CI 幂等校验 → 部署执行 → 记录状态
```

1. **编写脚本**
   - 命名：`V{YYYYMMDD}__{描述}.sql`（Flyway 标准格式：V 前缀 + 双下划线，如 `V20260608__init_order_table.sql`）。同一天多次迁移在日期后加序号 `V20260608_1__add_index.sql`
   - 一个文件只做一件事（建表、加列、加索引分开）
   - 所有 DDL 用 `IF NOT EXISTS` / `IF EXISTS` 保证幂等
   - 提供回滚脚本；若操作不可逆（如删列清表），标记 `[IRREVERSIBLE]` 并说明理由

2. **本地验证** — 执行迁移确认无报错；有回滚则验证可撤销

3. **提交仓库** — 迁移和回滚同时提交，同一 commit。**已部署到任何环境的脚本禁止修改**，变更写新脚本。未部署的可在合并前修正

4. **CI 幂等校验** — 迁移执行两次，第二次必须 0 变更；有回滚则同步验证

5. **部署执行** — 迁移作为独立步骤在应用部署之前执行。生产环境禁止应用启动时自动执行迁移

6. **记录状态** — 迁移工具自动记录执行历史；部署日志中记录执行的迁移文件名

**大表变更**：当 DDL 可能导致长时间锁表时，增加列先加可空分批设默认值，删除列先停写入再单独迁移删，重命名列先双写再删旧列。

**反模式**：一个文件改十几个表 · 先改生产再补脚本 · 迁移和业务代码不同 PR · 无回滚也不标记不可逆

## 定时任务

```
定义 → 注册 → 调度 → 执行 → 监控 → 下线
```

1. **定义**
   - 任务名全局唯一，命名格式：`{领域}:{动作}:{对象}`（如 `order:expire:cancel`）
   - cron 表达式外置到配置，禁止硬编码在注解或代码中
   - 明确任务超时时间（最大执行时长），超时视为失败
   - 明确预期处理数据量级，大任务拆分为小批次

2. **注册**
   - 显式注册：代码注解声明 或 调度中心 Web UI 录入
   - 禁止应用启动时隐式执行（如初始化钩子中调用任务方法）
   - 新任务上线前在非生产环境验证至少一个完整周期

3. **调度**
   - 调度器职责单一：触发 + 获取分布式锁，不做业务逻辑
   - 业务逻辑放在独立的 Service / Provider 方法中
   - 调度线程不得阻塞，耗时逻辑提交到独立线程池或消息队列

4. **执行**
   - 执行前获取分布式锁，获取失败则跳过本次（不等待）
   - 大批量数据分页/分批处理，每批提交事务
   - 超时控制：任务整体有截止时间，单次外部调用有超时

5. **监控**
   - 每次执行记录日志：任务名、开始时间、耗时、处理条数、成功/失败数
   - 暴露指标：执行次数、成功率、P99 耗时、最近失败时间
   - 连续失败 N 次触发告警（N 按业务定，建议默认 3）

6. **下线**
   - 从调度配置中移除（注解删除 / 调度中心停用）
   - 确认无下游消费者依赖此任务的产出数据
   - 清理关联的分布式锁 Key 和配置项

### 幂等性

同一个任务在同一时刻只应有一个实例执行，且重复执行不产生副作用。

| 手段 | 场景 | 实现 |
|------|------|------|
| 分布式锁 | 防止多实例同时执行 | Redis SET NX PX + Lua 释放；调度框架内置集群锁 |
| 业务幂等键 | 防止同一条数据被重复处理 | 唯一流水号 + 去重表 / 唯一索引 |
| 状态机保护 | 防止已处理数据回退 | 状态前置校验，终态数据跳过处理 |

- 锁 TTL 必须大于任务最大执行时间；长任务需锁续期（watchdog）
- 锁 Key 命名：`{app}:task:{taskName}:lock`，带环境前缀
- 锁释放必须在 `finally` 块中执行，确保异常时也能释放

### 错误处理

- **可重试错误**（网络超时、死锁、临时不可用）：指数退避重试，`delay = base * 2^attempt + random_jitter`，最大重试 3 次
- **不可重试错误**（数据校验失败、业务规则不满足）：记录 WARN 日志，跳过当前条目，继续处理下一条
- **死信**：超过最大重试次数的条目转入死信表/死信队列，等待人工介入
- **降级**：外部依赖不可用时，记录 WARN 日志并跳过，不影响主流程
- **告警**：单次执行失败率超过阈值（建议 10%）或连续 3 次执行全部失败，触发告警

### 分布式协调

多实例部署时必须保证任务互斥：

- **优先使用框架内置能力**：Java→XXL-Job（生产唯一方案，路由策略：故障转移/分片广播）、NestJS→BullMQ；禁止生产环境用 `@Scheduled`/@Cron 裸跑
- **自建锁**：Redis `SET key value NX PX ttl` + Lua 脚本原子释放
- **锁粒度**：按任务名加锁，不同任务互不影响
- **锁续期**：执行时间不固定的长任务，启动 watchdog 协程/线程定期续期

### 日志与可观测性

每次任务执行输出一条 INFO 汇总日志，包含以下字段：

| 字段 | 说明 | 示例 |
|------|------|------|
| task | 任务名 | `order:expire:cancel` |
| start_at | 开始时间 | `2026-05-26 10:00:00.000` |
| duration_ms | 执行耗时 | `1234` |
| lock_acquired | 是否获取锁 | `true` / `false` |
| total | 待处理总条数 | `5000` |
| processed | 实际处理条数 | `4980` |
| success | 成功条数 | `4975` |
| failed | 失败条数 | `5` |

- 分页处理时，每页可输出 DEBUG 级别进度日志
- 锁获取失败输出 WARN 日志（说明另一实例正在执行）

**反模式**：阻塞调度线程 · 无超时控制 · 无幂等保护 · 无分布式锁 · cron 硬编码 · 任务中启动新线程不等待 · 锁未在 finally 释放 · 一次性全量处理历史数据 · 失败无告警 · 日志不记录执行结果
