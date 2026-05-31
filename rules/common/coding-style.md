# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:

```
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
- Booleans: prefer `is`, `has`, `should`, or `can` prefixes
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

### 必须加注释的场景

- **Bug 修复**：在修复的关键代码处注释"为什么这么修"，方便后续维护者理解修复逻辑
- **非显而易见的逻辑**：算法选择、边界处理、性能优化等不直观的代码
- **公共接口/API**：Java 用 Javadoc（`@param`/`@return`/`@throws`），TypeScript 用 JSDoc（`@param`/`@returns`）
- **`@Deprecated`**：标注废弃方法/类时必须写替代方案

### 禁止的注释

- 代码自解释时画蛇添足的注释（如 `// 设置 name` 注释 `setName()`）
- 被注释掉的代码块（除非附带了"为什么保留"的说明和日期）
- 过期/错误的注释（修改代码时必须同步更新注释）

### TODO / FIXME

- `TODO` 用于计划实现但暂时搁置的功能，格式：`// TODO(username): 描述`
- `FIXME` 用于已知但暂未修复的问题，格式：`// FIXME(username): 问题描述`
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
