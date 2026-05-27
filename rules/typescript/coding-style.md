---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with TypeScript/JavaScript specific content.

## Types and Interfaces

为公开 API、共享模型和组件 Props 使用显式类型，使其可读、可复用。

### Public APIs

- Add parameter and return types to exported functions, shared utilities, and public class methods
- Let TypeScript infer obvious local variable types
- Extract repeated inline object shapes into named types or interfaces

```typescript
// WRONG: Exported function without explicit types
export function formatUser(user) {
  return `${user.firstName} ${user.lastName}`
}

// CORRECT: Explicit types on public APIs
interface User {
  firstName: string
  lastName: string
}

export function formatUser(user: User): string {
  return `${user.firstName} ${user.lastName}`
}
```

### Interfaces vs. Type Aliases

- Use `interface` for object shapes that may be extended or implemented
- Use `type` for unions, intersections, tuples, mapped types, and utility types
- Prefer string literal unions over `enum` unless an `enum` is required for interoperability

```typescript
interface User {
  id: string
  email: string
}

type UserRole = 'admin' | 'member'
type UserWithRole = User & {
  role: UserRole
}
```

### Avoid `any`

- Avoid `any` in application code
- Use `unknown` for external or untrusted input, then narrow it safely
- Use generics when a value's type depends on the caller

```typescript
// WRONG: any removes type safety
function getErrorMessage(error: any) {
  return error.message
}

// CORRECT: unknown forces safe narrowing
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message
  }

  return 'Unexpected error'
}
```

### React Props

- Define component props with a named `interface` or `type`
- Type callback props explicitly
- Do not use `React.FC` unless there is a specific reason to do so

```typescript
interface User {
  id: string
  email: string
}

interface UserCardProps {
  user: User
  onSelect: (id: string) => void
}

function UserCard({ user, onSelect }: UserCardProps) {
  return <button onClick={() => onSelect(user.id)}>{user.email}</button>
}
```

### JavaScript Files

- In `.js` and `.jsx` files, use JSDoc when types improve clarity and a TypeScript migration is not practical
- Keep JSDoc aligned with runtime behavior

```javascript
/**
 * @param {{ firstName: string, lastName: string }} user
 * @returns {string}
 */
export function formatUser(user) {
  return `${user.firstName} ${user.lastName}`
}
```

## Immutability

使用扩展运算符实现不可变更新：

```typescript
interface User {
  id: string
  name: string
}

// WRONG: Mutation
function updateUser(user: User, name: string): User {
  user.name = name // MUTATION!
  return user
}

// CORRECT: Immutability
function updateUser(user: Readonly<User>, name: string): User {
  return {
    ...user,
    name
  }
}
```

## Error Handling

Use async/await with try-catch and narrow unknown errors safely:

```typescript
interface User {
  id: string
  email: string
}

declare function riskyOperation(userId: string): Promise<User>

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message
  }

  return 'Unexpected error'
}

const logger = {
  error: (message: string, error: unknown) => {
    // Replace with your production logger (for example, pino or winston).
  }
}

async function loadUser(userId: string): Promise<User> {
  try {
    const result = await riskyOperation(userId)
    return result
  } catch (error: unknown) {
    logger.error('Operation failed', error)
    throw new Error(getErrorMessage(error))
  }
}
```

## Input Validation

Use Zod for schema-based validation and infer types from the schema:

```typescript
import { z } from 'zod'

const userSchema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150)
})

type UserInput = z.infer<typeof userSchema>

const validated: UserInput = userSchema.parse(input)
```

## Console.log

- No `console.log` statements in production code
- Use proper logging libraries instead
- See hooks for automatic detection

## NestJS Conventions

### File Naming

- Files: `snake_case` (`user_service.ts`, `auth_controller.ts`)
- Directories: `snake_case` (`src/modules/user_management/`)
- Test files: mirror source with `.spec.ts` or `.test.ts` suffix

### Naming in Code

- Classes: `PascalCase` (`UsersService`, `AuthController`)
- Methods and variables: `camelCase` (`findByEmail`, `userId`)
- Constants: `UPPER_SNAKE_CASE` (`MAX_RETRY_COUNT`)
- **Private methods**: double-underscore prefix (`__validateInput`, `__mapToDto`)
- Private fields: single underscore or `private readonly` (match project convention)

```typescript
@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  // Public API
  async createUser(dto: CreateUserDto): Promise<UserResponse> {
    this.__validateEmail(dto.email);
    const entity = this.__mapToEntity(dto);
    return this.userRepo.save(entity);
  }

  // Private internals
  private __validateEmail(email: string): void {
    if (!email.includes('@')) throw new BadRequestException('Invalid email');
  }

  private __mapToEntity(dto: CreateUserDto): User {
    return { ...dto, createdAt: new Date() };
  }
}
```

### Module Organization

```
src/
├── main.ts
├── app.module.ts
├── common/               # Cross-cutting: filters, guards, interceptors, pipes
├── config/               # env validation, configuration loaders
└── modules/
    └── <feature>/
        ├── <feature>.module.ts
        ├── <feature>.controller.ts
        ├── <feature>.service.ts
        ├── dto/
        └── entities/
```

- One feature per module directory
- Cross-cutting code in `common/`, not duplicated in each module
- Keep controllers thin: parse HTTP input, delegate to service, return DTO

### API Response Convention

遵循 `rules/common/patterns.md` API Response Format 定义的统一信封结构。NestJS 实现见 `rules/typescript/patterns.md`。

- Controller 返回业务数据，全局 ResponseInterceptor 统一包装为 `ApiResponse`
- 禁止在响应中暴露堆栈或内部错误信息
