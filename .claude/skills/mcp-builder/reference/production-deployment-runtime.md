# Production Deployment Runtime Patterns

Graceful shutdown, health checks, and multi-tenant context management for production MCP servers.

## 1. Graceful Shutdown Pattern (Kubernetes-Ready)

```typescript
// src/lifecycle/graceful-shutdown.ts
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { Server as HttpServer } from 'http';

export class GracefulShutdown {
  private isShuttingDown = false;
  private activeRequests = new Set<string>();
  private shutdownTimeout = 30000; // 30 seconds
  private mcpServer?: McpServer;
  private httpServer?: HttpServer;
  private cleanupCallbacks: Array<() => Promise<void>> = [];

  constructor(
    mcpServer?: McpServer,
    httpServer?: HttpServer,
    shutdownTimeout?: number
  ) {
    this.mcpServer = mcpServer;
    this.httpServer = httpServer;
    if (shutdownTimeout) {
      this.shutdownTimeout = shutdownTimeout;
    }
  }

  /**
   * Register signal handlers for graceful shutdown
   */
  registerSignalHandlers(): void {
    const signals: NodeJS.Signals[] = ['SIGTERM', 'SIGINT', 'SIGUSR2'];

    signals.forEach((signal) => {
      process.on(signal, async () => {
        console.log(`Received ${signal}, starting graceful shutdown...`);
        await this.shutdown();
      });
    });

    process.on('uncaughtException', async (error) => {
      console.error('Uncaught exception:', error);
      await this.shutdown();
    });

    process.on('unhandledRejection', async (reason, promise) => {
      console.error('Unhandled rejection at:', promise, 'reason:', reason);
      await this.shutdown();
    });
  }

  /**
   * Track an active request
   * Returns cleanup function to call when request completes
   */
  trackRequest(requestId: string): () => void {
    if (this.isShuttingDown) {
      throw new Error('Server is shutting down, cannot accept new requests');
    }

    this.activeRequests.add(requestId);
    console.log(`Request ${requestId} started. Active: ${this.activeRequests.size}`);

    return () => {
      this.activeRequests.delete(requestId);
      console.log(`Request ${requestId} completed. Active: ${this.activeRequests.size}`);
    };
  }

  /**
   * Add cleanup callback to run during shutdown
   */
  onShutdown(callback: () => Promise<void>): void {
    this.cleanupCallbacks.push(callback);
  }

  /**
   * Graceful shutdown sequence
   */
  async shutdown(): Promise<void> {
    if (this.isShuttingDown) {
      console.log('Shutdown already in progress');
      return;
    }

    this.isShuttingDown = true;
    console.log('Starting graceful shutdown...');

    try {
      // Step 1: Stop accepting new connections
      if (this.httpServer) {
        console.log('Closing HTTP server to new connections...');
        this.httpServer.close();
      }

      // Step 2: Wait for active requests with timeout
      if (this.activeRequests.size > 0) {
        console.log(`Waiting for ${this.activeRequests.size} active requests to complete...`);

        const waitForRequests = new Promise<void>((resolve) => {
          const checkInterval = setInterval(() => {
            if (this.activeRequests.size === 0) {
              clearInterval(checkInterval);
              resolve();
            }
          }, 100);
        });

        const timeout = new Promise<void>((resolve) => {
          setTimeout(() => {
            console.warn(
              `Shutdown timeout reached. ${this.activeRequests.size} requests still active.`
            );
            resolve();
          }, this.shutdownTimeout);
        });

        await Promise.race([waitForRequests, timeout]);
      }

      // Step 3: Close MCP server connections
      if (this.mcpServer) {
        console.log('Closing MCP server connections...');
        await this.mcpServer.close();
      }

      // Step 4: Run cleanup callbacks
      console.log('Running cleanup callbacks...');
      await Promise.all(this.cleanupCallbacks.map((cb) => cb()));

      console.log('Graceful shutdown completed successfully');
      process.exit(0);
    } catch (error) {
      console.error('Error during graceful shutdown:', error);
      process.exit(1);
    }
  }

  /**
   * Check if server is shutting down
   */
  get shuttingDown(): boolean {
    return this.isShuttingDown;
  }

  /**
   * Get count of active requests
   */
  get activeRequestCount(): number {
    return this.activeRequests.size;
  }
}
```

## 2. Kubernetes Health Checks

```typescript
// src/health/types.ts
export type HealthStatus = 'healthy' | 'degraded' | 'unhealthy';

export interface ComponentHealth {
  status: HealthStatus;
  latency_ms?: number;
  message?: string;
  last_checked: string;
}

export interface HealthCheckResult {
  status: HealthStatus;
  checks: Record<string, ComponentHealth>;
  version: string;
  uptime: number;
}

export type HealthCheckFunction = () => Promise<ComponentHealth>;
```

```typescript
// src/health/health-checker.ts
import { HealthCheckResult, HealthCheckFunction, ComponentHealth, HealthStatus } from './types.js';

export class HealthChecker {
  private checks = new Map<string, HealthCheckFunction>();
  private readonly version: string;
  private readonly startTime: number;

  constructor(version: string) {
    this.version = version;
    this.startTime = Date.now();
  }

  /**
   * Register a health check component
   */
  register(name: string, checkFn: HealthCheckFunction): void {
    this.checks.set(name, checkFn);
  }

  /**
   * Run all health checks
   */
  async runAll(): Promise<HealthCheckResult> {
    const checks: Record<string, ComponentHealth> = {};
    let overallStatus: HealthStatus = 'healthy';

    const results = await Promise.allSettled(
      Array.from(this.checks.entries()).map(async ([name, checkFn]) => {
        const result = await checkFn();
        return { name, result };
      })
    );

    for (const outcome of results) {
      if (outcome.status === 'fulfilled') {
        const { name, result } = outcome.value;
        checks[name] = result;

        if (result.status === 'unhealthy') {
          overallStatus = 'unhealthy';
        } else if (result.status === 'degraded' && overallStatus === 'healthy') {
          overallStatus = 'degraded';
        }
      } else {
        const name = 'unknown';
        checks[name] = {
          status: 'unhealthy',
          message: `Health check failed: ${outcome.reason}`,
          last_checked: new Date().toISOString(),
        };
        overallStatus = 'unhealthy';
      }
    }

    return {
      status: overallStatus,
      checks,
      version: this.version,
      uptime: Date.now() - this.startTime,
    };
  }
}
```

```typescript
// src/health/endpoints.ts
import { FastifyInstance } from 'fastify';
import { HealthChecker } from './health-checker.js';

/**
 * Register Kubernetes health check endpoints
 */
export function registerHealthEndpoints(
  app: FastifyInstance,
  checker: HealthChecker
): void {
  // Liveness probe - always returns 200 if process is alive
  app.get('/health/live', async (request, reply) => {
    return reply.status(200).send({
      status: 'alive',
      timestamp: new Date().toISOString(),
    });
  });

  // Readiness probe - returns 503 if unhealthy
  app.get('/health/ready', async (request, reply) => {
    const result = await checker.runAll();
    const statusCode = result.status === 'unhealthy' ? 503 : 200;

    return reply.status(statusCode).send({
      status: result.status,
      timestamp: new Date().toISOString(),
    });
  });

  // Detailed health - full diagnostics for dashboards
  app.get('/health/detailed', async (request, reply) => {
    const result = await checker.runAll();
    const statusCode = result.status === 'unhealthy' ? 503 : 200;

    return reply.status(statusCode).send(result);
  });
}
```

```typescript
// src/health/checks/database.ts
import { Pool } from 'pg';
import { ComponentHealth } from '../types.js';

export function createDatabaseHealthCheck(pool: Pool) {
  return async (): Promise<ComponentHealth> => {
    const start = Date.now();

    try {
      await pool.query('SELECT 1');
      const latency = Date.now() - start;

      return {
        status: latency < 1000 ? 'healthy' : 'degraded',
        latency_ms: latency,
        message: latency < 1000 ? 'Database responding normally' : 'Database slow',
        last_checked: new Date().toISOString(),
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        latency_ms: Date.now() - start,
        message: `Database connection failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
        last_checked: new Date().toISOString(),
      };
    }
  };
}
```

```typescript
// src/health/checks/external-api.ts
import { ComponentHealth } from '../types.js';
import { CircuitBreaker } from '../../utils/circuit-breaker.js';

export function createExternalApiHealthCheck(circuitBreaker: CircuitBreaker) {
  return async (): Promise<ComponentHealth> => {
    const state = circuitBreaker.getState();
    const stats = circuitBreaker.getStats();

    const status =
      state === 'open' ? 'unhealthy' :
      state === 'half-open' ? 'degraded' :
      'healthy';

    return {
      status,
      message: `Circuit breaker state: ${state}. Success rate: ${stats.successRate.toFixed(2)}%`,
      last_checked: new Date().toISOString(),
    };
  };
}
```

## 3. Multi-Tenant Support (SaaS Isolation)

```typescript
// src/multi-tenant/types.ts
export interface TenantContext {
  tenantId: string;
  organizationId: string;
  userId: string;
  permissions: string[];
  quotas: TenantQuotas;
}

export interface TenantQuotas {
  maxRequestsPerMinute: number;
  maxToolCallsPerHour: number;
  maxDataExportMb: number;
}

export class TenantContextNotFoundError extends Error {
  constructor() {
    super('Tenant context not found. Ensure request is within tenant scope.');
    this.name = 'TenantContextNotFoundError';
  }
}
```

```typescript
// src/multi-tenant/context.ts
import { AsyncLocalStorage } from 'node:async_hooks';
import { TenantContext, TenantContextNotFoundError } from './types.js';

const asyncLocalStorage = new AsyncLocalStorage<TenantContext>();

/**
 * Execute function with tenant context
 */
export function withTenantContext<T>(
  context: TenantContext,
  fn: () => T | Promise<T>
): T | Promise<T> {
  return asyncLocalStorage.run(context, fn);
}

/**
 * Get current tenant context (returns undefined if not set)
 */
export function getTenantContext(): TenantContext | undefined {
  return asyncLocalStorage.getStore();
}

/**
 * Get current tenant context (throws if not set)
 */
export function requireTenantContext(): TenantContext {
  const context = getTenantContext();
  if (!context) {
    throw new TenantContextNotFoundError();
  }
  return context;
}
```

```typescript
// src/multi-tenant/middleware.ts
import { FastifyRequest, FastifyReply } from 'fastify';
import { withTenantContext } from './context.js';
import { TenantContext } from './types.js';
import { loadTenantFromDatabase } from './loader.js';

/**
 * Fastify plugin to extract and set tenant context
 */
export async function tenantMiddleware(
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  const tenantId = request.headers['x-tenant-id'] as string;
  const userId = request.headers['x-user-id'] as string;

  if (!tenantId || !userId) {
    return reply.status(400).send({
      error: 'Missing required headers: x-tenant-id, x-user-id',
    });
  }

  try {
    // Load tenant configuration from database
    const tenantData = await loadTenantFromDatabase(tenantId, userId);

    const context: TenantContext = {
      tenantId,
      organizationId: tenantData.organizationId,
      userId,
      permissions: tenantData.permissions,
      quotas: tenantData.quotas,
    };

    // Store in AsyncLocalStorage for downstream access
    await withTenantContext(context, async () => {
      // Continue with request processing
      return;
    });
  } catch (error) {
    return reply.status(403).send({
      error: 'Invalid tenant or user',
    });
  }
}
```

```typescript
// src/multi-tenant/quota-enforcer.ts
import { requireTenantContext } from './context.js';
import { RedisClientType } from 'redis';

export class QuotaEnforcer {
  constructor(private redis: RedisClientType) {}

  async checkRequestQuota(): Promise<boolean> {
    const context = requireTenantContext();
    const key = `quota:requests:${context.tenantId}`;
    const count = await this.redis.incr(key);

    if (count === 1) {
      await this.redis.expire(key, 60); // 1 minute window
    }

    return count <= context.quotas.maxRequestsPerMinute;
  }

  async checkToolCallQuota(): Promise<boolean> {
    const context = requireTenantContext();
    const key = `quota:tools:${context.tenantId}`;
    const count = await this.redis.incr(key);

    if (count === 1) {
      await this.redis.expire(key, 3600); // 1 hour window
    }

    return count <= context.quotas.maxToolCallsPerHour;
  }
}
```

```typescript
// src/multi-tenant/audit-logger.ts
import { requireTenantContext } from './context.js';

export interface AuditLog {
  tenant_id: string;
  user_id: string;
  action: string;
  resource: string;
  metadata: Record<string, unknown>;
  timestamp: Date;
}

export class AuditLogger {
  async log(action: string, resource: string, metadata: Record<string, unknown> = {}): Promise<void> {
    const context = requireTenantContext();

    const auditLog: AuditLog = {
      tenant_id: context.tenantId,
      user_id: context.userId,
      action,
      resource,
      metadata,
      timestamp: new Date(),
    };

    // Write to audit log (database, file, or external service)
    console.log('AUDIT:', JSON.stringify(auditLog));

    // In production, persist to database or audit service
    // await this.auditRepository.create(auditLog);
  }
}
```

```typescript
// src/protocol/tool-execution.ts
import { requireTenantContext } from '../multi-tenant/context.js';
import { QuotaEnforcer } from '../multi-tenant/quota-enforcer.js';
import { AuditLogger } from '../multi-tenant/audit-logger.js';

export async function executeTool(
  toolName: string,
  args: Record<string, unknown>,
  quotaEnforcer: QuotaEnforcer,
  auditLogger: AuditLogger
): Promise<unknown> {
  const context = requireTenantContext();

  // Check quota
  const allowed = await quotaEnforcer.checkToolCallQuota();
  if (!allowed) {
    throw new Error(`Tool call quota exceeded for tenant ${context.tenantId}`);
  }

  // Audit log
  await auditLogger.log('tool_call', toolName, { args });

  // Execute tool with tenant isolation
  // Tool implementation should use requireTenantContext() to scope data access
  const result = await executeToolImplementation(toolName, args);

  return result;
}

async function executeToolImplementation(
  toolName: string,
  args: Record<string, unknown>
): Promise<unknown> {
  // Tool implementation here
  return { success: true };
}
```

## Usage Notes

1. **Graceful Shutdown**: Handles SIGTERM/SIGINT, waits for active requests, runs cleanup callbacks
2. **Health Checks**: Liveness (process alive), Readiness (dependencies healthy), Detailed (full diagnostics)
3. **Multi-Tenancy**: AsyncLocalStorage for context propagation, quota enforcement, audit logging
4. **Request Tracking**: Track active requests for graceful shutdown, prevent new requests during shutdown
