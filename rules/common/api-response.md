# API 响应格式

遵循《阿里巴巴 Java 开发手册》前后端规约。所有**有响应体**的 API 响应使用统一信封（DELETE 返回 204 No Content 时无响应体，是明确例外，见 [restful-api.md](./restful-api.md)）：

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
    "totalPages": 5,
    "currentPage": 1,
    "pageSize": 20
  }
}
```

| 字段 | 类型 | 说明 |
| ------ | ------ | ------ |
| `code` | `number \| string` | 成功=`0`（number）；失败=跨语言一致的 String 业务错误码（`UPPER_SNAKE_CASE`，如 `INVALID_PARAM`） |
| `message` | `string` | 用户提示信息 |
| `data` | `T` | 业务数据。空列表返回 `[]`，单条查询无结果可返回 `null`，错误响应 `data` 为 `null` |
| `requestId` | `string` | **= traceId**，Gateway 生成，全链路透传 |
| `metadata` | `object` | 请求上下文 + 分页。必填：timestamp/method/endpoint。分页专属：count/totalPages/currentPage/pageSize |

- requestId 不是独立 UUID，而是 traceId。Gateway 生成 → 经 `X-Trace-Id` 头透传 → 写入日志 + 返回给客户端
- JSON key 使用 lowerCamelCase
- 语言特定实现见 `rules/java/patterns.md` 和 `rules/typescript/patterns.md`
