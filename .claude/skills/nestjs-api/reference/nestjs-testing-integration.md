# NestJS 11.x Integration Testing Guide

End-to-end integration testing for NestJS 11.x applications using supertest, Fastify adapter, and Testcontainers for real PostgreSQL databases. This guide covers full app bootstrapping, database setup, and multi-layer request/response testing.

## Vitest Configuration for Integration Tests

### vitest.e2e.config.ts

```typescript
import { defineConfig } from 'vitest/config';
import swc from 'unplugin-swc';
import { resolve } from 'path';

export default defineConfig({
  test: {
    globals: true,
    root: './',
    environment: 'node',
    include: ['**/*.e2e-spec.ts'],
    testTimeout: 60000,
    hookTimeout: 60000,
    poolOptions: {
      threads: {
        singleThread: true,
      },
    },
  },
  plugins: [
    swc.vite({
      module: { type: 'es6' },
      jsc: {
        parser: {
          syntax: 'typescript',
          decorators: true,
        },
        transform: {
          decoratorMetadata: true,
        },
        target: 'es2022',
      },
    }),
  ],
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
});
```

## Full App Bootstrap with supertest

```typescript
// test/users.e2e-spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import request from 'supertest';
import { AppModule } from '@/app.module';
import { ValidationPipe } from '@nestjs/common';
import { DatabaseService } from '@/core/database/database.service';
import { GenericContainer, StartedTestContainer } from 'testcontainers';

describe('Users API (e2e)', () => {
  let app: NestFastifyApplication;
  let databaseService: DatabaseService;
  let postgresContainer: StartedTestContainer;

  beforeAll(async () => {
    // Start PostgreSQL container
    postgresContainer = await new GenericContainer('postgres:16-alpine')
      .withEnvironment({
        POSTGRES_USER: 'test',
        POSTGRES_PASSWORD: 'test',
        POSTGRES_DB: 'testdb',
      })
      .withExposedPorts(5432)
      .start();

    const port = postgresContainer.getMappedPort(5432);
    const databaseUrl = `postgresql://test:test@localhost:${port}/testdb`;

    // Set environment variable for Prisma
    process.env.DATABASE_URL = databaseUrl;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );

    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    databaseService = app.get<DatabaseService>(DatabaseService);

    // Run migrations
    const { execSync } = await import('child_process');
    execSync('npx prisma migrate deploy', {
      env: { ...process.env, DATABASE_URL: databaseUrl },
    });

    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await databaseService.$disconnect();
    await app.close();
    await postgresContainer.stop();
  });

  beforeEach(async () => {
    // Clean database before each test
    await databaseService.user.deleteMany();
  });

  describe('/api/v1/users (POST)', () => {
    it('should create a new user', async () => {
      const createUserDto = {
        email: 'test@example.com',
        name: 'Test User',
        role: 'USER',
      };

      const response = await request(app.getHttpServer())
        .post('/api/v1/users')
        .send(createUserDto)
        .expect(201);

      expect(response.body).toMatchObject({
        email: createUserDto.email,
        name: createUserDto.name,
        role: createUserDto.role,
        isActive: true,
      });
      expect(response.body.id).toBeDefined();
      expect(response.body.createdAt).toBeDefined();

      // Verify in database
      const user = await databaseService.user.findUnique({
        where: { id: response.body.id },
      });
      expect(user).not.toBeNull();
      expect(user?.email).toBe(createUserDto.email);
    });

    it('should return 400 for invalid email', async () => {
      const invalidDto = {
        email: 'invalid-email',
        name: 'Test User',
        role: 'USER',
      };

      const response = await request(app.getHttpServer())
        .post('/api/v1/users')
        .send(invalidDto)
        .expect(400);

      expect(response.body.message).toContain('email');
    });

    it('should return 409 for duplicate email', async () => {
      const createUserDto = {
        email: 'duplicate@example.com',
        name: 'Test User',
        role: 'USER',
      };

      // Create first user
      await request(app.getHttpServer())
        .post('/api/v1/users')
        .send(createUserDto)
        .expect(201);

      // Try to create duplicate
      await request(app.getHttpServer())
        .post('/api/v1/users')
        .send(createUserDto)
        .expect(409);
    });
  });

  describe('/api/v1/users (GET)', () => {
    it('should return paginated users', async () => {
      // Create test users
      await databaseService.user.createMany({
        data: [
          { email: 'user1@example.com', name: 'User 1', role: 'USER' },
          { email: 'user2@example.com', name: 'User 2', role: 'ADMIN' },
        ],
      });

      const response = await request(app.getHttpServer())
        .get('/api/v1/users')
        .query({ page: 1, limit: 10 })
        .expect(200);

      expect(response.body.data).toHaveLength(2);
      expect(response.body.meta).toMatchObject({
        total: 2,
        page: 1,
        limit: 10,
        totalPages: 1,
      });
    });
  });

  describe('CRUD Flow', () => {
    it('should complete full CRUD lifecycle', async () => {
      // CREATE
      const createResponse = await request(app.getHttpServer())
        .post('/api/v1/users')
        .send({
          email: 'crud@example.com',
          name: 'CRUD User',
          role: 'USER',
        })
        .expect(201);

      const userId = createResponse.body.id;

      // READ
      const getResponse = await request(app.getHttpServer())
        .get(`/api/v1/users/${userId}`)
        .expect(200);

      expect(getResponse.body.email).toBe('crud@example.com');

      // UPDATE
      const updateResponse = await request(app.getHttpServer())
        .patch(`/api/v1/users/${userId}`)
        .send({ name: 'Updated CRUD User' })
        .expect(200);

      expect(updateResponse.body.name).toBe('Updated CRUD User');

      // Verify update in database
      const updatedUser = await databaseService.user.findUnique({
        where: { id: userId },
      });
      expect(updatedUser?.name).toBe('Updated CRUD User');

      // DELETE
      await request(app.getHttpServer())
        .delete(`/api/v1/users/${userId}`)
        .expect(200);

      // Verify soft delete
      const deletedUser = await databaseService.user.findUnique({
        where: { id: userId },
      });
      expect(deletedUser?.isActive).toBe(false);
    });
  });
});
```

## Testcontainers — Real PostgreSQL

```typescript
// test/helpers/testcontainers.ts
import { GenericContainer, StartedTestContainer } from 'testcontainers';

export class PostgresTestContainer {
  private container: StartedTestContainer | null = null;

  async start(): Promise<string> {
    this.container = await new GenericContainer('postgres:16-alpine')
      .withEnvironment({
        POSTGRES_USER: 'test',
        POSTGRES_PASSWORD: 'test',
        POSTGRES_DB: 'testdb',
      })
      .withExposedPorts(5432)
      .withStartupTimeout(120000)
      .start();

    const host = this.container.getHost();
    const port = this.container.getMappedPort(5432);

    return `postgresql://test:test@${host}:${port}/testdb`;
  }

  async stop(): Promise<void> {
    if (this.container) {
      await this.container.stop();
    }
  }

  async reset(databaseUrl: string): Promise<void> {
    const { PrismaClient } = await import('@prisma/client');
    const prisma = new PrismaClient({
      datasources: {
        db: {
          url: databaseUrl,
        },
      },
    });

    // Get all table names
    const tables = await prisma.$queryRaw<Array<{ tablename: string }>>`
      SELECT tablename FROM pg_tables WHERE schemaname='public'
    `;

    // Truncate all tables
    for (const { tablename } of tables) {
      if (tablename !== '_prisma_migrations') {
        await prisma.$executeRawUnsafe(
          `TRUNCATE TABLE "${tablename}" CASCADE`,
        );
      }
    }

    await prisma.$disconnect();
  }
}

// Usage in test setup
import { PostgresTestContainer } from './helpers/testcontainers';

describe('Integration Tests', () => {
  const postgres = new PostgresTestContainer();
  let databaseUrl: string;

  beforeAll(async () => {
    databaseUrl = await postgres.start();
    process.env.DATABASE_URL = databaseUrl;

    // Run migrations
    const { execSync } = await import('child_process');
    execSync('npx prisma migrate deploy', {
      env: { ...process.env, DATABASE_URL: databaseUrl },
    });
  });

  afterAll(async () => {
    await postgres.stop();
  });

  beforeEach(async () => {
    await postgres.reset(databaseUrl);
  });
});
```

## Integration Test Naming Conventions

```typescript
// File naming
users.e2e-spec.ts            // Integration test for users feature
auth.e2e-spec.ts             // Integration test for auth feature

// Test structure
describe('Feature API (e2e)', () => {
  describe('/api/v1/resource (POST)', () => {
    it('should create resource successfully', async () => {
      const response = await request(app.getHttpServer())
        .post('/api/v1/resource')
        .send(createDto)
        .expect(201);

      expect(response.body).toMatchObject(expectedShape);
    });
  });

  describe('/api/v1/resource/:id (GET)', () => {
    it('should return 404 for non-existent resource', async () => {
      await request(app.getHttpServer())
        .get('/api/v1/resource/invalid-id')
        .expect(404);
    });
  });
});
```

## Testing Validation Pipes

```typescript
describe('Validation', () => {
  it('should reject request with missing required fields', async () => {
    const incompleteDto = {
      name: 'Test User',
      // missing email and role
    };

    const response = await request(app.getHttpServer())
      .post('/api/v1/users')
      .send(incompleteDto)
      .expect(400);

    expect(response.body.message).toContain('email');
    expect(response.body.message).toContain('role');
  });

  it('should reject request with invalid field types', async () => {
    const invalidDto = {
      email: 'test@example.com',
      name: 123, // should be string
      role: 'USER',
    };

    const response = await request(app.getHttpServer())
      .post('/api/v1/users')
      .send(invalidDto)
      .expect(400);

    expect(response.body.message).toContain('name');
  });

  it('should strip non-whitelisted fields', async () => {
    const dtoWithExtra = {
      email: 'test@example.com',
      name: 'Test User',
      role: 'USER',
      maliciousField: 'should be removed',
    };

    const response = await request(app.getHttpServer())
      .post('/api/v1/users')
      .send(dtoWithExtra)
      .expect(201);

    expect(response.body.maliciousField).toBeUndefined();
  });
});
```

## Testing Authentication/Authorization

```typescript
describe('Protected Endpoints', () => {
  let authToken: string;
  let userId: string;

  beforeEach(async () => {
    // Create user and get token
    const signupResponse = await request(app.getHttpServer())
      .post('/api/v1/auth/signup')
      .send({
        email: 'auth@example.com',
        password: 'SecurePassword123!',
        name: 'Auth User',
      })
      .expect(201);

    authToken = signupResponse.body.accessToken;
    userId = signupResponse.body.user.id;
  });

  it('should return 401 for unauthenticated requests', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/users/profile')
      .expect(401);
  });

  it('should allow access with valid token', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/users/profile')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    expect(response.body.id).toBe(userId);
  });

  it('should return 403 for insufficient permissions', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/admin/settings')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ key: 'value' })
      .expect(403);
  });
});
```

## Testing Database Transactions

```typescript
describe('Transactional Operations', () => {
  it('should rollback on error in transaction', async () => {
    // Attempt to create user with duplicate email in transaction
    const dto = {
      email: 'transaction@example.com',
      name: 'Transaction User',
      role: 'USER',
    };

    // Create first user
    await request(app.getHttpServer())
      .post('/api/v1/users')
      .send(dto)
      .expect(201);

    // Attempt to create duplicate - should fail and rollback
    await request(app.getHttpServer())
      .post('/api/v1/users/batch')
      .send({
        users: [
          dto, // duplicate email
          { email: 'another@example.com', name: 'Another User', role: 'USER' },
        ],
      })
      .expect(409);

    // Verify second user was not created
    const users = await databaseService.user.findMany({
      where: { email: 'another@example.com' },
    });

    expect(users).toHaveLength(0);
  });
});
```

## Running Integration Tests

```bash
# Run all integration tests
npm run test:e2e

# Run in watch mode
npm run test:e2e:watch

# Run specific integration test
npm run test:e2e users.e2e-spec.ts

# Run with environment variables
DATABASE_URL=postgresql://test:test@localhost:5432/testdb npm run test:e2e
```

## NPM Scripts

```json
{
  "scripts": {
    "test:e2e": "vitest run --config vitest.e2e.config.ts",
    "test:e2e:watch": "vitest watch --config vitest.e2e.config.ts"
  }
}
```

## Common Integration Test Patterns

### Testing Pagination

```typescript
it('should paginate results correctly', async () => {
  // Create 25 users
  await databaseService.user.createMany({
    data: Array.from({ length: 25 }, (_, i) => ({
      email: `user${i}@example.com`,
      name: `User ${i}`,
      role: 'USER',
    })),
  });

  // Request page 2 with limit 10
  const response = await request(app.getHttpServer())
    .get('/api/v1/users')
    .query({ page: 2, limit: 10 })
    .expect(200);

  expect(response.body.data).toHaveLength(10);
  expect(response.body.meta).toMatchObject({
    total: 25,
    page: 2,
    limit: 10,
    totalPages: 3,
  });
});
```

### Testing Sorting

```typescript
it('should sort users by name ascending', async () => {
  await databaseService.user.createMany({
    data: [
      { email: 'c@example.com', name: 'Charlie', role: 'USER' },
      { email: 'a@example.com', name: 'Alice', role: 'USER' },
      { email: 'b@example.com', name: 'Bob', role: 'USER' },
    ],
  });

  const response = await request(app.getHttpServer())
    .get('/api/v1/users')
    .query({ sortBy: 'name', order: 'asc' })
    .expect(200);

  const names = response.body.data.map((u) => u.name);
  expect(names).toEqual(['Alice', 'Bob', 'Charlie']);
});
```

### Testing Filtering

```typescript
it('should filter users by role', async () => {
  await databaseService.user.createMany({
    data: [
      { email: 'admin1@example.com', name: 'Admin 1', role: 'ADMIN' },
      { email: 'user1@example.com', name: 'User 1', role: 'USER' },
      { email: 'admin2@example.com', name: 'Admin 2', role: 'ADMIN' },
    ],
  });

  const response = await request(app.getHttpServer())
    .get('/api/v1/users')
    .query({ role: 'ADMIN' })
    .expect(200);

  expect(response.body.data).toHaveLength(2);
  expect(response.body.data.every((u) => u.role === 'ADMIN')).toBe(true);
});
```

---

**Key Takeaways:**

1. Use Testcontainers for real PostgreSQL in integration tests
2. Bootstrap full NestJS app with Fastify adapter
3. Run migrations before tests, clean database between tests
4. Use supertest for HTTP request testing
5. Test full CRUD lifecycle and error scenarios
6. Verify database state after operations
7. Test validation, authentication, authorization in integration layer
8. Use realistic timeouts (60s) for container startup
9. Call `await app.init()` and `await app.getHttpAdapter().getInstance().ready()` before tests
10. Always disconnect from database and stop containers in `afterAll`
