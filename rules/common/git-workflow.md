# Git Workflow

## Commit Message Format
```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci, style

### Commit Body 规范

Subject 描述**做了什么**，body 描述**为什么这样做**。

**Bug 修复必须有 root cause**：
```
fix(order): 修复高并发下库存超卖

Root cause: SELECT查+UPDATE写之间存在竞态窗口
Fix: 改为 UPDATE SET stock = stock - ? WHERE stock >= ? 原子操作
Impact: 所有涉及库存扣减的接口
```

**重构必须有动机**：
```
refactor(auth): 提取Token验证为独立服务

为什么: BFF层4个服务各自实现Token验证，代码重复90%+
```

**性能优化必须附数据**：
```
perf(query): 优化学生列表查询

Before: 2.3s (全表扫描)  After: 45ms (复合索引)
```

## Branch Naming

格式：`<type>/YYMMDD_short-desc`

| 元素 | 规则 | 示例 |
|------|------|------|
| type | feat/fix/hotfix/refactor/docs/chore | `feat` |
| YYMMDD | 6 位日期 | `260513` |
| desc | kebab-case，小写英文+连字符 | `add-login-page` |

示例：`feat/260513_add-user-profile`、`fix/260513_null-pointer`、`hotfix/260513_payment-failure`

Note: Attribution disabled globally via ~/.claude/settings.json.

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch

## PR Description 模板

```markdown
## Summary
_一句话概述本次变更_

## What Changed
- 

## Why
_业务背景 / 技术动机_

## Testing
- [ ] 单元测试通过
- [ ] 覆盖率 >= 80%
- [ ] 关键流程 E2E 通过

### Test Plan
1. 

## Risk
- [ ] 低: 纯新增，不影响已有逻辑
- [ ] 中: 修改已有逻辑，范围可控
- [ ] 高: 核心模块（认证/支付/迁移），需灰度
```

> For the full development process (planning, TDD, code review) before git operations,
> see [development-workflow.md](./development-workflow.md).
