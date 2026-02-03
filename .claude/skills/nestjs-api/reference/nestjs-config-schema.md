# NestJS Configuration Schema

Package configuration, TypeScript setup, Prisma schema, and environment templates for NestJS 11.x.

## package.json

NestJS 11 backend service with enterprise-grade dependencies.

```json
{
  "name": "{project_name}",
  "version": "0.1.0",
  "description": "{description}",
  "author": "",
  "private": true,
  "license": "MIT",
  "scripts": {
    "build": "swc src -d dist --strip-leading-paths",
    "start": "node dist/main.js",
    "start:dev": "npm run build && node dist/main.js",
    "start:prod": "NODE_ENV=production node dist/main.js",
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:cov": "vitest run --coverage",
    "test:e2e": "vitest --config vitest.e2e.config.ts",
    "test:ci": "vitest run --coverage --reporter=junit --outputFile=./test-results/junit.xml",
    "lint": "eslint . --ext .ts,.tsx",
    "lint:fix": "eslint . --ext .ts,.tsx --fix",
    "format": "prettier --write \"src/**/*.ts\" \"test/**/*.ts\"",
    "format:check": "prettier --check \"src/**/*.ts\" \"test/**/*.ts\"",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:migrate:deploy": "prisma migrate deploy",
    "prisma:seed": "tsx prisma/seeds/seed.ts",
    "prisma:studio": "prisma studio",
    "prisma:reset": "prisma migrate reset --force",
    "docker:dev": "docker-compose -f docker/docker-compose.dev.yml up -d",
    "docker:down": "docker-compose -f docker/docker-compose.dev.yml down",
    "docker:test": "docker-compose -f docker/docker-compose.test.yml up -d",
    "docker:build": "docker build -t {project_name}:latest .",
    "typecheck": "tsc --noEmit",
    "validate": "npm run typecheck && npm run lint && npm run test:ci",
    "prepare": "prisma generate"
  },
  "dependencies": {
    "@nestjs/common": "~11.0.0",
    "@nestjs/config": "~3.3.0",
    "@nestjs/core": "~11.0.0",
    "@nestjs/event-emitter": "~2.1.0",
    "@nestjs/platform-fastify": "~11.0.0",
    "@nestjs/schedule": "~4.1.0",
    "@nestjs/swagger": "~8.0.0",
    "@nestjs/terminus": "~11.0.0",
    "@nestjs/throttler": "~6.3.0",
    "@nestjs/bullmq": "~10.2.0",
    "@bull-board/api": "~5.21.0",
    "@bull-board/nestjs": "~5.21.0",
    "@bull-board/express": "~5.21.0",
    "bullmq": "~5.13.0",
    "@golevelup/nestjs-rabbitmq": "~5.5.0",
    "amqplib": "~0.10.4",
    "kafkajs": "~2.2.4",
    "@opentelemetry/api": "~1.9.0",
    "@opentelemetry/auto-instrumentations-node": "~0.50.0",
    "@opentelemetry/exporter-metrics-otlp-http": "~0.53.0",
    "@opentelemetry/exporter-trace-otlp-http": "~0.53.0",
    "@opentelemetry/resources": "~1.26.0",
    "@opentelemetry/sdk-metrics": "~1.26.0",
    "@opentelemetry/sdk-node": "~0.53.0",
    "@opentelemetry/sdk-trace-node": "~1.26.0",
    "@opentelemetry/semantic-conventions": "~1.26.0",
    "@prisma/adapter-pg": "~7.3.0",
    "@prisma/client": "~7.3.0",
    "pg": "~8.13.0",
    "axios": "~1.7.0",
    "class-transformer": "~0.5.1",
    "class-validator": "~0.14.1",
    "compression": "~1.7.4",
    "decimal.js": "~10.4.3",
    "dotenv": "~16.4.5",
    "@fastify/compress": "~8.0.0",
    "@fastify/helmet": "~12.0.0",
    "@fastify/static": "~8.0.0",
    "lru-cache": "~11.0.0",
    "redis": "~4.7.0",
    "reflect-metadata": "~0.2.2",
    "rxjs": "~7.8.1",
    "uuid": "~10.0.0",
    "zod": "~3.23.0"
  },
  "devDependencies": {
    "@eslint/js": "~9.15.0",
    "@nestjs/testing": "~11.0.0",
    "@swc/cli": "~0.4.0",
    "@swc/core": "~1.7.0",
    "@types/compression": "~1.7.5",
    "@types/node": "~22.9.0",
    "@types/uuid": "~10.0.0",
    "@typescript-eslint/eslint-plugin": "~8.15.0",
    "@typescript-eslint/parser": "~8.15.0",
    "@vitest/coverage-v8": "~2.1.0",
    "eslint": "~9.15.0",
    "eslint-config-prettier": "~9.1.0",
    "eslint-plugin-import": "~2.31.0",
    "eslint-plugin-promise": "~7.1.0",
    "eslint-plugin-security": "~3.0.0",
    "eslint-plugin-sonarjs": "~2.0.0",
    "prettier": "~3.4.0",
    "@types/pg": "~8.11.0",
    "prisma": "~7.3.0",
    "tsx": "~4.19.0",
    "typescript": "~5.7.0",
    "vitest": "~2.1.0"
  },
  "engines": {
    "node": ">=22.15.0",
    "pnpm": ">=9.0.0"
  },
  "packageManager": "pnpm@9.14.2"
}
```

## tsconfig.json

NestJS uses CommonJS module system with decorators and metadata reflection.

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "allowJs": false,
    "checkJs": false,
    "outDir": "./dist",
    "rootDir": "./src",
    "removeComments": true,
    "noEmit": false,
    "importHelpers": false,
    "downlevelIteration": true,
    "isolatedModules": true,

    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": false,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,

    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,

    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,

    "sourceMap": true,
    "declaration": false,
    "declarationMap": false,
    "incremental": true,
    "tsBuildInfoFile": ".tsbuildinfo",

    "baseUrl": "./",
    "paths": {
      "@app/*": ["src/*"],
      "@config/*": ["src/config/*"],
      "@common/*": ["src/common/*"],
      "@core/*": ["src/core/*"],
      "@features/*": ["src/features/*"],
      "@shared/*": ["src/shared/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": [
    "node_modules",
    "dist",
    "test",
    "**/*.spec.ts",
    "**/*.test.ts",
    "**/*.e2e-spec.ts"
  ]
}
```

## Prisma 7.x Schema

Enterprise-grade Prisma 7.x schema with audit trails, feature flags, and transactional outbox pattern.

**IMPORTANT — Prisma 7.x breaking changes:**
- Generator: `provider = "prisma-client"` (not `prisma-client-js`), explicit `output` path required
- Datasource: **no `url` property** — connection URL goes in `prisma.config.ts` at project root
- PrismaService: use **composition** with `@prisma/adapter-pg` (do NOT extend PrismaClient)
- Generated client output (e.g., `src/generated/`) must be in `.gitignore`

**File:** `prisma/schema.prisma`

```prisma
// {project_name} Database Schema
// Enterprise-grade schema with audit trails, optimistic locking, and financial precision

generator client {
  provider = "prisma-client"
  output   = "../src/generated/prisma"
}

datasource db {
  provider = "postgresql"
}

// ================================
// SYSTEM CONFIGURATION (Required)
// ================================

model SystemConfig {
  id          String   @id @default(cuid())

  key         String   @unique @db.VarChar(100)
  value       Json
  dataType    String   @map("data_type") @db.VarChar(20)

  description String?  @db.Text
  category    String?  @db.VarChar(50)
  isSecret    Boolean  @default(false) @map("is_secret")

  validation  Json?

  // Optimistic locking for concurrent updates
  version     Int      @default(1)

  // TTL support for temporary configurations
  expiresAt   DateTime? @map("expires_at")

  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @updatedAt @map("updated_at")

  // Composite index for efficient lookups
  @@index([key, category])
  @@index([category])
  @@index([expiresAt])
  @@map("system_configs")
}

// ================================
// FEATURE FLAGS (Required for safe rollouts)
// ================================

model FeatureFlag {
  id          String   @id @default(cuid())

  key         String   @unique @db.VarChar(100)
  name        String   @db.VarChar(200)
  description String?  @db.Text

  enabled     Boolean  @default(false)

  // Percentage-based rollout (0-100)
  percentage  Int      @default(0)

  // Target specific user/tenant segments
  targetRules Json?    @map("target_rules")

  // Optimistic locking
  version     Int      @default(1)

  // Scheduling
  enabledAt   DateTime? @map("enabled_at")
  disabledAt  DateTime? @map("disabled_at")

  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @updatedAt @map("updated_at")

  @@index([key])
  @@index([enabled])
  @@map("feature_flags")
}

// ================================
// AUDIT LOG (Required for enterprise)
// ================================

model AuditLog {
  id            String   @id @default(cuid())
  correlationId String   @map("correlation_id")

  eventType     String   @map("event_type") @db.VarChar(50)
  entityType    String   @map("entity_type") @db.VarChar(50)
  entityId      String?  @map("entity_id")

  action        String   @db.VarChar(50)
  userId        String?  @map("user_id") @db.VarChar(100)
  sessionId     String?  @map("session_id") @db.VarChar(100)
  tenantId      String?  @map("tenant_id") @db.VarChar(100)

  oldValues     Json?    @map("old_values")
  newValues     Json?    @map("new_values")
  metadata      Json?

  ipAddress     String?  @map("ip_address") @db.VarChar(45)
  userAgent     String?  @map("user_agent") @db.Text

  // Performance: duration in milliseconds
  durationMs    Int?     @map("duration_ms")

  timestamp     DateTime @default(now())
  createdAt     DateTime @default(now()) @map("created_at")

  @@index([correlationId])
  @@index([eventType, timestamp])
  @@index([entityType, entityId, timestamp])
  @@index([userId, timestamp])
  @@index([tenantId, timestamp])
  @@map("audit_logs")
}

// ================================
// OUTBOX (For reliable event publishing)
// ================================

model Outbox {
  id            String   @id @default(cuid())

  aggregateType String   @map("aggregate_type") @db.VarChar(100)
  aggregateId   String   @map("aggregate_id") @db.VarChar(100)
  eventType     String   @map("event_type") @db.VarChar(100)

  payload       Json

  // Processing status
  status        OutboxStatus @default(PENDING)
  processedAt   DateTime?    @map("processed_at")
  retryCount    Int          @default(0) @map("retry_count")
  lastError     String?      @map("last_error") @db.Text

  createdAt     DateTime @default(now()) @map("created_at")

  @@index([status, createdAt])
  @@index([aggregateType, aggregateId])
  @@map("outbox")
}

enum OutboxStatus {
  PENDING
  PROCESSING
  COMPLETED
  FAILED
}

// ================================
// USER (if authentication is selected)
// ================================

model User {
  id            String    @id @default(cuid())

  email         String    @unique @db.VarChar(255)
  passwordHash  String    @map("password_hash") @db.VarChar(255)

  firstName     String?   @map("first_name") @db.VarChar(100)
  lastName      String?   @map("last_name") @db.VarChar(100)

  role          UserRole  @default(USER)
  status        UserStatus @default(ACTIVE)

  // Optimistic locking
  version       Int       @default(1)

  // Multi-tenancy support (if enabled)
  tenantId      String?   @map("tenant_id") @db.VarChar(100)

  lastLoginAt   DateTime? @map("last_login_at")
  emailVerifiedAt DateTime? @map("email_verified_at")
  passwordChangedAt DateTime? @map("password_changed_at")

  // Security: failed login tracking
  failedLoginAttempts Int @default(0) @map("failed_login_attempts")
  lockedUntil   DateTime? @map("locked_until")

  createdAt     DateTime  @default(now()) @map("created_at")
  updatedAt     DateTime  @updatedAt @map("updated_at")
  deletedAt     DateTime? @map("deleted_at")

  @@index([email])
  @@index([status])
  @@index([tenantId])
  @@index([deletedAt])
  @@map("users")
}

enum UserRole {
  SUPER_ADMIN
  ADMIN
  USER
  VIEWER
}

enum UserStatus {
  ACTIVE
  INACTIVE
  SUSPENDED
  PENDING_VERIFICATION
}

// ================================
// {ENTITY} MODELS (Generated per entity)
// ================================

// Example: Replace with actual entities from user requirements
// model {Entity} {
//   id          String   @id @default(cuid())
//
//   // Entity-specific fields here
//
//   // Optimistic locking
//   version     Int      @default(1)
//
//   // Multi-tenancy (if enabled)
//   tenantId    String?  @map("tenant_id") @db.VarChar(100)
//
//   // Audit fields
//   createdBy   String?  @map("created_by") @db.VarChar(100)
//   updatedBy   String?  @map("updated_by") @db.VarChar(100)
//
//   createdAt   DateTime @default(now()) @map("created_at")
//   updatedAt   DateTime @updatedAt @map("updated_at")
//   deletedAt   DateTime? @map("deleted_at")
//
//   @@index([tenantId])
//   @@index([deletedAt])
//   @@map("{entity_table_name}")
// }
```

## prisma.config.ts (Prisma 7.x — required)

Prisma 7.x moved the datasource URL from `schema.prisma` to `prisma.config.ts`. This file is auto-created by `npx prisma init` — keep it.

**File:** `prisma.config.ts` (project root)

```typescript
import 'dotenv/config';
import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    url: process.env['DATABASE_URL'],
  },
});
```

## PrismaService (Prisma 7.x — composition pattern)

Prisma 7.x `PrismaClient` requires a driver adapter. Use composition, NOT inheritance.

**File:** `src/core/database/prisma.service.ts`

```typescript
import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '../../generated/prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';

@Injectable()
export class PrismaService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);
  private readonly _client: PrismaClient;

  constructor(private readonly configService: ConfigService) {
    const databaseUrl =
      this.configService.get<string>('database.url') ??
      process.env['DATABASE_URL'];

    if (!databaseUrl) {
      throw new Error('DATABASE_URL is not configured');
    }

    const adapter = new PrismaPg({ connectionString: databaseUrl });
    this._client = new PrismaClient({ adapter });
  }

  get client(): PrismaClient {
    return this._client;
  }

  async onModuleInit(): Promise<void> {
    this.logger.log('Connecting to database...');
    await this._client.$connect();
    this.logger.log('Database connection established');
  }

  async onModuleDestroy(): Promise<void> {
    this.logger.log('Disconnecting from database...');
    await this._client.$disconnect();
  }
}
```

## Environment File (.env)

**IMPORTANT:** The `.env` file must be populated with working defaults at scaffold time. The app must boot with zero manual configuration after scaffolding.

**Write `.env` via Bash** (not Write/Edit tools — hooks block `.env` modifications):
```bash
cat > .env << 'EOF'
# {project_name} - Local Development Defaults
# All values match docker-compose.dev.yml — app boots immediately

# Database (matches docker-compose.dev.yml credentials)
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/{project_name}?schema=public"

# Application
APP_NAME={project_name}
NODE_ENV=development
PORT=3000
ENABLE_SWAGGER=true

# Security
SECURITY_CORS_ORIGINS=http://localhost:4200
EOF
```

Every `getRequired*()` call in config files **must** have a matching entry in `.env`. If a config uses `getOptionalString('FOO') ?? 'default'`, it does NOT need a `.env` entry. If it uses `getRequiredString('FOO')`, it MUST have `FOO=value` in `.env`.

### Extended `.env` (when features are added)

Add these as needed — only when the corresponding config code requires them:

```bash
# Logging (optional — configs have defaults)
LOG_LEVEL=debug
LOG_FORMAT=json

# Redis (when cache/queues are added)
REDIS_URL="redis://localhost:6379"

# JWT (when auth module is added)
SECURITY_JWT_SECRET=your-super-secret-jwt-key-minimum-32-characters
SECURITY_JWT_EXPIRES_IN=1h

# Rate limiting (optional — throttler.config.ts has hardcoded defaults)
THROTTLER_SHORT_TTL=1000
THROTTLER_SHORT_LIMIT=3
```

## Key Patterns

| Pattern | Description |
|---------|-------------|
| Optimistic locking | `version` field on models prevents race conditions |
| Soft delete | `deletedAt` field for recoverable deletions |
| Audit trail | AuditLog model captures all state changes |
| Feature flags | FeatureFlag model for percentage-based rollouts |
| Outbox pattern | Reliable event publishing with transactional guarantees |
