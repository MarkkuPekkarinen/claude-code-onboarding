# NestJS 11.x Unit Testing Guide

Unit testing patterns for NestJS 11.x services, controllers, guards, and interceptors with Vitest, TypeScript 5.x, and Prisma ORM. This guide covers isolated testing with mocked dependencies, test data factories, and mocking strategies.

## Test Categories

| Category | Share | Setup | Use When |
|----------|-------|-------|----------|
| **Unit Tests** | 70-80% | `Test.createTestingModule` with mocked providers | Testing individual services, controllers, guards in isolation |
| **Integration Tests** | 15-25% | Full NestJS app with Testcontainers PostgreSQL | Testing full request/response flow, database interactions, multi-layer integration |
| **Contract Tests** | 5-10% | External API client verification with nock/msw | Verifying external service integrations, API contracts |

## Vitest Configuration for Unit Tests

### vitest.config.ts

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

## Service Unit Test Pattern

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

## Controller Unit Test Pattern

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

## Test Data Factories

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

## Mocking Patterns

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

## Naming Conventions

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
```

## Running Unit Tests

```bash
# Run all unit tests
npm run test

# Run in watch mode
npm run test:watch

# Run specific test file
npm run test users.service.spec.ts

# Run with coverage
npm run test:cov
```

---

**Key Takeaways:**

1. Mock all external dependencies at service boundaries
2. Use `Test.createTestingModule` with `useValue` for mock injection
3. Reset mocks in `beforeEach` to prevent test pollution
4. Test both happy paths and error scenarios
5. Use factories for consistent test data generation
6. Follow Arrange-Act-Assert pattern
7. Maintain 90% line coverage, 80% branch coverage
8. Use descriptive test names that explain the scenario
