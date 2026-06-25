# API 响应格式

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
| ------ | ------ | ------ |
| `code` | `number \| string` | 成功=0（number），失败=业务错误码（string）。**不是纯 number**：Java `BusinessCode` 枚举为 String，NestJS 项目用数字 status，两者统一为 `number \| string` |
| `message` | `string` | 用户提示信息 |
| `data` | `T` | 业务数据。空列表返回 `[]`，单条查询无结果可返回 `null`，错误响应 `data` 为 `null` |
| `requestId` | `string` | **= traceId**，Gateway 生成，全链路透传 |
| `metadata` | `object` | 请求上下文 + 分页。必填：timestamp/method/endpoint。分页专属：count/totalPages/currentPage/pageSize |

- requestId 不是独立 UUID，而是 traceId。Gateway 生成 → 经 `X-Trace-Id` 头透传 → 写入日志 + 返回给客户端
- JSON key 使用 lowerCamelCase
- 语言特定实现见 `rules/java/patterns.md` 和 `rules/typescript/patterns.md`
