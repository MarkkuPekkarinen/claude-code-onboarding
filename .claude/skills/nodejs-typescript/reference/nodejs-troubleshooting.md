# Node.js / TypeScript - Troubleshooting & Workflow

## Common Issues and Solutions

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
- Validate env vars with Zod schema (see nodejs-templates.md)
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
