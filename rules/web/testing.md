---
paths:
  - "**/*.vue"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.test.*"
  - "**/*.spec.*"
---
# Frontend Testing

> This file extends [common/testing.md](../common/testing.md) with Vue/React specific content.

## Test Priority (优先级)

1. **Visual Regression** — 截图关键断点：320, 768, 1024, 1440
2. **Accessibility** — 自动化 a11y 检查 + 键盘导航 + reduced-motion
3. **E2E** — 关键用户流程（登录、注册、核心功能）
4. **Unit** — 工具函数、composables/hooks、数据转换
5. **Performance** — Lighthouse 或等价工具

## Framework

| 层 | 工具 |
| ---- | ------ |
| Unit / Component | Vitest + Vue Test Utils / React Testing Library |
| E2E | Playwright |
| Visual | Playwright screenshots |
| A11y | axe-core / @axe-core/playwright |
| Coverage | v8 (Vitest) |

## Component Test Pattern

```tsx
// React component test
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

test('calls onSelect when button clicked', async () => {
  const onSelect = vi.fn()
  render(<UserCard user={mockUser} onSelect={onSelect} />)

  await userEvent.click(screen.getByRole('button'))

  expect(onSelect).toHaveBeenCalledWith(mockUser.id)
})
```

```ts
// Vue composable test
import { useCounter } from './useCounter'

test('increments counter', () => {
  const { count, increment } = useCounter()
  expect(count.value).toBe(0)
  increment()
  expect(count.value).toBe(1)
})
```

## E2E Pattern

```ts
import { test, expect } from '@playwright/test'

test('hero loads and is visible', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('h1')).toBeVisible()
})
```

- 优先 `data-testid` / `role` 选择器，而非 CSS class
- 避免 flaky timeout 断言，用 `expect(...).toBeVisible()` 自带重试

## Visual Regression

```ts
test('landing page at 768', async ({ page }) => {
  await page.setViewportSize({ width: 768, height: 1024 })
  await page.goto('/')
  await expect(page).toHaveScreenshot('landing-768.png', { fullPage: true })
})
```

断点：320, 375, 768, 1024, 1440, 1920。

## Accessibility

```ts
import AxeBuilder from '@axe-core/playwright'

test('a11y check', async ({ page }) => {
  await page.goto('/')
  const results = await new AxeBuilder({ page }).analyze()
  expect(results.violations).toEqual([])
})
```

## Coverage

- Target 80%+ lines
- 对于高度视觉化的组件，visual regression 往往比脆弱的 DOM 断言更有价值
