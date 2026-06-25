# Elasticsearch 索引规范

## 命名格式

```text
{dataset}[-{subtype}]-{namespace}[-YYYY-MM]
```

| 段 | 说明 | 必填 | 示例 |
| ---- | ------ | :---: | ------ |
| `{dataset}` | 数据描述，小写连字符，简洁命名 | **是** | `documents`、`memory-facts`、`search-logs` |
| `{subtype}` | 子类型，进一步细分数据 | 否 | `chunks`、`embeddings` |
| `{namespace}` | 环境标识，后缀位置 | **是** | `production`、`staging` |
| `-YYYY-MM` | 时间后缀，4 位年 + 2 位月 | 否 | `-2026-06` |

### 分隔符

- **统一使用 `-`（连字符）**，对齐 ECS 标准（`{type}-{dataset}-{namespace}`）
- 禁止混用 `_` 和 `-`

### 时间后缀判断

| 数据类型 | 加时间后缀？ | 判断标准 |
| --------- | :---: | ------ |
| 实体索引 | 否 | 数据按业务主键 CRUD，5 年后仍需在同一索引（文档、知识库、用户画像） |
| 时序索引 | **是** | 数据 append-only，按月自然增长（日志、对话记忆、事件流、消息记录） |

### 示例

```text
# 实体索引
documents-production
documents-chunks-staging
knowledge-chunks-production

# 时序索引
memory-facts-production-2026-06
memory-facts-staging-2026-06
search-logs-production-2026-06
```

## 别名

每个索引创建时**必须**同时创建读写别名，应用代码始终通过别名操作索引：

| 别名 | 指向 | 用途 |
| ------ | ------ | ------ |
| `{index}-write` | 当前活跃索引 | 写入 |
| `{index}-read` | 单个索引或最近 N 个月索引 | 读取 |

```text
# 实体索引
documents-production-write    →  documents-production
documents-production-read     →  documents-production

# 时序索引
memory-facts-production-write →  memory-facts-production-2026-06
memory-facts-production-read  →  memory-facts-production-*（最近 3 个月）
```

## Index Template

所有索引必须通过 index template 创建，确保 mappings、settings、aliases 一致：

```json
{
  "index_patterns": ["documents-*"],
  "template": {
    "aliases": {
      "documents-production-read": {}
    },
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "dynamic": "strict"
    }
  }
}
```

- **命名**：template 名称与索引 `{dataset}` 一致（如 `documents-template`）
- **mappings**：`dynamic: strict` 防止未定义字段写入
- **settings**：分片数和副本数按数据量配置，默认 1+0

## ILM（Index Lifecycle Management）

时序索引必须配置 ILM policy 自动 rollover 和删除：

| 阶段 | 触发条件 | 动作 |
| ------ | --------- | ------ |
| hot | — | 写入中 |
| warm | 距创建 30 天 | 迁移到温节点，readonly |
| delete | 距创建 90 天 | 删除索引 |

- ILM policy 名称：`{dataset}-policy`
- 实体索引可省略 ILM

## 反模式

| 反模式 | 正确做法 |
| -------- | --------- |
| 硬编码索引名 | 使用集中化 `getIndexName()` 函数 |
| 混用 `_` 和 `-` 分隔符 | 统一 `-` |
| 无别名直接操作索引 | 始终通过 `-read` / `-write` 别名 |
| 实体索引加时间后缀（`documents-production-2026-06`） | `documents-production` |
| 时序索引无时间后缀无限增长 | 加 `-YYYY-MM` 后缀 + ILM |
| namespace 重复出现 | 只出现在末尾 |
| `dynamic: true`（默认） | 显式设置 `dynamic: strict` |
| 全小写 `shakespeare-macbeth` | ES 索引名受 255 字节限制 |

## 审查清单

新增或修改 ES 索引时逐项检查：

- [ ] 命名格式 `{dataset}[-{subtype}]-{namespace}[-YYYY-MM]`
- [ ] 全小写，`-` 分隔，无特殊字符
- [ ] 实体索引无时间后缀，时序索引加 `-YYYY-MM`
- [ ] 读写别名已创建，应用代码通过别名访问
- [ ] index template 已配置（mappings/settings/aliases）
- [ ] 时序索引已配置 ILM policy
- [ ] `dynamic: strict` 防止未定义字段
- [ ] 索引名通过集中化工具函数生成，无硬编码
