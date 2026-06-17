# ESLint 检查清单

> 阶段 5 格式检查时逐项核对。ESLint 负责代码质量，Prettier 负责格式。

## Error 级别（CI 阻断）

| 规则 | 说明 |
|------|------|
| `react-hooks/rules-of-hooks` | Hook 必须在顶层调用，禁止条件/循环中使用 |
| `react-hooks/exhaustive-deps` | useEffect/useMemo/useCallback 依赖数组完整 |
| `react/jsx-key` | 列表渲染必须有唯一 key |
| `react/jsx-no-target-blank` | `target="_blank"` 必须含 `rel="noopener noreferrer"` |
| `react/jsx-no-duplicate-props` | 禁止重复 prop |
| `react/no-direct-mutation-state` | 禁止直接修改 state |
| `@typescript-eslint/no-unused-vars` | 未使用变量（`_` 前缀允许忽略） |
| `@typescript-eslint/no-floating-promises` | 捕获未处理的 Promise（闭包/then 返回值） |
| `@typescript-eslint/no-misused-promises` | async/await 类型检查 |
| `@typescript-eslint/await-thenable` | 仅 await 真正的 thenable |
| `no-console` | 禁止 `console.log` 进入生产（允许 `warn`/`error`） |
| `eqeqeq` | 强制 `===`，避免隐式类型转换 |
| `no-var` | 禁止 `var` |
| `prefer-const` | 优先 `const`，不重新赋值不用 `let` |
| `prefer-arrow-callback` | 匿名函数优先箭头函数 |
| `func-names` | 禁止匿名函数表达式（调试时堆栈看不到函数名） |
| `no-loop-func` | 循环中禁止闭包引用外部变量 |
| `max-nested-callbacks` | 禁止回调嵌套（>1 层），强制 async/await 替代 `.then()` 链 |

## Warn 级别

| 规则 | 说明 |
|------|------|
| `@typescript-eslint/no-explicit-any` | 避免 `any`，用 `unknown` 替代 |
| `@typescript-eslint/consistent-type-imports` | 统一 `import type` |
| `@typescript-eslint/prefer-nullish-coalescing` | 强制 `??`（更精确的 null 处理） |

## 建议关闭

| 规则 | 原因 |
|------|------|
| `react/react-in-jsx-scope` | React 17+ 自动 JSX 运行时 |
| `react/prop-types` | TypeScript 已提供类型检查 |

## 基础配置（ESLint 9 Flat Config）

```js
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import reactHooks from 'eslint-plugin-react-hooks';

export default tseslint.defineConfig([
  { ignores: ['dist/', 'node_modules/'] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    plugins: { 'react-hooks': reactHooks },
    rules: {
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
      'no-console': ['error', { allow: ['warn', 'error'] }],
      'eqeqeq': 'error',
      'no-var': 'error',
      'prefer-const': 'error',
      'prefer-arrow-callback': 'error',
      'func-names': 'error',
      'no-loop-func': 'error',
      'max-nested-callbacks': ['error', 1],
    },
  },
]);
```

## 阶段 5 执行

```
<pkg> prettier --check . && <pkg> eslint . --max-warnings 0
```
