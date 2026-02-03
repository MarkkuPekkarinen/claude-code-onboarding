# NestJS 11.x Debugging & Observability Guide

Production-quality debugging patterns for NestJS 11.x with Fastify, Prisma ORM, and TypeScript 5.x.

## 1. NestJS Debug Mode

### Bootstrap with Environment-Aware Logging

```typescript
// src/main.ts
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { Logger, LogLevel } from '@nestjs/common';
import { AppModule } from './app.module';
import { Config } from './config/static-config';

async function bootstrap() {
  const logLevels: Record<string, LogLevel[]> = {
    development: ['log', 'error', 'warn', 'debug', 'verbose'],
    test: ['error', 'warn'],
    production: ['error', 'warn', 'log'],
  };

  const logger = new Logger('Bootstrap');
  const currentEnv = Config.nodeEnv;
  const levels = logLevels[currentEnv] || logLevels.production;

  logger.log(`Starting application in ${currentEnv} mode with log levels: ${levels.join(', ')}`);

  const fastifyAdapter = new FastifyAdapter({
    logger: currentEnv === 'development' ? {
      level: 'info',
      prettyPrint: {
        colorize: true,
        translateTime: 'HH:MM:ss Z',
        ignore: 'pid,hostname',
      },
    } : false,
    requestIdHeader: 'x-correlation-id',
    requestIdLogLabel: 'correlationId',
  });

  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    fastifyAdapter,
    {
      logger: levels,
      abortOnError: true, // Fail fast on initialization errors
      bufferLogs: true,
    },
  );

  // Enable Fastify request/response logging in development
  if (currentEnv === 'development') {
    app.getHttpAdapter().getInstance().addHook('onRequest', async (request, reply) => {
      logger.debug(`→ ${request.method} ${request.url}`, 'FastifyRequest');
    });

    app.getHttpAdapter().getInstance().addHook('onResponse', async (request, reply) => {
      logger.debug(
        `← ${request.method} ${request.url} ${reply.statusCode} (${reply.getResponseTime().toFixed(2)}ms)`,
        'FastifyResponse'
      );
    });
  }

  await app.listen(Config.port, '0.0.0.0');
  logger.log(`Application listening on port ${Config.port}`, 'Bootstrap');
}

bootstrap();
```

### Per-Module Logger Instances

```typescript
// src/features/users/users.service.ts
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  async findById(id: string) {
    this.logger.debug(`Finding user by ID: ${id}`);
    try {
      const user = await this.prisma.user.findUnique({ where: { id } });
      if (!user) {
        this.logger.warn(`User not found: ${id}`);
      }
      return user;
    } catch (error) {
      this.logger.error(`Failed to find user ${id}: ${error.message}`, error.stack);
      throw error;
    }
  }
}
```

## 2. Prisma Query Logging & Debugging

### Event-Based Query Logging

```typescript
// src/database/prisma.service.ts
import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient, Prisma } from '@prisma/client';
import { Config } from '../config/static-config';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);
  private readonly SLOW_QUERY_THRESHOLD = 1000; // ms

  constructor() {
    const logLevels: Prisma.LogLevel[] = Config.isDevelopment
      ? ['query', 'info', 'warn', 'error']
      : ['warn', 'error'];

    super({
      log: logLevels.map(level => ({ level, emit: 'event' })),
      errorFormat: 'pretty',
    });

    // Query event logging (development only)
    if (Config.isDevelopment) {
      this.$on('query' as never, (event: Prisma.QueryEvent) => {
        this.logger.debug(
          `Query: ${event.query} | Params: ${event.params} | Duration: ${event.duration}ms`,
          'PrismaQuery'
        );
      });
    }

    // Slow query warning (all environments)
    this.$on('query' as never, (event: Prisma.QueryEvent) => {
      if (event.duration >= this.SLOW_QUERY_THRESHOLD) {
        this.logger.warn(
          `Slow query detected (${event.duration}ms): ${event.query.substring(0, 200)}`,
          'PrismaSlowQuery'
        );
      }
    });

    // Error event logging
    this.$on('error' as never, (event: Prisma.LogEvent) => {
      this.logger.error(`Prisma error: ${event.message}`, 'PrismaError');
    });

    // Info and warn events
    this.$on('info' as never, (event: Prisma.LogEvent) => {
      this.logger.log(event.message, 'PrismaInfo');
    });

    this.$on('warn' as never, (event: Prisma.LogEvent) => {
      this.logger.warn(event.message, 'PrismaWarn');
    });
  }

  async onModuleInit() {
    await this.$connect();
    this.logger.log('Database connection established');
    this.logConnectionPoolMetrics();
  }

  async onModuleDestroy() {
    await this.$disconnect();
    this.logger.log('Database connection closed');
  }

  // Connection pool monitoring
  private logConnectionPoolMetrics() {
    setInterval(() => {
      this.logger.debug(
        `Connection pool active: ${this.$metrics ? JSON.stringify(this.$metrics) : 'N/A'}`,
        'PrismaPool'
      );
    }, 30000); // Every 30 seconds
  }

  // Query profiling helper
  async profileQuery<T>(queryName: string, query: () => Promise<T>): Promise<T> {
    const start = performance.now();
    try {
      const result = await query();
      const duration = performance.now() - start;
      this.logger.log(`${queryName} completed in ${duration.toFixed(2)}ms`, 'PrismaProfile');
      return result;
    } catch (error) {
      const duration = performance.now() - start;
      this.logger.error(
        `${queryName} failed after ${duration.toFixed(2)}ms: ${error.message}`,
        error.stack,
        'PrismaProfile'
      );
      throw error;
    }
  }
}
```

### Prisma Debugging Commands

```bash
# Visual database browser (auto-opens in browser)
npx prisma studio

# Introspect existing database schema
DATABASE_URL="postgresql://user:pass@localhost:5432/db" npx prisma db pull

# Validate schema without migrations
npx prisma validate

# Generate Prisma Client with debug output
npx prisma generate --schema=./prisma/schema.prisma

# Debug connection issues
DEBUG=* npx prisma db push

# View pending migrations
npx prisma migrate status

# Reset database (development only)
npx prisma migrate reset
```

## 3. Fastify Request Lifecycle Debugging

### Lifecycle Hooks for Tracing

```typescript
// src/common/interceptors/lifecycle-debug.interceptor.ts
import { Injectable, NestInterceptor, ExecutionContext, CallHandler, Logger } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { FastifyRequest, FastifyReply } from 'fastify';

@Injectable()
export class LifecycleDebugInterceptor implements NestInterceptor {
  private readonly logger = new Logger(LifecycleDebugInterceptor.name);

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest<FastifyRequest>();
    const reply = context.switchToHttp().getResponse<FastifyReply>();
    const { method, url } = request;
    const correlationId = request.headers['x-correlation-id'] || 'unknown';

    this.logger.debug(`[${correlationId}] → ${method} ${url} | Phase: preHandler`, 'Lifecycle');

    return next.handle().pipe(
      tap({
        next: (data) => {
          this.logger.debug(
            `[${correlationId}] ← ${method} ${url} ${reply.statusCode} | Phase: onSend`,
            'Lifecycle'
          );
        },
        error: (error) => {
          this.logger.error(
            `[${correlationId}] ✗ ${method} ${url} ${error.status || 500} | Phase: onError`,
            error.stack,
            'Lifecycle'
          );
        },
      }),
    );
  }
}
```

### Adding Debug Hooks at Bootstrap

```typescript
// src/main.ts (additional setup)
async function bootstrap() {
  // ... existing setup

  const fastifyInstance = app.getHttpAdapter().getInstance();

  if (Config.isDevelopment) {
    fastifyInstance.addHook('onRequest', async (request, reply) => {
      logger.debug(`[onRequest] ${request.method} ${request.url}`, 'FastifyHook');
    });

    fastifyInstance.addHook('preParsing', async (request, reply, payload) => {
      logger.debug(`[preParsing] Content-Type: ${request.headers['content-type']}`, 'FastifyHook');
    });

    fastifyInstance.addHook('preValidation', async (request, reply) => {
      logger.debug(`[preValidation] Body: ${JSON.stringify(request.body).substring(0, 100)}`, 'FastifyHook');
    });

    fastifyInstance.addHook('preHandler', async (request, reply) => {
      logger.debug(`[preHandler] About to execute handler`, 'FastifyHook');
    });

    fastifyInstance.addHook('onSend', async (request, reply, payload) => {
      logger.debug(`[onSend] Status: ${reply.statusCode}`, 'FastifyHook');
    });

    fastifyInstance.addHook('onResponse', async (request, reply) => {
      logger.debug(`[onResponse] Completed in ${reply.getResponseTime()}ms`, 'FastifyHook');
    });

    fastifyInstance.addHook('onError', async (request, reply, error) => {
      logger.error(`[onError] ${error.message}`, error.stack, 'FastifyHook');
    });

    // Debug route not found
    fastifyInstance.setNotFoundHandler((request, reply) => {
      logger.warn(`Route not found: ${request.method} ${request.url}`, 'FastifyNotFound');
      reply.status(404).send({ error: 'Not Found', path: request.url });
    });
  }
}
```

### Content-Type Parsing Issues

```typescript
// Common issue: JSON parsing fails silently
// Fix: Register content type parser with logging
fastifyInstance.addContentTypeParser('application/json', { parseAs: 'string' }, (req, body, done) => {
  try {
    const json = JSON.parse(body as string);
    done(null, json);
  } catch (error) {
    logger.error(`JSON parse error: ${error.message} | Body: ${body}`, 'ContentTypeParser');
    done(error as Error, undefined);
  }
});
```

## 4. AsyncLocalStorage & Request Context Debugging

### Common Context Loss Issues

```typescript
// src/common/context/request-context.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { AsyncLocalStorage } from 'async_hooks';

interface RequestContext {
  correlationId: string;
  userId?: string;
  timestamp: number;
}

@Injectable()
export class RequestContextService {
  private readonly als = new AsyncLocalStorage<RequestContext>();
  private readonly logger = new Logger(RequestContextService.name);

  run<T>(context: RequestContext, callback: () => T): T {
    this.logger.debug(`Creating context: ${JSON.stringify(context)}`, 'ALS');
    return this.als.run(context, callback);
  }

  get(): RequestContext | undefined {
    const context = this.als.getStore();
    if (!context) {
      this.logger.warn('Context not found in current async scope', 'ALS');
    }
    return context;
  }

  // Pattern: wrap async operations to preserve context
  wrapAsync<T>(fn: () => Promise<T>): Promise<T> {
    const context = this.get();
    if (!context) {
      this.logger.error('Cannot wrap async operation: no active context', 'ALS');
      throw new Error('No active request context');
    }

    return this.als.run(context, async () => {
      this.logger.debug(`Wrapped async operation with context: ${context.correlationId}`, 'ALS');
      return fn();
    });
  }

  // Fix for setTimeout/setInterval context loss
  wrapTimeout(callback: () => void, delay: number): NodeJS.Timeout {
    const context = this.get();
    if (!context) {
      this.logger.warn('setTimeout called without context', 'ALS');
      return setTimeout(callback, delay);
    }

    return setTimeout(() => {
      this.als.run(context, callback);
    }, delay);
  }
}
```

### Debugging Context in Prisma Middleware

```typescript
// src/database/prisma.service.ts (additional middleware)
async onModuleInit() {
  await this.$connect();

  // Prisma middleware to propagate context
  this.$use(async (params, next) => {
    const context = this.contextService.get();
    if (!context) {
      this.logger.warn(`Prisma query without context: ${params.model}.${params.action}`, 'PrismaContext');
    } else {
      this.logger.debug(
        `Prisma query with context ${context.correlationId}: ${params.model}.${params.action}`,
        'PrismaContext'
      );
    }
    return next(params);
  });
}
```

### Context Loss in Bull Queue Jobs

```typescript
// src/queues/email.processor.ts
import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Logger } from '@nestjs/common';
import { RequestContextService } from '../common/context/request-context.service';

@Processor('email')
export class EmailProcessor {
  private readonly logger = new Logger(EmailProcessor.name);

  constructor(private readonly contextService: RequestContextService) {}

  @Process('send')
  async handleSend(job: Job) {
    // Context is NOT automatically propagated to queue jobs
    // Solution: store context in job.data and recreate it
    const { correlationId, userId, ...emailData } = job.data;

    return this.contextService.run(
      { correlationId, userId, timestamp: Date.now() },
      async () => {
        this.logger.log(`Processing email job with context: ${correlationId}`, 'EmailProcessor');
        // Now all async operations in this scope have context
        return this.sendEmail(emailData);
      }
    );
  }

  private async sendEmail(data: any) {
    const context = this.contextService.get();
    this.logger.debug(`Sending email in context: ${context?.correlationId || 'MISSING'}`, 'EmailProcessor');
    // ... send email
  }
}
```

## 5. Memory Leak Detection

### Memory Usage Endpoint

```typescript
// src/health/health.controller.ts
import { Controller, Get } from '@nestjs/common';
import { SkipAuth } from '../common/decorators/skip-auth.decorator';

@Controller('api/v1/health')
export class HealthController {
  @Get('memory')
  @SkipAuth()
  getMemoryUsage() {
    const usage = process.memoryUsage();
    return {
      rss: `${(usage.rss / 1024 / 1024).toFixed(2)} MB`, // Resident Set Size
      heapTotal: `${(usage.heapTotal / 1024 / 1024).toFixed(2)} MB`,
      heapUsed: `${(usage.heapUsed / 1024 / 1024).toFixed(2)} MB`,
      external: `${(usage.external / 1024 / 1024).toFixed(2)} MB`,
      arrayBuffers: `${(usage.arrayBuffers / 1024 / 1024).toFixed(2)} MB`,
      uptime: `${(process.uptime() / 60).toFixed(2)} minutes`,
    };
  }
}
```

### Common NestJS Memory Leaks

```typescript
// BAD: Unclosed Prisma connections
@Injectable()
export class BadService {
  async getData() {
    const prisma = new PrismaClient(); // Never disconnected - LEAK!
    return prisma.user.findMany();
  }
}

// GOOD: Use singleton PrismaService
@Injectable()
export class GoodService {
  constructor(private readonly prisma: PrismaService) {}

  async getData() {
    return this.prisma.user.findMany();
  }
}

// BAD: EventEmitter listener leak
@Injectable()
export class BadEventService implements OnModuleInit {
  constructor(private readonly eventEmitter: EventEmitter2) {}

  onModuleInit() {
    setInterval(() => {
      this.eventEmitter.on('event', () => {}); // Adds listener every second - LEAK!
    }, 1000);
  }
}

// GOOD: Add listener once
@Injectable()
export class GoodEventService implements OnModuleInit, OnModuleDestroy {
  private handler = () => {};

  constructor(private readonly eventEmitter: EventEmitter2) {}

  onModuleInit() {
    this.eventEmitter.on('event', this.handler);
  }

  onModuleDestroy() {
    this.eventEmitter.off('event', this.handler);
  }
}

// BAD: Circular DI reference leak
@Injectable()
export class ServiceA {
  constructor(private readonly serviceB: ServiceB) {}
}

@Injectable()
export class ServiceB {
  constructor(private readonly serviceA: ServiceA) {} // Circular!
}

// GOOD: Use forwardRef
@Injectable()
export class ServiceA {
  constructor(@Inject(forwardRef(() => ServiceB)) private readonly serviceB: ServiceB) {}
}
```

### Memory Debugging Commands

```bash
# Run with Chrome DevTools inspector
node --inspect dist/main.js
# Then open chrome://inspect in Chrome

# Limit heap size to detect leaks faster
node --max-old-space-size=512 dist/main.js

# Generate heap snapshot programmatically
v8.writeHeapSnapshot('./heap-snapshot.heapsnapshot');

# Analyze heap snapshots: load two snapshots in Chrome DevTools Memory tab and compare
```

## 6. Performance Profiling

### Custom Performance Interceptor

```typescript
// src/common/interceptors/performance.interceptor.ts
import { Injectable, NestInterceptor, ExecutionContext, CallHandler, Logger } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { performance, PerformanceObserver } from 'perf_hooks';

@Injectable()
export class PerformanceInterceptor implements NestInterceptor {
  private readonly logger = new Logger(PerformanceInterceptor.name);
  private readonly SLOW_REQUEST_THRESHOLD = 500; // ms

  constructor() {
    const obs = new PerformanceObserver((items) => {
      items.getEntries().forEach((entry) => {
        if (entry.duration > this.SLOW_REQUEST_THRESHOLD) {
          this.logger.warn(
            `Slow request: ${entry.name} took ${entry.duration.toFixed(2)}ms`,
            'Performance'
          );
        }
      });
    });
    obs.observe({ entryTypes: ['measure'] });
  }

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url } = request;
    const markStart = `${method}-${url}-start`;
    const markEnd = `${method}-${url}-end`;
    const measureName = `${method} ${url}`;

    performance.mark(markStart);

    return next.handle().pipe(
      tap({
        next: () => {
          performance.mark(markEnd);
          performance.measure(measureName, markStart, markEnd);
          const measure = performance.getEntriesByName(measureName)[0];
          this.logger.log(`${measureName} completed in ${measure.duration.toFixed(2)}ms`, 'Performance');
          performance.clearMarks(markStart);
          performance.clearMarks(markEnd);
          performance.clearMeasures(measureName);
        },
        error: () => {
          performance.clearMarks(markStart);
        },
      }),
    );
  }
}
```

### Prisma Query Timing Middleware

```typescript
// src/database/prisma.service.ts (additional middleware)
async onModuleInit() {
  await this.$connect();

  // Query timing middleware
  this.$use(async (params, next) => {
    const before = performance.now();
    const result = await next(params);
    const after = performance.now();
    const duration = after - before;

    this.logger.debug(
      `${params.model}.${params.action} took ${duration.toFixed(2)}ms`,
      'PrismaPerformance'
    );

    if (duration > 100) {
      this.logger.warn(
        `Slow Prisma query: ${params.model}.${params.action} (${duration.toFixed(2)}ms)`,
        'PrismaSlowQuery'
      );
    }

    return result;
  });
}
```

### CPU Profiling Commands

```bash
# Generate CPU profile
node --prof dist/main.js
# Stop after some requests, then process the log
node --prof-process isolate-*.log > profile.txt

# V8 profiling with Chrome DevTools
node --inspect-brk dist/main.js
# Open chrome://inspect, click "inspect", go to Profiler tab

# Trace event profiling
node --trace-event-categories v8,node,node.async_hooks dist/main.js
# Generates node_trace.*.log, open in chrome://tracing
```

## 7. Circuit Breaker State Debugging

### Circuit Breaker Inspection Endpoint

```typescript
// src/resilience/resilience.controller.ts
import { Controller, Get, Post, Param } from '@nestjs/common';
import { CircuitBreakerRegistry } from './circuit-breaker.registry';

@Controller('api/v1/resilience')
export class ResilienceController {
  constructor(private readonly registry: CircuitBreakerRegistry) {}

  @Get('circuits')
  getAllCircuits() {
    return this.registry.getAllStates();
  }

  @Get('circuits/:name')
  getCircuitByName(@Param('name') name: string) {
    const state = this.registry.getState(name);
    if (!state) {
      return { error: `Circuit breaker '${name}' not found` };
    }
    return state;
  }

  @Post('circuits/:name/reset')
  resetCircuit(@Param('name') name: string) {
    this.registry.reset(name);
    return { message: `Circuit '${name}' reset to CLOSED` };
  }
}
```

### Circuit Breaker with State Logging

```typescript
// src/resilience/circuit-breaker.registry.ts
import { Injectable, Logger } from '@nestjs/common';

export interface CircuitState {
  name: string;
  state: 'CLOSED' | 'OPEN' | 'HALF_OPEN';
  failureCount: number;
  successCount: number;
  totalCalls: number;
  lastFailureTime?: number;
  openedAt?: number;
}

@Injectable()
export class CircuitBreakerRegistry {
  private readonly logger = new Logger(CircuitBreakerRegistry.name);
  private readonly circuits = new Map<string, CircuitState>();

  register(name: string): void {
    if (!this.circuits.has(name)) {
      this.circuits.set(name, {
        name,
        state: 'CLOSED',
        failureCount: 0,
        successCount: 0,
        totalCalls: 0,
      });
      this.logger.log(`Circuit breaker '${name}' registered`, 'Registry');
    }
  }

  recordSuccess(name: string): void {
    const circuit = this.circuits.get(name);
    if (circuit) {
      circuit.successCount++;
      circuit.totalCalls++;
      if (circuit.state === 'HALF_OPEN') {
        this.logger.log(`Circuit '${name}' transitioning HALF_OPEN → CLOSED`, 'StateTransition');
        circuit.state = 'CLOSED';
        circuit.failureCount = 0;
      }
    }
  }

  recordFailure(name: string, threshold: number): void {
    const circuit = this.circuits.get(name);
    if (circuit) {
      circuit.failureCount++;
      circuit.totalCalls++;
      circuit.lastFailureTime = Date.now();

      if (circuit.state === 'CLOSED' && circuit.failureCount >= threshold) {
        this.logger.warn(
          `Circuit '${name}' OPENING: failure count ${circuit.failureCount} >= threshold ${threshold}`,
          'StateTransition'
        );
        circuit.state = 'OPEN';
        circuit.openedAt = Date.now();
      } else if (circuit.state === 'HALF_OPEN') {
        this.logger.warn(`Circuit '${name}' transitioning HALF_OPEN → OPEN`, 'StateTransition');
        circuit.state = 'OPEN';
        circuit.openedAt = Date.now();
      }
    }
  }

  tryHalfOpen(name: string, timeout: number): boolean {
    const circuit = this.circuits.get(name);
    if (circuit && circuit.state === 'OPEN' && circuit.openedAt) {
      const elapsed = Date.now() - circuit.openedAt;
      if (elapsed >= timeout) {
        this.logger.log(`Circuit '${name}' transitioning OPEN → HALF_OPEN`, 'StateTransition');
        circuit.state = 'HALF_OPEN';
        return true;
      }
    }
    return false;
  }

  getAllStates(): CircuitState[] {
    return Array.from(this.circuits.values());
  }

  getState(name: string): CircuitState | undefined {
    return this.circuits.get(name);
  }

  reset(name: string): void {
    const circuit = this.circuits.get(name);
    if (circuit) {
      this.logger.log(`Circuit '${name}' manually reset to CLOSED`, 'ManualReset');
      circuit.state = 'CLOSED';
      circuit.failureCount = 0;
      circuit.successCount = 0;
      delete circuit.openedAt;
    }
  }
}
```

## 8. Dependency Injection Debugging

### Common DI Issues and Fixes

```typescript
// Issue: "Cannot resolve dependency" error
// Symptom: Nest can't find a provider

// BAD: Service not in module providers
@Module({
  controllers: [UsersController],
  // Missing: UsersService in providers array
})
export class UsersModule {}

// GOOD: Service registered in module
@Module({
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService], // Export if other modules need it
})
export class UsersModule {}

// Issue: Circular dependency
// Symptom: "A circular dependency has been detected"

// BAD: Direct circular reference
@Injectable()
export class UserService {
  constructor(private readonly postService: PostService) {}
}

@Injectable()
export class PostService {
  constructor(private readonly userService: UserService) {} // Circular!
}

// GOOD: Use forwardRef
@Injectable()
export class UserService {
  constructor(@Inject(forwardRef(() => PostService)) private readonly postService: PostService) {}
}

@Injectable()
export class PostService {
  constructor(@Inject(forwardRef(() => UserService)) private readonly userService: UserService) {}
}

// Issue: Optional dependency
// Symptom: App crashes when optional service is missing

// BAD: Required dependency that might not exist
@Injectable()
export class NotificationService {
  constructor(private readonly smsProvider: SmsProvider) {} // Crashes if SMS not configured
}

// GOOD: Use @Optional() decorator
@Injectable()
export class NotificationService {
  constructor(@Optional() private readonly smsProvider?: SmsProvider) {}

  async send(message: string) {
    if (this.smsProvider) {
      await this.smsProvider.send(message);
    } else {
      console.log('SMS provider not configured, skipping SMS notification');
    }
  }
}

// Issue: Module import ordering
// Symptom: Provider from Module A not available in Module B

// BAD: Importing module that doesn't export the provider
@Module({
  imports: [DatabaseModule], // DatabaseModule doesn't export PrismaService
  providers: [UserService], // UserService needs PrismaService - ERROR!
})
export class UserModule {}

// GOOD: Ensure DatabaseModule exports PrismaService
@Module({
  providers: [PrismaService],
  exports: [PrismaService], // Now available to importing modules
})
export class DatabaseModule {}
```

## 9. Environment & Configuration Debugging

### Fail-Fast Static Configuration

```typescript
// src/config/static-config.ts
import { Logger } from '@nestjs/common';
import * as dotenv from 'dotenv';

dotenv.config();

const logger = new Logger('StaticConfig');

function getEnv(key: string, defaultValue?: string): string {
  const value = process.env[key];
  if (!value && defaultValue === undefined) {
    logger.error(`Missing required environment variable: ${key}`);
    throw new Error(`Missing required environment variable: ${key}`);
  }
  const result = value || defaultValue!;
  logger.debug(`Loaded ${key}=${result.includes('PASSWORD') ? '***' : result}`);
  return result;
}

export const Config = {
  nodeEnv: getEnv('NODE_ENV', 'development'),
  port: parseInt(getEnv('PORT', '3000'), 10),
  databaseUrl: getEnv('DATABASE_URL'),
  jwtSecret: getEnv('JWT_SECRET'),
  isDevelopment: getEnv('NODE_ENV', 'development') === 'development',
  isProduction: getEnv('NODE_ENV') === 'production',
} as const;

logger.log(`Configuration loaded for environment: ${Config.nodeEnv}`);
```

### Debugging .env File Loading

```bash
# Check if .env file is loaded
node -e "require('dotenv').config(); console.log(process.env)"

# Check specific variable
node -e "require('dotenv').config(); console.log('DATABASE_URL:', process.env.DATABASE_URL)"

# Environment variable precedence (highest to lowest):
# 1. System environment variables (export VAR=value)
# 2. .env.local (not committed to git)
# 3. .env
# 4. Default values in code

# Debug: print all process.env at startup
# src/main.ts
if (Config.isDevelopment) {
  console.log('Environment variables:', JSON.stringify(process.env, null, 2));
}
```

## 10. Troubleshooting Table

| Issue | Symptom | Fix |
|-------|---------|-----|
| Route not found | 404 for valid endpoint | Check controller path prefix, ensure module is imported in AppModule |
| Request body is undefined | `req.body` is `{}` | Register `@nestjs/platform-fastify` body parser, ensure `Content-Type: application/json` |
| Validation not working | Invalid data passes through | Apply `ValidationPipe` globally in `main.ts`, ensure DTO has `class-validator` decorators |
| Circular dependency | Module initialization fails | Use `forwardRef(() => Module)` in imports and `@Inject(forwardRef(() => Service))` in constructor |
| Prisma "Connection pool timeout" | Queries hang indefinitely | Increase `connection_limit` in `DATABASE_URL`, check for unclosed transactions, ensure `$disconnect()` in tests |
| Context lost in async operations | `contextService.get()` returns `undefined` | Use `contextService.wrapAsync()` or manually propagate context with `als.run()` |
| Memory leak in production | Heap grows unbounded | Check for unclosed DB connections, EventEmitter listeners, circular references, Redis subscriptions |
| Circuit breaker stuck OPEN | All requests fail with 503 | Check circuit state via `/api/v1/resilience/circuits`, manually reset, or wait for timeout |
| Config value is undefined | `Config.someValue` is `undefined` | Check `.env` file exists, variable name matches, dotenv loaded before config import |
| Slow API response | Request takes >1s | Enable Prisma query logging, add performance interceptor, check for N+1 queries, missing indexes |
| Fastify validation error | `FST_ERR_VALIDATION` in logs | Check route schema matches DTO, ensure JSON schema plugin installed, validate request body manually |
| Middleware not executing | Custom middleware skipped | Ensure middleware applied globally or to specific routes, check execution order |
| JWT authentication fails | 401 Unauthorized for valid token | Check JWT secret matches, verify token not expired, ensure AuthGuard applied correctly |
| Prisma migration fails | `Migration failed` error | Check schema syntax, ensure database accessible, rollback failed migration, check for conflicting migrations |
| Bull queue job fails silently | Job completes but no effect | Check processor decorated with `@Processor()`, ensure queue registered in module, add error logging in `@OnQueueFailed()` |
