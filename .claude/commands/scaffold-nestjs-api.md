---
description: Scaffold a new NestJS 11.x REST API project with Fastify, Prisma, structured logging, and proper module structure
argument-hint: "[project name]"
allowed-tools: Bash, Read, Write, Edit
disable-model-invocation: true
---

# Scaffold NestJS API

Create a new NestJS 11.x / TypeScript 5.x API project with the following:

**Project name:** $ARGUMENTS (default to "my-nestjs-api" if not provided)

## Steps
1. Create NestJS project using `npx @nestjs/cli new <name> --package-manager npm --strict --skip-git`
2. Install additional dependencies: @nestjs/platform-fastify, @nestjs/config, @nestjs/swagger, @nestjs/terminus, @nestjs/throttler, @prisma/client, @prisma/adapter-pg, pg, class-validator, class-transformer, @fastify/helmet, @fastify/compress, @fastify/static, dotenv
3. Remove Jest (NestJS CLI default): uninstall `jest`, `@types/jest`, `ts-jest`, remove `jest` config from `package.json`, delete any generated `.spec.ts` files and `test/` directory
4. Install dev dependencies: prisma, vitest, unplugin-swc, @swc/core, @vitest/coverage-v8, supertest, @types/supertest, @types/pg
5. Create `vitest.config.ts` with SWC transform for decorator support
6. Replace Express with Fastify adapter in `src/main.ts` (include `import 'dotenv/config'` at top)
7. Set up directory structure: `src/config/`, `src/common/exceptions/`, `src/common/filters/`, `src/common/interceptors/`, `src/common/middleware/`, `src/common/context/`, `src/core/`, `src/features/`
8. Create static config reader with fail-fast env validation (getRequired* and getOptional* functions)
9. Create config module aggregating application, database, security, and throttler configs
10. Initialize Prisma with PostgreSQL using Prisma 7.x format:
    - Run `npx prisma init --datasource-provider postgresql`
    - Update `prisma/schema.prisma`: change `provider = "prisma-client-js"` to `provider = "prisma-client"`, add `output = "../src/generated/prisma"`, remove `url` from datasource block
    - Keep `prisma.config.ts` (created by prisma init) — it provides the DATABASE_URL to Prisma CLI
    - Run `npx prisma generate` to generate the client
    - Add `src/generated/` to `.gitignore`
    - Delete default `src/app.controller.ts`, `src/app.service.ts` boilerplate
11. Create PrismaService using composition with `@prisma/adapter-pg` (Prisma 7.x requires driver adapters — do NOT extend PrismaClient)
12. Create a health module (health) at `GET /api/v1/health` using @nestjs/terminus
13. Create the requested feature module(s) with controller, service, DTOs, and Prisma model
14. Add global exception filter (RFC 9457 ProblemDetail), validation pipe, and logging interceptor
15. Add security middleware (Helmet) and CORS configuration
16. Add a `Dockerfile` and `docker-compose.dev.yml` with PostgreSQL and Redis
17. Add npm scripts: start:dev, build, start:prod, test, test:cov, typecheck, prisma:generate, prisma:migrate
18. Create `.env` with working dev defaults using **Bash** (not Write/Edit tools — `.env` is blocked by hooks). Must include ALL required env vars so the app boots without manual config:
    ```bash
    cat > .env << 'EOF'
    DATABASE_URL="postgresql://postgres:postgres@localhost:5432/{db_name}?schema=public"
    APP_NAME={project_name}
    NODE_ENV=development
    PORT=3000
    ENABLE_SWAGGER=true
    SECURITY_CORS_ORIGINS=http://localhost:4200
    EOF
    ```
    The DATABASE_URL must match the credentials in `docker-compose.dev.yml`.
19. Verify the scaffold works: run `npx tsc --noEmit` — fix any errors before finishing
20. Print summary of created files and next steps

Use the nestjs-api skill for patterns and templates.
