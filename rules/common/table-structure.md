# 表结构规范

> MySQL 表结构设计规范，基于 p3c（阿里巴巴 Java 开发手册）数据库规约。语言无关。

## 命名

- 数据库名/表名/列名：**全小写 + 下划线**，禁止大写字母
- 表名不使用复数（`admin_user` 非 `admin_users`）
- 索引命名：`pk_`（主键）/ `uk_`（唯一）/ `idx_`（普通）
- 表名/列名长度 ≤ 32 字符

## 字段类型

| 场景 | 类型 | 说明 |
|------|------|------|
| 主键 ID | `INT NOT NULL AUTO_INCREMENT` | 非 p3c 的 `BIGINT`，INT 足够（2^31 ≈ 21 亿） |
| 金额 | `DECIMAL(m,n)` | 禁止 `FLOAT`/`DOUBLE`，m 和 n 按业务设定 |
| 定长字符串 | `CHAR(n)` | n ≤ 255 |
| 变长字符串 | `VARCHAR(n)` | n ≤ 5000，超长用 `TEXT` |
| 是/否 | `TINYINT` | 禁止 `CHAR(1)` 或 `ENUM` |
| 时间 | `DATETIME` | 禁止 `TIMESTAMP`（2038 溢出风险） |
| 状态 | `TINYINT` 或 `VARCHAR(32)` | 枚举值写入 `COMMENT` 中 |
| 日期 | `DATE` | `yyyy-MM-dd` 格式 |

所有字段必须 `COMMENT`。尽可能 `NOT NULL`，必须为空时才用 `NULL`。

## 审计字段

| 表类型 | id | created_by / updated_by | created_at / updated_at | deleted_at |
|--------|:---:|:---:|:---:|:---:|
| 业务主表 | ✅ | ✅ | ✅ | ✅ 逻辑删除 |
| 关联表（中间表） | ✅ | ❌ | ❌ | ❌ 物理删除 |
| 日志表 | ✅ | ❌ | ✅ | ❌ 物理删除 |

## 自增 ID

自增 ID 从 **1000-3000 之间随机数**开始，禁止从 1 开始——防止按 ID 遍历、泄露数据量、合并时冲突。

```sql
CREATE TABLE `order` (
    ...
) ENGINE=InnoDB AUTO_INCREMENT={1000-3000随机值};
```

## 核心约束

- **禁止使用外键** — 在应用层解决
- 业务表逻辑删除：`deleted_at`，关联表/日志表物理删除
- 数据库用户：`{库名}_{环境}`，禁止 root
- 字符集统一 `utf8mb4`，排序规则 `utf8mb4_unicode_ci`
- 所有 DDL 语句用 `IF NOT EXISTS` 保证幂等

## 业务表模板

```sql
CREATE TABLE IF NOT EXISTS `{table_name}` (
    id         INT    NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
    -- 业务字段 --
    created_by INT      COMMENT '创建人 ID',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_by INT      COMMENT '更新人 ID',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at DATETIME COMMENT '逻辑删除（NULL=未删除）',
    PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT={1000-3000随机值} DEFAULT CHARSET=utf8mb4;
```

## 关联表模板

```sql
CREATE TABLE IF NOT EXISTS `{table_name}` (
    id         INT  NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
    -- 关联字段 --
    PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT={1000-3000随机值} DEFAULT CHARSET=utf8mb4;
```

## 日志表模板

```sql
CREATE TABLE IF NOT EXISTS `{table_name}` (
    id          INT      NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
    -- 日志字段 --
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT={1000-3000随机值} DEFAULT CHARSET=utf8mb4;
```

## 审查清单

- [ ] 表名/列名全小写+下划线，长度 ≤ 32
- [ ] 主键 `INT AUTO_INCREMENT`，非 `BIGINT`
- [ ] 金额用 `DECIMAL`，非 `FLOAT`/`DOUBLE`
- [ ] 时间用 `DATETIME`，非 `TIMESTAMP`
- [ ] 所有字段有 `COMMENT`
- [ ] 尽可能 `NOT NULL`
- [ ] 审计字段按表类型正确配置
- [ ] 自增 ID 起始值在 1000-3000 之间
- [ ] 无物理外键
- [ ] 字符集 `utf8mb4`
