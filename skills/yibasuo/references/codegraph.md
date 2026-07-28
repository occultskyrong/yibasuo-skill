# CodeGraph 集成

> **强制规则**：项目根目录已经存在 `.codegraph/` 时，内部代码查询（理解功能逻辑、查找引用、定位调用链）优先使用 CodeGraph。没有索引时使用 Read/rg/Glob；索引是用户决策，未经明确同意不得安装 CodeGraph 或执行 `init/index`。

[CodeGraph](https://github.com/colbymchenry/codegraph) 预索引代码库，替代 agent 手工扫描文件，大幅减少 token 消耗（~62% 工具调用、~25% total token）。

## 环境要求

| 组件 | 版本 | 安装 |
|------|------|------|
| Node.js | **22**（`>=18.0.0 <25.0.0`） | `nvm install 22` |
| codegraph | 用户确认的兼容版本 | 从用户认可的官方渠道安装；技能不得自行执行 |

调用前必须 `nvm use 22`（或通过 wrapper 自动切换）。

## 项目初始化（一次性，需确认）

```bash
nvm use 22 && codegraph init -i && codegraph index
```

执行前必须说明将创建 `.codegraph/`、可能下载依赖及所需时间，并取得用户明确同意。初始化后确认 `.codegraph/` 已加入项目约定的 ignore 规则，除非该仓库明确要求跟踪索引。

## 阶段注入点

| 阶段 | CodeGraph 命令 | 替代行为 |
|------|------|------|
| 1 规划 | `codegraph context "<需求描述>"` → markdown 注入 planner prompt | 替代 agent 手工 Read/grep 扫项目结构 |
| 2 架构 | `codegraph query -k class "<关键类名>"` | 替代 agent 盲目搜调用链 |
| 3 TDD | `codegraph affected src/改动的文件.ts` | 自动定位受影响测试文件 |
| 4 审查 | `codegraph query "<变更的符号名>"` | 验证所有引用点已更新 |
| 持续 | `codegraph sync` | 增量更新索引 |
