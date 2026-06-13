# CodeGraph 集成

> **强制规则**：项目开启 CodeGraph 后，内部代码查询（理解功能逻辑、查找引用、定位调用链）**必须使用 CodeGraph 命令**，禁止用 grep/glob 手工扫描。`codegraph context/query/affected` 替代所有 `grep -rn` / `find | xargs grep` 操作。

[CodeGraph](https://github.com/colbymchenry/codegraph) 预索引代码库，替代 agent 手工扫描文件，大幅减少 token 消耗（~62% 工具调用、~25% total token）。

## 环境要求

| 组件 | 版本 | 安装 |
|------|------|------|
| Node.js | **22**（`>=18.0.0 <25.0.0`） | `nvm install 22` |
| codegraph | latest | `nvm use 22 && npx @colbymchenry/codegraph` |

调用前必须 `nvm use 22`（或通过 wrapper 自动切换）。

## 项目初始化（一次性）

```bash
nvm use 22 && codegraph init -i && codegraph index
```

## 阶段注入点

| 阶段 | CodeGraph 命令 | 替代行为 |
|------|------|------|
| 1 规划 | `codegraph context "<需求描述>"` → markdown 注入 planner prompt | 替代 agent 手工 Read/grep 扫项目结构 |
| 2 架构 | `codegraph query -k class "<关键类名>"` | 替代 agent 盲目搜调用链 |
| 3 TDD | `codegraph affected src/改动的文件.ts` | 自动定位受影响测试文件 |
| 4 审查 | `codegraph query "<变更的符号名>"` | 验证所有引用点已更新 |
| 持续 | `codegraph sync` | 增量更新索引 |
