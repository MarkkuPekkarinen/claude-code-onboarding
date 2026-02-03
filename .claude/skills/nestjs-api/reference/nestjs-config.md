# NestJS Configuration & Schema

Configuration patterns for NestJS 11.x with Fastify, Prisma, and fail-fast environment validation.

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
    "@prisma/client": "6.1.0",
    "axios": "~1.7.0",
    "class-transformer": "~0.5.1",
    "class-validator": "~0.14.1",
    "compression": "~1.7.4",
    "decimal.js": "~10.4.3",
    "dotenv": "~16.4.5",
    "helmet": "~8.0.0",
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
    "prisma": "6.1.0",
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

## Static Configuration Reader

All environment variable validation happens in a centralized reader with fail-fast behavior.

**File:** `src/config/static-config-reader.ts`

```typescript
/**
 * Static Configuration Reader
 *
 * PRINCIPLES:
 * - NO hardcoded defaults
 * - NO fallback values
 * - ALL validation happens here
 * - Application FAILS FAST if configs are missing
 */

import { StaticConfigurationException } from '../common/exceptions/static-configuration.exception';

const NON_EMPTY_STRING_MSG = 'non-empty string';

/**
 * Get required string environment variable
 * @throws {StaticConfigurationException} if variable is missing or empty
 */
export const getRequiredString = (key: string): string => {
  if (!key) {
    throw StaticConfigurationException.invalidEnvVar('key', key, NON_EMPTY_STRING_MSG);
  }

  const value = process.env[key];
  if (value === undefined || value.trim() === '') {
    throw StaticConfigurationException.missingEnvVar(key);
  }

  return value.trim();
};

/**
 * Get required numeric environment variable
 * @throws {StaticConfigurationException} if variable is missing or not a valid number
 */
export const getRequiredNumber = (key: string): number => {
  if (!key) {
    throw StaticConfigurationException.invalidEnvVar('key', key, NON_EMPTY_STRING_MSG);
  }

  const value = process.env[key];
  if (value === undefined || value.trim() === '') {
    throw StaticConfigurationException.missingEnvVar(key);
  }

  const parsed = parseFloat(value);
  if (isNaN(parsed)) {
    throw StaticConfigurationException.invalidEnvVar(key, value, 'number');
  }

  return parsed;
};

/**
 * Get required integer environment variable
 */
export const getRequiredInt = (key: string): number => {
  if (!key) {
    throw StaticConfigurationException.invalidEnvVar('key', key, NON_EMPTY_STRING_MSG);
  }

  const value = process.env[key];
  if (value === undefined || value.trim() === '') {
    throw StaticConfigurationException.missingEnvVar(key);
  }

  const parsed = parseInt(value, 10);
  if (isNaN(parsed)) {
    throw StaticConfigurationException.invalidEnvVar(key, value, 'integer');
  }

  return parsed;
};

/**
 * Get required boolean environment variable
 */
export const getRequiredBoolean = (key: string): boolean => {
  if (!key) {
    throw StaticConfigurationException.invalidEnvVar('key', key, NON_EMPTY_STRING_MSG);
  }

  const value = process.env[key];
  if (value === undefined || value === '') {
    throw StaticConfigurationException.missingEnvVar(key);
  }

  const lowerValue = value.toLowerCase().trim();
  if (lowerValue !== 'true' && lowerValue !== 'false') {
    throw StaticConfigurationException.invalidEnvVar(key, value, 'boolean (true/false)');
  }

  return lowerValue === 'true';
};

/**
 * Get required JSON environment variable
 */
export const getRequiredJson = <T = unknown>(key: string): T => {
  if (!key) {
    throw StaticConfigurationException.invalidEnvVar('key', key, NON_EMPTY_STRING_MSG);
  }

  const value = process.env[key];
  if (value === undefined || value === '') {
    throw StaticConfigurationException.missingEnvVar(key);
  }

  try {
    return JSON.parse(value) as T;
  } catch {
    throw StaticConfigurationException.invalidEnvVar(key, value, 'valid JSON');
  }
};

/**
 * Get required string array environment variable (comma-separated)
 */
export const getRequiredStringArray = (key: string): string[] => {
  if (!key) {
    throw StaticConfigurationException.invalidEnvVar('key', key, NON_EMPTY_STRING_MSG);
  }

  const value = process.env[key];
  if (value === undefined || value === '') {
    throw StaticConfigurationException.missingEnvVar(key);
  }

  return value.split(',').map(item => item.trim()).filter(item => item !== '');
};

/**
 * Get optional string array environment variable
 */
export const getOptionalArray = (key: string): string[] => {
  if (!key) {
    throw StaticConfigurationException.invalidEnvVar('key', key, NON_EMPTY_STRING_MSG);
  }

  const value = process.env[key];
  if (value === undefined || value === '') {
    return [];
  }

  return value.split(',').map(item => item.trim()).filter(item => item !== '');
};

/**
 * Get optional environment variable
 */
export const getOptionalString = (key: string): string | undefined => {
  if (!key) {
    throw StaticConfigurationException.invalidEnvVar('key', key, NON_EMPTY_STRING_MSG);
  }

  const value = process.env[key];
  if (value === undefined) {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed === '' ? undefined : trimmed;
};

/**
 * Get optional numeric environment variable
 */
export const getOptionalNumber = (key: string): number | undefined => {
  if (!key) {
    throw StaticConfigurationException.invalidEnvVar('key', key, NON_EMPTY_STRING_MSG);
  }

  const value = process.env[key];
  if (value === undefined || value.trim() === '') {
    return undefined;
  }

  const parsed = parseFloat(value);
  if (isNaN(parsed)) {
    throw StaticConfigurationException.invalidEnvVar(key, value, 'number or leave unset');
  }

  return parsed;
};

/**
 * Get optional boolean environment variable
 */
export const getOptionalBoolean = (key: string): boolean | undefined => {
  if (!key) {
    throw StaticConfigurationException.invalidEnvVar('key', key, NON_EMPTY_STRING_MSG);
  }

  const value = process.env[key];
  if (value === undefined || value === '') {
    return undefined;
  }

  const lowerValue = value.toLowerCase().trim();
  if (lowerValue !== 'true' && lowerValue !== 'false') {
    throw StaticConfigurationException.invalidEnvVar(key, value, 'boolean (true/false) or leave unset');
  }

  return lowerValue === 'true';
};

/**
 * Validate that all required environment variables are present
 */
export const validateRequiredEnvVars = (requiredVars: string[]): void => {
  const missing: string[] = [];

  for (const varName of requiredVars) {
    const value = process.env[varName];
    if (value === undefined || value.trim() === '') {
      missing.push(varName);
    }
  }

  if (missing.length > 0) {
    const errorMsg = `Missing required environment variables:\n${missing.map(v => `  - ${v}`).join('\n')}\n\nPlease add these to your .env file.`;
    throw new StaticConfigurationException(errorMsg);
  }
};
```

## Configuration Module

The root configuration module aggregates ALL individual config files.

**File:** `src/config/config.module.ts`

```typescript
/**
 * Configuration Module
 *
 * THE SINGLE AGGREGATOR for ALL configuration files.
 *
 * Architecture Pattern: Module Aggregation
 * - Single entry point for all configurations
 * - Ensures all configs are loaded at startup
 */

import { Module } from '@nestjs/common';
import { ConfigModule as NestConfigModule } from '@nestjs/config';

// Core application configurations
import apiConfig from './api.config';
import applicationConfig from './application.config';
import cacheConfig from './cache.config';
import databaseConfig from './database.config';
import healthConfig from './health.config';
import resilienceConfig from './resilience.config';
import securityConfig from './security.config';
import throttlerConfig from './throttler.config';

export const ALL_CONFIGS = [
  applicationConfig,
  databaseConfig,
  cacheConfig,
  securityConfig,
  apiConfig,
  resilienceConfig,
  throttlerConfig,
  healthConfig,
];

@Module({
  imports: [
    NestConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      expandVariables: true,
      load: ALL_CONFIGS,
      validationOptions: {
        allowUnknown: false,
        abortEarly: true,
      },
    }),
  ],
  exports: [NestConfigModule],
})
export class ConfigModule {}

// Export individual configs for direct usage if needed
export {
  apiConfig,
  applicationConfig,
  cacheConfig,
  databaseConfig,
  healthConfig,
  resilienceConfig,
  securityConfig,
  throttlerConfig,
};
```

## Individual Config File Pattern

Each config file uses `registerAs()` from `@nestjs/config` and the static config reader for validation.

**Example:** `src/config/logging.config.ts`

```typescript
/**
 * Structured Logging Configuration
 *
 * Supports multiple output formats and cloud logging providers:
 * - JSON format for production (GCP, AWS, Azure compatible)
 * - Pretty format for development
 * - Configurable log levels per environment
 */

import { registerAs } from '@nestjs/config';
import { getRequiredString, getOptionalString, getOptionalBoolean } from './static-config-reader';

export default registerAs('logging', () => ({
  // Log level: error, warn, log, debug, verbose
  level: getOptionalString('LOG_LEVEL') ?? 'info',

  // Output format: json, pretty
  format: getOptionalString('LOG_FORMAT') ?? 'json',

  // Include timestamps in logs
  timestamps: getOptionalBoolean('LOG_TIMESTAMPS') ?? true,

  // Service context for structured logging
  serviceContext: {
    service: getRequiredString('APP_NAME'),
    version: process.env.npm_package_version ?? '0.0.0',
    environment: getRequiredString('NODE_ENV'),
  },

  // Cloud logging configuration
  cloudLogging: {
    // Enable cloud logging integration
    enabled: getOptionalBoolean('CLOUD_LOGGING_ENABLED') ?? false,

    // GCP-specific
    gcpProjectId: getOptionalString('GCP_PROJECT_ID'),

    // AWS-specific
    awsRegion: getOptionalString('AWS_REGION'),
    awsLogGroup: getOptionalString('AWS_LOG_GROUP'),

    // Azure-specific
    azureConnectionString: getOptionalString('AZURE_APPINSIGHTS_CONNECTION_STRING'),
  },

  // Request logging
  requestLogging: {
    // Log all requests
    enabled: getOptionalBoolean('LOG_REQUESTS') ?? true,

    // Fields to exclude from request body logging
    excludeFields: ['password', 'token', 'secret', 'apiKey', 'authorization'],

    // Max body size to log (bytes)
    maxBodySize: 10000,

    // Log slow requests (ms)
    slowRequestThreshold: 3000,
  },
}));
```

## Prisma Schema

Enterprise-grade Prisma schema with audit trails, feature flags, and transactional outbox pattern.

**File:** `prisma/schema.prisma`

```prisma
// {project_name} Database Schema
// Enterprise-grade schema with audit trails, optimistic locking, and financial precision

generator client {
  provider        = "prisma-client-js"
  binaryTargets   = ["native", "darwin", "darwin-arm64", "linux-musl-openssl-3.0.x"]
  previewFeatures = ["fullTextSearch", "fullTextIndex"] // PostgreSQL only
}

datasource db {
  provider     = "{database_type}" // postgresql, mysql, sqlite, mongodb
  url          = env("DATABASE_URL")
  relationMode = "prisma" // Recommended for edge deployments and serverless
  // Connection pooling configured via DATABASE_URL params:
  // ?connection_limit=20&pool_timeout=30&connect_timeout=10
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

## Environment Template (.env.example)

Comprehensive environment variable template with all configuration categories.

**File:** `.env.example`

```bash
# {project_name} - Environment Variables
# Copy to .env and update with your values

# ================================
# APPLICATION
# ================================
NODE_ENV=development
APP_NAME="{project_name}"
PORT=3000
API_PREFIX=api/v1
SWAGGER_PATH=api/docs
ENABLE_SWAGGER=true

# ================================
# LOGGING
# ================================
LOG_LEVEL=debug
LOG_FORMAT=json

# ================================
# DATABASE
# ================================
DATABASE_URL="postgresql://user:password@localhost:5432/{project_name}?schema=public"

# ================================
# REDIS (if selected)
# ================================
REDIS_URL="redis://localhost:6379"
REDIS_HOST=localhost
REDIS_PORT=6379

# ================================
# SECURITY
# ================================
SECURITY_CORS_ORIGINS=http://localhost:4200,http://localhost:3000
SECURITY_CORS_CREDENTIALS=true
SECURITY_CORS_MAX_AGE=86400
SECURITY_CORS_METHODS=GET,POST,PUT,DELETE,PATCH,OPTIONS
SECURITY_CORS_ALLOWED_HEADERS=Content-Type,Authorization,x-correlation-id
SECURITY_CORS_EXPOSED_HEADERS=x-correlation-id,x-request-id

# JWT (if authentication is selected)
SECURITY_JWT_SECRET=your-super-secret-jwt-key-minimum-32-characters
SECURITY_JWT_EXPIRES_IN=1h
SECURITY_REFRESH_TOKEN_EXPIRES_IN=7d

# ================================
# RATE LIMITING
# ================================
THROTTLER_SHORT_TTL=1000
THROTTLER_SHORT_LIMIT=3
THROTTLER_MEDIUM_TTL=10000
THROTTLER_MEDIUM_LIMIT=20
THROTTLER_LONG_TTL=60000
THROTTLER_LONG_LIMIT=100

# ================================
# PERFORMANCE
# ================================
REQUEST_TIMEOUT=30000
MAX_REQUEST_SIZE=1mb

# ================================
# RESILIENCE
# ================================
RESILIENCE_CIRCUIT_BREAKER_ENABLED=true
RESILIENCE_CIRCUIT_BREAKER_THRESHOLD=50
RESILIENCE_CIRCUIT_BREAKER_TIMEOUT=30000
RESILIENCE_RETRY_ENABLED=true
RESILIENCE_RETRY_MAX_ATTEMPTS=3
RESILIENCE_RETRY_DELAY=1000
RESILIENCE_TIMEOUT_MS=10000

# ================================
# HEALTH CHECKS
# ================================
HEALTH_CHECK_INTERVAL=30000
HEALTH_CHECK_TIMEOUT=5000

# ================================
# EXTERNAL APIS (if selected)
# ================================
# Add your external API configurations here
```

## Key Patterns

| Pattern | Description |
|---------|-------------|
| Fail-fast validation | All required env vars validated at startup via static config reader |
| No hardcoded defaults | Every value comes from environment or explicit fallback in config |
| Type-safe configs | Use `registerAs()` for namespaced, type-safe config access |
| Global config module | `isGlobal: true` makes ConfigService available everywhere |
| Optimistic locking | `version` field on models prevents race conditions |
| Soft delete | `deletedAt` field for recoverable deletions |
| Audit trail | AuditLog model captures all state changes |
| Feature flags | FeatureFlag model for percentage-based rollouts |
| Outbox pattern | Reliable event publishing with transactional guarantees |

## Usage in Services

```typescript
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class MyService {
  constructor(private readonly configService: ConfigService) {}

  someMethod() {
    // Access namespaced config
    const logLevel = this.configService.get<string>('logging.level');
    const dbUrl = this.configService.get<string>('database.url');

    // Type-safe with inference
    const config = this.configService.get<{
      level: string;
      format: string;
    }>('logging');
  }
}
```
