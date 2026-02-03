---
description: Scaffold a new Node.js 24 / TypeScript 5.x REST API project with Express, Zod validation, and proper structure
allowed-tools: Bash, Read, Write, Edit
disable-model-invocation: true
---

# Scaffold Node.js TypeScript API

Create a new Node.js 24 / TypeScript 5.x API project with the following:

**Project name:** $ARGUMENTS (default to "my-node-api" if not provided)

## Steps
1. Initialize npm project with `"type": "module"`
2. Install dependencies: express, zod, dotenv, typescript, tsx, vitest
3. Create `tsconfig.json` with strict mode, ES2024 target, NodeNext module
4. Set up folder structure: `src/routes/`, `src/services/`, `src/models/`, `src/middleware/`, `src/utils/`, `src/config/`
5. Create `src/app.ts` with Express setup and JSON middleware
6. Create `src/index.ts` entry point
7. Create a sample route, service, and Zod schema for a "hello world" resource
8. Add error handler middleware with ZodError support
9. Add a Vitest test for the sample route
10. Create a `Dockerfile` for production build
11. Add npm scripts: dev, build, start, test, lint, typecheck
12. Print summary of created files and next steps

Use the nodejs-typescript skill for patterns and templates.
