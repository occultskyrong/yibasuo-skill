# Java gRPC 微服务模板规格 (Spring Boot 4.0.6 + Java 21)

gRPC 业务 + HTTP health 微服务。业务调用只走 gRPC；HTTP 只暴露 `/healthy`。它不承载端侧 JWT/RBAC，但所有业务 RPC 必须校验调用方身份 metadata。

## 目录结构

```
{project}/
├── README.md / CLAUDE.md / .env.example / .gitignore / .dockerignore
├── pom.xml / mvnw / mvnw.cmd
├── src/main/java/{package}/
│   ├── Application.java                 # @SpringBootApplication + @MapperScan
│   ├── common/
│   │   └── Constants.java               # 业务常量
│   ├── entity/                          # MyBatis-Plus Entity
│   ├── mapper/                          # MyBatis-Plus BaseMapper
│   ├── config/
│   │   └── ServiceSecurityProperties.java # callers.<service> 鉴权配置
│   ├── service/
│   │   └── XxxServiceImpl.java          # @GrpcService，extends XxxServiceGrpc.XxxServiceImplBase
│   └── interceptor/
│       ├── TraceIdInterceptor.java      # @GlobalServerInterceptor，metadata → MDC
│       └── InternalAuthInterceptor.java # @GlobalServerInterceptor，调用方 token 校验
├── src/main/proto/{domain}/v1/
│   ├── common.proto                     # PageRequest / PageResponse
│   └── {service}_service.proto          # gRPC service + RPC 定义
└── src/main/resources/
    ├── application.yml
    ├── application-test.yml
    ├── application-prod.yml
    └── logback-spring.xml
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
    <spring-cloud.version>2025.1.1</spring-cloud.version>
    <spring-cloud-alibaba.version>2025.1.0.0</spring-cloud-alibaba.version>
    <grpc.version>1.77.1</grpc.version>
    <protobuf.version>4.29.3</protobuf.version>
    <mybatis-plus.version>3.5.16</mybatis-plus.version>
    <logstash-logback.version>9.0</logstash-logback.version>
</properties>
```

### 核心依赖

| 依赖 | artifact | 版本 | 说明 |
|------|---------|------|------|
| Spring Boot | `spring-boot-starter` | 4.0.6 | 基础 |
| Spring Web | `spring-boot-starter-web` | (代管) | 仅用于 HTTP `/healthy` 和 Nacos 自动注册事件 |
| Spring gRPC | `spring-grpc-spring-boot-starter` | **1.0.2** | gRPC 服务端 |
| Protobuf | `protobuf-java` | `${protobuf.version}` | 锁定与 protoc 一致 |
| javax annotation | `javax.annotation-api` | 1.3.2 | protobuf 生成代码引用 |
| Nacos Config | `spring-cloud-starter-alibaba-nacos-config` | (代管) | 配置中心 |
| Nacos Discovery | `spring-cloud-starter-alibaba-nacos-discovery` | (代管) | 服务发现 |
| MyBatis-Plus | `mybatis-plus-spring-boot4-starter` | 3.5.16 | ORM |
| MySQL | `mysql-connector-j` | (代管) | 数据库驱动 |
| Actuator | `spring-boot-starter-actuator` | (代管) | 健康检查 |
| 日志 JSON | `logstash-logback-encoder` | 9.0 | JSON 日志 |
| gRPC Test | `grpc-testing` | `${grpc.version}` | 测试，**scope=test** |

```xml
<dependencies>
    <!-- Spring Boot -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <!-- Nacos -->
    <dependency>
        <groupId>com.alibaba.cloud</groupId>
        <artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
    </dependency>
    <dependency>
        <groupId>com.alibaba.cloud</groupId>
        <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
    </dependency>

    <!-- Spring gRPC -->
    <dependency>
        <groupId>org.springframework.grpc</groupId>
        <artifactId>spring-grpc-spring-boot-starter</artifactId>
        <version>1.0.2</version>
        <exclusions>
            <exclusion>
                <groupId>com.google.protobuf</groupId>
                <artifactId>protobuf-java</artifactId>
            </exclusion>
        </exclusions>
    </dependency>

    <!-- 锁定 protobuf 版本与 protoc 一致 -->
    <dependency>
        <groupId>com.google.protobuf</groupId>
        <artifactId>protobuf-java</artifactId>
        <version>${protobuf.version}</version>
    </dependency>

    <dependency>
        <groupId>javax.annotation</groupId>
        <artifactId>javax.annotation-api</artifactId>
        <version>1.3.2</version>
    </dependency>

    <!-- MyBatis-Plus -->
    <dependency>
        <groupId>com.baomidou</groupId>
        <artifactId>mybatis-plus-spring-boot4-starter</artifactId>
        <version>${mybatis-plus.version}</version>
    </dependency>

    <!-- MySQL -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
    </dependency>

    <!-- Actuator -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>

    <!-- logstash（JSON 日志） -->
    <dependency>
        <groupId>net.logstash.logback</groupId>
        <artifactId>logstash-logback-encoder</artifactId>
        <version>${logstash-logback.version}</version>
    </dependency>

    <!-- gRPC Test -->
    <dependency>
        <groupId>io.grpc</groupId>
        <artifactId>grpc-testing</artifactId>
        <version>${grpc.version}</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### protobuf-maven-plugin

```xml
<build>
    <finalName>{project}</finalName>
    <extensions>
        <extension>
            <groupId>kr.motd.maven</groupId>
            <artifactId>os-maven-plugin</artifactId>
            <version>1.7.1</version>
        </extension>
    </extensions>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
        <plugin>
            <groupId>org.xolstice.maven.plugins</groupId>
            <artifactId>protobuf-maven-plugin</artifactId>
            <version>0.6.1</version>
            <configuration>
                <protocArtifact>com.google.protobuf:protoc:${protobuf.version}:exe:${os.detected.classifier}</protocArtifact>
                <pluginId>grpc-java</pluginId>
                <pluginArtifact>io.grpc:protoc-gen-grpc-java:${grpc.version}:exe:${os.detected.classifier}</pluginArtifact>
            </configuration>
            <executions>
                <execution>
                    <goals>
                        <goal>compile</goal>
                        <goal>compile-custom</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

## ⚠️ gRPC 版本对齐铁律（CRITICAL）

**`<grpc.version>` 必须与 `spring-grpc-spring-boot-starter` 传递引入的 `grpc-netty` 版本完全一致。**

### 为什么？

```
spring-grpc-spring-boot-starter:1.0.2
  └── grpc-netty:1.77.1  ← Netty HTTP/2 传输层

grpc-testing:${grpc.version}  ← 如果不对齐
  ├── grpc-core:1.68.0        ← 内部 API 与 1.77.1 不兼容！
  ├── grpc-api:1.68.0
  └── grpc-stub:1.68.0
```

版本不匹配的**症状**：
- TCP 握手正常
- HTTP/2 SETTINGS 帧交换正常
- 但 gRPC 数据传输时服务端 RST 连接
- 所有客户端（grpc-js、grpcurl、Go）全部失败
- curl `--http2-prior-knowledge` 能连接但发数据即断

**排查极其困难** — 协议层没有任何明显错误信息。

### 如何确认版本匹配？

```bash
# 查 spring-grpc 传递的 grpc-netty 版本
./mvnw dependency:tree -Dincludes=io.grpc:grpc-netty 2>&1 | grep grpc-netty
# 输出示例: io.grpc:grpc-netty:jar:1.77.1:compile
#                               ↑ 这个版本号 = ${grpc.version}

# 检查所有 io.grpc 依赖是否一致
./mvnw dependency:tree -Dincludes=io.grpc 2>&1 | grep -E "grpc-[a-z]"
```

### 升级 spring-grpc 时的强制检查清单

1. 升级 `spring-grpc-spring-boot-starter` 版本号
2. 运行 `./mvnw dependency:tree -Dincludes=io.grpc:grpc-netty` 获取新的 grpc-netty 版本
3. 将 `<grpc.version>` 更新为匹配版本
4. 运行 `./mvnw dependency:tree -Dincludes=io.grpc` 确认所有 io.grpc 版本统一
5. 本地启动 + `grpcurl -plaintext localhost:{port} list` 验证
6. **禁止只升级 spring-grpc 版本而不同步升级 `<grpc.version>`**

## Application.java

```java
package {package};

import org.mybatis.spring.annotation.MapperScan;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;

@SpringBootApplication
@ConfigurationPropertiesScan
@MapperScan("{package}.mapper")
public class Application {

    private static final Logger log = LoggerFactory.getLogger(Application.class);

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @EventListener(ApplicationReadyEvent.class)
    public void onReady() {
        log.info("gRPC server ready on port {}",
                System.getProperty("grpc.port",
                    System.getenv().getOrDefault("GRPC_PORT", "{port}")));
    }
}
```

## TraceIdInterceptor.java

gRPC 回调可能跨线程执行，因此每个 listener 回调都要重新进入 MDC，并在回调结束后清理。

```java
package {package}.interceptor;

import io.grpc.ForwardingServerCallListener;
import io.grpc.Metadata;
import io.grpc.ServerCall;
import io.grpc.ServerCallHandler;
import io.grpc.ServerInterceptor;
import org.slf4j.MDC;
import org.springframework.core.annotation.Order;
import org.springframework.grpc.server.GlobalServerInterceptor;

import java.util.UUID;
import java.util.function.Supplier;
import java.util.regex.Pattern;

@GlobalServerInterceptor
@Order(0)
public class TraceIdInterceptor implements ServerInterceptor {

    private static final Metadata.Key<String> TRACE_ID_KEY =
            Metadata.Key.of("x-trace-id", Metadata.ASCII_STRING_MARSHALLER);
    private static final Pattern VALID_TRACE_ID =
            Pattern.compile("[A-Za-z0-9._-]{1,64}");

    @Override
    public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
            ServerCall<ReqT, RespT> call,
            Metadata headers,
            ServerCallHandler<ReqT, RespT> next) {

        String incoming = headers.get(TRACE_ID_KEY);
        String traceId = incoming != null && VALID_TRACE_ID.matcher(incoming).matches()
                ? incoming
                : UUID.randomUUID().toString().replace("-", "");

        ServerCall.Listener<ReqT> delegate =
                withMdc(traceId, () -> next.startCall(call, headers));
        return new ForwardingServerCallListener.SimpleForwardingServerCallListener<>(
                delegate) {
            @Override
            public void onMessage(ReqT message) {
                withMdc(traceId, () -> super.onMessage(message));
            }

            @Override
            public void onHalfClose() {
                withMdc(traceId, super::onHalfClose);
            }

            @Override
            public void onReady() {
                withMdc(traceId, super::onReady);
            }

            @Override
            public void onComplete() {
                withMdc(traceId, super::onComplete);
            }

            @Override
            public void onCancel() {
                withMdc(traceId, super::onCancel);
            }
        };
    }

    private static void withMdc(String traceId, Runnable action) {
        withMdc(traceId, () -> {
            action.run();
            return null;
        });
    }

    private static <T> T withMdc(String traceId, Supplier<T> action) {
        try (MDC.MDCCloseable ignored = MDC.putCloseable("traceId", traceId)) {
            return action.get();
        }
    }
}
```

> **注意**：gRPC 微服务用 `ServerInterceptor`，而 HTTP/BFF 用 `Filter` + `doFilter`。两者 API 不同，别混用。

## application.yml

```yaml
server:
  port: ${HTTP_PORT:${SERVER_PORT:18080}}

spring:
  application:
    name: {project}
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}
  main:
    web-application-type: servlet       # HTTP 仅暴露 /healthy
  cloud:
    nacos:
      config:
        enabled: false                   # dev 环境禁用 Nacos
      discovery:
        enabled: false
  grpc:
    server:
      port: ${GRPC_PORT:{port}}

management:
  endpoints:
    web:
      base-path: /
      exposure:
        include: health
      path-mapping:
        health: healthy
  endpoint:
    health:
      probes:
        enabled: true

mybatis-plus:
  global-config:
    db-config:
      # 与 HTTP 模板 BaseEntity @TableLogic 保持一致
      # @TableLogic(value = "null", delval = "now()") → deleted_at IS NULL 为未删除
      logic-delete-field: deletedAt
      logic-delete-value: "now()"
      logic-not-delete-value: "null"

# Redis Key 前缀：yms:{service}:{env}:，通过环境变量注入
# 规范见 rules/java/patterns.md → Redis 段
# 示例：REDIS_KEY_PREFIX=yms:child:staging

logging:
  file:
    name: ${user.home}/logs/${spring.application.name}.log
```

- `web-application-type: servlet` — 只为 `/healthy` 和 Nacos 自动注册启动 HTTP server
- `server.port` — HTTP health 端口，禁止承载业务 Controller
- `spring.grpc.server.port` — gRPC 业务端口，也是 Nacos Discovery 注册端口

### 服务内身份与 TraceId

`TraceIdInterceptor` 和 `InternalAuthInterceptor` 都必须使用 `@GlobalServerInterceptor` 注册，不能只声明 `@Component`。业务 RPC metadata 固定包含 `x-caller-service`、`x-internal-token` 和 `x-trace-id`：服务端按调用方从 `callers.<service>.token` 取得独立 token，并以常量时间比较；未配置 token 时拒绝。健康检查与反射接口只能按完整方法名显式豁免。

`TraceIdInterceptor` 必须只接受 `[A-Za-z0-9._-]{1,64}`；非法或缺失时生成 32 位 hex。不能假设 gRPC listener 始终在拦截器线程执行，所有回调都要重新设置并清理 MDC。

### ServiceSecurityProperties.java

```java
package {package}.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.Map;
import java.util.Set;

@ConfigurationProperties(prefix = "{domain}.security")
public record ServiceSecurityProperties(Map<String, Caller> callers) {

    public ServiceSecurityProperties {
        callers = callers == null ? Map.of() : Map.copyOf(callers);
    }

    public enum Role {
        ADMIN,
        RESTRICTED
    }

    public record Caller(String token, Role role, Set<String> allowedMethods) {
        public Caller {
            allowedMethods = allowedMethods == null
                    ? Set.of()
                    : Set.copyOf(allowedMethods);
        }
    }
}
```

### InternalAuthInterceptor.java

```java
package {package}.interceptor;

import {package}.config.ServiceSecurityProperties;
import io.grpc.Metadata;
import io.grpc.ServerCall;
import io.grpc.ServerCallHandler;
import io.grpc.ServerInterceptor;
import io.grpc.Status;
import org.springframework.core.annotation.Order;
import org.springframework.grpc.server.GlobalServerInterceptor;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Set;

@GlobalServerInterceptor
@Order(10)
public class InternalAuthInterceptor implements ServerInterceptor {

    private static final Metadata.Key<String> CALLER_KEY =
            Metadata.Key.of("x-caller-service", Metadata.ASCII_STRING_MARSHALLER);
    private static final Metadata.Key<String> TOKEN_KEY =
            Metadata.Key.of("x-internal-token", Metadata.ASCII_STRING_MARSHALLER);
    private static final Set<String> INFRASTRUCTURE_METHODS = Set.of(
            "grpc.health.v1.Health/Check",
            "grpc.health.v1.Health/Watch",
            "grpc.reflection.v1.ServerReflection/ServerReflectionInfo",
            "grpc.reflection.v1alpha.ServerReflection/ServerReflectionInfo"
    );

    private final ServiceSecurityProperties security;

    public InternalAuthInterceptor(ServiceSecurityProperties security) {
        this.security = security;
    }

    @Override
    public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
            ServerCall<ReqT, RespT> call,
            Metadata headers,
            ServerCallHandler<ReqT, RespT> next) {

        String method = call.getMethodDescriptor().getFullMethodName();
        if (INFRASTRUCTURE_METHODS.contains(method)) {
            return next.startCall(call, headers);
        }

        String callerName = headers.get(CALLER_KEY);
        String suppliedToken = headers.get(TOKEN_KEY);
        ServiceSecurityProperties.Caller caller =
                callerName == null ? null : security.callers().get(callerName);

        if (caller == null
                || caller.token() == null
                || caller.token().isBlank()
                || suppliedToken == null
                || !constantTimeEquals(caller.token(), suppliedToken)) {
            return reject(call, Status.UNAUTHENTICATED, "Invalid service credentials");
        }

        boolean allowed = caller.role() == ServiceSecurityProperties.Role.ADMIN
                || (caller.role() == ServiceSecurityProperties.Role.RESTRICTED
                    && caller.allowedMethods().contains(method));
        if (!allowed) {
            return reject(call, Status.PERMISSION_DENIED, "Method is not allowed");
        }
        return next.startCall(call, headers);
    }

    private static boolean constantTimeEquals(String expected, String actual) {
        return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                actual.getBytes(StandardCharsets.UTF_8));
    }

    private static <ReqT, RespT> ServerCall.Listener<ReqT> reject(
            ServerCall<ReqT, RespT> call, Status status, String description) {
        call.close(status.withDescription(description), new Metadata());
        return new ServerCall.Listener<>() {};
    }
}
```

调用方配置必须来自环境变量或 Nacos，禁止把 token 写进仓库，也禁止在日志中打印 token：

```yaml
{domain}:
  security:
    callers:
      yms-admin-api:
        token: ${YMS_ADMIN_API_INTERNAL_TOKEN}
        role: ADMIN
      yms-business-api:
        token: ${YMS_BUSINESS_API_INTERNAL_TOKEN}
        role: RESTRICTED
        allowed-methods:
          - {domain}.v1.XxxService/SearchSomething
```

### 强制测试

生成项目时必须用 in-process gRPC server 覆盖：缺失/错误 token → `UNAUTHENTICATED`；未知角色和受限方法越权 → `PERMISSION_DENIED`；`ADMIN` 与受限方法白名单正常放行；只豁免列出的 health/reflection 完整方法名。TraceId 测试必须覆盖合法值透传、非法值生成 32 位 hex、每个 listener 回调内 MDC 可见且回调后清理。未知异常只向客户端返回通用 `INTERNAL` 描述，并验证服务端仍记录完整异常。

## application-test.yml / application-prod.yml

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
        namespace: ${NACOS_NAMESPACE}
        username: ${NACOS_USERNAME}
        password: ${NACOS_PASSWORD}
      discovery:
        enabled: true
        server-addr: ${NACOS_ADDR}
        namespace: ${NACOS_NAMESPACE}
        group: ${NACOS_GROUP:DEFAULT_GROUP}
        username: ${NACOS_USERNAME}
        password: ${NACOS_PASSWORD}
        ip: ${NACOS_REGISTER_IP}
        port: ${GRPC_PORT:{port}}
        metadata:
          protocol: grpc
          grpcPort: ${GRPC_PORT:{port}}
          httpPort: ${HTTP_PORT:${SERVER_PORT:18080}}
          healthPath: /healthy
```

## gRPC Service 实现模板

```java
package {package}.service;

import {package}.grpc.*;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.grpc.stub.StreamObserver;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.grpc.server.service.GrpcService;

@GrpcService
public class XxxServiceImpl extends XxxServiceGrpc.XxxServiceImplBase {

    private static final Logger log = LoggerFactory.getLogger(XxxServiceImpl.class);
    private final XxxMapper mapper;

    public XxxServiceImpl(XxxMapper mapper) {
        this.mapper = mapper;
    }

    @Override
    public void searchSomething(
            SearchSomethingRequest request,
            StreamObserver<SearchSomethingResponse> responseObserver) {

        try {
            // 业务逻辑
            SearchSomethingResponse response = SearchSomethingResponse.newBuilder()
                    .build();
            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } catch (StatusRuntimeException e) {
            responseObserver.onError(e);
        } catch (Exception e) {
            log.error("SearchSomething failed", e);
            responseObserver.onError(
                Status.INTERNAL
                    .withDescription("Internal server error")
                    .asRuntimeException());
        }
    }
}
```

## Proto 协议规范

```
src/main/proto/{domain}/v1/
├── common.proto              # 共享消息类型
└── {service}_service.proto   # gRPC 服务定义
```

### common.proto

```protobuf
syntax = "proto3";

package {domain}.v1;

option java_multiple_files = true;
option java_package = "{package}.grpc.common";

// 分页请求
message PageRequest {
  int32 page = 1;   // 从 1 开始
  int32 size = 2;   // 上限 100
}

// 分页响应
message PageResponse {
  int32 page = 1;
  int32 size = 2;
  int64 total = 3;
}
```

### service.proto

```protobuf
syntax = "proto3";

package {domain}.v1;

option java_multiple_files = true;
option java_package = "{package}.grpc";

import "{domain}/v1/common.proto";

service XxxService {
  rpc SearchSomething (SearchSomethingRequest) returns (SearchSomethingResponse);
}

message SearchSomethingRequest {
  // 字段
}

message SearchSomethingResponse {
  // 仅定义领域结果字段；错误一律用 gRPC status 表达，不复刻 HTTP ApiResponse。
}
```

## CLAUDE.md 模板

```markdown
# CLAUDE.md — {project}

{一句话描述}。gRPC 微服务（内网调用；不承载端侧鉴权，但校验服务身份 metadata）。

## 常用命令

| 操作 | 命令 |
|------|------|
| 开发 | `./mvnw spring-boot:run -Dspring-boot.run.profiles=dev` |
| 构建 | `./mvnw clean package -DskipTests` |
| 测试 | `./mvnw test` |

## 分层职责

| 组件 | 职责 |
|------|------|
| `interceptor/TraceIdInterceptor` | gRPC metadata `X-Trace-Id` → MDC |
| `interceptor/InternalAuthInterceptor` | 校验 `x-caller-service` + 独立 `x-internal-token` |
| `service/XxxServiceImpl` | @GrpcService，构造器注入 Mapper |

## 环境

| 环境 | gRPC 端口 | HTTP health 端口 | Profile | DB |
|------|-----------|------------------|---------|-----|
| 本地 | {port} | 18080 | dev | 远程 MySQL |
| 测试 | {port} | 18080 | test | (Nacos) |
| 生产 | {port} | 18080 | prod | (Nacos) |

## 注意事项

- gRPC 微服务不承载端侧 JWT/RBAC；业务 RPC 校验服务身份 metadata
- traceId 优先从 `X-Trace-Id` metadata 透传，无则自生成
- HTTP 只暴露 `/healthy`，禁止新增业务 Controller
- Nacos Discovery 注册 `NACOS_REGISTER_IP:GRPC_PORT`，不要注册 HTTP health 端口
- **主键 `INT AUTO_INCREMENT`**，不从 1 起（1000-3000 随机起始），禁止 BIGINT 雪花 ID
- Redis Key 格式 `yms:{service}:{env}:{module}:{key}`，全部带 TTL
```

## 反模式

- **不要写 HTTP 业务接口** — HTTP 只用于 `/healthy`
- **不要跳过服务内身份校验** — Nacos 可达性不等于调用方身份可信
- **不要固定写死注册 IP** — 使用 `NACOS_REGISTER_IP` 注入
- **不要注册 HTTP 端口到 Nacos** — Nacos `port` 必须是 `GRPC_PORT`
- **不要字段注入** — gRPC Service 用构造器注入 Mapper
- **不要在 Service 实现里重复端侧 JWT/RBAC** — 服务身份鉴权统一放在 `InternalAuthInterceptor`，不能信任网络可达性
- **不要混用 Filter 和 ServerInterceptor** — gRPC 用后者
- **`<grpc.version>` 不要不对齐** — 见上方版本对齐铁律，是最高发的事故！
