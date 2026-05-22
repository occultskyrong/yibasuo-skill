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

Use a consistent envelope for all API responses:
- Include a success/status indicator
- Include the data payload (nullable on error)
- Include an error message field (nullable on success)
- Include metadata for paginated responses (total, page, limit)

## 数据库迁移

```
编写脚本 → 本地验证 → 提交仓库 → CI 幂等校验 → 部署执行 → 记录状态
```

1. **编写脚本**
   - 命名：`YYYYMMDD-{动作}-{对象}.sql`，日期在前确保按时间排序
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
