# 命名规范

> 统一 HTTP/JSON 层、数据库层、代码层的命名约定。**一条铁律：JSON 全用 camelCase，关系型 DB（MySQL）全用 snake_case，MongoDB 字段例外用 camelCase（见 [mongodb.md](./mongodb.md)），中间层负责转换。**

## 分层命名

```text
HTTP/JSON 层 (camelCase)         数据库层 (snake_case)
─────────────────────────────    ───────────────────────
POST /users                      CREATE TABLE sys_user (
Body: { "createdBy": 1 }   →        created_by INT,
Resp: { "requestId": ".."}   ←     ) ENGINE=InnoDB;
```

## Request 参数命名

| 位置 | 命名风格 | 示例 |
| ------ | --------- | ------ |
| **Request Body** (JSON) | lowerCamelCase | `{ "createdBy": 1, "userName": "foo" }` |
| **Query 参数** | lowerCamelCase | `?page=1&pageSize=20&sort=-createdAt` |
| **Path 变量** | lowerCamelCase | `/users/{userId}/orders/{orderId}` |
| **URL 路径段** | kebab-case | `/course-materials`, `/api/v1/order-items` |

## Response 命名

| 位置 | 命名风格 | 示例 |
| ------ | --------- | ------ |
| **Response Body** (JSON) | lowerCamelCase | `{ "code": 0, "data": { "userName": "foo" } }` |
| **分页 metadata** | lowerCamelCase | `{ "currentPage": 1, "pageSize": 20, "totalPages": 10, "count": 100 }` |
| **成功 code** | number | `0`（成功专用） |
| **错误 code** | String `UPPER_SNAKE_CASE` | `"INVALID_PARAM"`（Java/NestJS 一致，见 api-response.md） |

## DTO 命名

| 用途 | 后缀 | 示例 |
| ------ | ------ | ------ |
| 创建请求 | `Create{Entity}Dto` | `CreateUserDto`, `CreateOrderDto` |
| 更新请求 | `Update{Entity}Dto` | `UpdateUserDto`, `UpdateOrderDto` |
| 分页查询 | `{Entity}PageRequest` / `{Entity}PageQuery` | `UserPageRequest`, `OrderPageQuery` |
| 列表查询 | `{Entity}Query` | `UserQuery`, `OrderQuery` |
| 响应 | `{Entity}Response` | `UserResponse`, `OrderResponse` |
| 批量操作 | `Batch{Action}{Entity}Dto` | `BatchDeleteUserDto` |

非 CRUD 动作以动作命名：`CancelOrderDto`, `RefundOrderDto`。

> **注意区分**：`{Entity}Response`（如 `UserResponse`）是 DTO 类名后缀，表示**单条业务数据**的响应结构；`ApiResponse<T>`（见 [api-response.md](./api-response.md)）是 HTTP 统一响应信封（含 code/message/data/requestId/metadata），两者职责不同，命名空间独立。

## 数据库层（见 table-structure.md）

| 对象 | 命名风格 |
| ------ | --------- |
| MySQL 表/列/索引 | **snake_case 全小写** |
| MongoDB 集合 | **snake_case** 复数（见 `mongodb.md`） |
| MongoDB 字段 | **camelCase** |

## 代码层（见各语言 coding-style.md）

| 语言 | 变量/函数 | 类/接口/组件 | 常量 | 文件名 |
| ------ | ---------- | ------------- | ------ | -------- |
| Java | camelCase | PascalCase | UPPER_SNAKE_CASE | PascalCase |
| TypeScript | camelCase | PascalCase | UPPER_SNAKE_CASE | snake_case (NestJS) / PascalCase (React) |
| Vue/React 组件 | — | PascalCase | — | PascalCase |

## 禁止项

| 反模式 | 正例 |
| -------- | ------ |
| JSON key 用 snake_case | `"userName"` 非 `"user_name"` |
| Query 参数用 snake_case | `?pageSize=20` 非 `?page_size=20` |
| URL path 用 camelCase | `/course-materials` 非 `/courseMaterials` |
| DB 列用 camelCase | `created_by` 非 `createdBy`（MySQL） |
| DTO 无后缀 | `CreateUserDto` 非 `User`（跟实体混淆） |
| 分页参数混用 | `page` + `pageSize` 全链路统一 |

## 审查清单

- [ ] Request Body JSON key 全部 lowerCamelCase
- [ ] Response Body JSON key 全部 lowerCamelCase
- [ ] Query 参数 lowerCamelCase
- [ ] URL path 段 kebab-case
- [ ] DTO 命名符合后缀规范
- [ ] MySQL 列名 snake_case（见 table-structure.md）
- [ ] 无跨层混用（JSON 里出现 snake_case、DB 里出现 camelCase）
