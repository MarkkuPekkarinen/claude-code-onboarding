---
name: nestjs-api
description: This skill provides patterns and templates for NestJS 11.x with Fastify, Prisma ORM, and TypeScript 5.x development. It should be activated when creating NestJS modules, controllers, services, DTOs, guards, interceptors, or tests.
allowed-tools: Bash, Read, Write, Edit
---

# NestJS 11.x + Fastify + Prisma REST API Skill

## Quick Scaffold — New NestJS Project

```bash
# Using NestJS CLI
npx @nestjs/cli new my-service --package-manager npm --strict
```

## Process

1. **Scaffold** using NestJS CLI or the command above
2. **Configure** package.json and tsconfig — read `reference/nestjs-config.md`
3. **Create files** using templates — read `reference/nestjs-templates.md` for main.ts, AppModule, CoreModule, feature module, Controller, Service, DTO, and Test templates
4. **Follow conventions** below for package layout and NestJS rules
5. **Write tests** with Vitest + supertest or NestJS Testing utilities
6. **Format and check**: `npm run lint && npm run typecheck`

## Key Patterns

| Pattern | Implementation |
|---------|---------------|
| **Modules** | `@Module()` with imports/providers/exports, aggregation pattern |
| **Controllers** | `@Controller('api/v1/...')` with route decorators |
| **Services** | `@Injectable()` with constructor injection |
| **DTOs** | Classes with `class-validator` decorators (`@IsString()`, `@IsNotEmpty()`) |
| **Repositories** | Prisma Client via `DatabaseService` wrapper |
| **Error handling** | `@Catch()` exception filter returning `ProblemDetail` (RFC 9457) |
| **Config** | Fail-fast `registerAs()` with static config reader |
| **Migrations** | Prisma Migrate in `prisma/migrations/` |
| **Guards** | `@UseGuards()` for auth (`JwtAuthGuard`, `RolesGuard`) |
| **Interceptors** | `LoggingInterceptor`, `TransformInterceptor` (global) |
| **Pipes** | Global `ValidationPipe` with whitelist and transform |

## Package Layout

```
src/
├── main.ts
├── app.module.ts
├── config/          # Configuration management (fail-fast)
├── common/          # Cross-cutting: exceptions, filters, interceptors, middleware, pipes, context
├── core/            # Infrastructure: database, cache, resilience, health, observability, messaging, feature-flags
├── shared/          # Cross-feature types, utils, constants
├── auth/            # Authentication (guards, strategies, decorators)
└── features/        # Business feature modules
    └── {entity}/    # module, controller, service, dto, repository
```

## NestJS Rules

- Use decorator-based DI (`@Injectable()`, `@Module()`, `@Controller()`)
- Module aggregation pattern: ConfigModule → CommonModule → CoreModule → FeaturesModule
- Fail-fast configuration: app crashes at startup if env vars are missing
- Use class-validator + class-transformer for DTO validation
- Use Prisma Client for database access (not TypeORM or Sequelize)
- Return structured responses via interceptors (TransformInterceptor)
- Global exception filter produces RFC 9457 ProblemDetail responses
- All external calls wrapped in circuit breaker pattern
- Request context via AsyncLocalStorage for correlation ID propagation

## Reference Files

| File | Content |
|------|---------|
| `reference/nestjs-config.md` | package.json, tsconfig.json, static config reader, config module, Prisma schema |
| `reference/nestjs-templates.md` | main.ts, app.module, core.module, feature module, controller, service, DTO, Dockerfile |
| `reference/nestjs-enterprise.md` | Exception hierarchy, security middleware (Helmet), rate limiting, Swagger, health checks, validation pipe |
| `reference/nestjs-resilience.md` | Circuit breaker, database fallback, request context (AsyncLocalStorage), feature flags |
| `reference/nestjs-observability.md` | OpenTelemetry tracing/metrics, structured logging, cloud logging |
| `reference/nestjs-messaging.md` | BullMQ queues, RabbitMQ, Kafka, platform comparison |
| `reference/nestjs-testing.md` | Vitest patterns, Test.createTestingModule, supertest, Testcontainers, circuit breaker testing, test data factories |
| `reference/nestjs-rest-service-guide.md` | OpenAPI/Swagger, DTO mapping, pagination, external clients, file uploads, soft delete |
| `reference/nestjs-security-hardening.md` | OWASP scanning, security headers, JWT hardening, PII masking, rate limiting, Prisma security |
| `reference/nestjs-debugging.md` | Prisma query logging, Fastify lifecycle, AsyncLocalStorage debugging, memory leaks, performance profiling |

## Error Handling

**Validation errors**: Use `class-validator` decorators on DTO classes. Global ValidationPipe auto-returns 422 with details.

**Not-found errors**: Throw `NotFoundException` from services. Global exception filter returns structured 404.

**Duplicate errors**: Catch Prisma `P2002` unique constraint violation and convert to `409 Conflict`.
