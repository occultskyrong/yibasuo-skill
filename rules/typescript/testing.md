---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript Testing

> This file extends [common/testing.md](../common/testing.md) with TypeScript/JavaScript specific content.

## Test Framework

| Layer | Tool |
| ------- | ------ |
| Unit / Integration | Vitest (preferred) or Jest |
| HTTP endpoint | supertest |
| E2E | Playwright |
| Coverage | v8 (Vitest) or Istanbul (Jest) |

## Test Organization

```text
src/test/
├── unit/                  # Pure function / isolated provider tests
│   └── modules/
│       └── users/
│           └── users.service.spec.ts
├── integration/           # HTTP endpoint tests (supertest)
│   └── modules/
│       └── users/
│           └── users.controller.spec.ts
└── e2e/                   # Playwright end-to-end tests
    └── auth-flow.spec.ts
```

- Mirror the source directory structure under `test/`
- Unit tests live near the source file OR under `test/unit/` (match project convention)

## Unit Tests — Service Layer

Isolate the provider from its dependencies with mocks:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { UsersRepository } from './users.repository';
import { NotFoundException } from '@nestjs/common';

describe('UsersService', () => {
  let service: UsersService;
  let repo: { findById: ReturnType<typeof vi.fn> };

  beforeEach(async () => {
    repo = { findById: vi.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: UsersRepository, useValue: repo },
      ],
    }).compile();

    service = module.get(UsersService);
  });

  describe('getById', () => {
    it('returns user when found', async () => {
      const user = { id: '1', email: 'a@b.com', name: 'Alice' };
      repo.findById.mockResolvedValue(user);

      const result = await service.getById('1');

      expect(result).toMatchObject({ id: '1', email: 'a@b.com' });
    });

    it('throws NotFoundException when user missing', async () => {
      repo.findById.mockResolvedValue(null);

      await expect(service.getById('99')).rejects.toThrow(NotFoundException);
    });
  });
});
```

## Integration Tests — HTTP Layer

Test the full request pipeline (guard → pipe → controller → service) with supertest:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('UsersController (integration)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('POST /users validates required fields', async () => {
    await request(app.getHttpServer())
      .post('/users')
      .send({ email: 'not-an-email' })
      .expect(400);
  });
});
```

- Apply the same global pipes, guards, and filters that production uses
- Use a test database or mock the repository layer — never hit production data

## E2E Testing

Use **Playwright** for critical user flows:

```typescript
import { test, expect } from '@playwright/test';

test('user can log in', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'password');
  await page.click('button[type="submit"]');
  await expect(page.locator('[data-testid="dashboard"]')).toBeVisible();
});
```

- Prefer `data-testid` selectors over CSS classes or text content
- Avoid flaky timeout-based assertions; use `waitForSelector` or `expect(...).toBeVisible()` with built-in retry

## Test Naming

```typescript
describe('<Unit Under Test>', () => {
  describe('<method or scenario group>', () => {
    it('<expected behavior when condition>', () => { ... });
  });
});
```

Example: `describe('UsersService', () => { describe('getById', () => { it('throws when user not found', ...) }) })`

## Coverage

- Target **80%+** line/branch coverage
- Vitest: `vitest --coverage` (v8 provider)
- Jest: `jest --coverage` (Istanbul)
- Skip trivial getters, config files, and generated code from coverage

## Agent Support

- **tdd-guide** — Enforce TDD workflow for new features and bug fixes
- **code-reviewer** — Review test quality and coverage
- **typescript-reviewer** — TypeScript-specific test patterns

## References

See skill: `nestjs-patterns` for NestJS testing patterns.
See skill: `e2e-testing` for Playwright E2E patterns.
