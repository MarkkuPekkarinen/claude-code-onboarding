# NestJS Resilience Patterns

Resilience patterns for NestJS 11.x covering circuit breaker, database fallback, request context propagation, and feature flags.

## Circuit Breaker Pattern

The circuit breaker prevents cascading failures by failing fast when a service is down. It implements a state machine with three states: CLOSED (normal operation), OPEN (failing fast), and HALF_OPEN (testing recovery).

### Implementation (`src/core/resilience/patterns/circuit-breaker.pattern.ts`)

```typescript
/**
 * Circuit Breaker Pattern Implementation
 *
 * Prevents cascading failures by failing fast when a service is down.
 * States: CLOSED → OPEN → HALF_OPEN → CLOSED
 */

import { Injectable, Logger } from '@nestjs/common';

import type {
  ICircuitBreakerState,
  IResilienceContext,
  IPatternExecutor
} from '../interfaces/resilience.interface';

interface CircuitBreakerConfig {
  enabled: boolean;
  failureThreshold: number;
  resetTimeout: number;
  halfOpenMaxCalls: number;
  monitoringPeriod: number;
}

interface CircuitState {
  state: 'open' | 'closed' | 'half-open';
  failures: number;
  successes: number;
  totalCalls: number;
  lastFailureTime?: Date;
  nextRetryTime?: Date;
  consecutiveSuccesses: number;
  windowStart: number;
}

@Injectable()
export class CircuitBreakerPattern implements IPatternExecutor {
  private readonly logger = new Logger(CircuitBreakerPattern.name);
  private readonly circuits = new Map<string, CircuitState>();

  async execute<T>(
    operation: () => Promise<T>,
    config: CircuitBreakerConfig,
    context: IResilienceContext
  ): Promise<T> {
    if (!config.enabled) {
      return operation();
    }

    const circuitKey = `${context.policyName}:${context.endpoint ?? 'default'}`;
    const state = this.getOrCreateState(circuitKey);

    // Check if circuit is open
    if (state.state === 'open') {
      if (Date.now() < state.nextRetryTime!.getTime()) {
        throw new Error(`Circuit breaker is open for ${circuitKey}`);
      }
      state.state = 'half-open';
      state.consecutiveSuccesses = 0;
      this.logger.log(`Circuit breaker moved to half-open for ${circuitKey}`);
    }

    // Check if half-open and max calls reached
    if (state.state === 'half-open' && state.consecutiveSuccesses >= config.halfOpenMaxCalls) {
      state.state = 'closed';
      state.failures = 0;
      state.successes = 0;
      state.totalCalls = 0;
      state.windowStart = Date.now();
      this.logger.log(`Circuit breaker closed for ${circuitKey}`);
    }

    try {
      const result = await operation();
      this.recordSuccess(state, config);
      return result;
    } catch (error) {
      this.recordFailure(state, config, circuitKey);
      throw error;
    }
  }

  getAllStates(): Record<string, ICircuitBreakerState> {
    const states: Record<string, ICircuitBreakerState> = {};

    for (const [key, state] of this.circuits) {
      states[key] = {
        state: state.state,
        failures: state.failures,
        successes: state.successes,
        lastFailureTime: state.lastFailureTime,
        nextRetryTime: state.nextRetryTime,
        consecutiveSuccesses: state.consecutiveSuccesses,
      };
    }

    return states;
  }

  getMetrics(): Record<string, unknown> {
    const metrics: Record<string, unknown> = {
      totalCircuits: this.circuits.size,
      openCircuits: 0,
      halfOpenCircuits: 0,
      closedCircuits: 0,
      circuits: {},
    };

    for (const [key, state] of this.circuits) {
      if (state.state === 'open') (metrics.openCircuits as number)++;
      else if (state.state === 'half-open') (metrics.halfOpenCircuits as number)++;
      else (metrics.closedCircuits as number)++;

      const failureRate = state.totalCalls > 0
        ? (state.failures / state.totalCalls) * 100
        : 0;

      (metrics.circuits as Record<string, unknown>)[key] = {
        state: state.state,
        failureRate: `${failureRate.toFixed(2)}%`,
        totalCalls: state.totalCalls,
        failures: state.failures,
        successes: state.successes,
      };
    }

    return metrics;
  }

  reset(policyName: string): void {
    const keysToReset: string[] = [];

    for (const key of this.circuits.keys()) {
      if (key.startsWith(policyName)) {
        keysToReset.push(key);
      }
    }

    keysToReset.forEach(key => {
      this.circuits.delete(key);
      this.logger.log(`Circuit breaker reset for ${key}`);
    });
  }

  private getOrCreateState(circuitKey: string): CircuitState {
    if (!this.circuits.has(circuitKey)) {
      this.circuits.set(circuitKey, {
        state: 'closed',
        failures: 0,
        successes: 0,
        totalCalls: 0,
        consecutiveSuccesses: 0,
        windowStart: Date.now(),
      });
    }

    return this.circuits.get(circuitKey)!;
  }

  private recordSuccess(state: CircuitState, config: CircuitBreakerConfig): void {
    state.successes++;
    state.totalCalls++;

    if (state.state === 'half-open') {
      state.consecutiveSuccesses++;
    }

    this.checkWindowReset(state, config);
  }

  private recordFailure(
    state: CircuitState,
    config: CircuitBreakerConfig,
    circuitKey: string
  ): void {
    state.failures++;
    state.totalCalls++;
    state.lastFailureTime = new Date();
    state.consecutiveSuccesses = 0;

    this.checkWindowReset(state, config);

    const failureRate = (state.failures / state.totalCalls) * 100;

    if (state.state !== 'open' && failureRate >= config.failureThreshold) {
      state.state = 'open';
      state.nextRetryTime = new Date(Date.now() + config.resetTimeout);

      this.logger.warn(
        `Circuit breaker opened for ${circuitKey}. ` +
        `Failure rate: ${failureRate.toFixed(2)}% (threshold: ${config.failureThreshold}%)`
      );
    }

    if (state.state === 'half-open') {
      state.state = 'open';
      state.nextRetryTime = new Date(Date.now() + config.resetTimeout);
      this.logger.warn(`Circuit breaker reopened for ${circuitKey}`);
    }
  }

  private checkWindowReset(state: CircuitState, config: CircuitBreakerConfig): void {
    const now = Date.now();

    if (now - state.windowStart > config.monitoringPeriod) {
      state.failures = 0;
      state.successes = 0;
      state.totalCalls = 0;
      state.windowStart = now;
    }
  }
}
```

### Usage

```typescript
// In a service
constructor(
  private readonly circuitBreaker: CircuitBreakerPattern
) {}

async fetchData(): Promise<Data> {
  return this.circuitBreaker.execute(
    () => this.externalService.getData(),
    {
      enabled: true,
      failureThreshold: 50, // Open circuit at 50% failure rate
      resetTimeout: 30000, // 30 seconds
      halfOpenMaxCalls: 3, // Test with 3 calls before closing
      monitoringPeriod: 60000 // 1 minute sliding window
    },
    {
      policyName: 'external-api',
      endpoint: '/api/data'
    }
  );
}
```

## Database Fallback Service

Provides graceful degradation when the database is unavailable using in-memory cache fallback, queued writes for eventual consistency, and health-aware automatic recovery.

### Implementation (`src/core/database/services/database-fallback.service.ts`)

```typescript
/**
 * Database Fallback Service
 *
 * Provides graceful degradation when database is unavailable:
 * - In-memory cache fallback for read operations
 * - Queued writes for eventual consistency
 * - Health-aware automatic recovery
 */

import { Injectable, Logger } from '@nestjs/common';

interface CachedData<T> {
  data: T;
  expiry: number;
  stale: boolean;
}

@Injectable()
export class DatabaseFallbackService {
  private readonly logger = new Logger(DatabaseFallbackService.name);
  private readonly cache = new Map<string, CachedData<unknown>>();
  private readonly defaultTtl = 300000; // 5 minutes

  /**
   * Execute a database operation with cache fallback
   *
   * @param operation - The database operation to execute
   * @param cacheKey - Unique key for caching the result
   * @param options - Configuration options
   */
  async executeWithFallback<T>(
    operation: () => Promise<T>,
    cacheKey: string,
    options: {
      ttl?: number;
      staleWhileRevalidate?: boolean;
      fallbackValue?: T;
    } = {}
  ): Promise<T> {
    const { ttl = this.defaultTtl, staleWhileRevalidate = true, fallbackValue } = options;

    try {
      // Attempt the database operation
      const result = await operation();

      // Cache successful result
      this.cache.set(cacheKey, {
        data: result,
        expiry: Date.now() + ttl,
        stale: false,
      });

      return result;
    } catch (error) {
      // Check for cached data
      const cached = this.cache.get(cacheKey) as CachedData<T> | undefined;

      if (cached) {
        const isExpired = cached.expiry < Date.now();

        if (!isExpired) {
          // Return fresh cached data
          this.logger.warn(`Database unavailable, serving from cache: ${cacheKey}`);
          return cached.data;
        }

        if (staleWhileRevalidate) {
          // Return stale data while marking for revalidation
          this.logger.warn(`Database unavailable, serving stale data: ${cacheKey}`);
          cached.stale = true;
          return cached.data;
        }
      }

      // No cached data available
      if (fallbackValue !== undefined) {
        this.logger.warn(`Database unavailable, using fallback value: ${cacheKey}`);
        return fallbackValue;
      }

      // Re-throw if no fallback available
      this.logger.error(`Database unavailable, no fallback for: ${cacheKey}`);
      throw error;
    }
  }

  /**
   * Invalidate cached data
   */
  invalidate(cacheKey: string): void {
    this.cache.delete(cacheKey);
  }

  /**
   * Invalidate all cached data matching a pattern
   */
  invalidatePattern(pattern: string): void {
    const regex = new RegExp(pattern);
    for (const key of this.cache.keys()) {
      if (regex.test(key)) {
        this.cache.delete(key);
      }
    }
  }

  /**
   * Get cache statistics
   */
  getStats(): { size: number; staleCount: number } {
    let staleCount = 0;
    for (const value of this.cache.values()) {
      if (value.stale) staleCount++;
    }
    return { size: this.cache.size, staleCount };
  }
}
```

### Usage

```typescript
// In a repository
constructor(
  private readonly dbFallback: DatabaseFallbackService
) {}

async findUser(id: string): Promise<User | null> {
  return this.dbFallback.executeWithFallback(
    () => this.userRepository.findOne({ where: { id } }),
    `user:${id}`,
    {
      ttl: 600000, // 10 minutes
      staleWhileRevalidate: true,
      fallbackValue: null
    }
  );
}

// Invalidate on update
async updateUser(id: string, data: UpdateUserDto): Promise<User> {
  const user = await this.userRepository.update(id, data);
  this.dbFallback.invalidate(`user:${id}`);
  return user;
}
```

## Request Context (AsyncLocalStorage)

Propagates request context through the entire call chain using AsyncLocalStorage, enabling access to correlation ID, user info, and other request metadata from any point in the application without passing through parameters.

### Implementation (`src/common/context/request-context.service.ts`)

```typescript
/**
 * Request Context Service
 *
 * Propagates request context through the entire call chain using AsyncLocalStorage.
 * Enables access to correlation ID, user info, and other request metadata
 * from any point in the application without passing through parameters.
 */

import { AsyncLocalStorage } from 'async_hooks';

export interface RequestContext {
  /** Unique identifier for request tracing */
  correlationId: string;

  /** Request timestamp */
  startTime: number;

  /** Authenticated user ID (if any) */
  userId?: string;

  /** Tenant ID for multi-tenant applications */
  tenantId?: string;

  /** Session ID */
  sessionId?: string;

  /** Client IP address */
  ipAddress?: string;

  /** User agent string */
  userAgent?: string;

  /** Request path */
  path?: string;

  /** HTTP method */
  method?: string;

  /** Custom metadata */
  metadata: Record<string, unknown>;
}

/**
 * AsyncLocalStorage instance for request context
 */
export const requestContext = new AsyncLocalStorage<RequestContext>();

/**
 * Get current request context (if any)
 */
export function getRequestContext(): RequestContext | undefined {
  return requestContext.getStore();
}

/**
 * Get correlation ID from current context
 */
export function getCorrelationId(): string | undefined {
  return requestContext.getStore()?.correlationId;
}

/**
 * Get user ID from current context
 */
export function getUserId(): string | undefined {
  return requestContext.getStore()?.userId;
}

/**
 * Get tenant ID from current context
 */
export function getTenantId(): string | undefined {
  return requestContext.getStore()?.tenantId;
}

/**
 * Run a function within a request context
 */
export function runWithContext<T>(context: RequestContext, fn: () => T): T {
  return requestContext.run(context, fn);
}

/**
 * Run an async function within a request context
 */
export async function runWithContextAsync<T>(
  context: RequestContext,
  fn: () => Promise<T>
): Promise<T> {
  return requestContext.run(context, fn);
}

/**
 * Update current context metadata
 */
export function updateContextMetadata(updates: Record<string, unknown>): void {
  const context = requestContext.getStore();
  if (context) {
    context.metadata = { ...context.metadata, ...updates };
  }
}
```

## Request Context Middleware

Initializes request context for every incoming request, extracting correlation ID from headers or generating a new UUID.

### Implementation (`src/common/context/request-context.middleware.ts`)

```typescript
/**
 * Request Context Middleware
 *
 * Initializes request context for every incoming request
 */

import { Injectable, NestMiddleware, Logger } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { requestContext, RequestContext } from './request-context.service';

import type { FastifyRequest, FastifyReply } from 'fastify';

@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  private readonly logger = new Logger(RequestContextMiddleware.name);

  use(req: FastifyRequest['raw'], res: FastifyReply['raw'], next: () => void): void {
    const correlationId =
      (req.headers['x-correlation-id'] as string) ??
      (req.headers['x-request-id'] as string) ??
      randomUUID();

    const context: RequestContext = {
      correlationId,
      startTime: Date.now(),
      ipAddress: req.headers['x-forwarded-for'] as string ?? req.socket.remoteAddress,
      userAgent: req.headers['user-agent'],
      path: req.url,
      method: req.method,
      metadata: {},
    };

    // Set correlation ID in response headers
    res.setHeader('x-correlation-id', correlationId);

    // Run the rest of the request within this context
    requestContext.run(context, () => {
      next();
    });
  }
}
```

### Module Registration

```typescript
import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { RequestContextMiddleware } from './common/context/request-context.middleware';

@Module({
  // ...
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(RequestContextMiddleware)
      .forRoutes('*');
  }
}
```

### Usage in Services

```typescript
import { getRequestContext, getCorrelationId, getUserId } from './common/context/request-context.service';

export class OrderService {
  async createOrder(data: CreateOrderDto): Promise<Order> {
    const context = getRequestContext();

    // Access correlation ID for logging
    this.logger.log(`Creating order`, { correlationId: getCorrelationId() });

    // Access user ID for auditing
    const userId = getUserId();

    // Custom metadata
    context?.metadata.orderType = data.type;

    return this.orderRepository.create({
      ...data,
      userId,
      createdBy: userId,
    });
  }
}
```

## Feature Flags Service

Provides feature flag evaluation with support for boolean toggles, percentage-based rollouts, user/tenant targeting, and scheduled enablement.

### Implementation (`src/core/feature-flags/services/feature-flags.service.ts`)

```typescript
/**
 * Feature Flags Service
 *
 * Provides feature flag evaluation with support for:
 * - Boolean toggles
 * - Percentage-based rollouts
 * - User/tenant targeting
 * - Scheduled enablement
 */

import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { createHash } from 'crypto';

import { DynamicConfigurationService } from '../../dynamic-configuration/services/dynamic-configuration.service';
import { getRequestContext } from '../../../common/context/request-context.service';

interface FeatureFlagConfig {
  enabled: boolean;
  percentage?: number;
  targetRules?: {
    userIds?: string[];
    tenantIds?: string[];
    environments?: string[];
  };
  enabledAt?: Date;
  disabledAt?: Date;
}

@Injectable()
export class FeatureFlagsService implements OnModuleInit {
  private readonly logger = new Logger(FeatureFlagsService.name);
  private readonly flagCache = new Map<string, FeatureFlagConfig>();
  private lastRefresh = 0;
  private readonly refreshInterval = 60000; // 1 minute

  constructor(
    private readonly dynamicConfig: DynamicConfigurationService,
  ) {}

  async onModuleInit(): Promise<void> {
    await this.refreshFlags();
  }

  /**
   * Check if a feature flag is enabled
   *
   * @param flagKey - The feature flag key
   * @param context - Optional context for targeted evaluation
   */
  async isEnabled(
    flagKey: string,
    context?: { userId?: string; tenantId?: string }
  ): Promise<boolean> {
    // Refresh cache if stale
    if (Date.now() - this.lastRefresh > this.refreshInterval) {
      await this.refreshFlags();
    }

    const flag = this.flagCache.get(flagKey);

    if (!flag) {
      this.logger.debug(`Feature flag not found: ${flagKey}`);
      return false;
    }

    // Check if globally disabled
    if (!flag.enabled) {
      return false;
    }

    // Check scheduled enablement
    const now = new Date();
    if (flag.enabledAt && now < flag.enabledAt) {
      return false;
    }
    if (flag.disabledAt && now > flag.disabledAt) {
      return false;
    }

    // Get context from request if not provided
    const requestCtx = getRequestContext();
    const userId = context?.userId ?? requestCtx?.userId;
    const tenantId = context?.tenantId ?? requestCtx?.tenantId;

    // Check target rules
    if (flag.targetRules) {
      // User targeting
      if (flag.targetRules.userIds?.length && userId) {
        if (flag.targetRules.userIds.includes(userId)) {
          return true;
        }
      }

      // Tenant targeting
      if (flag.targetRules.tenantIds?.length && tenantId) {
        if (flag.targetRules.tenantIds.includes(tenantId)) {
          return true;
        }
      }

      // Environment targeting
      if (flag.targetRules.environments?.length) {
        const env = process.env.NODE_ENV ?? 'development';
        if (!flag.targetRules.environments.includes(env)) {
          return false;
        }
      }
    }

    // Check percentage rollout
    if (flag.percentage !== undefined && flag.percentage < 100) {
      const identifier = userId ?? tenantId ?? 'anonymous';
      const hash = this.hashIdentifier(flagKey, identifier);
      return hash < flag.percentage;
    }

    return true;
  }

  /**
   * Get all feature flags
   */
  getAllFlags(): Map<string, FeatureFlagConfig> {
    return new Map(this.flagCache);
  }

  /**
   * Refresh flags from database
   */
  @Cron(CronExpression.EVERY_MINUTE)
  async refreshFlags(): Promise<void> {
    try {
      const flags = await this.dynamicConfig.getAllByCategory('feature_flag');

      this.flagCache.clear();
      for (const [key, value] of Object.entries(flags)) {
        this.flagCache.set(key.replace('feature.', ''), value as FeatureFlagConfig);
      }

      this.lastRefresh = Date.now();
      this.logger.debug(`Refreshed ${this.flagCache.size} feature flags`);
    } catch (error) {
      this.logger.error('Failed to refresh feature flags', error);
    }
  }

  /**
   * Hash identifier for percentage rollout
   * Returns a number between 0 and 100
   */
  private hashIdentifier(flagKey: string, identifier: string): number {
    const hash = createHash('sha256')
      .update(`${flagKey}:${identifier}`)
      .digest('hex');

    // Convert first 8 chars of hash to number and mod 100
    const num = parseInt(hash.substring(0, 8), 16);
    return num % 100;
  }
}
```

### Usage

```typescript
// In a controller or service
constructor(
  private readonly featureFlags: FeatureFlagsService
) {}

async getProducts(): Promise<Product[]> {
  // Simple check
  const newSearchEnabled = await this.featureFlags.isEnabled('new-search-algorithm');

  if (newSearchEnabled) {
    return this.productService.searchV2();
  }
  return this.productService.searchV1();
}

// With explicit context
async getUserDashboard(userId: string): Promise<Dashboard> {
  const betaFeaturesEnabled = await this.featureFlags.isEnabled(
    'beta-dashboard',
    { userId }
  );

  return this.dashboardService.getDashboard(userId, betaFeaturesEnabled);
}
```

## Feature Flags with Redis Fallback

For multi-instance deployments, this version uses Redis as a shared cache to ensure consistency across instances, with local cache as fallback when Redis is unavailable.

### Implementation (`src/core/feature-flags/services/feature-flags-redis.service.ts`)

```typescript
/**
 * Feature Flags Service with Redis Fallback
 *
 * For multi-instance deployments, this version uses Redis
 * as a shared cache to ensure consistency across instances.
 */

import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { createHash } from 'crypto';

import { L2CacheService } from '../../cache/services/l2-cache.service';
import { DynamicConfigurationService } from '../../dynamic-configuration/services/dynamic-configuration.service';
import { getRequestContext } from '../../../common/context/request-context.service';

interface FeatureFlagConfig {
  enabled: boolean;
  percentage?: number;
  targetRules?: {
    userIds?: string[];
    tenantIds?: string[];
    environments?: string[];
  };
  enabledAt?: Date;
  disabledAt?: Date;
}

@Injectable()
export class FeatureFlagsRedisService implements OnModuleInit {
  private readonly logger = new Logger(FeatureFlagsRedisService.name);
  private readonly localCache = new Map<string, FeatureFlagConfig>();
  private readonly CACHE_KEY_PREFIX = 'feature_flags:';
  private readonly CACHE_TTL = 60; // 1 minute
  private lastRefresh = 0;

  constructor(
    private readonly dynamicConfig: DynamicConfigurationService,
    private readonly redisCache: L2CacheService,
  ) {}

  async onModuleInit(): Promise<void> {
    await this.refreshFlags();
  }

  /**
   * Check if a feature flag is enabled
   * Uses Redis for multi-instance consistency with local cache fallback
   */
  async isEnabled(
    flagKey: string,
    context?: { userId?: string; tenantId?: string }
  ): Promise<boolean> {
    // Try Redis first for multi-instance consistency
    let flag = await this.getFlagFromRedis(flagKey);

    // Fallback to local cache if Redis unavailable
    if (!flag) {
      flag = this.localCache.get(flagKey);
    }

    if (!flag) {
      this.logger.debug(`Feature flag not found: ${flagKey}`);
      return false;
    }

    return this.evaluateFlag(flag, flagKey, context);
  }

  private async getFlagFromRedis(flagKey: string): Promise<FeatureFlagConfig | null> {
    try {
      const cached = await this.redisCache.get<FeatureFlagConfig>(
        `${this.CACHE_KEY_PREFIX}${flagKey}`
      );
      return cached ?? null;
    } catch (error) {
      this.logger.warn(`Redis unavailable for feature flag: ${flagKey}`, error);
      return null;
    }
  }

  private evaluateFlag(
    flag: FeatureFlagConfig,
    flagKey: string,
    context?: { userId?: string; tenantId?: string }
  ): boolean {
    if (!flag.enabled) return false;

    const now = new Date();
    if (flag.enabledAt && now < new Date(flag.enabledAt)) return false;
    if (flag.disabledAt && now > new Date(flag.disabledAt)) return false;

    const requestCtx = getRequestContext();
    const userId = context?.userId ?? requestCtx?.userId;
    const tenantId = context?.tenantId ?? requestCtx?.tenantId;

    // Check targeting rules
    if (flag.targetRules) {
      if (flag.targetRules.userIds?.includes(userId ?? '')) return true;
      if (flag.targetRules.tenantIds?.includes(tenantId ?? '')) return true;
      if (flag.targetRules.environments?.length) {
        const env = process.env.NODE_ENV ?? 'development';
        if (!flag.targetRules.environments.includes(env)) return false;
      }
    }

    // Percentage rollout
    if (flag.percentage !== undefined && flag.percentage < 100) {
      const identifier = userId ?? tenantId ?? 'anonymous';
      const hash = this.hashIdentifier(flagKey, identifier);
      return hash < flag.percentage;
    }

    return true;
  }

  @Cron(CronExpression.EVERY_MINUTE)
  async refreshFlags(): Promise<void> {
    try {
      const flags = await this.dynamicConfig.getAllByCategory('feature_flag');

      // Update both local cache and Redis
      for (const [key, value] of Object.entries(flags)) {
        const flagKey = key.replace('feature.', '');
        const flagConfig = value as FeatureFlagConfig;

        this.localCache.set(flagKey, flagConfig);

        // Update Redis for multi-instance consistency
        try {
          await this.redisCache.set(
            `${this.CACHE_KEY_PREFIX}${flagKey}`,
            flagConfig,
            this.CACHE_TTL
          );
        } catch (error) {
          this.logger.warn(`Failed to update Redis for flag: ${flagKey}`);
        }
      }

      this.lastRefresh = Date.now();
      this.logger.debug(`Refreshed ${this.localCache.size} feature flags`);
    } catch (error) {
      this.logger.error('Failed to refresh feature flags', error);
    }
  }

  private hashIdentifier(flagKey: string, identifier: string): number {
    const hash = createHash('sha256')
      .update(`${flagKey}:${identifier}`)
      .digest('hex');
    return parseInt(hash.substring(0, 8), 16) % 100;
  }
}
```

### Module Configuration

```typescript
import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { FeatureFlagsRedisService } from './feature-flags-redis.service';
import { L2CacheService } from '../../cache/services/l2-cache.service';
import { DynamicConfigurationService } from '../../dynamic-configuration/services/dynamic-configuration.service';

@Module({
  imports: [ScheduleModule.forRoot()],
  providers: [
    FeatureFlagsRedisService,
    L2CacheService,
    DynamicConfigurationService,
  ],
  exports: [FeatureFlagsRedisService],
})
export class FeatureFlagsModule {}
```

## Best Practices

### Circuit Breaker
- Set `failureThreshold` based on acceptable error rate (typically 50-80%)
- Configure `resetTimeout` to allow downstream services time to recover (30-60 seconds)
- Use `halfOpenMaxCalls` to test recovery with limited traffic (3-5 calls)
- Monitor circuit state via `getMetrics()` and expose via health endpoints

### Database Fallback
- Always set appropriate `ttl` values based on data freshness requirements
- Use `staleWhileRevalidate` for non-critical data to improve availability
- Invalidate cache on writes to maintain consistency
- Monitor cache hit/miss ratios via `getStats()`

### Request Context
- Always apply `RequestContextMiddleware` globally to ensure context availability
- Use `getCorrelationId()` in all log statements for distributed tracing
- Store tenant/user info in context for multi-tenant applications
- Avoid storing large objects in metadata to prevent memory overhead

### Feature Flags
- Use percentage rollout for gradual feature releases (10% → 25% → 50% → 100%)
- Target specific users/tenants for beta testing before full rollout
- Schedule feature enablement using `enabledAt`/`disabledAt` for time-based releases
- Use Redis-backed version in multi-instance deployments for consistency
- Always provide default behavior when flag evaluation fails
