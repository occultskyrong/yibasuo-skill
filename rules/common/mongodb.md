# MongoDB 规范

> 基于 MongoDB 官方最佳实践（2024-2025）和现有项目经验（pts-server TypeORM + MongoDB）。

## 集合命名

| 规则 | 说明 |
| ------ | ------ |
| 格式 | `snake_case`，复数名词 |
| 长度 | ≤ 120 字节 |
| 禁止 | `$`、`.`、空格、`\0`，禁止以 `system.` 开头 |

### 示例

```text
# 业务集合
child_attendances
temp_users
student_leave_records

# 归档集合
{collection}_archive      # 删除前归档
{collection}_logs          # 变更日志
```

## 字段命名

| 规则 | 说明 |
| ------ | ------ |
| 格式 | **`camelCase`**（MongoDB 官方推荐，文档体积比 snake_case 小 ~7%） |
| 禁止 | `$` 前缀、`.` 在字段名中 |
| 禁止 | 过长字段名（每个字段名占用 BSON 空间） |
| `_id` | 始终使用默认 ObjectId，**禁止自定义 `_id` 类型**（如自增数字、UUID） |

```json
// GOOD
{
  "_id": ObjectId("..."),
  "childId": "CH001",
  "fullName": "张三",
  "attendanceDate": "2026-06-08",
  "createdAt": ISODate("2026-06-08T08:00:00Z"),
  "createdBy": "admin"
}

// BAD — snake_case 浪费 BSON 缓存
{
  "_id": ObjectId("..."),
  "child_id": "CH001",
  "full_name": "张三",
  "attendance_date": "2026-06-08"
}
```

## 文档设计

### 嵌入 vs 引用

| | 嵌入（Embedded） | 引用（Reference） |
| --- | :---: | :---: |
| 适用 | 1:few 关系，始终一起读取 | 1:many 关系，独立查询 |
| 上限 | 子文档 < 100 条 | 无限制 |
| 更新 | 原子写入 | 需要多次操作或多文档事务 |
| 文档大小 | 不超过 16MB BSON 限制 | — |

### 混合模式（推荐）

嵌入摘要，引用详情——平衡读性能和写效率：

```json
// orders 集合 — 嵌入商品摘要
{
  "_id": ObjectId("..."),
  "userId": ObjectId("..."),
  "items": [
    {
      "productId": ObjectId("..."),
      "productName": "笔记本电脑",     // 嵌入摘要（快速展示）
      "price": 999
    }
  ],
  "createdAt": ISODate("...")
}

// products 集合 — 完整商品详情
{
  "_id": ObjectId("..."),
  "name": "笔记本电脑",
  "description": "...",
  "specifications": { ... },
  "stock": 100
}
```

### 判断标准

执行 `$lookup` 前问自己：这条数据是否**总是**和父文档一起展示？是→嵌入，否→引用。

## 审计字段

MongoDB 不需要逻辑删除。**删前归档 + 物理删除**：

```json
{
  "_id": ObjectId("..."),
  "createdBy": "admin",
  "createdAt": ISODate("2026-06-08T08:00:00Z"),
  "updatedBy": "admin",
  "updatedAt": ISODate("2026-06-08T08:00:00Z"),
  // 业务字段...
}
```

| 字段 | 类型 | 说明 |
| ------ | ------ | ------ |
| `_id` | ObjectId | MongoDB 默认主键，天然分布式唯一 |
| `createdBy` | String? | 创建人 ID |
| `createdAt` | ISODate | 创建时间 |
| `updatedBy` | String? | 更新人 ID |
| `updatedAt` | ISODate | 更新时间 |

### 删除流程

```text
1. 将文档写入 {collection}_archive
2. 从主集合中物理删除
3. 归档集合保留原始 `_id` + 删除时间 `archivedAt`
```

## 索引策略

### 命名

```text
{collection}_{字段1}[_{字段2}]_idx
```

| 索引类型 | 前缀 | 示例 |
| --------- | ------ | ------ |
| 普通索引 | `idx` | `child_attendances_child_id_idx` |
| 唯一索引 | `uk` | `users_phone_uk` |
| 复合索引 | `idx` | `orders_user_status_idx` |
| 文本索引 | `txt` | `products_name_txt` |

### 规则

- **每个集合索引数 ≤ 5**
- 高区分度字段优先建索引
- 覆盖查询：`projection` 只返回索引中的字段
- `$lookup` 的 `foreignField` 必须建索引
- 用 `explain()` 验证：`db.collection.find(...).explain("executionStats")`

### 反模式

| 反模式 | 说明 |
| -------- | ------ |
| 无索引全表扫描 | `COLLSCAN` 导致慢查询 |
| 大数组字段建索引 | 数组元素每个都建索引项，体积爆炸 |
| 写入密集集合建过多索引 | 每次写入要更新所有索引 |
| 正则查询无索引支持 | 用 `text` index 替代 `$regex` |

## 数据迁移

MongoDB 无 schema 约束，迁移策略与 MySQL 不同：

| 场景 | 做法 |
| ------ | ------ |
| 新增字段 | 直接写入，旧文档 `$exists: false` 做默认值处理 |
| 删除字段 | 跑脚本 `$unset` 清理，或代码层面忽略 |
| 改字段名 | 跑脚本 `$rename` 批量更新，分批 1000 条 |
| 改字段类型 | 跑脚本逐条转换，禁止全量 `updateMany` 直接改 |

- 迁移脚本与业务代码**同 PR 提交**
- 迁移脚本必须**幂等**（可重复执行）
- 大集合迁移用 `batchSize` 分批，避免锁库

## 反模式

| 反模式 | 正确做法 |
| -------- | --------- |
| snake_case 字段名 | camelCase，MongoDB 官方推荐 |
| `_id` 用自增数字或 UUID | 始终用 ObjectId |
| 逻辑删除（`deletedAt`） | 删前归档 + 物理删除 |
| 超大文档（接近 16MB） | 拆分为引用集合 |
| 无限增长的嵌套数组 | 抽到独立集合 |
| 无索引的全集合扫描 | explain() 验证后用索引 |
| `$lookup` 不加索引 | `foreignField` 必建索引 |
| 全量 updateMany 改 schema | 分批处理，每批 ≤ 1000 条 |
| 无写入关注（write concern） | 生产环境 `w: "majority"` |
| 直接在生产库跑迁移 | 先在 staging 验证 |

## 审查清单

- [ ] 集合名 `snake_case` 复数，≤ 120 字节
- [ ] 字段名 `camelCase`，无 `$` 前缀
- [ ] `_id` 使用 ObjectId，未自定义类型
- [ ] 审计字段 `createdBy`/`createdAt`/`updatedBy`/`updatedAt` 完整
- [ ] 无 `deletedAt` 逻辑删除
- [ ] 文档不超过 16MB，嵌入数组有上限
- [ ] 查询字段已建索引，用 `explain()` 验证
- [ ] `$lookup` 的 `foreignField` 已建索引
- [ ] 迁移脚本已幂等，大集合分批处理
- [ ] 删除操作有归档步骤
