---
name: nestjs-api
description: This skill provides patterns and templates for NestJS 11.x with Fastify, Prisma ORM, and TypeScript 5.x development. It should be activated when creating NestJS modules, controllers, services, DTOs, guards, interceptors, or tests.
allowed-tools: Bash, Read, Write, Edit
---

# NestJS 11.x + Fastify + Prisma REST API Skill

## Conventions & Rules

> For code conventions, package layout, NestJS rules, Prisma 7.x rules, and environment file rules, read `reference/nestjs-conventions.md`

## Quick Scaffold — New NestJS Project

```bash
# Using NestJS CLI
npx @nestjs/cli new my-service --package-manager npm --strict
```

## Process

1. **Scaffold** using NestJS CLI or the command above
2. **Configure** package.json and tsconfig — read `reference/nestjs-config-basics.md` and `reference/nestjs-config-schema.md`
3. **Create files** using templates — read `reference/nestjs-templates-core.md` for main.ts, AppModule, CoreModule; read `reference/nestjs-templates-features.md` for feature modules, controllers, services, DTOs
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

## Reference Files

| File | Content |
|------|---------|
| `reference/nestjs-config-basics.md` | Static config reader, config module aggregation, fail-fast validation |
| `reference/nestjs-config-schema.md` | package.json, tsconfig.json, Prisma schema, .env template |
| `reference/nestjs-templates-core.md` | main.ts, app.module, core.module templates |
| `reference/nestjs-templates-features.md` | Feature module, controller, service, DTO templates |
| `reference/nestjs-templates-infrastructure.md` | Dockerfile, docker-compose, Vitest config |
| `reference/nestjs-enterprise-patterns.md` | Exception hierarchy, validation pipe, API versioning |
| `reference/nestjs-enterprise-infrastructure.md` | Security middleware (Helmet), rate limiting, Swagger, health checks |
| `reference/nestjs-resilience-patterns.md` | Circuit breaker, database fallback, request context (AsyncLocalStorage) |
| `reference/nestjs-feature-flags.md` | Feature flags service, Redis fallback, gradual rollout |
| `reference/nestjs-observability.md` | OpenTelemetry tracing/metrics, structured logging, cloud logging |
| `reference/nestjs-messaging-basics.md` | BullMQ queues, background job processing |
| `reference/nestjs-messaging-queues.md` | RabbitMQ reliable messaging, dead letter queues |
| `reference/nestjs-messaging-streaming.md` | Kafka event streaming, high-throughput patterns |
| `reference/nestjs-testing-unit.md` | Unit testing with Vitest, mocking, test data factories |
| `reference/nestjs-testing-integration.md` | E2E testing with supertest, Testcontainers |
| `reference/nestjs-testing-advanced.md` | Circuit breaker testing, coverage standards, CI/CD |
| `reference/nestjs-rest-controllers.md` | OpenAPI/Swagger, DTO mapping, pagination, file uploads |
| `reference/nestjs-rest-services.md` | Service patterns, external API clients, bulk operations, soft delete |
| `reference/nestjs-security-auth.md` | JWT authentication (RS256), password hashing, token management |
| `reference/nestjs-security-hardening.md` | OWASP scanning, security headers, PII masking, input validation |
| `reference/nestjs-debugging-basics.md` | Prisma query logging, Fastify lifecycle, config debugging |
| `reference/nestjs-debugging-advanced.md` | Memory leaks, performance profiling, production debugging, tracing |

## Documentation Sources

Before generating code, consult these sources for current syntax and APIs:

| Source | URL / Tool | Purpose |
|--------|-----------|---------|
| Prisma ORM | `https://www.prisma.io/docs/llms.txt` | Prisma schema, migrations, client API |
| NestJS / TypeScript | `Context7` MCP | Latest NestJS decorators, modules, patterns |

## Error Handling

**Validation errors**: Use `class-validator` decorators on DTO classes. Global ValidationPipe auto-returns 422 with details.

**Not-found errors**: Throw `NotFoundException` from services. Global exception filter returns structured 404.

**Duplicate errors**: Catch Prisma `P2002` unique constraint violation and convert to `409 Conflict`.
