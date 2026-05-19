# Git Workflow

## Commit Message Format
```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

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

> For the full development process (planning, TDD, code review) before git operations,
> see [development-workflow.md](./development-workflow.md).
