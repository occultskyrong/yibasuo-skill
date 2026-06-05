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

### Dependency Management

- 新增 npm 包必须通过 `<pkg> add <package>` 安装，**禁止手动编辑 `package.json`** 或直接 `import` 不声明
- 版本号由包管理器写入 `package.json` + lockfile，**lockfile 必须提交**（`package-lock.json` / `pnpm-lock.yaml`）
- 禁止依赖全局安装的包（`npm install -g`）—— 所有依赖必须是项目级
- 区分 `dependencies`（运行时）和 `devDependencies`（构建/测试/格式）

```bash
# GOOD
pnpm add @nestjs/schedule
npm install --save @nestjs/schedule

# BAD — 手动编辑 package.json 再 npm install
# BAD — import 了但没加到 package.json，靠全局安装碰运气
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
- **禁止 `src/` 下超过 2 层嵌套**。如需更深层级，要么把下层拆到 `src/modules/` 下作为独立 module，要么把文件夹展平

```typescript
// BAD — src/modules/ 下嵌套了 3+ 层
src/modules/order/
  └── submodules/
      └── payment/
          └── services/
              └── payment.service.ts

// GOOD — 拆到 src/modules/ 下作为独立 module
src/modules/order/
  └── order.module.ts
src/modules/payment/
  └── payment.module.ts

// GOOD — 展平为单层
src/modules/order/
  ├── order.module.ts
  ├── order.service.ts
  └── payment/
      ├── payment.module.ts
      └── payment.service.ts
```

### API Response Convention

遵循 `rules/common/patterns.md` API Response Format 定义的统一信封结构。NestJS 实现见 `rules/typescript/patterns.md`。

- Controller 返回业务数据，全局 ResponseInterceptor 统一包装为 `ApiResponse`
- 禁止在响应中暴露堆栈或内部错误信息

### `satisfies` 操作符 (TS 4.9+)

优先用 `satisfies` 替代 `as` 断言——`satisfies` 保留字面量类型且校验，`as` 绕过类型检查：

```typescript
// GOOD — satisfies 校验结构，保留字面量类型
const config = {
  port: 3000,
  host: 'localhost',
} satisfies Record<string, string | number>;
// config.port 类型是 number（字面量），不是 string | number

// BAD — as 不校验，可能遗漏字段
const config = {
  port: 3000,
} as Record<string, string | number>; // 编译通过，但缺字段
```

### 泛型约束

NestJS 中泛型广泛用于 Repository 模式和 ApiResponse 封装：

```typescript
// 基本约束
function findById<T extends { id: number }>(repo: Repository<T>, id: number): Promise<T | null> {
  return repo.findOneBy({ id } as FindOptionsWhere<T>);
}

// 泛型工具类型
type CreateUserDto = Pick<User, 'username' | 'phone'>;
type UpdateUserDto = Partial<Omit<User, 'id' | 'createdAt'>>;
type UserResponse = Omit<User, 'password' | 'deletedAt'>;
```

- `Pick` — 选取部分字段
- `Omit` — 排除部分字段
- `Partial` — 所有字段可选
- `Required` — 所有字段必填

### Branded Types（防 ID 混用）

对 ID 类型使用 branded types 防止"stringly typed"错误：

```typescript
type UserId = string & { readonly __brand: 'UserId' };
type OrderId = string & { readonly __brand: 'OrderId' };

function getUser(id: UserId): Promise<User> { ... }

// 编译报错：OrderId 不能赋值给 UserId
getUser(orderId); // Type Error
```

## 注释与 JSDoc

> 继承 [common/coding-style.md](../common/coding-style.md) 注释规范。

### JSDoc 强制范围

| 位置 | 要求 |
|------|:---:|
| 所有 `export` 函数/类/常量 | **必须** |
| 公共 API（Controller/Service 公开方法） | **必须** |
| 复杂泛型（`infer`/条件类型/模板字面量类型） | **必须** |
| 工具函数（`utils/`、`helpers/`） | **必须** |
| 简单 getter/setter、一目了然的私有方法 | 可省略 |

**判断原则**：类型签名 + 函数名已自解释时可省略；涉及业务逻辑/边界条件/副作用时必须写。

```typescript
// 不需要 JSDoc — 类型已自解释
function formatFullName(first: string, last: string): string {
  return `${first} ${last}`
}

// 需要 JSDoc — 有副作用（写 DB），类型无法体现
/**
 * 激活园区，级联创建默认班级和课程模板。
 * 激活成功后会异步通知家长端。
 *
 * @throws NotFoundException 园区不存在或已删除
 */
async activateGarden(gardenId: string): Promise<Garden> { ... }
```

### JSDoc 标签规范

| 标签 | 说明 | 必填场景 |
|------|------|----------|
| `@param` | 参数描述+约束 | 参数名不自解释或有多参数依赖时 |
| `@returns` | 返回值描述 | 返回值类型复杂或方法有副作用时 |
| `@throws` | 可能抛出的异常 | 方法主动抛异常给调用方时 |
| `@deprecated` | 废弃+替代方案 | **必填**，必须写替代方案和版本号 |
| `@example` | 调用示例 | 工具函数、配置复杂的 API |
| `@typeParam` | 泛型参数说明 | 泛型名称不自解释时 |

标签顺序：`@param` → `@returns` → `@throws` → `@deprecated` → `@see` → `@example`

禁止空 JSDoc、禁止标签无描述内容。

### 类型注释 vs 值注释的边界

TypeScript 类型系统本身即是文档。注释应解释 **为什么**（设计意图、约束、边界），不是 **是什么**（类型已说清楚）。

```typescript
// BAD — 注释重复类型签名
/**
 * @param name - 用户名，string 类型
 * @param age - 年龄，number 类型
 */
function greet(name: string, age: number): string { ... }

// GOOD — 注释补充类型无法传递的信息
interface User {
  id: string
  email: string
  /** 手机号遵循 E.164 格式（+8613800138000），用于短信通知 */
  phone: string
  /** 出生日期为空时生成报告会使用系统默认年龄估算值 */
  birthday: Date | null
}
```

### NestJS Controller 注释

```typescript
/**
 * 创建新课程。
 *
 * POST /courses
 *
 * @throws ConflictException 课程名称在同一机构下已存在
 */
@Post()
async create(@Body() dto: CreateCourseDto): Promise<ApiResponse<Course>> { ... }

/**
 * 分页查询课程列表，支持多条件筛选。
 *
 * GET /courses?keyword=&status=&page=&pageSize=
 *
 * @throws ForbiddenException 无权限访问目标机构
 */
@Get()
async list(@Query() query: CourseListQuery): Promise<ApiResponse<PaginatedResult<Course>>> { ... }
```

### NestJS Service 注释

聚焦**前置条件**和**副作用**：

```typescript
/**
 * 创建课程实体并写入数据库。
 *
 * 前置条件: 机构已存在且未停用
 * 副作用: 写入 courses 表; 若 enableDefaultTemplate 为 true，自动创建默认课节模板
 */
async create(dto: CreateCourseDto): Promise<Course> { ... }
```

### @Deprecated 规范

```typescript
/**
 * @deprecated 自 v2.3.0 起，请使用 {@link updateV2}。
 *             计划在 v3.0.0 移除此方法。
 */
async update(id: string, dto: UpdateDto): Promise<Course> { ... }
```

### 不推荐的注释

### 单行 vs 块注释

- 单行注释用 `//`，**禁止 `/* */` 写单行注释**
- 多行注释用连续的 `//`，禁止 `/* */` 块注释（避免和被注释掉的代码混淆）
- 只有 JSDoc（`/** */`）可以使用块形式，且仅用于文档注释

### 反模式速查

| 反模式 | 替代做法 |
|--------|----------|
| 注释掉的代码 | 删除，Git 保留历史 |
| `// fix later` / `// hack` | `TODO(owner): 具体描述 [target]` |
| 逐行翻译式注释 | 代码已自解释 → 删除 |
| 与代码不一致的注释 | 改代码时同步更新注释 |
| 情绪化注释 | `FIXME` + 技术原因 |
| `any` 辩解注释 | 用 `unknown` + 类型守卫或 `zod`
