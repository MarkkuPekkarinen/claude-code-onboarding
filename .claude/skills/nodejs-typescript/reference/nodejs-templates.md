# Node.js + TypeScript Code Templates

This file contains all code templates and configuration patterns for Node.js 24 / TypeScript 5.x development.

## package.json Essentials

```json
{
  "name": "my-service",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "vitest run",
    "test:watch": "vitest",
    "lint": "eslint src/",
    "typecheck": "tsc --noEmit"
  },
  "engines": {
    "node": ">=24.0.0"
  }
}
```

## tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2024",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "esModuleInterop": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,
    "sourceMap": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

## Express App Template

```typescript
// src/app.ts
import express from 'express';
import { errorHandler } from './middleware/error-handler.js';
import { userRouter } from './routes/user.routes.js';

const app = express();
app.use(express.json());
app.use('/api/v1/users', userRouter);
app.use(errorHandler);

export { app };
```

```typescript
// src/index.ts
import { app } from './app.js';

const PORT = process.env.PORT ?? 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
```

## Zod Validation + Type Inference

```typescript
import { z } from 'zod';

export const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['admin', 'user', 'viewer']).default('user'),
});

export type CreateUserDto = z.infer<typeof CreateUserSchema>;

// In route handler:
const dto = CreateUserSchema.parse(req.body); // throws ZodError on invalid input
```

## Error Handler Middleware

```typescript
import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';

export function errorHandler(err: Error, req: Request, res: Response, next: NextFunction) {
  if (err instanceof ZodError) {
    res.status(400).json({ error: 'Validation failed', details: err.errors });
    return;
  }
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
}
```

## Route Template

```typescript
import { Router, Request, Response, NextFunction } from 'express';
import { CreateUserSchema } from '../models/user.schema.js';
import { userService } from '../services/user.service.js';

export const userRouter = Router();

userRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const users = await userService.findAll();
    res.json({ data: users });
  } catch (error) {
    next(error);
  }
});

userRouter.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const dto = CreateUserSchema.parse(req.body);
    const user = await userService.create(dto);
    res.status(201).json(user);
  } catch (error) {
    next(error);
  }
});
```

## Vitest Test Template

```typescript
import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { app } from '../src/app.js';

describe('User API', () => {
  it('POST /api/v1/users returns 201', async () => {
    const res = await request(app)
      .post('/api/v1/users')
      .send({ email: 'test@example.com', name: 'Test User' });

    expect(res.status).toBe(201);
    expect(res.body.email).toBe('test@example.com');
  });

  it('POST /api/v1/users returns 400 on invalid email', async () => {
    const res = await request(app)
      .post('/api/v1/users')
      .send({ email: 'not-an-email', name: 'Test' });

    expect(res.status).toBe(400);
  });
});
```

## Docker Template

```dockerfile
FROM node:24-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:24-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
RUN npm ci --omit=dev
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

## Environment Configuration

```typescript
// src/config/env.ts
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
});

export const env = envSchema.parse(process.env);
```

## Service Layer Template

```typescript
// src/services/user.service.ts
import { CreateUserDto } from '../models/user.schema.js';
import { userRepository } from '../repositories/user.repository.js';

class UserService {
  async findAll() {
    return await userRepository.findAll();
  }

  async findById(id: string) {
    const user = await userRepository.findById(id);
    if (!user) {
      throw new Error('User not found');
    }
    return user;
  }

  async create(dto: CreateUserDto) {
    return await userRepository.create(dto);
  }

  async delete(id: string) {
    await userRepository.delete(id);
  }
}

export const userService = new UserService();
```

## Custom Error Classes

```typescript
// src/models/errors.ts
export class NotFoundError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'NotFoundError';
  }
}

export class ValidationError extends Error {
  constructor(message: string, public details?: unknown) {
    super(message);
    this.name = 'ValidationError';
  }
}

export class UnauthorizedError extends Error {
  constructor(message: string = 'Unauthorized') {
    super(message);
    this.name = 'UnauthorizedError';
  }
}
```

## Enhanced Error Handler

```typescript
import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { NotFoundError, ValidationError, UnauthorizedError } from '../models/errors.js';

export function errorHandler(err: Error, req: Request, res: Response, next: NextFunction) {
  console.error(`[Error] ${err.name}: ${err.message}`);

  if (err instanceof ZodError) {
    res.status(400).json({ error: 'Validation failed', details: err.errors });
    return;
  }

  if (err instanceof ValidationError) {
    res.status(400).json({ error: err.message, details: err.details });
    return;
  }

  if (err instanceof NotFoundError) {
    res.status(404).json({ error: err.message });
    return;
  }

  if (err instanceof UnauthorizedError) {
    res.status(401).json({ error: err.message });
    return;
  }

  res.status(500).json({ error: 'Internal server error' });
}
```

## Logging Middleware

```typescript
// src/middleware/logger.ts
import { Request, Response, NextFunction } from 'express';

export function logger(req: Request, res: Response, next: NextFunction) {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.path} ${res.statusCode} - ${duration}ms`);
  });

  next();
}
```

## vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      exclude: ['dist/', 'node_modules/', '**/*.spec.ts'],
    },
  },
});
```
