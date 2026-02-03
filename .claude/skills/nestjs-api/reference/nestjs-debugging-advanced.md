# NestJS Advanced Debugging

Performance profiling, memory leak detection, circuit breaker monitoring, and production debugging for NestJS 11.x.

## 1. Memory Leak Detection

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

## 2. Performance Profiling

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

## 3. Circuit Breaker State Debugging

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

## 4. Production Debugging Patterns

### Structured Logging with Context

```typescript
// src/common/logging/logger.service.ts
import { Injectable, Logger, LoggerService } from '@nestjs/common';
import { getCorrelationId, getUserId } from '../context/request-context.service';

@Injectable()
export class StructuredLogger implements LoggerService {
  private readonly logger = new Logger();

  log(message: string, context?: string, metadata?: Record<string, any>) {
    this.logger.log(this.formatMessage(message, metadata), context);
  }

  error(message: string, trace?: string, context?: string, metadata?: Record<string, any>) {
    this.logger.error(this.formatMessage(message, metadata), trace, context);
  }

  warn(message: string, context?: string, metadata?: Record<string, any>) {
    this.logger.warn(this.formatMessage(message, metadata), context);
  }

  debug(message: string, context?: string, metadata?: Record<string, any>) {
    this.logger.debug(this.formatMessage(message, metadata), context);
  }

  verbose(message: string, context?: string, metadata?: Record<string, any>) {
    this.logger.verbose(this.formatMessage(message, metadata), context);
  }

  private formatMessage(message: string, metadata?: Record<string, any>): string {
    const correlationId = getCorrelationId();
    const userId = getUserId();

    const logObject = {
      message,
      correlationId,
      userId,
      timestamp: new Date().toISOString(),
      ...metadata,
    };

    return JSON.stringify(logObject);
  }
}
```

### Health Check with Dependency Monitoring

```typescript
// src/health/health.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CircuitBreakerRegistry } from '../resilience/circuit-breaker.registry';

interface HealthStatus {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: string;
  uptime: number;
  checks: {
    database: { status: string; latency?: number; error?: string };
    memory: { status: string; heapUsed: string; heapTotal: string };
    circuits: { status: string; openCount: number; details?: any };
  };
}

@Injectable()
export class HealthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly circuitRegistry: CircuitBreakerRegistry,
  ) {}

  async getHealth(): Promise<HealthStatus> {
    const checks = {
      database: await this.checkDatabase(),
      memory: this.checkMemory(),
      circuits: this.checkCircuits(),
    };

    const status = this.determineOverallStatus(checks);

    return {
      status,
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      checks,
    };
  }

  private async checkDatabase(): Promise<any> {
    const start = performance.now();
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      const latency = performance.now() - start;
      return {
        status: latency < 100 ? 'healthy' : 'degraded',
        latency: Math.round(latency),
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
      };
    }
  }

  private checkMemory(): any {
    const usage = process.memoryUsage();
    const heapUsedMB = usage.heapUsed / 1024 / 1024;
    const heapTotalMB = usage.heapTotal / 1024 / 1024;
    const heapPercentage = (heapUsedMB / heapTotalMB) * 100;

    return {
      status: heapPercentage < 80 ? 'healthy' : heapPercentage < 95 ? 'degraded' : 'unhealthy',
      heapUsed: `${heapUsedMB.toFixed(2)} MB`,
      heapTotal: `${heapTotalMB.toFixed(2)} MB`,
    };
  }

  private checkCircuits(): any {
    const states = this.circuitRegistry.getAllStates();
    const openCount = states.filter(s => s.state === 'OPEN').length;

    return {
      status: openCount === 0 ? 'healthy' : openCount < 3 ? 'degraded' : 'unhealthy',
      openCount,
      details: states.filter(s => s.state === 'OPEN'),
    };
  }

  private determineOverallStatus(checks: any): 'healthy' | 'degraded' | 'unhealthy' {
    const statuses = [checks.database.status, checks.memory.status, checks.circuits.status];

    if (statuses.includes('unhealthy')) return 'unhealthy';
    if (statuses.includes('degraded')) return 'degraded';
    return 'healthy';
  }
}
```

### Request Tracing with Distributed Context

```typescript
// src/common/interceptors/tracing.interceptor.ts
import { Injectable, NestInterceptor, ExecutionContext, CallHandler, Logger } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';
import { getCorrelationId, updateContextMetadata } from '../context/request-context.service';

@Injectable()
export class TracingInterceptor implements NestInterceptor {
  private readonly logger = new Logger(TracingInterceptor.name);

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url } = request;
    const correlationId = getCorrelationId();
    const startTime = Date.now();

    this.logger.log(`[${correlationId}] → ${method} ${url}`, 'Tracing');

    return next.handle().pipe(
      tap(() => {
        const duration = Date.now() - startTime;
        updateContextMetadata({ requestDuration: duration });
        this.logger.log(
          `[${correlationId}] ← ${method} ${url} (${duration}ms)`,
          'Tracing'
        );
      }),
      catchError((error) => {
        const duration = Date.now() - startTime;
        this.logger.error(
          `[${correlationId}] ✗ ${method} ${url} (${duration}ms): ${error.message}`,
          error.stack,
          'Tracing'
        );
        throw error;
      })
    );
  }
}
```

## 5. Debugging Best Practices

### Development Environment

- Use `logger.debug()` liberally for detailed flow tracing
- Enable Prisma query logging to identify N+1 queries
- Use Fastify lifecycle hooks to track request processing stages
- Leverage Chrome DevTools for memory profiling and CPU profiling

### Production Environment

- Use structured JSON logging with correlation IDs
- Implement comprehensive health checks with dependency monitoring
- Monitor circuit breaker states via dedicated endpoints
- Track request duration and slow query warnings
- Use external APM tools (DataDog, New Relic, Sentry) for distributed tracing

### Common Pitfalls

- Never log sensitive data (passwords, tokens, PII)
- Avoid excessive logging in hot paths (use sampling)
- Clean up event listeners and timers in `OnModuleDestroy`
- Use connection pooling for database and external services
- Implement graceful shutdown to avoid connection leaks
