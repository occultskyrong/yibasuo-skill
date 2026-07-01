# Java 项目模板规格 (Spring Boot 4.0.6 + Java 21)

## 目录结构

```
{project}/
├── README.md / CLAUDE.md / .env.example / .gitignore / .dockerignore
├── pom.xml / mvnw / mvnw.cmd
├── src/main/java/{package}/
│   ├── Application.java              # @SpringBootApplication
│   ├── common/
│   │   ├── ApiResponse.java          # Record: status/message/data/requestId/metadata
│   │   ├── BaseEntity.java           # @MappedSuperclass，6 个审计字段（业务表用）
│   │   ├── AuditMetaObjectHandler.java  # MyBatis-Plus 审计字段自动填充
│   │   ├── GlobalExceptionHandler.java
│   │   └── MybatisPlusConfig.java    # 分页插件 + MapperScan
│   └── modules/                      # .gitkeep 占位
├── src/main/resources/
│   ├── application.yml
│   ├── application-test.yml
│   ├── application-prod.yml
│   └── logback-spring.xml
├── src/main/resources/db/migration/
│   └── V{YYYYMMDD}__init_schema.sql  # Flyway DDL，含审计字段模板
└── src/test/java/{package}/
```

## pom.xml

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.0.6</version>
</parent>

<properties>
    <java.version>21</java.version>
    <spring-cloud.version>2025.1.0</spring-cloud.version>
    <spring-cloud-alibaba.version>2025.1.0.0</spring-cloud-alibaba.version>
    <mybatis-plus.version>3.5.16</mybatis-plus.version>
    <nimbus-jose-jwt.version>10.9</nimbus-jose-jwt.version>
    <springdoc-openapi.version>3.0.3</springdoc-openapi.version>
    <logstash-logback.version>9.0</logstash-logback.version>
</properties>
```

> **⚠️ 如需添加 gRPC 依赖（如 `spring-grpc-spring-boot-starter`）**，必须同时添加 `<grpc.version>` 属性并与 `grpc-netty` 传递版本对齐。详见 [java-grpc-templates.md](java-grpc-templates.md) 中的「gRPC 版本对齐铁律」。版本不对齐会导致所有 gRPC 客户端连接失败，极难排查。

### 核心依赖

| 依赖 | artifact | 版本 | 说明 |
|------|---------|------|------|
| Spring Boot | `spring-boot-starter-web` | 4.0.6 | Web 框架 |
| Spring Boot | `spring-boot-starter-validation` | 4.0.6 | Bean Validation |
| Spring Boot | `spring-boot-starter-security` | 4.0.6 | 安全框架 |
| Spring Boot | `spring-boot-starter-data-redis` | 4.0.6 | Redis 客户端 |
| Spring Boot | `spring-boot-starter-actuator` | 4.0.6 | 健康检查 |
| Spring Cloud | `spring-cloud-dependencies` | 2025.1 (Oakwood) | 微服务 BOM |
| Spring Cloud Alibaba | `spring-cloud-alibaba-dependencies` | 2025.1.0.0 | 阿里云 BOM |
| Nacos Config | `spring-cloud-starter-alibaba-nacos-config` | (代管) | 配置中心 |
| Nacos Discovery | `spring-cloud-starter-alibaba-nacos-discovery` | (代管) | 服务发现 |
| MyBatis-Plus | `mybatis-plus-spring-boot4-starter` | 3.5.16 | ORM（注意用 boot4-starter） |
| JWT | `nimbus-jose-jwt` | 10.9 | JWT 解析（CVE-2025-53864 修复） |
| OpenAPI | `springdoc-openapi-starter-webmvc-ui` | 3.0.3 | API 文档（SB4 需 v3.x） |
| 日志 JSON | `logstash-logback-encoder` | 9.0 | JSON 日志（Jackson 3） |
| 数据库 | `mysql-connector-j` | (代管) | MySQL 驱动 |
| 迁移 | `flyway-mysql` | (代管) | 数据库迁移 |
| 定时任务 | `xxl-job-core` | 2.5.0 | 分布式任务调度（生产唯一方案） |
| 工具 | `lombok` | (代管) | 可选 |
| AOP | `aspectjweaver` | (代管) | AOP 支持，按需引入 |
| Sentinel | `sentinel-spring-cloud-gateway-adapter` | **1.8.8** | Gateway 限流熔断，**SCA BOM 不管此 artifact，需显式锁版本** |

### Gateway 专用

SC 2025.x 中 Gateway artifact 已拆分，需用新的：

```xml
<!-- Gateway 服务端 (WebFlux) -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway-server-webflux</artifactId>
</dependency>

<!-- 负载均衡（Gateway 必须保留） -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-loadbalancer</artifactId>
</dependency>
```

Gateway 配置前缀也变更：
```yaml
# 旧 (SC 2023.x)
spring.cloud.gateway.routes
# 新 (SC 2025.x)
spring.cloud.gateway.server.webflux.routes
```

- **禁止** `spring-cloud-starter-bootstrap`：SCA 2025.1 已移除 bootstrap 支持，改用 `spring.config.import`
- p3c-pmd plugin（阿里巴巴 Java 开发手册）
- maven-wrapper (mvnw)

## CLAUDE.md

面向 AI 的项目文档。初始化后随项目演进持续更新。

```markdown
# CLAUDE.md — {project}

## 项目概述

{project} — {一句话描述}。{技术栈简述}。

## 架构

{分层说明，如 Controller→Service→Mapper→Entity}

### 模块清单

| 模块 | 路径 | 说明 |
|------|------|------|

## 常用命令

| 操作 | 命令 |
|------|------|
| 开发 | `./mvnw spring-boot:run` |
| 构建 | `./mvnw clean package -DskipTests` |
| 测试 | `./mvnw test` |
| 格式检查 | `./mvnw pmd:check` |

## 端口 & 配置

| 环境 | 端口 | 数据库 | Redis |
|------|------|--------|-------|
| dev  | {port} | {db} | {redis} |

## 编码约定

遵循 `rules/java/patterns.md` + 阿里巴巴 Java 开发手册。

- 分层 controller→service→mapper→entity，Controller 禁止直接调用 Mapper
- 统一 `ApiResponse<T>` 响应
- 逻辑删除 `deleted_at` + MyBatis-Plus `@TableLogic`
- Redis Key 带环境前缀，全部带 TTL
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

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 填入数据库、Redis 等配置

# 3. 启动
./mvnw spring-boot:run
```

## 技术栈

| 组件 | 版本 |
|------|------|
| Java | 21 |
| Spring Boot | 4.0.6 |
| MyBatis-Plus | 3.5.16 |
| MySQL | 8.x |
| Redis | 7.x |

## API

启动后访问 Swagger 文档：`http://localhost:{port}/swagger-ui.html`

## 部署

```bash
./mvnw clean package -DskipTests
java -jar target/{project}.jar --spring.profiles.active=prod
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

## Application.java

- `@SpringBootApplication` + `main` 方法

## ApiResponse.java

遵循 `rules/java/patterns.md` + 阿里巴巴 Java 开发手册前后端规约：

```java
public record ApiResponse<T>(Object code, String message, T data, String requestId) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(0, "操作成功", data, UUID.randomUUID().toString().replace("-", ""));
    }
    public static <T> ApiResponse<T> fail(String code, String message) {
        return new ApiResponse<>(code, message, null, UUID.randomUUID().toString().replace("-", ""));
    }
}
```

- `code`: 成功=0(Integer)，失败=String（业务错误码）
- `requestId`: UUID 去横线，每次请求唯一
- 空列表返回 `[]`，禁止 `null`

## GlobalExceptionHandler.java

- `@RestControllerAdvice`
- MethodArgumentNotValidException → 400 + ApiResponse.error
- Exception → 500 + 记录完整堆栈 + 返回 "Internal server error"

## application.yml（基础配置）

Nacos 在 base 配置中**禁用**，只在 test/prod profile 中激活：

```yaml
spring:
  application.name: {project}
  profiles.active: ${SPRING_PROFILES_ACTIVE:dev}
  cloud.nacos.config.enabled: false
  cloud.nacos.discovery.enabled: false
  data.redis:
    host: ${REDIS_HOST:localhost}
    port: ${REDIS_PORT:6379}
    password: ${REDIS_PASSWORD:}
    database: 10
  datasource:
    url: jdbc:mysql://${DB_HOST:localhost}:${DB_PORT:3306}/{db_name}?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}

server:
  port: {port}

logging:
  file.name: ${user.home}/logs/${spring.application.name}.log
```

## application-test.yml / application-prod.yml（环境激活 Nacos）

**SCA 2025.1 不再支持 bootstrap.yml**，改用 profile 文件 + `spring.config.import`：

```yaml
spring:
  config:
    import:
      - optional:nacos:application-common.yaml?group=DEFAULT_GROUP&namespace=${NACOS_NAMESPACE}&refreshEnabled=true
      - optional:nacos:${spring.application.name}.yaml?group=DEFAULT_GROUP&namespace=${NACOS_NAMESPACE}&refreshEnabled=true
  cloud:
    nacos:
      config:
        enabled: true
        server-addr: ${NACOS_ADDR}
        username: ${NACOS_USERNAME}
        password: ${NACOS_PASSWORD}
      discovery:
        enabled: true
        server-addr: ${NACOS_ADDR}
        namespace: ${NACOS_NAMESPACE}
        username: ${NACOS_USERNAME}
        password: ${NACOS_PASSWORD}

logging:
  level:
    root: WARN  # prod profile 中设置
```

- bootstrap.yml / bootstrap-test.yml / bootstrap-prod.yml **全部删除**
- `optional:` 前缀确保 Nacos 不可用时服务仍可启动（降级使用 application.yml 中的默认值）

## logback-spring.xml

严格遵循 `rules/java/logging.md`：

- 控制台: 彩色(dev) / 纯文本(prod)
- 文件: SizeAndTimeBasedRollingPolicy, 10MB/30天
- AsyncAppender: queueSize=512, discardingThreshold=0
- TraceId: `%X{traceId}`
- Root: WARN(prod) / INFO(dev), 业务包: INFO
- 格式: `%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] [%X{traceId}] %-5level %logger{50}:%L - %msg%n`

## TraceIdFilter.java

```java
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class TraceIdFilter implements Filter {
    private static final String TRACE_ID_HEADER = "X-Trace-Id";
    private static final String MDC_KEY = "traceId";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String traceId = httpRequest.getHeader(TRACE_ID_HEADER);
        if (traceId == null || traceId.isEmpty()) {
            traceId = UUID.randomUUID().toString().replace("-", "").substring(0, 8);
        }
        MDC.put(MDC_KEY, traceId);
        httpResponse.setHeader(TRACE_ID_HEADER, traceId);
        try {
            chain.doFilter(request, response);
        } finally {
            MDC.remove(MDC_KEY);
        }
    }
}
```

## RestClient 转发 traceId

```java
// forward() 中
String traceId = MDC.get("traceId");
if (traceId != null && !traceId.isEmpty()) {
    spec = spec.header("X-Trace-Id", traceId);
}
// ⚠️ 必须判空。MDC 在测试环境可能无值，直接 header("X-Trace-Id", null) 会导致
//    RestClient 静默丢 header，下游收不到 traceId。
```

## Gateway（WebFlux）特殊注意

- **AuthFilter**: traceId 必须写入 `exchange.getResponse().getHeaders()`（供后续 filter 读）
- **ResponseLogFilter**: 从响应头读 traceId——**不要**从 MDC 或 Reactor context 读（WebFlux 线程切换会丢）
- 详细规范见 `references/trace-id.md`（yibasuo skill）

## BaseEntity.java

业务实体基类，包含 6 个标准审计字段。**仅业务主表继承此类**。

| 表类型 | 继承 BaseEntity | deleted_at | created_by/updated_by |
|--------|:---:|:---:|:---:|
| 业务主表 | ✅ | ✅（逻辑删除） | ✅ |
| 关联表（中间表） | ❌ | ❌（物理删除） | ❌ |
| 日志表 | ❌ | ❌（物理删除） | ❌ |

```java
package {package}.common;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public abstract class BaseEntity {

    @TableId(type = IdType.AUTO)
    private Integer id;

    @TableField(fill = FieldFill.INSERT)
    private Integer createdBy;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private Integer updatedBy;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;

    @TableLogic(value = "null", delval = "now()")
    private LocalDateTime deletedAt;
}
```

### 使用方式

```java
// 业务表 — 继承 BaseEntity
@Getter
@Setter
@TableName("admin_user")
public class AdminUser extends BaseEntity {
    private String username;
    private String phone;
}

// 关联表 — 不继承，自行声明字段
@Getter
@Setter
@TableName("user_role")
public class UserRole {
    @TableId(type = IdType.AUTO)
    private Integer id;
    private Integer userId;
    private Integer roleId;
    // 无 createdAt / updatedAt / deletedAt
}
```

| 注解 | 作用 |
|------|------|
| `@TableId(type = IdType.AUTO)` | MySQL 自增主键 |
| `@TableField(fill = FieldFill.INSERT)` | insert 时自动填充（AuditMetaObjectHandler） |
| `@TableLogic(value = "null", delval = "now()")` | select 自动附加 `WHERE deleted_at IS NULL`；delete 自动改为 `UPDATE SET deleted_at = NOW()` |

## AuditMetaObjectHandler.java

MyBatis-Plus `MetaObjectHandler`，自动填充 `createdAt`/`updatedAt`/`createdBy`/`updatedBy`。

```java
package {package}.common;

import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class AuditMetaObjectHandler implements MetaObjectHandler {

    @Override
    public void insertFill(MetaObject metaObject) {
        LocalDateTime now = LocalDateTime.now();
        this.strictInsertFill(metaObject, "createdAt", LocalDateTime.class, now);
        this.strictInsertFill(metaObject, "updatedAt", LocalDateTime.class, now);
        Integer userId = getCurrentUserId();
        if (userId != null) {
            this.strictInsertFill(metaObject, "createdBy", Integer.class, userId);
            this.strictInsertFill(metaObject, "updatedBy", Integer.class, userId);
        }
    }

    @Override
    public void updateFill(MetaObject metaObject) {
        this.strictUpdateFill(metaObject, "updatedAt", LocalDateTime.class, LocalDateTime.now());
        Integer userId = getCurrentUserId();
        if (userId != null) {
            this.strictUpdateFill(metaObject, "updatedBy", Integer.class, userId);
        }
    }

    /**
     * 从 SecurityContext 提取当前用户 ID。
     * BFF 层覆盖此方法接入 JWT principal；微服务层（无鉴权）返回 null，由业务层手动 set。
     */
    protected Integer getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated()) {
            // BFF 层: 从 JWT principal 提取 user_id（按项目实际类型调整）
            return null;
        }
        return null;
    }
}
```

## MybatisPlusConfig.java

```java
package {package}.common;

import com.baomidou.mybatisplus.annotation.DbType;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@MapperScan("{package}.modules.**.mapper")
public class MybatisPlusConfig {

    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        interceptor.addInnerInterceptor(new PaginationInnerInterceptor(DbType.MYSQL));
        return interceptor;
    }
}
```

## Flyway 数据库迁移

### 依赖与配置

Spring Boot 自动集成 Flyway，**启动时自动执行迁移**（无需手动触发）。

**依赖**：`pom.xml` 中 `flyway-mysql`（由 infra 模板统一管理，版本由 Spring Boot BOM 代管）。

**`application.yml` 配置**：

```yaml
spring:
  flyway:
    enabled: true
    table: flyway_schema_history_{project}   # 每个项目独立 history 表
```

> 自定义 `table` 名称避免多项目共享同一数据库时 Flyway history 冲突。

**启动顺序**：Spring Boot 启动时 Flyway **先于** `@Entity` 扫描和 `ApplicationRunner` 执行。数据初始化逻辑（如 Seed Data）应放在 `ApplicationRunner` 中，确保迁移已完成后再写入。

### 迁移文件

文件放在 `src/main/resources/db/migration/`，命名遵循 Flyway 约定：

| 格式 | 适用场景 | 示例 |
|------|---------|------|
| `V{序号}__{描述}.sql` | BFF 层项目，迁移数量可控 | `V1__init_rbac_schema.sql`、`V2__init_super_admin.sql` |
| `V{YYYYMMDD}__{描述}.sql` | 微服务层，按日期避免编号冲突 | `V20260606__init_all_tables.sql` |

两种格式均可，同一项目内保持一致即可。**必须用双下划线 `__` 分隔版本和描述**（Flyway 强制约定）。

### 业务表模板（含审计字段）

```sql
CREATE TABLE IF NOT EXISTS `{table_name}` (
    `id`         INT       NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
    -- ↓ 业务字段在此 ↓
    `name`       VARCHAR(64)  NOT NULL                COMMENT '名称',
    -- ↑ 业务字段在此 ↑
    `created_by` INT          DEFAULT NULL            COMMENT '创建人 ID',
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_by` INT          DEFAULT NULL            COMMENT '更新人 ID',
    `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME     DEFAULT NULL            COMMENT '逻辑删除（NULL=未删除）',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT={1000-3000随机值} DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='{table_comment}';
```

### 关联表模板（无审计字段）

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

### 日志表模板（无审计字段，物理删除）

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
| 命名 | `V{YYYYMMDD}__{描述}.sql`（Flyway 默认约定，V 前缀 + 双下划线） |
| 一文件一事 | 建表、加列、加索引分开 |
| 幂等 | 所有 DDL 用 `IF NOT EXISTS` / `IF EXISTS` |
| 已部署禁改 | 已部署到任何环境的脚本禁止修改，变更写新脚本 |
| 审计字段 | 业务表必须含 6 个审计字段；关联表/日志表不含 |
| 逻辑删除 | 业务表用 `deleted_at`；关联表/日志表物理删除 |
