# 安全指南

> 覆盖 OWASP Top 10 (2021) 核心类别。语言特定实现见 `rules/java/security.md` 和 `rules/typescript/security.md`。

## 强制安全检查

提交前必须确认：
- [ ] 无生产密钥硬编码（支付密钥、生产数据库密码、JWT Secret）
- [ ] 所有用户输入已验证
- [ ] SQL 注入防护（参数化查询）
- [ ] XSS 防护（HTML 转义）
- [ ] CSRF 保护已启用（仅当 token 存储在 cookie 中时需要；纯 `Authorization: Bearer` 头的 JWT 项目可跳过）
- [ ] 认证/授权已验证
- [ ] 所有端点已配置速率限制
- [ ] 生产环境强制 HTTPS
- [ ] 错误消息不泄露敏感数据
- [ ] 无 SSRF 风险（用户输入未直接用于 HTTP 请求目标）
- [ ] 无反序列化漏洞（未使用 `ObjectInputStream` / Jackson `enableDefaultTyping` / `eval()`）
- [ ] 依赖扫描通过（无已知高危 CVE）

## 密钥管理

**生产密钥禁止硬编码**（支付密钥、生产数据库密码、生产 JWT Secret）。

**开发默认值**允许作为 fallback（如 LLM API key 指向默认 provider），前提：
1. 明确标注为开发密钥
2. 生产环境通过 env 覆盖
3. 不用于高敏感场景（支付密钥、生产 DB 密码、OAuth Secret）

- 启动时验证生产密钥是否已配置
- 轮换所有已暴露的密钥

## 访问控制 (A01)

- **IDOR 防护**：资源操作前校验当前用户是否有权访问该资源（不能只靠前端传的 ID）
- **权限提升检查**：修改/删除操作前验证角色权限，不信任前端传来的角色标识
- **资源级鉴权**：每个 API 端点必须声明所需权限，全局默认拒绝
- **最小权限原则**：数据库连接、API Key、文件系统权限按最小需要分配

## 输入验证

所有外部输入（HTTP 参数、请求体、文件名、URL）必须在系统边界验证：
- 使用 schema 验证（Zod / Bean Validation / class-validator）
- 类型、长度、范围、格式全部校验
- 拒绝未知字段（whitelist 模式）
- 文件上传：校验扩展名 + MIME 白名单 + magic number + 文件大小限制

## 注入防护

### SQL 注入
- 参数化查询 / ORM，禁止字符串拼接
- 存储过程参数同样需要校验

### NoSQL 注入
- MongoDB：schema 验证输入类型为 string，拒绝 `{ "$gt": "" }` 等对象
- 用 Zod `z.string()` 而非 `String()` 转换

### XSS
- 输出编码（HTML/JS/URL 上下文分别编码）
- 富文本用 DOMPurify 白名单过滤
- CSP 响应头限制内联脚本

### XXE (XML 外部实体)
- XML 解析器禁用外部实体：`FEATURE_SECURE_PROCESSING`、`disallow-doctype-decl`
- 如无必要，不使用 XML（优先 JSON）

### SSRF (服务端请求伪造)
- 用户输入的 URL 必须校验协议（仅 http/https）、域名（白名单）、禁止内网地址
- 禁止 `file://`、`gopher://`、`dict://` 等协议
- HTTP 客户端设置超时和最大响应大小
- **IPv6 绕过防护**：`http://[::1]`、`http://[0:0:0:0:0:ffff:127.0.0.1]` 同样属于内网
- **DNS Rebinding 防护**：解析 URL 后获取实际 IP，校验是否属于内网 CIDR（`127.0.0.0/8`、`10.0.0.0/8`、`172.16.0.0/12`、`192.168.0.0/16`、`::1`、`fc00::/7`）

## 反序列化安全 (A08)

- Java：禁止 `ObjectInputStream` 反序列化不受信数据；Jackson 禁用 `enableDefaultTyping`（2.10+ 用 `activateDefaultTyping`）；SnakeYAML 必须使用 `SafeConstructor`
- JavaScript：禁止 `eval()`、`new Function()` 处理用户输入
- 如需序列化，使用安全的 JSON 格式，不使用 Java 原生序列化

## 密码存储

- 使用 bcrypt 或 Argon2id，禁止 MD5 / SHA1 / 明文
- 密码字段不记录到日志、不返回到 API 响应
- 登录失败不泄露"用户不存在"还是"密码错误"

## 敏感数据保护

- 日志中禁止记录密码、Token、密钥、PII（手机号、身份证）
- 必须记录时，脱敏处理（如 `138****8000`、`sk-****abcd`）
- API 响应中不返回内部字段（密码哈希、salt、内部 ID）

## 安全日志 (A09)

安全事件必须结构化记录，便于审计和告警：

| 事件 | 必记字段 | 级别 |
|------|---------|------|
| 登录失败 | IP、时间、用户名（脱敏）、失败原因 | WARN |
| 权限拒绝 | 用户 ID、资源、操作、IP | WARN |
| 密码修改 | 用户 ID、IP、时间 | INFO |
| 角色变更 | 操作人、目标用户、旧角色→新角色 | INFO |
| 敏感操作 | 操作人、操作类型、目标资源、结果 | INFO |

- 所有安全日志必须包含 TraceID（requestId）用于关联分析
- 日志保留策略：安全日志 ≥ 180 天

## 安全头 (A05)

| 头 | 值 | 说明 |
|----|-----|------|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | 强制 HTTPS |
| `X-Content-Type-Options` | `nosniff` | 禁止 MIME 嗅探 |
| `X-Frame-Options` | `DENY` 或 `SAMEORIGIN` | 防止点击劫持 |
| `Content-Security-Policy` | 按项目配置 | 限制资源加载来源 |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | 控制 Referer 泄露 |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | 限制浏览器特性访问 |

- 生产环境禁止 `server.error.include-stacktrace=always`（Spring Boot）或等效配置
- 禁用 debug 模式、移除默认凭据

## 依赖安全 (A06)

- 定期运行依赖扫描：`mvn dependency-check:check`（Java）、`npm audit`（Node.js）
- CI 中集成 CVE 扫描，高危漏洞阻塞合并
- 锁定依赖版本（`pom.xml` 显式版本、`package-lock.json` 提交到仓库）
- 禁止使用已废弃或无维护的包

## 速率限制

- 公开端点：基于 IP 限流（如 100 req/min）
- 认证端点：更严格（如 5 req/min for login）
- 返回 `429 Too Many Requests` + `Retry-After` 头
- Java 实现见 `rules/java/security.md`，NestJS 实现见 `rules/typescript/security.md`

## 安全响应协议

发现安全问题时：
1. 立即停止当前代码编辑/提交（不是停止线上服务）
2. 调用 **security-reviewer** agent
3. 修复 CRITICAL 问题后再继续
4. 轮换所有已暴露的密钥
5. 审查整个代码库是否有类似问题
