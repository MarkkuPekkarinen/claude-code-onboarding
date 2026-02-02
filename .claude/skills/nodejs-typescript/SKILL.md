---
name: nodejs-typescript
description: Patterns and templates for Node.js 24 / TypeScript 5.x development. Activate when creating Node.js services, Express/Fastify APIs, TypeScript utilities, npm packages, or tests.
allowed-tools: Bash, Read, Write, Edit
---

# Node.js 24 + TypeScript 5.x Development Skill

This skill provides patterns for Node.js 24 with TypeScript 5.x, including Express REST APIs, Zod validation, testing with Vitest, and Docker deployment.

## Process

1. **Scaffold** - Use quick commands below to initialize project structure
2. **Configure** - Read templates from reference file for package.json, tsconfig, and environment setup
3. **Build API** - Create Express app with routes, services, middleware, and error handling
4. **Validate** - Implement Zod schemas for runtime validation and type inference
5. **Test** - Write integration tests with Vitest and supertest
6. **Containerize** - Add Docker multi-stage build for production deployment

## Quick Scaffold — New Node.js/TypeScript Project

```bash
mkdir my-service && cd my-service
npm init -y
npm install typescript @types/node tsx --save-dev
npm install express zod dotenv
npm install @types/express --save-dev
npx tsc --init
```

## Code Templates Reference

For all code templates and configuration patterns, Read the reference file:

**[reference/nodejs-templates.md](reference/nodejs-templates.md)**

Contains:
- package.json Essentials
- tsconfig.json
- Express App Template (app.ts + index.ts)
- Zod Validation + Type Inference
- Error Handler Middleware
- Route Template (Router with GET/POST)
- Vitest Test Template
- Docker Template (multi-stage build)
- Environment Configuration (Zod-validated env)
- Service Layer Template
- Custom Error Classes
- Enhanced Error Handler
- Logging Middleware
- vitest.config.ts

## Key Patterns

| Pattern | Description |
|---------|-------------|
| ESM-first | `"type": "module"` in package.json, `.js` extensions in imports |
| Strict TypeScript | `strict: true`, target `ES2024`, module `NodeNext` |
| Zod validation | Runtime validation with automatic TypeScript type inference |
| Layered architecture | routes → services → repositories → models |
| Error handling | Custom error classes + centralized error middleware |
| Async/await | Always use `async`/`await`, wrap in try-catch, call `next(error)` |
| Type inference | Use `z.infer<typeof Schema>` instead of manual types |

## Folder Structure

```
src/
├── index.ts           # Entry point
├── app.ts             # Express app setup
├── routes/            # API route handlers
├── services/          # Business logic
├── repositories/      # Data access layer
├── models/            # Types, interfaces, Zod schemas
├── middleware/        # Auth, validation, error handling, logging
├── config/            # Environment config
└── utils/             # Shared utilities

tests/
├── unit/
└── integration/
```

## Error Handling

### Common Issues and Solutions

**Import errors with .js extensions**
- Node.js ESM requires `.js` extensions even for `.ts` files
- Example: `import { app } from './app.js';`

**Module not found errors**
- Check `"type": "module"` in package.json
- Verify `tsconfig.json` has `"module": "NodeNext"` and `"moduleResolution": "NodeNext"`

**Zod validation failures**
- Wrap `Schema.parse()` in try-catch or let error handler catch `ZodError`
- Use `Schema.safeParse()` for manual error handling without throwing

**TypeScript type mismatches**
- Run `npx tsc --noEmit` to check types without building
- Use `satisfies` operator for type-safe literals
- Prefer `z.infer<typeof Schema>` over manual types

**Port already in use**
- Check for running processes: `lsof -i :3000`
- Use dynamic port: `process.env.PORT ?? 3000`

**Missing environment variables**
- Validate env vars with Zod schema (see reference file)
- Use `.env` file locally, never commit it

## Testing Best Practices

- Use `supertest` for API integration tests
- Mock external dependencies in service layer tests
- Use `beforeEach` to reset state between tests
- Run `npm test` before commits
- Aim for 80%+ coverage on critical paths

## Development Workflow

```bash
npm run dev        # Start dev server with hot reload
npm run typecheck  # Check types without building
npm run build      # Compile to dist/
npm test           # Run tests once
npm run test:watch # Run tests in watch mode
```

## Key Dependencies

- **express** - Web framework
- **zod** - Runtime validation + type inference
- **tsx** - TypeScript execution with hot reload
- **vitest** - Fast unit test framework
- **supertest** - HTTP assertion library for API tests
- **dotenv** - Environment variable loading
