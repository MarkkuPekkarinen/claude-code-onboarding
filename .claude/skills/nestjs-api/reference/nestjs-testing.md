# NestJS 11.x Testing Guide

Comprehensive testing patterns for NestJS 11.x with Fastify, Prisma ORM, TypeScript 5.x, and Vitest.

## 1. Test Categories

| Category | Share | Setup | Use When |
|----------|-------|-------|----------|
| **Unit Tests** | 70-80% | `Test.createTestingModule` with mocked providers | Testing individual services, controllers, guards in isolation |
| **Integration Tests** | 15-25% | Full NestJS app with Testcontainers PostgreSQL | Testing full request/response flow, database interactions, multi-layer integration |
| **Contract Tests** | 5-10% | External API client verification with nock/msw | Verifying external service integrations, API contracts |

## 2. Vitest Configuration

### vitest.config.ts (Unit Tests)

```typescript
import { defineConfig } from 'vitest/config';
import swc from 'unplugin-swc';
import { resolve } from 'path';

export default defineConfig({
  test: {
    globals: true,
    root: './',
    environment: 'node',
    include: ['**/*.spec.ts'],
    exclude: ['**/*.e2e-spec.ts', 'node_modules', 'dist'],
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

### vitest.e2e.config.ts (Integration Tests)

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

## 3. Unit Testing Patterns

### Service Unit Test

```typescript
// src/features/users/users.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { UsersService } from './users.service';
import { DatabaseService } from '@/core/database/database.service';
import { CacheService } from '@/core/cache/cache.service';
import { CreateUserDto, UpdateUserDto } from './dto';
import { User } from '@prisma/client';
import { NotFoundException, ConflictException } from '@nestjs/common';

describe('UsersService', () => {
  let service: UsersService;
  let databaseService: DatabaseService;
  let cacheService: CacheService;

  const mockUser: User = {
    id: '123e4567-e89b-12d3-a456-426614174000',
    email: 'test@example.com',
    name: 'Test User',
    role: 'USER',
    isActive: true,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  };

  const mockDatabaseService = {
    user: {
      create: vi.fn(),
      findUnique: vi.fn(),
      findMany: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
      count: vi.fn(),
    },
    $transaction: vi.fn((callback) => callback(mockDatabaseService)),
  };

  const mockCacheService = {
    get: vi.fn(),
    set: vi.fn(),
    del: vi.fn(),
    delPattern: vi.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: DatabaseService,
          useValue: mockDatabaseService,
        },
        {
          provide: CacheService,
          useValue: mockCacheService,
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    databaseService = module.get<DatabaseService>(DatabaseService);
    cacheService = module.get<CacheService>(CacheService);

    // Reset mocks between tests
    vi.clearAllMocks();
  });

  describe('create', () => {
    it('should create a new user successfully', async () => {
      const createUserDto: CreateUserDto = {
        email: 'test@example.com',
        name: 'Test User',
        role: 'USER',
      };

      mockDatabaseService.user.findUnique.mockResolvedValue(null);
      mockDatabaseService.user.create.mockResolvedValue(mockUser);

      const result = await service.create(createUserDto);

      expect(result).toEqual(mockUser);
      expect(mockDatabaseService.user.findUnique).toHaveBeenCalledWith({
        where: { email: createUserDto.email },
      });
      expect(mockDatabaseService.user.create).toHaveBeenCalledWith({
        data: createUserDto,
      });
      expect(mockCacheService.delPattern).toHaveBeenCalledWith('users:*');
    });

    it('should throw ConflictException when email already exists', async () => {
      const createUserDto: CreateUserDto = {
        email: 'test@example.com',
        name: 'Test User',
        role: 'USER',
      };

      mockDatabaseService.user.findUnique.mockResolvedValue(mockUser);

      await expect(service.create(createUserDto)).rejects.toThrow(
        ConflictException,
      );
      expect(mockDatabaseService.user.create).not.toHaveBeenCalled();
    });
  });

  describe('findOne', () => {
    it('should return a user when found in cache', async () => {
      const userId = mockUser.id;
      mockCacheService.get.mockResolvedValue(mockUser);

      const result = await service.findOne(userId);

      expect(result).toEqual(mockUser);
      expect(mockCacheService.get).toHaveBeenCalledWith(`user:${userId}`);
      expect(mockDatabaseService.user.findUnique).not.toHaveBeenCalled();
    });

    it('should return a user from database when not in cache', async () => {
      const userId = mockUser.id;
      mockCacheService.get.mockResolvedValue(null);
      mockDatabaseService.user.findUnique.mockResolvedValue(mockUser);

      const result = await service.findOne(userId);

      expect(result).toEqual(mockUser);
      expect(mockCacheService.get).toHaveBeenCalledWith(`user:${userId}`);
      expect(mockDatabaseService.user.findUnique).toHaveBeenCalledWith({
        where: { id: userId },
      });
      expect(mockCacheService.set).toHaveBeenCalledWith(
        `user:${userId}`,
        mockUser,
        3600,
      );
    });

    it('should throw NotFoundException when user does not exist', async () => {
      const userId = 'non-existent-id';
      mockCacheService.get.mockResolvedValue(null);
      mockDatabaseService.user.findUnique.mockResolvedValue(null);

      await expect(service.findOne(userId)).rejects.toThrow(NotFoundException);
    });
  });

  describe('update', () => {
    it('should update user successfully', async () => {
      const userId = mockUser.id;
      const updateUserDto: UpdateUserDto = {
        name: 'Updated Name',
      };
      const updatedUser = { ...mockUser, name: 'Updated Name' };

      mockDatabaseService.user.findUnique.mockResolvedValue(mockUser);
      mockDatabaseService.user.update.mockResolvedValue(updatedUser);

      const result = await service.update(userId, updateUserDto);

      expect(result).toEqual(updatedUser);
      expect(mockDatabaseService.user.update).toHaveBeenCalledWith({
        where: { id: userId },
        data: updateUserDto,
      });
      expect(mockCacheService.del).toHaveBeenCalledWith(`user:${userId}`);
      expect(mockCacheService.delPattern).toHaveBeenCalledWith('users:*');
    });

    it('should throw NotFoundException when updating non-existent user', async () => {
      const userId = 'non-existent-id';
      const updateUserDto: UpdateUserDto = { name: 'Updated Name' };

      mockDatabaseService.user.findUnique.mockResolvedValue(null);

      await expect(service.update(userId, updateUserDto)).rejects.toThrow(
        NotFoundException,
      );
      expect(mockDatabaseService.user.update).not.toHaveBeenCalled();
    });
  });

  describe('remove', () => {
    it('should soft delete user successfully', async () => {
      const userId = mockUser.id;
      const deactivatedUser = { ...mockUser, isActive: false };

      mockDatabaseService.user.findUnique.mockResolvedValue(mockUser);
      mockDatabaseService.user.update.mockResolvedValue(deactivatedUser);

      await service.remove(userId);

      expect(mockDatabaseService.user.update).toHaveBeenCalledWith({
        where: { id: userId },
        data: { isActive: false },
      });
      expect(mockCacheService.del).toHaveBeenCalledWith(`user:${userId}`);
      expect(mockCacheService.delPattern).toHaveBeenCalledWith('users:*');
    });

    it('should throw NotFoundException when deleting non-existent user', async () => {
      const userId = 'non-existent-id';
      mockDatabaseService.user.findUnique.mockResolvedValue(null);

      await expect(service.remove(userId)).rejects.toThrow(NotFoundException);
      expect(mockDatabaseService.user.update).not.toHaveBeenCalled();
    });
  });

  describe('findAll', () => {
    it('should return paginated users', async () => {
      const users = [mockUser];
      const total = 1;

      mockDatabaseService.user.findMany.mockResolvedValue(users);
      mockDatabaseService.user.count.mockResolvedValue(total);

      const result = await service.findAll({ page: 1, limit: 10 });

      expect(result).toEqual({
        data: users,
        meta: {
          total,
          page: 1,
          limit: 10,
          totalPages: 1,
        },
      });
    });
  });
});
```

### Controller Unit Test

```typescript
// src/features/users/users.controller.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { CreateUserDto, UpdateUserDto } from './dto';
import { User } from '@prisma/client';
import { NotFoundException } from '@nestjs/common';

describe('UsersController', () => {
  let controller: UsersController;
  let service: UsersService;

  const mockUser: User = {
    id: '123e4567-e89b-12d3-a456-426614174000',
    email: 'test@example.com',
    name: 'Test User',
    role: 'USER',
    isActive: true,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  };

  const mockUsersService = {
    create: vi.fn(),
    findAll: vi.fn(),
    findOne: vi.fn(),
    update: vi.fn(),
    remove: vi.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: mockUsersService,
        },
      ],
    }).compile();

    controller = module.get<UsersController>(UsersController);
    service = module.get<UsersService>(UsersService);

    vi.clearAllMocks();
  });

  describe('create', () => {
    it('should create a user and return 201', async () => {
      const createUserDto: CreateUserDto = {
        email: 'test@example.com',
        name: 'Test User',
        role: 'USER',
      };

      mockUsersService.create.mockResolvedValue(mockUser);

      const result = await controller.create(createUserDto);

      expect(result).toEqual(mockUser);
      expect(service.create).toHaveBeenCalledWith(createUserDto);
    });
  });

  describe('findAll', () => {
    it('should return paginated users', async () => {
      const paginatedResult = {
        data: [mockUser],
        meta: {
          total: 1,
          page: 1,
          limit: 10,
          totalPages: 1,
        },
      };

      mockUsersService.findAll.mockResolvedValue(paginatedResult);

      const result = await controller.findAll({ page: 1, limit: 10 });

      expect(result).toEqual(paginatedResult);
      expect(service.findAll).toHaveBeenCalledWith({ page: 1, limit: 10 });
    });
  });

  describe('findOne', () => {
    it('should return a single user', async () => {
      mockUsersService.findOne.mockResolvedValue(mockUser);

      const result = await controller.findOne(mockUser.id);

      expect(result).toEqual(mockUser);
      expect(service.findOne).toHaveBeenCalledWith(mockUser.id);
    });

    it('should throw NotFoundException for invalid ID', async () => {
      const invalidId = 'invalid-id';
      mockUsersService.findOne.mockRejectedValue(new NotFoundException());

      await expect(controller.findOne(invalidId)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('update', () => {
    it('should update a user', async () => {
      const updateUserDto: UpdateUserDto = { name: 'Updated Name' };
      const updatedUser = { ...mockUser, name: 'Updated Name' };

      mockUsersService.update.mockResolvedValue(updatedUser);

      const result = await controller.update(mockUser.id, updateUserDto);

      expect(result).toEqual(updatedUser);
      expect(service.update).toHaveBeenCalledWith(mockUser.id, updateUserDto);
    });
  });

  describe('remove', () => {
    it('should delete a user', async () => {
      mockUsersService.remove.mockResolvedValue(undefined);

      await controller.remove(mockUser.id);

      expect(service.remove).toHaveBeenCalledWith(mockUser.id);
    });
  });
});
```

## 4. Integration Testing with supertest

### Full App Bootstrap

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

## 5. Testcontainers — Real PostgreSQL

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

## 6. Circuit Breaker Testing

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

## 7. Testing Request Context (AsyncLocalStorage)

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

## 8. Test Data Factories

```typescript
// test/factories/user.factory.ts
import { User, Role } from '@prisma/client';
import { faker } from '@faker-js/faker';

export class UserFactory {
  private data: Partial<User> = {
    email: faker.internet.email(),
    name: faker.person.fullName(),
    role: 'USER' as Role,
    isActive: true,
  };

  with(overrides: Partial<User>): this {
    this.data = { ...this.data, ...overrides };
    return this;
  }

  build(): Omit<User, 'id' | 'createdAt' | 'updatedAt'> {
    return this.data as Omit<User, 'id' | 'createdAt' | 'updatedAt'>;
  }

  async create(prisma: any): Promise<User> {
    return prisma.user.create({
      data: this.build(),
    });
  }

  static make(overrides?: Partial<User>): UserFactory {
    const factory = new UserFactory();
    if (overrides) {
      factory.with(overrides);
    }
    return factory;
  }
}

// Usage in tests
import { UserFactory } from './factories/user.factory';

describe('User Tests', () => {
  it('should create test user with factory', async () => {
    const user = await UserFactory.make()
      .with({ email: 'specific@example.com', role: 'ADMIN' })
      .create(databaseService);

    expect(user.email).toBe('specific@example.com');
    expect(user.role).toBe('ADMIN');
  });

  it('should create multiple users', async () => {
    const users = await Promise.all([
      UserFactory.make().create(databaseService),
      UserFactory.make().create(databaseService),
      UserFactory.make().create(databaseService),
    ]);

    expect(users).toHaveLength(3);
  });
});
```

### Prisma Seed Helpers

```typescript
// test/helpers/seed.ts
import { PrismaClient } from '@prisma/client';
import { UserFactory } from '../factories/user.factory';

export class TestSeeder {
  constructor(private readonly prisma: PrismaClient) {}

  async seedUsers(count: number = 10) {
    const users = [];
    for (let i = 0; i < count; i++) {
      users.push(await UserFactory.make().create(this.prisma));
    }
    return users;
  }

  async seedAdminUser() {
    return UserFactory.make()
      .with({
        email: 'admin@example.com',
        role: 'ADMIN',
      })
      .create(this.prisma);
  }

  async clean() {
    await this.prisma.user.deleteMany();
  }
}

// Usage
beforeEach(async () => {
  const seeder = new TestSeeder(databaseService);
  await seeder.clean();
  await seeder.seedUsers(5);
});
```

## 9. Mocking Patterns

### Prisma Client Mocking

```typescript
// test/mocks/prisma.mock.ts
import { vi } from 'vitest';
import { PrismaClient } from '@prisma/client';
import { mockDeep, mockReset, DeepMockProxy } from 'vitest-mock-extended';

export type MockPrismaClient = DeepMockProxy<PrismaClient>;

export const createMockPrismaClient = (): MockPrismaClient => {
  return mockDeep<PrismaClient>();
};

// Usage
import { createMockPrismaClient } from './mocks/prisma.mock';

describe('Service with Prisma', () => {
  let mockPrisma: MockPrismaClient;

  beforeEach(() => {
    mockPrisma = createMockPrismaClient();
  });

  it('should query users', async () => {
    mockPrisma.user.findMany.mockResolvedValue([
      { id: '1', email: 'test@example.com' } as any,
    ]);

    const result = await mockPrisma.user.findMany();
    expect(result).toHaveLength(1);
  });
});
```

### Redis/Cache Mocking

```typescript
// test/mocks/cache.mock.ts
import { vi } from 'vitest';

export const createMockCacheService = () => ({
  get: vi.fn(),
  set: vi.fn(),
  del: vi.fn(),
  delPattern: vi.fn(),
  exists: vi.fn(),
  ttl: vi.fn(),
  keys: vi.fn(),
  flushAll: vi.fn(),
});

// Usage
const mockCache = createMockCacheService();
mockCache.get.mockResolvedValue({ id: '1', name: 'Cached User' });
```

### External HTTP Service Mocking with nock

```typescript
// test/external-api.spec.ts
import nock from 'nock';
import { describe, it, expect, afterEach } from 'vitest';
import { ExternalApiService } from '@/services/external-api.service';

describe('ExternalApiService', () => {
  afterEach(() => {
    nock.cleanAll();
  });

  it('should fetch data from external API', async () => {
    const mockResponse = { id: 1, data: 'test' };

    nock('https://api.example.com')
      .get('/endpoint')
      .reply(200, mockResponse);

    const service = new ExternalApiService();
    const result = await service.fetchData();

    expect(result).toEqual(mockResponse);
  });

  it('should handle API errors', async () => {
    nock('https://api.example.com').get('/endpoint').reply(500, {
      error: 'Internal Server Error',
    });

    const service = new ExternalApiService();

    await expect(service.fetchData()).rejects.toThrow();
  });

  it('should verify request headers', async () => {
    nock('https://api.example.com', {
      reqheaders: {
        authorization: 'Bearer test-token',
        'content-type': 'application/json',
      },
    })
      .post('/endpoint', { name: 'test' })
      .reply(201, { success: true });

    const service = new ExternalApiService();
    const result = await service.createResource({ name: 'test' });

    expect(result).toEqual({ success: true });
  });
});
```

### ConfigService Mocking

```typescript
// test/mocks/config.mock.ts
import { vi } from 'vitest';

export const createMockConfigService = (values: Record<string, any> = {}) => ({
  get: vi.fn((key: string) => values[key]),
  getOrThrow: vi.fn((key: string) => {
    if (!(key in values)) {
      throw new Error(`Configuration key ${key} not found`);
    }
    return values[key];
  }),
});

// Usage
const mockConfig = createMockConfigService({
  DATABASE_URL: 'postgresql://test',
  JWT_SECRET: 'test-secret',
  PORT: 3000,
});
```

## 10. Coverage Standards

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

## 11. CI/CD Integration

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

## 12. Testing Checklist

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

## 13. Naming Conventions

```typescript
// File naming
users.service.spec.ts        // Unit test
users.e2e-spec.ts            // Integration test
circuit-breaker.spec.ts      // Component test

// Test structure
describe('ServiceName', () => {
  describe('methodName', () => {
    it('should return X when Y', async () => {
      // Arrange
      const input = { ... };
      mockService.method.mockResolvedValue(expectedOutput);

      // Act
      const result = await service.methodName(input);

      // Assert
      expect(result).toEqual(expectedOutput);
      expect(mockService.method).toHaveBeenCalledWith(input);
    });

    it('should throw NotFoundException when entity does not exist', async () => {
      mockRepository.findUnique.mockResolvedValue(null);

      await expect(service.methodName('invalid-id')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});

// Integration test structure
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
});
```

## 14. Troubleshooting

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

---

**Key Takeaways:**

1. Use Vitest with SWC for fast decorator support
2. Testcontainers for real PostgreSQL in integration tests
3. Mock at service boundaries, test business logic in isolation
4. Maintain 90% line coverage, 80% branch coverage
5. Reset state between tests (database, mocks, cache)
6. Test circuit breaker states and fallback paths
7. Verify request context propagation with AsyncLocalStorage
8. Use factories for test data consistency
9. Run tests in CI with coverage reporting
10. Follow naming conventions: `*.spec.ts` for unit, `*.e2e-spec.ts` for integration
