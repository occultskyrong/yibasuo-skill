# Java gRPC 微服务模板规格 (Spring Boot 4.0.6 + Java 21)

纯 gRPC 微服务，不鉴权，信任 BFF 传来的身份（gRPC metadata）。

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
│   ├── service/
│   │   └── XxxServiceImpl.java          # @GrpcService，extends XxxServiceGrpc.XxxServiceImplBase
│   └── interceptor/
│       └── TraceIdInterceptor.java      # gRPC ServerInterceptor
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
| Spring Boot | `spring-boot-starter` | 4.0.6 | 基础（不含 Web） |
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
    <!-- Spring Boot（不含 Web） -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter</artifactId>
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
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;

@SpringBootApplication
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

gRPC 拦截器，从 metadata `X-Trace-Id` 提取 traceId 写入 MDC，onComplete/onCancel 清理。

```java
package {package}.interceptor;

import io.grpc.ForwardingServerCallListener;
import io.grpc.Metadata;
import io.grpc.ServerCall;
import io.grpc.ServerCallHandler;
import io.grpc.ServerInterceptor;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class TraceIdInterceptor implements ServerInterceptor {

    private static final Metadata.Key<String> TRACE_ID_KEY =
            Metadata.Key.of("X-Trace-Id", Metadata.ASCII_STRING_MARSHALLER);

    private static final int TRACE_ID_LENGTH = 8;

    @Override
    public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
            ServerCall<ReqT, RespT> call,
            Metadata headers,
            ServerCallHandler<ReqT, RespT> next) {

        String traceId = headers.get(TRACE_ID_KEY);
        if (traceId == null || traceId.isEmpty()) {
            traceId = UUID.randomUUID().toString().replace("-", "").substring(0, TRACE_ID_LENGTH);
        }
        MDC.put("traceId", traceId);

        return new ForwardingServerCallListener.SimpleForwardingServerCallListener<>(
                next.startCall(call, headers)) {
            @Override
            public void onComplete() {
                MDC.remove("traceId");
                super.onComplete();
            }

            @Override
            public void onCancel() {
                MDC.remove("traceId");
                super.onCancel();
            }
        };
    }
}
```

> **注意**：gRPC 微服务用 `ServerInterceptor`，而 HTTP/BFF 用 `Filter` + `doFilter`。两者 API 不同，别混用。

## application.yml

```yaml
server:
  port: ${SERVER_PORT:{port}}

spring:
  application:
    name: {project}
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}
  main:
    web-application-type: none          # ← 禁用 HTTP
  autoconfigure:
    exclude:
      - com.alibaba.cloud.nacos.registry.NacosServiceRegistryAutoConfiguration
  cloud:
    nacos:
      config:
        enabled: false                   # dev 环境禁用 Nacos
      discovery:
        enabled: false
  grpc:
    server:
      port: ${GRPC_PORT:{port}}

mybatis-plus:
  global-config:
    db-config:
      logic-delete-field: deletedAt
      logic-delete-value: "CURRENT_TIMESTAMP"
      logic-not-delete-value: "null"

logging:
  file:
    name: ${user.home}/logs/${spring.application.name}.log
```

- `web-application-type: none` — 纯 gRPC 微服务，不启动 Tomcat
- `autoconfigure.exclude` — 不注册到 Nacos（可选，按需启用）
- gRPC 端口与 HTTP 端口都用 `{port}`，因为 HTTP 已禁用

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
        username: ${NACOS_USERNAME}
        password: ${NACOS_PASSWORD}
      discovery:
        enabled: true
        server-addr: ${NACOS_ADDR}
        namespace: ${NACOS_NAMESPACE}
        username: ${NACOS_USERNAME}
        password: ${NACOS_PASSWORD}
```

## gRPC Service 实现模板

```java
package {package}.service;

import {package}.grpc.*;
import io.grpc.Status;
import io.grpc.stub.StreamObserver;
import org.springframework.grpc.server.service.GrpcService;

@GrpcService
public class XxxServiceImpl extends XxxServiceGrpc.XxxServiceImplBase {

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
        } catch (Exception e) {
            responseObserver.onError(
                Status.INTERNAL.withDescription(e.getMessage()).asRuntimeException());
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
  int32 code = 1;
  string message = 2;
  // data 字段
}
```

## CLAUDE.md 模板

```markdown
# CLAUDE.md — {project}

{一句话描述}。gRPC 微服务（内网调用，不鉴权）。

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
| `service/XxxServiceImpl` | @GrpcService，构造器注入 Mapper |

## 环境

| 环境 | 端口 | Profile | DB |
|------|------|---------|-----|
| 本地 | {port} | dev | 远程 MySQL |
| 测试 | {port} | test | (Nacos) |
| 生产 | {port} | prod | (Nacos) |

## 注意事项

- gRPC 微服务不鉴权，信任 BFF 传来的身份
- traceId 优先从 `X-Trace-Id` metadata 透传，无则自生成
- `spring.main.web-application-type: none` 禁用 HTTP
```

## 反模式

- **不要启动 HTTP** — `web-application-type: none` 必须设置
- **不要字段注入** — gRPC Service 用构造器注入 Mapper
- **不要在 gRPC Service 里做鉴权** — 信任 BFF
- **不要混用 Filter 和 ServerInterceptor** — gRPC 用后者
- **`<grpc.version>` 不要不对齐** — 见上方版本对齐铁律，是最高发的事故！
