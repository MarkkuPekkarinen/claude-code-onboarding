---
description: Scaffold a new NestJS 11.x REST API project with Fastify, Prisma, structured logging, and proper module structure
allowed-tools: Bash, Read, Write, Edit
disable-model-invocation: true
---

# Scaffold NestJS API

Create a new NestJS 11.x / TypeScript 5.x API project with the following:

**Project name:** $ARGUMENTS (default to "my-nestjs-api" if not provided)

## Steps
1. Create NestJS project using `npx @nestjs/cli new <name> --package-manager npm --strict`
2. Install additional dependencies: @nestjs/platform-fastify, @nestjs/config, @nestjs/swagger, @nestjs/terminus, @nestjs/throttler, @prisma/client, class-validator, class-transformer, @fastify/helmet, @fastify/compress
3. Remove Jest (NestJS CLI default): uninstall `jest`, `@types/jest`, `ts-jest`, remove `jest` config from `package.json`, delete any generated `.spec.ts` files
4. Install dev dependencies: prisma, vitest, unplugin-swc, @swc/core, @vitest/coverage-v8, supertest, @types/supertest
5. Create `vitest.config.ts` with SWC transform for decorator support
6. Replace Express with Fastify adapter in `src/main.ts`
7. Set up directory structure: `src/config/`, `src/common/exceptions/`, `src/common/filters/`, `src/common/interceptors/`, `src/common/middleware/`, `src/common/context/`, `src/core/`, `src/features/`
8. Create static config reader with fail-fast env validation
9. Create config module aggregating application, database, and security configs
10. Initialize Prisma with PostgreSQL: `npx prisma init --datasource-provider postgresql`
11. Create a sample feature module (health) at `GET /api/v1/health`
12. Create a sample entity feature (e.g., "products") with module, controller, service, DTOs, and Prisma model
13. Add global exception filter, validation pipe, and logging interceptor
14. Add security middleware (Helmet) and CORS configuration
15. Add a `Dockerfile` and `docker-compose.dev.yml` with PostgreSQL and Redis
16. Add npm scripts: dev, build, start:prod, test, test:e2e, lint, typecheck
17. Create `.env.example` with all required environment variables
18. Print summary of created files and next steps

Use the nestjs-api skill for patterns and templates.
