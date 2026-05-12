---
paths:
  - "**/*.vue"
  - "**/*.tsx"
  - "**/*.jsx"
---
# Frontend Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Vue/React specific content.

## Component Composition

### Compound Components (React)

```tsx
<Tabs defaultValue="overview">
  <Tabs.List>
    <Tabs.Trigger value="overview">Overview</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Content value="overview">...</Tabs.Content>
</Tabs>
```

- Parent 持有状态，children 通过 context 消费
- 复杂 widget 优先此模式，而非 prop drilling

### Slots (Vue)

```vue
<template>
  <Card>
    <template #header><h2>Title</h2></template>
    <template #default>Content here</template>
    <template #footer><Button>OK</Button></template>
  </Card>
</template>
```

## State Management

| 关注点 | 方案 |
|--------|------|
| Server state | TanStack Query (Vue/React), SWR (React) |
| Client state | Pinia (Vue), Zustand / Jotai (React) |
| URL state | search params、route segments |
| Form state | React Hook Form (React), vee-validate (Vue) |

- 不把 server state 复制到 client store
- 派生值直接计算，不存储冗余

## URL as State

将以下可分享状态持久化到 URL：filters、sort、pagination、active tab、search query。

## Data Fetching

### Stale-While-Revalidate
- 返回缓存数据立即渲染
- 后台重新验证
- 用 TanStack Query 等库，不手写

### Optimistic Updates
- 快照当前状态 → 应用乐观更新 → 失败则回滚 → 回滚时给可见错误反馈

### Parallel Loading
- 独立数据并行 fetch
- 避免父子请求瀑布
- 预取可能的下一页

## Container / Presentational

- Container 组件负责数据加载和副作用
- Presentational 组件接收 props 纯渲染
- Presentational 保持纯函数

## Perf Checklist

- [ ] 图片有明确 width/height
- [ ] 无意外渲染阻塞资源
- [ ] 动态内容无 layout shift（CLS < 0.1）
- [ ] LCP 图片 `fetchpriority="high"` + `loading="eager"`
- [ ] 非首屏图片 `loading="lazy"`
- [ ] 重库动态 import（`await import('gsap')`）
- [ ] 仅首屏字体 preload，其余 `font-display: swap`
