---
paths:
  - "**/*.vue"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.css"
  - "**/*.scss"
---
# Frontend Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Vue/React specific content.

## Framework Selection

根据项目现有技术栈选择，不引入不必要的框架：

| 项目 | 框架 | 构建工具 |
|------|------|---------|
| Vue 3 | Composition API + `<script setup>` | Vite |
| React 18+ | Functional Components + Hooks | Vite / Next.js |

## Naming

- Components: `PascalCase` (`UserCard`, `ScrollySection`)
- Composables/Hooks: `use` 前缀 (`useReducedMotion`, `useScrollProgress`)
- CSS classes: kebab-case 或 utility classes
- Files: 匹配组件名（`UserCard.vue`, `UserCard.tsx`）
- Directories: kebab-case（`src/components/user-profile/`）

## File Organization

按功能/表面组织，不按文件类型：

```
src/
├── components/
│   ├── hero/
│   │   ├── Hero.vue / Hero.tsx
│   │   ├── HeroVisual.vue / HeroVisual.tsx
│   │   └── hero.css
│   └── ui/
│       ├── Button.vue / Button.tsx
│       └── SurfaceCard.vue / SurfaceCard.tsx
├── composables/ 或 hooks/
├── lib/ 或 utils/
└── styles/
    ├── tokens.css
    └── global.css
```

## Vue SFC

```vue
<script setup lang="ts">
interface Props {
  title: string
  items: Item[]
}

const props = defineProps<Props>()
const emit = defineEmits<{ select: [id: string] }>()
</script>

<template>
  <section>
    <h1>{{ title }}</h1>
    <ul>
      <li v-for="item in items" :key="item.id" @click="emit('select', item.id)">
        {{ item.name }}
      </li>
    </ul>
  </section>
</template>

<style scoped>
section { ... }
</style>
```

- 使用 `<script setup lang="ts">`，TypeScript 必须
- Props/Emits 用类型声明，不用 `defineComponent`
- CSS 使用 `scoped` 或 CSS Modules

## React Component

```tsx
interface UserCardProps {
  user: User
  onSelect: (id: string) => void
}

function UserCard({ user, onSelect }: UserCardProps) {
  return <button onClick={() => onSelect(user.id)}>{user.email}</button>
}
```

- Props 用 named interface，不内联
- 不用 `React.FC`，用普通函数 + 类型标注
- 组件不要有任何副作用，副作用在使用者（page/container）中处理

## CSS Custom Properties

定义设计 token 为变量，禁止硬编码颜色/字号/间距：

```css
:root {
  --color-surface: oklch(98% 0 0);
  --color-text: oklch(18% 0 0);
  --color-accent: oklch(68% 0.21 250);
  --text-base: clamp(1rem, 1vw, 1.125rem);
  --space-section: clamp(4rem, 5vw, 10rem);
  --duration-normal: 300ms;
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
}
```

## Animation

只动画合成器友好属性：`transform`、`opacity`、`clip-path`、`filter`（慎用）。
禁止动画 layout-bound 属性：`width`、`height`、`top`、`left`、`margin`、`padding`。

## Code Smells

- 巨型组件（>300 行）→ 提取子组件或 composables
- 深层嵌套（>3 层）→ 提取子组件
- 内联样式 → 用 CSS 变量或 class
- `any` 类型 → 用具体类型或泛型
- `console.log` → 用 logger 或移除
