---
paths:
  - "**/*.vue"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.css"
  - "**/*.scss"
  - "**/package.json"
---
# Frontend Hooks

> This file extends [common/hooks.md](../common/hooks.md) with Vue/React specific content.

## PostToolUse Hooks

Configure in `~/.claude/settings.json`:

- **Prettier**: `pnpm prettier --write "$FILE_PATH"` after Write/Edit
- **ESLint**: `pnpm eslint --fix "$FILE_PATH"` after Write/Edit
- **Type check**: `pnpm vue-tsc --noEmit` (Vue) or `pnpm tsc --noEmit` (React)

## Pre-Commit Checks

提交前必须执行，缺一不可：

### 1. 格式化

```bash
pnpm prettier --write "src/**/*.{vue,tsx,jsx,ts,js,css,scss}"
```

### 2. 构建验证

```bash
# 优先检测 package.json scripts:
pnpm build    # 首选
npm run build # 备选
```

### 3. 缺少构建命令时

如果 `package.json` 中 `scripts` 不包含 `build`，必须明确警告：

> **WARNING**: 项目未配置 build 命令。请执行以下操作之一：
>
> 1. 在 package.json 中配置 `"build": "..."` 命令
> 2. 手动执行构建并确认通过
>
> 在 build 命令确认可用之前，不应提交。

### Stop Hooks

```json
{
  "hooks": {
    "Stop": [
      {
        "command": "pnpm build",
        "description": "Verify production build at session end"
      }
    ]
  }
}
```

## Recommended Hook Order

1. `prettier --write`
2. `eslint --fix`
3. `tsc --noEmit` / `vue-tsc --noEmit`
4. `pnpm build`
