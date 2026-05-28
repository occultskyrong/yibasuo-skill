# 一把梭 (yibasuo) — 全流程开发管线 v2.10.0

> 需求 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交。7 个内置 Agent + 4 套 Rules，流程化消除 AI 编码的随机性。

## 安装

```bash
git clone git@github.com:occultskyrong/yibasuo-skill.git /tmp/yibasuo-skill
cd /tmp/yibasuo-skill && bash install.sh        # Claude Code
cd /tmp/yibasuo-skill && bash install.sh --codex # Codex
```


## 模式

| 模式 | 触发词 | 行为 |
|------|--------|------|
| 自动（默认） | `一把梭` `全流程` `梭哈` | 阶段 0 确认后，1-4 连续执行，提交前确认 |
| 交互 | `一步步梭` `交互梭` `确认梭` | 每阶段确认后再继续 |

中途说 `停一下` 切交互，`继续梭` 回自动。

## 6 阶段详解

### 0. 需求确认
1. 研究复用（搜索项目内/GitHub/包注册表已有方案）
2. 澄清需求，提出 2-3 种实现方案（含 trade-off）
3. 输出需求卡片（标题/类型/范围/验收标准）
4. **暂停等用户确认**

### 1. 规划
1. 读取项目代码 + 语言规范
2. 调用 `planner` agent：输出任务分解、依赖关系、风险点
3. 自动模式直接继续，交互模式确认

### 2. 架构
1. 调用 `architect` agent：输出 ADR、接口契约、数据变更
2. 自检 P0 问题，至少 3 轮打磨（最多 5 轮）
3. 自动模式直接继续，交互模式确认

### 3. 测试驱动开发
1. 调用 `tdd-guide` agent：Java→JUnit5 / Node→Vitest / 前端→Vitest+Playwright
2. RED→GREEN→IMPROVE，目标覆盖率 **≥ 80%**
3. 覆盖率不达标 → 暂停修复，达标 → 继续

### 4. 审查
1. Java→`java-reviewer`，Node/前端→`typescript-reviewer` + `security-reviewer`（并行）
2. CRITICAL/HIGH → 必须修复，至少 3 轮审查（最多 5 轮）
3. 基础设施配置审查（硬编码密钥、配置文件一致性）

### 5. 提交
1. 启动验证（Java: `mvn spring-boot:run` / NestJS: `npm start`）
2. 格式检查（prettier+eslint / p3c）+ 构建验证
3. 完成前验证（测试/审查/构建/无调试残留）
4. 文档更新（CLAUDE.md + README.md 全量梳理）
5. Conventional Commit → SemVer Tag → Push

## 规范体系

`install.sh` 安装后自动加载，按 `paths:` 匹配语言自动生效。

| 分类 | 文件 | 覆盖内容 |
|------|------|---------|
| **common** | `patterns.md` | 统一返回结构、API 版本控制、HTTP/gRPC 分层、数据库迁移、定时任务 |
| | `security.md` | OWASP Top 10、访问控制、注入防护、SSRF、密钥管理 |
| | `concurrency.md` | 线程池、锁、CompletableFuture、并发集合、Virtual Threads |
| | `development-workflow.md` | 研究复用→TDD→审查→提交 全流程 |
| | `testing.md` | 覆盖率≥80%、RED→GREEN→IMPROVE、AAA 模式 |
| | `git-workflow.md` | 分支命名、Conventional Commits、SemVer |
| | `coding-style.md` | 不可变性、KISS/DRY/YAGNI、命名规范 |
| | `code-review.md` / `agents.md` / `hooks.md` / `performance.md` | 审查标准、Agent 编排、Hooks、性能 |
| **java** | `patterns.md` | Spring Boot 分层、构造器注入、索引规范、定时任务、gRPC |
| | `security.md` | Spring Security、AES 加密、JWT、数据权限 |
| | `testing.md` | JUnit5+Mockito+Testcontainers、AIR 原则 |
| | `coding-style.md` | equals/hashCode、集合、控制语句、Virtual Threads |
| | `logging.md` | Logback、traceId、JSON 格式、敏感数据脱敏 |
| **typescript** | `patterns.md` | NestJS 分层、DTO/Guard/Interceptor、定时任务、BullMQ、gRPC |
| | `security.md` | Helmet/CORS/CSRF、速率限制、NoSQL 注入 |
| | `testing.md` | Vitest+supertest+Playwright、mock 策略 |
| | `coding-style.md` | satisfies/泛型/Branded Types、模块组织 |
| | `logging.md` | pino、traceId、结构化日志 |
| **web** | `patterns.md` / `testing.md` / `coding-style.md` | 前端测试、组件模式、命名 |
| | `static-website-checklist.md` | CDN 替换、备案、SEO、无障碍 |

## ⚠️ Token 消耗说明

一把梭会显著增加 API 调用量——每个阶段都会调用内置 Agent 进行独立分析，这些额外消耗换来的是架构评审、强制 TDD、代码审查、安全审查、提交前验证。

| 场景 | 直接对话 | 一把梭 | 倍数 |
|------|---------|--------|------|
| 新功能（中等复杂度） | ~25K | ~90K | **~3.5x** |
| Bug 修复 | ~12K | ~40K | **~3x** |
| 简单改动 | ~5K | ~8K | ~1.5x |

> 多的 50-70K tokens 成本买的是 4 道质检 + 确定性流程。如果只是改一行文字，不建议使用。

## 支持的技术栈

| 技术栈 | 测试框架 | 格式检查 |
|--------|---------|---------|
| Java / Spring Boot | JUnit5 + AssertJ + Mockito + Testcontainers | p3c (阿里巴巴) |
| Node.js / NestJS | Vitest + supertest + Playwright | Prettier + ESLint |
| Vue / React | Vitest + Testing Library + Playwright | Prettier + ESLint |

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 | 完整 6 阶段 |
| 重构 | 阶段 0 简化为范围确认，阶段 2 侧重影响分析，阶段 3 侧重回归测试 |
| Bug 修复 | 跳过 0-2，阶段 3(TDD)→4→5 |
| 依赖升级 | 跳过 0-1，阶段 2 兼容性分析，阶段 3 全量回归，阶段 4 breaking change 审查 |
| 数据库迁移 | 阶段 0 确认范围+大表风险，阶段 5 迁移文件不可变检查 |
| 单文件小改 | 不建议用，直接手改 + code-reviewer |
| 纯研究 / 调研 | 不适用，用 planner agent 出调研报告 |
| 生成说明文档 | 收集项目信息 → 调用 ui-ux-pro-max 生成 HTML |

## 更新

```bash
cd /tmp/yibasuo-skill && git pull && bash install.sh --force
```

查看版本：`cat ~/.claude/skills/yibasuo/.installed-version`

## 自包含

安装后即用：7 个 Agent + 4 套 Rules（common/java/typescript/web）+ git-workflow 技能，`install.sh` 一键安装。覆盖 HTTP/BFF 和 gRPC 微服务全场景，另配 [yibasuo-infra](https://github.com/occultskyrong/yibasuo-infra) 初始化项目骨架。
