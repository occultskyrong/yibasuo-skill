---
name: yibasuo
version: "2.5.0"
description: "一把梭 — 全流程开发管线。默认自动模式（触发词：一把梭、全流程、梭哈）：阶段0-4连续执行，仅提交前确认。交互模式需显式触发：一步步梭、交互梭、确认梭。"
requires:
  agents: [planner, architect, tdd-guide, code-reviewer, security-reviewer]
  rules: [common, "java (Java 项目)", "typescript (Node.js 项目)", "web (Vue/React 前端项目)"]
---

# 一把梭

> 需求 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交

## 运行模式

| 模式 | 触发词 | 阶段 0 | 阶段 1-4 | 阶段 5 |
|------|--------|--------|---------|--------|
| 自动（默认） | `一把梭` `全流程` `梭哈` | 确认 | 连续 | 确认 |
| 交互（显式） | `一步步梭` `交互梭` `确认梭` | 确认 | 每阶段确认 | 确认 |

中途说"停一下"切交互，说"继续梭"回自动。

## 行为红线

1. **编码前思考** — 不确定时提 2-3 种解释，不默默假设
2. **简洁优先** — 最少代码解决问题，不添加未请求的功能
3. **手术刀改动** — 只改任务相关代码，不顺手重构；死代码只提不删
4. **循环验证** — 每阶段定义成功标准，不达标不回；覆盖率≥60%、CRITICAL=0 是底线

## 语言适配

| 技术栈 | 注入要点 |
|--------|---------|
| Java | JUnit5+AssertJ+Mockito+Testcontainers，p3c，构造器注入，Logback |
| Node.js / NestJS | Vitest+supertest，NestJS分层，pino，`__`私有前缀，Zod |
| Vue / React | Vitest+Testing Library，Pinia/Zustand，Playwright E2E，Prettier+ESLint |

阶段 3-4 的 agent 直接操作文件，rules 按 `paths:` 自动加载。阶段 1-2 需手动在 agent prompt 中注入。

## 工作流

```
需求确认 → 规划 → 架构 → 测试驱动开发 → 审查 → 提交(格式→构建→commit→tag)
  ▲                            ▲                                 ▲
  │                            │                                 │
 两种模式                    自动:跳过                         两种模式
 都需确认                    交互:确认                         都需确认
```

### 0. 需求确认

1. 理解输入，识别模糊点。多子系统**先拆解**，逐个处理
2. 一次只问一个问题澄清（功能边界、交互细节、异常情况）
3. 确认技术栈和影响范围
4. **提出 2-3 种实现方案**，含 trade-off 和推荐理由
5. 输出需求卡片（标题/类型/范围/验收标准/约束）
6. **暂停，等用户确认。**

### 1. 规划

1. **先读项目代码**：`Read`/`Bash` 确认项目结构、模块、版本
2. `Agent({ subagent_type: "planner" })`，prompt 含：需求卡片 + 项目结构摘要 + 语言规范。要求输出任务分解、依赖关系图、风险点列表
3. Agent 失败 → **展示错误，暂停**（两种模式都停）
4. 默认（自动）直接继续。交互模式问"计划 OK？"

### 2. 架构

1. `Agent({ subagent_type: "architect" })`，prompt 含：需求 + 计划 + 语言规范。要求产出 ADR（决策/后果/替代方案）+ 接口契约 + 数据变更
2. 自检 P0 问题（缺关键决策/接口遗漏/数据变更缺失），**至少 3 轮、最多 5 轮**。即使无 P0 也跑满 3 轮以充分打磨。5 轮后仍有 P0 → 暂停等用户决定
3. Agent 失败 → **展示错误，暂停**
4. 默认（自动）直接继续。交互模式问"方案 OK？"

### 3. 测试驱动开发

**铁律**：没有失败测试 → 没有生产代码。先行代码 = 删除。

1. `Agent({ subagent_type: "tdd-guide" })`，prompt 含需求 + 计划 + 架构 + 按技术栈指定测试命令：
   - Java → `mvn test`，JUnit5+AssertJ+Mockito，Testcontainers，JaCoCo
   - Node.js → `pnpm test`，Vitest+supertest，Playwright E2E，v8
   - 前端 → `pnpm test`，Vitest+Testing Library，Playwright E2E
   - **强制 agent 先 Read 项目的 `rules/<lang>/testing.md` 再动手**
2. RED → GREEN → IMPROVE，**默认覆盖率 ≥ 60%**
3. Agent 失败 → **展示错误，暂停**
4. 展示覆盖率，询问：「当前 XX%。是否继续提高到 80%？」用户说"够了"则继续。自动模式：60% 达标直接过，未达标暂停。

### 4. 审查

1. 按技术栈 **并行**启动：Java→`java-reviewer`，Node.js/前端→`typescript-reviewer` + `security-reviewer`
2. 任一 agent 失败 → **展示错误，暂停**
3. CRITICAL/HIGH → **必须修复**（两种模式都拦截），修复前先写复现测试
4. 修复后重审，**至少 3 轮、最多 5 轮**。即使无 CRITICAL/HIGH 也跑满 3 轮以充分审查。5 轮后仍有 → 暂停等用户决定
5. MEDIUM/LOW → 展示建议，不强制
6. 默认（自动）无 CRITICAL/HIGH 则继续

### 5. 提交

1. **环境检查**：非 git 仓库警告暂停，`git diff --stat`
2. **格式检查**（按技术栈）：
   - Node.js/前端：prettier → eslint → ts-prune（僵尸代码扫描，列清单不自动删）
   - Java：`mvn pmd:check`（p3c），修复建议 `mvn p3c:pmd` 或 IDE 插件
   - 格式失败 → 暂停。优先复用项目已有 formatter/linter 配置
3. **构建验证**（Node.js/前端）：`pnpm build`，构建失败或缺 build 命令 → 暂停
4. **完成前验证**：测试通过 + 覆盖率达标 + 无 CRITICAL/HIGH + 格式已执行 + 构建通过 + 无调试残留
5. **生成 commit message**：遵循 [Conventional Commits](references/commit-conventions.md)（`<type>[!]: <desc>`），破坏性变更加 `!`
6. **展示确认**（两种模式都必确认）
7. `git add` + `git commit`
8. **创建 tag**：遵循 [SemVer](references/commit-conventions.md#semver-tag)，根据 type 确定 MAJOR/MINOR/PATCH。非功能变更（docs/chore/refactor）不创建 tag。**标签不可变**
9. 询问是否 push（含 `--tags`）。引导 PR/合并策略

## 中断与恢复

- 随时可中断，重说"继续梭"恢复
- 说"回到阶段 X"重做，说"跳过阶段 X"跳过
- 说"从阶段 X 开始梭"或"梭到审查就行"

## 任务适配

| 类型 | 行为 |
|------|------|
| 新功能 / 重构 | 完整 6 阶段 |
| Bug 修复 | 跳过 1-2，直接 测试驱动开发 + 审查 + 提交 |
| 单文件小改 | 不建议用 |

## 示例

用户说：`自动梭 修复登录超时没提示` → 阶段0澄清→跳过1-2→阶段3 TDD→阶段4审查→阶段5 commit `fix: 登录超时增加用户提示`→tag `v1.2.1`

## 反模式

- **不要跳过门禁** — 确认是安全阀
- **不要忽略审查** — CRITICAL 必须修
- **不要模糊需求直接梭** — 阶段 0 没搞清楚就往下走，5 阶段白跑
- **不要并行依赖阶段** — 架构没出来就编码无意义
