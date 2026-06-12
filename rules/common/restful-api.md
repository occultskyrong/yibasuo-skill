# RESTful API 设计规范

所有 HTTP 接口必须遵循 RESTful 规范。

## URL 设计

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

## HTTP 方法

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

## 查询参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `page` | int | 页码，从 1 开始 |
| `pageSize` | int | 每页条数，默认 20，最大 100 |
| `sort` | string | `-` 前缀降序（`?sort=-createdAt`） |
| `q` | string | 全文搜索关键词 |

项目特定参数加在后面：`?page=1&pageSize=20&status=ACTIVE`。

## 状态码

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

## 反模式

| 反模式 | 正例 |
|--------|------|
| URL 包含动词 | `/users/{id}` 替代 `/getUserById?id={id}` |
| CRUD 操作写在 URL 末尾 | `DELETE /users/{id}` 替代 `POST /users/{id}/delete` |
| 嵌套超过 2 层 | 拆为独立路径 + query 参数 |
| 全部返回 200，body 里区分错误 | HTTP 状态码 + `code` 字段双重标识 |
| 单复数混用 | 全部统一为复数 |
