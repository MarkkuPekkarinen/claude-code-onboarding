# NestJS 11.x Advanced Testing Guide

Advanced testing patterns for NestJS 11.x including circuit breaker testing, request context propagation, coverage standards, CI/CD integration, and troubleshooting common issues.

## Circuit Breaker Testing

```typescript
// src/core/circuit-breaker/circuit-breaker.spec.ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { CircuitBreaker } from './circuit-breaker';
import { CircuitBreakerOpenException } from './circuit-breaker.exception';

describe('CircuitBreaker', () => {
  let breaker: CircuitBreaker;

  beforeEach(() => {
    breaker = new CircuitBreaker({
      failureThreshold: 3,
      resetTimeout: 1000,
      halfOpenMaxAttempts: 2,
    });
  });

  describe('Happy Path', () => {
    it('should execute operation successfully when circuit is closed', async () => {
      const operation = vi.fn().mockResolvedValue('success');

      const result = await breaker.execute(operation);

      expect(result).toBe('success');
      expect(operation).toHaveBeenCalledTimes(1);
      expect(breaker.getState()).toBe('CLOSED');
    });
  });

  describe('Circuit Open', () => {
    it('should open circuit after threshold failures', async () => {
      const operation = vi.fn().mockRejectedValue(new Error('Service down'));

      // Trigger failures to open circuit
      for (let i = 0; i < 3; i++) {
        await expect(breaker.execute(operation)).rejects.toThrow(
          'Service down',
        );
      }

      expect(breaker.getState()).toBe('OPEN');

      // Next call should fail fast without calling operation
      await expect(breaker.execute(operation)).rejects.toThrow(
        CircuitBreakerOpenException,
      );
      expect(operation).toHaveBeenCalledTimes(3); // Not 4
    });
  });

  describe('Half-Open Recovery', () => {
    it('should transition to half-open after reset timeout', async () => {
      const operation = vi.fn().mockRejectedValue(new Error('Service down'));

      // Open the circuit
      for (let i = 0; i < 3; i++) {
        await expect(breaker.execute(operation)).rejects.toThrow();
      }

      expect(breaker.getState()).toBe('OPEN');

      // Wait for reset timeout
      await new Promise((resolve) => setTimeout(resolve, 1100));

      expect(breaker.getState()).toBe('HALF_OPEN');
    });

    it('should close circuit after successful half-open attempts', async () => {
      const operation = vi
        .fn()
        .mockRejectedValueOnce(new Error('Fail 1'))
        .mockRejectedValueOnce(new Error('Fail 2'))
        .mockRejectedValueOnce(new Error('Fail 3'))
        .mockResolvedValue('success');

      // Open the circuit
      for (let i = 0; i < 3; i++) {
        await expect(breaker.execute(operation)).rejects.toThrow();
      }

      expect(breaker.getState()).toBe('OPEN');

      // Wait for reset timeout
      await new Promise((resolve) => setTimeout(resolve, 1100));

      // Successful call in half-open state
      const result = await breaker.execute(operation);

      expect(result).toBe('success');
      expect(breaker.getState()).toBe('CLOSED');
    });

    it('should reopen circuit if half-open attempt fails', async () => {
      const operation = vi.fn().mockRejectedValue(new Error('Still failing'));

      // Open the circuit
      for (let i = 0; i < 3; i++) {
        await expect(breaker.execute(operation)).rejects.toThrow();
      }

      // Wait for reset timeout
      await new Promise((resolve) => setTimeout(resolve, 1100));

      expect(breaker.getState()).toBe('HALF_OPEN');

      // Fail in half-open state
      await expect(breaker.execute(operation)).rejects.toThrow(
        'Still failing',
      );

      expect(breaker.getState()).toBe('OPEN');
    });
  });

  describe('Fallback Verification', () => {
    it('should execute fallback when circuit is open', async () => {
      const operation = vi.fn().mockRejectedValue(new Error('Service down'));
      const fallback = vi.fn().mockResolvedValue('fallback-value');

      // Open the circuit
      for (let i = 0; i < 3; i++) {
        await expect(breaker.execute(operation)).rejects.toThrow();
      }

      const result = await breaker.executeWithFallback(operation, fallback);

      expect(result).toBe('fallback-value');
      expect(fallback).toHaveBeenCalled();
    });
  });

  describe('Metrics', () => {
    it('should track success and failure counts', async () => {
      const successOp = vi.fn().mockResolvedValue('success');
      const failOp = vi.fn().mockRejectedValue(new Error('fail'));

      await breaker.execute(successOp);
      await breaker.execute(successOp);

      try {
        await breaker.execute(failOp);
      } catch (error) {
        // Expected
      }

      const metrics = breaker.getMetrics();

      expect(metrics.successCount).toBe(2);
      expect(metrics.failureCount).toBe(1);
      expect(metrics.state).toBe('CLOSED');
    });
  });
});
```

## Testing Request Context (AsyncLocalStorage)

```typescript
// src/core/context/request-context.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { describe, it, expect, beforeEach } from 'vitest';
import { RequestContextService } from './request-context.service';
import { RequestContextMiddleware } from './request-context.middleware';

describe('RequestContextService', () => {
  let service: RequestContextService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [RequestContextService],
    }).compile();

    service = module.get<RequestContextService>(RequestContextService);
  });

  describe('Correlation ID Propagation', () => {
    it('should set and get correlation ID within context', async () => {
      const correlationId = 'test-correlation-id';

      await service.run({ correlationId }, async () => {
        const retrieved = service.getCorrelationId();
        expect(retrieved).toBe(correlationId);
      });
    });

    it('should return undefined when no context is set', () => {
      const correlationId = service.getCorrelationId();
      expect(correlationId).toBeUndefined();
    });

    it('should maintain separate contexts for concurrent operations', async () => {
      const promises = [
        service.run({ correlationId: 'request-1' }, async () => {
          await new Promise((resolve) => setTimeout(resolve, 10));
          return service.getCorrelationId();
        }),
        service.run({ correlationId: 'request-2' }, async () => {
          await new Promise((resolve) => setTimeout(resolve, 5));
          return service.getCorrelationId();
        }),
      ];

      const [id1, id2] = await Promise.all(promises);

      expect(id1).toBe('request-1');
      expect(id2).toBe('request-2');
    });
  });

  describe('User Context', () => {
    it('should store and retrieve user information', async () => {
      const context = {
        correlationId: 'test-id',
        userId: 'user-123',
        userRole: 'ADMIN',
      };

      await service.run(context, async () => {
        expect(service.getUserId()).toBe('user-123');
        expect(service.getUserRole()).toBe('ADMIN');
      });
    });
  });
});

describe('RequestContextMiddleware', () => {
  let middleware: RequestContextMiddleware;
  let contextService: RequestContextService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [RequestContextMiddleware, RequestContextService],
    }).compile();

    middleware = module.get<RequestContextMiddleware>(
      RequestContextMiddleware,
    );
    contextService = module.get<RequestContextService>(RequestContextService);
  });

  it('should generate correlation ID if not present', async () => {
    const req = {
      headers: {},
    };
    const res = {};
    const next = vi.fn();

    await middleware.use(req, res, next);

    expect(req.headers['x-correlation-id']).toBeDefined();
    expect(next).toHaveBeenCalled();
  });

  it('should use existing correlation ID from header', async () => {
    const existingId = 'existing-correlation-id';
    const req = {
      headers: {
        'x-correlation-id': existingId,
      },
    };
    const res = {};
    const next = vi.fn();

    await middleware.use(req, res, next);

    expect(req.headers['x-correlation-id']).toBe(existingId);
  });
});
```

## Coverage Standards

| Metric | Minimum | Tool | Configuration |
|--------|---------|------|---------------|
| **Lines** | 90% | @vitest/coverage-v8 | `coverage.lines: 90` |
| **Functions** | 90% | @vitest/coverage-v8 | `coverage.functions: 90` |
| **Branches** | 80% | @vitest/coverage-v8 | `coverage.branches: 80` |
| **Statements** | 90% | @vitest/coverage-v8 | `coverage.statements: 90` |

### Running Coverage

```bash
# Generate coverage report
npm run test:cov

# View HTML report
open coverage/index.html

# Check coverage thresholds (fails if below minimum)
npm run test:cov -- --coverage.thresholds.lines=90
```

### Coverage Configuration in vitest.config.ts

```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      include: ['src/**/*.ts'],
      exclude: [
        'src/**/*.spec.ts',
        'src/**/*.e2e-spec.ts',
        'src/main.ts',
        'src/**/*.module.ts',
        'src/**/*.dto.ts',
        'src/**/*.entity.ts',
        'src/migrations/**',
      ],
      lines: 90,
      functions: 90,
      branches: 80,
      statements: 90,
    },
  },
});
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run Prisma migrations
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb

      - name: Run unit tests
        run: npm run test

      - name: Run integration tests
        run: npm run test:e2e
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb

      - name: Generate coverage
        run: npm run test:cov

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage/lcov.info
```

### NPM Scripts

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest watch",
    "test:e2e": "vitest run --config vitest.e2e.config.ts",
    "test:e2e:watch": "vitest watch --config vitest.e2e.config.ts",
    "test:cov": "vitest run --coverage",
    "test:debug": "vitest --inspect-brk --inspect --logHeapUsage --threads=false"
  }
}
```

## Testing Checklist

- [ ] All services have unit tests with mocked dependencies
- [ ] All controllers have unit tests with mocked services
- [ ] CRUD operations have integration tests with real database
- [ ] DTOs have validation tests (invalid inputs trigger 400 errors)
- [ ] Error scenarios are tested (404, 409, 500)
- [ ] Circuit breaker patterns are tested (happy path, open, half-open, fallback)
- [ ] Request context propagation is verified
- [ ] External API calls are mocked or use contract tests
- [ ] Database queries are verified against actual PostgreSQL (Testcontainers)
- [ ] Coverage thresholds are met (90% lines, 80% branches)
- [ ] Tests run in CI/CD pipeline
- [ ] Test data factories are used for entity creation
- [ ] Cleanup happens between tests (database reset, mock reset)
- [ ] Async operations use proper async/await patterns
- [ ] No test pollution (tests don't depend on execution order)

## Troubleshooting

| Issue | Symptom | Fix |
|-------|---------|-----|
| **DI Resolution Failed** | `Nest can't resolve dependencies` | Verify all providers in `providers` array; check imports in module; ensure mocked service uses correct token |
| **Fastify Not Ready** | `app.getHttpServer() returns undefined` | Call `await app.init()` and `await app.getHttpAdapter().getInstance().ready()` before tests |
| **Prisma Connection Error** | `Can't reach database server` | Check `DATABASE_URL` is set; verify Testcontainer is started; run migrations before tests |
| **Test Timeout** | `Test timed out after 5000ms` | Increase `testTimeout` in vitest config; ensure async operations complete; check for unresolved promises |
| **Decorator Metadata Missing** | `design:paramtypes is undefined` | Add SWC plugin to vitest config with `decoratorMetadata: true` |
| **Module Not Found** | `Cannot find module '@/...'` | Add path alias to `resolve.alias` in vitest config matching tsconfig paths |
| **Coverage Threshold Failed** | `Coverage for lines (85%) does not meet threshold (90%)` | Write missing tests; exclude irrelevant files in `coverage.exclude` |
| **Database State Pollution** | Tests fail when run together but pass individually | Reset database in `beforeEach`; ensure transactions rollback; use `vi.clearAllMocks()` |
| **Mock Not Called** | `expect(mock).toHaveBeenCalled()` fails | Verify mock is injected correctly; check if actual implementation is called instead; reset mocks in `beforeEach` |
| **Async Assertion Failure** | Test passes but assertion never runs | Always `await` async test functions; use `expect(...).rejects.toThrow()` for error tests |

### Debugging Tests

```bash
# Run tests in debug mode with Chrome DevTools
npm run test:debug

# Run single test file in debug mode
npm run test:debug users.service.spec.ts

# Run tests with increased timeout
vitest run --testTimeout=120000

# Run tests without threads for easier debugging
vitest run --poolOptions.threads.singleThread=true
```

### Common Mock Issues

```typescript
// ❌ WRONG: Mock not properly injected
const mockService = { method: vi.fn() };
// Missing useValue provider registration

// ✅ CORRECT: Properly registered mock
const module = await Test.createTestingModule({
  providers: [
    ServiceUnderTest,
    {
      provide: DependencyService,
      useValue: mockService,
    },
  ],
}).compile();
```

```typescript
// ❌ WRONG: Not resetting mocks between tests
beforeEach(() => {
  // Missing vi.clearAllMocks()
});

// ✅ CORRECT: Reset mocks before each test
beforeEach(() => {
  vi.clearAllMocks();
});
```

```typescript
// ❌ WRONG: Forgetting to await async operations
it('should do something', () => {
  service.asyncMethod(); // Missing await
  expect(result).toBe(expected); // Will fail
});

// ✅ CORRECT: Always await async operations
it('should do something', async () => {
  const result = await service.asyncMethod();
  expect(result).toBe(expected);
});
```

## Performance Testing

### Load Testing with autocannon

```typescript
// test/load/users.load.ts
import autocannon from 'autocannon';
import { Test, TestingModule } from '@nestjs/testing';
import { NestFastifyApplication, FastifyAdapter } from '@nestjs/platform-fastify';
import { AppModule } from '@/app.module';

describe('Load Tests', () => {
  let app: NestFastifyApplication;
  let url: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );

    await app.init();
    await app.getHttpAdapter().getInstance().ready();

    const address = await app.listen(0); // Random port
    url = address;
  });

  afterAll(async () => {
    await app.close();
  });

  it('should handle 1000 requests/second', async () => {
    const result = await autocannon({
      url: `${url}/api/v1/health`,
      connections: 100,
      duration: 10,
    });

    expect(result.requests.average).toBeGreaterThan(1000);
    expect(result.errors).toBe(0);
  });
});
```

## Snapshot Testing

```typescript
describe('API Response Snapshots', () => {
  it('should match user response snapshot', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/users/123')
      .expect(200);

    expect(response.body).toMatchSnapshot({
      id: expect.any(String),
      createdAt: expect.any(String),
      updatedAt: expect.any(String),
    });
  });
});
```

---

**Key Takeaways:**

1. Test circuit breaker states: CLOSED, OPEN, HALF_OPEN with timeout transitions
2. Verify request context propagation with AsyncLocalStorage across async operations
3. Maintain 90% line coverage, 80% branch coverage
4. Use GitHub Actions with PostgreSQL service for CI/CD
5. Always reset database and mocks between tests to prevent pollution
6. Use `vi.clearAllMocks()` in `beforeEach` hooks
7. Increase `testTimeout` for integration tests (60s recommended)
8. Debug with `--inspect-brk` flag and Chrome DevTools
9. Use autocannon for load testing critical endpoints
10. Upload coverage reports to Codecov for tracking over time
