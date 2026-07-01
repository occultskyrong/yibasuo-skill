# NestJS 项目模板规格 (v11 + Node 24 LTS)

## 目录结构

```
{project}/
├── README.md / CLAUDE.md / .env.example / .gitignore / .dockerignore
├── package.json / tsconfig.json / tsconfig.build.json / nest-cli.json
├── .prettierrc / .eslintrc.js
├── src/
│   ├── main.ts                       # ValidationPipe + Helmet + CORS + pino
│   ├── app.module.ts
│   ├── common/
│   │   ├── entities/
│   │   │   └── base.entity.ts           # 抽象基类，6 个审计字段（业务表用）
│   │   ├── filters/http-exception.filter.ts
│   │   ├── interceptors/response.interceptor.ts
│   │   └── dto/api-response.dto.ts
│   └── <feature>/                     # .gitkeep 占位，module 直接铺在 src 下
├── test/
│   ├── app.e2e-spec.ts / jest-e2e.json
└── logs/
```

## package.json

- `@nestjs/core` ^11.1, `@nestjs/platform-express`
- `class-validator`, `class-transformer`
- `helmet`, `pino`, `pino-pretty`
- scripts: `start:dev`, `start:prod`, `build`, `test`, `test:e2e`, `format`, `lint`

## CLAUDE.md

面向 AI 的项目文档。初始化后随项目演进持续更新。

```markdown
# CLAUDE.md — {project}

## 项目概述

{project} — {一句话描述}。{技术栈简述}。

## 架构

{分层说明，如 Controller→Service→Repository}

### 模块清单

| 模块 | 路径 | 说明 |
|------|------|------|

## 常用命令

| 操作 | 命令 |
|------|------|
| 开发 | `<pkg> start:dev` |
| 构建 | `<pkg> build` |
| 测试 | `<pkg> test` |
| E2E | `<pkg> test:e2e` |
| 格式 | `<pkg> format && <pkg> lint` |

## 端口 & 配置

| 环境 | 端口 | 数据库 | Redis |
|------|------|--------|-------|
| dev  | {port} | {db} | {redis} |

## 编码约定

遵循 `rules/typescript/patterns.md`。

- 严格分层 Controller→Service→Repository，绝不越层调用
- 统一 `ApiResponse` 响应：`{ code, message, data, requestId, metadata }`
- requestId 即 traceId，全链路透传
- pino 日志，`__` 前缀私有方法
- 时间格式 `yyyy-MM-dd HH:mm:ss.SSS`
```

## README.md

面向用户的项目文档。初始化后随功能变化更新。

```markdown
# {project}

> {一句话描述}

## 快速开始

```bash
# 1. 克隆
git clone {repo_url}
cd {project}

# 2. 安装依赖
pnpm install  # 或 yarn / npm install

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env 填入数据库、Redis 等配置

# 4. 启动
pnpm start:dev
```

## 技术栈

| 组件 | 版本 |
|------|------|
| Node.js | >= 20.11.1 |
| NestJS | 11.x |
| TypeScript | 5.x |
| MySQL | 8.x |
| Redis | 7.x |

## API

启动后访问 Swagger 文档：`http://localhost:{port}/api`

## 部署

```bash
pnpm build
pnpm start:prod
```
```

### 更新时机

| 事件 | 更新哪个 |
|------|---------|
| 新增模块 | CLAUDE.md 模块清单 |
| 修改端口/数据库 | CLAUDE.md 端口配置 |
| 新增 API 接口 | README.md API 说明 |
| 修改安装步骤 | README.md 快速开始 |
| 技术栈升级 | 两者都更新 |
| 架构变更 | CLAUDE.md 架构图 |

## main.ts

遵循 `rules/typescript/logging.md`：

- ValidationPipe: whitelist + forbidNonWhitelisted + transform
- Helmet + CORS
- traceId 中间件: 从 `X-Trace-Id` 请求头提取，无则 UUID 生成 → AsyncLocalStorage
- pino/日志注入: winston `format((info) => { info.traceId = getTraceId(); return info; })()`
- 日志格式: `时间 [traceId] 级别 来源 - 消息`
- 全局注册: HttpExceptionFilter + ResponseInterceptor

## trace.context.ts

```typescript
import { AsyncLocalStorage } from 'async_hooks';

interface TraceContext { traceId: string; }

export const traceContext = new AsyncLocalStorage<TraceContext>();

export function getTraceId(): string {
  return traceContext.getStore()?.traceId ?? '';
}
```

## trace.middleware.ts

```typescript
@Injectable()
export class TraceMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const traceId = req.get('x-trace-id')
      || `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;
    res.setHeader('X-Trace-Id', traceId);
    traceContext.run({ traceId }, () => next());
  }
}
```

## 中间件注册顺序

```typescript
// TraceMiddleware 必须最先
consumer.apply(TraceMiddleware, LoggerMiddleware, CorsMiddleware).forRoutes('*');
```

## Logger 注入 traceId

```typescript
// winston format 链
format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
format((info) => { info.traceId = getTraceId(); return info; })(),
format.json(),

// console printf
const tid = traceId ? `[${traceId}] ` : '';
return `${timestamp} [${level}] ${tid}${ctx}${message}`;
```

## app.module.ts

- 空模块，仅 `imports: []`

## http-exception.filter.ts

遵循 `rules/typescript/patterns.md`：

- `@Catch()` 捕获所有异常
- HttpException → status >=2, safe message + error_code
- 未知 → status 10001, 记录完整 Error, 返回 "Internal server error"

## response.interceptor.ts

- 包裹: `{ status: 0, message: "请求成功", data, requestId, metadata: { timestamp, method, endpoint } }`
- 自动处理分页 metadata（count, totalPages, currentPage, pageSize）

## api-response.dto.ts

- `status: number`, `message: string`, `data: T|null`, `requestId: string`
- `error_code?: number`, `error_message?: string`
- `metadata: { timestamp: string, method: string, endpoint: string, count?, totalPages?, currentPage?, pageSize? }`

## tsconfig.json

- `strict: true`, `target: ES2023`, `module: NodeNext`, `moduleResolution: NodeNext`
- `experimentalDecorators: true`, `emitDecoratorMetadata: true`

## base.entity.ts

业务实体基类，包含 6 个标准审计字段。**仅业务主表继承此类**。

| 表类型 | 继承 BaseEntity | deleted_at | createdBy/updatedBy |
|--------|:---:|:---:|:---:|
| 业务主表 | ✅ | ✅（逻辑删除） | ✅ |
| 关联表（中间表） | ❌ | ❌（物理删除） | ❌ |
| 日志表 | ❌ | ❌（物理删除） | ❌ |

```typescript
import {
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  DeleteDateColumn,
  Column,
} from 'typeorm';

export abstract class BaseEntity {
  @PrimaryGeneratedColumn({ type: 'int', comment: '主键 ID' })
  id: number;

  @Column({ type: 'int', nullable: true, comment: '创建人 ID' })
  createdBy: number | null;

  @CreateDateColumn({ type: 'datetime', precision: 3, comment: '创建时间' })
  createdAt: Date;

  @Column({ type: 'int', nullable: true, comment: '更新人 ID' })
  updatedBy: number | null;

  @UpdateDateColumn({ type: 'datetime', precision: 3, comment: '更新时间' })
  updatedAt: Date;

  @DeleteDateColumn({ type: 'datetime', precision: 3, nullable: true, comment: '逻辑删除（NULL=未删除）' })
  deletedAt: Date | null;
}
```

### 使用方式

```typescript
// 业务表 — 继承 BaseEntity
@Entity('admin_user')
export class AdminUser extends BaseEntity {
  @Column({ type: 'varchar', length: 64 })
  username: string;
}

// 关联表 — 不继承，自行声明字段
@Entity('user_role')
export class UserRole {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @Column({ type: 'int' })
  userId: number;

  @Column({ type: 'int' })
  roleId: number;
}
```

| 装饰器 | 作用 |
|--------|------|
| `@PrimaryGeneratedColumn({ type: 'int' })` | MySQL INT 自增主键 |
| `@CreateDateColumn` | insert 时自动设为 `CURRENT_TIMESTAMP` |
| `@UpdateDateColumn` | insert + update 时自动设为 `CURRENT_TIMESTAMP` |
| `@DeleteDateColumn` | softDelete 自动填 `deleted_at`；find 自动附加 `WHERE deleted_at IS NULL` |

### Prisma Schema（无 TypeORM 时）

```prisma
model AdminUser {
  id        Int       @id @default(autoincrement()) @db.Int
  username  String    @db.VarChar(64)
  createdBy Int?      @map("created_by")
  createdAt DateTime  @default(now()) @map("created_at")
  updatedBy Int?      @map("updated_by")
  updatedAt DateTime  @updatedAt @map("updated_at")
  deletedAt DateTime? @map("deleted_at")

  @@map("admin_user")
}
```

### 逻辑删除支持

| ORM | 方式 |
|-----|------|
| TypeORM | `@DeleteDateColumn()` + `softDelete()` / `softRemove()` + find 自动附加 `WHERE deleted_at IS NULL` |
| Prisma | 无内置软删除，需手动 `where: { deletedAt: null }` 或 middleware 注入 |
| 原生 SQL | 手动 `WHERE deleted_at IS NULL` |

## DDL 迁移模板

### 业务表（含审计字段）

```sql
CREATE TABLE IF NOT EXISTS `{table_name}` (
    `id`         INT       NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
    -- ↓ 业务字段 ↓
    `name`       VARCHAR(64)  NOT NULL                COMMENT '名称',
    -- ↑ 业务字段 ↑
    `created_by` INT          DEFAULT NULL            COMMENT '创建人 ID',
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_by` INT          DEFAULT NULL            COMMENT '更新人 ID',
    `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME     DEFAULT NULL            COMMENT '逻辑删除（NULL=未删除）',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT={1000-3000随机值} DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='{table_comment}';
```

### 关联表（无审计字段）

```sql
CREATE TABLE IF NOT EXISTS `{table_name}` (
    `id`         INT       NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
    -- ↓ 关联字段 ↓
    `user_id`    INT       NOT NULL                COMMENT '用户 ID',
    `role_id`    INT       NOT NULL                COMMENT '角色 ID',
    -- ↑ 关联字段 ↑
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_role` (`user_id`, `role_id`)
) ENGINE=InnoDB AUTO_INCREMENT={1000-3000随机值} DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='{table_comment}';
```

### 日志表（无审计字段，物理删除）

```sql
CREATE TABLE IF NOT EXISTS `{table_name}` (
    `id`          INT       NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
    -- ↓ 日志字段 ↓
    `user_id`     INT       DEFAULT NULL            COMMENT '操作人 ID',
    `action`      VARCHAR(32)  NOT NULL                COMMENT '操作类型',
    `detail`      TEXT                                 COMMENT '操作详情',
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    -- ↑ 日志字段 ↑
    PRIMARY KEY (`id`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT={1000-3000随机值} DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='{table_comment}';
```

### 迁移铁律

| 规则 | 说明 |
|------|------|
| 命名 | `V{YYYYMMDD}__{描述}.sql`（Flyway 默认约定） |
| 一文件一事 | 建表、加列、加索引分开 |
| 幂等 | 所有 DDL 用 `IF NOT EXISTS` / `IF EXISTS` |
| 已部署禁改 | 已部署到任何环境的脚本禁止修改，变更写新脚本 |
| 审计字段 | 业务表必须含 6 个审计字段；关联表/日志表不含 |
| 逻辑删除 | 业务表用 `deleted_at`；关联表/日志表物理删除 |
