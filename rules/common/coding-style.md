# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:

```text
// Pseudocode
WRONG:  modify(original, field, value) → changes original in-place
CORRECT: update(original, field, value) → returns new copy with change
```

Rationale: Immutable data prevents hidden side effects, makes debugging easier, and enables safe concurrency.

## Core Principles

### KISS (Keep It Simple)

- Prefer the simplest solution that actually works
- Avoid premature optimization
- Optimize for clarity over cleverness

### DRY (Don't Repeat Yourself)

- Extract repeated logic into shared functions or utilities
- Avoid copy-paste implementation drift
- Introduce abstractions when repetition is real, not speculative

### YAGNI (You Aren't Gonna Need It)

- Do not build features or abstractions before they are needed
- Avoid speculative generality
- Start simple, then refactor when the pressure is real

## File Organization

MANY SMALL FILES > FEW LARGE FILES:

- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large modules
- Organize by feature/domain, not by type

## Error Handling

ALWAYS handle errors comprehensively:

- Handle errors explicitly at every level
- Provide user-friendly error messages in UI-facing code
- Log detailed error context on the server side
- Never silently swallow errors

## Input Validation

ALWAYS validate at system boundaries:

- Validate all user input before processing
- Use schema-based validation where available
- Fail fast with clear error messages
- Never trust external data (API responses, user input, file content)

## Naming Conventions

- Variables and functions: `camelCase` with descriptive names
- Booleans: prefer `is`, `has`, `should`, or `can` prefixes（**例外：Java POJO `boolean`/`Boolean` 属性禁止 `is` 前缀**，Jackson 序列化冲突，详见 `rules/java/coding-style.md`）
- Interfaces, types, and components: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Custom hooks: `camelCase` with a `use` prefix

## Code Smells to Avoid

### Deep Nesting

Prefer early returns over nested conditionals once the logic starts stacking.

### Magic Numbers

Use named constants for meaningful thresholds, delays, and limits.

### Long Functions

Split large functions into focused pieces with clear responsibilities.

## 注释

参考：阿里巴巴 Java 开发手册 p3c 注释规约。

### 必须加注释的场景

| 场景 | 说明 |
| ------ | ------ |
| **Bug 修复** | 必须注释根因 + 修复思路，不写 "fix bug" |
| **复杂算法** | 算法名称、核心思路、为什么选这个算法 |
| **非直观业务规则** | 业务背景、为什么这样处理 |
| **Magic Number** | 值的含义、为什么是这个值、来源依据 |
| **Workaround / Hack** | 临时方案原因、正确做法、关联 issue |
| **性能敏感的代码选择** | 为什么用这个数据结构、benchmark 结果 |
| **非显而易见的副作用** | 修改了外部状态、调用了有副作用的操作 |
| **跨模块隐式依赖** | 依赖了不明显的上游数据格式或下游行为 |
| **公共接口/API** | Java Javadoc / TypeScript JSDoc |
| **@Deprecated** | 必须写出替代方案 |

### 注释内容要求

**为什么 > 做什么**：代码本身描述 "做什么"，注释必须解释 "为什么"。

```text
// BAD — 复述代码
// 遍历用户列表
for (User user : users) { ... }

// GOOD — 解释为什么
// 先查缓存再查库，避免瞬时高并发穿透到 DB
for (User user : users) { ... }
```

- 修改代码时**必须同步更新注释**。审查时注释与代码不一致视为 HIGH 级别问题
- 注释语言统一（同项目内中文或英文二选一）

### 禁止项

- **注释掉的代码**：直接删除，Git 保留历史
- **情绪化注释**：`// 天坑，别动` → 改为解释技术原因
- **手工变更日志**：`// 2024-01 by xx: 新增XX` → 用 Git commit/CHANGELOG
- **画蛇添足**：`// 设置用户名` 注释 `setUsername()`
- **被注释掉的 import**

### 特殊标记

| 标记 | 含义 | 格式 |
| ------ | ------ | ------ |
| `TODO` | 待完成 | `// TODO(owner): 描述 [target_version]` |
| `FIXME` | 已知问题 | `// FIXME: 描述（必须有原因和方案）` |
| `HACK` | 临时方案 | `// HACK: reason. TODO(#ticket): proper fix` |
| `XXX` | 严重需关注 | `// XXX: critical issue` |

- TODO/FIXME 必须有责任人和具体说明，不能只写 "后面改"
- 禁止用 TODO 代替功能需求的正确记录

## Code Quality Checklist

Before marking work complete:

- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No hardcoded values (use constants or config)
- [ ] No mutation (immutable patterns used)
- [ ] Bug fix includes explanatory comments at key code locations
