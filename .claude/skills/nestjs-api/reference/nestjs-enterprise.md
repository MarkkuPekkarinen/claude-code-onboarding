# NestJS Enterprise Patterns

Enterprise patterns for NestJS 11.x covering exception handling, security, rate limiting, health checks, Swagger, and validation.

## Exception Hierarchy

### Base Exception

```typescript
// src/common/exceptions/base.exception.ts
import { HttpException, HttpStatus } from '@nestjs/common';

export class BaseException extends HttpException {
  constructor(
    public readonly errorCode: string,
    message: string,
    status: HttpStatus,
    public readonly details?: Record<string, unknown>,
  ) {
    super({ errorCode, message, details }, status);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}
```

### Concrete Exceptions

```typescript
// src/common/exceptions/business.exception.ts
import { HttpStatus } from '@nestjs/common';
import { BaseException } from './base.exception';

export class BusinessException extends BaseException {
  constructor(
    errorCode: string,
    message: string,
    details?: Record<string, unknown>,
  ) {
    super(errorCode, message, HttpStatus.UNPROCESSABLE_ENTITY, details);
  }
}

// src/common/exceptions/validation.exception.ts
export class ValidationException extends BaseException {
  constructor(
    message: string,
    errors: string[] = [],
    details?: Record<string, unknown>,
  ) {
    super(
      'VALIDATION_ERROR',
      message,
      HttpStatus.BAD_REQUEST,
      { ...details, errors },
    );
  }
}

// src/common/exceptions/not-found.exception.ts
export class NotFoundException extends BaseException {
  constructor(resource: string, identifier: string | number) {
    super(
      'RESOURCE_NOT_FOUND',
      `${resource} with ID ${identifier} not found`,
      HttpStatus.NOT_FOUND,
      { resource, identifier },
    );
  }
}

// src/common/exceptions/database.exception.ts
export class DatabaseException extends BaseException {
  constructor(message: string, cause?: Error) {
    super(
      'DATABASE_ERROR',
      message,
      HttpStatus.SERVICE_UNAVAILABLE,
      { cause: cause?.message },
    );
  }
}

// src/common/exceptions/static-configuration.exception.ts
// Used by static config reader for fail-fast startup validation
export class StaticConfigurationException extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'StaticConfigurationException';
  }

  static missingEnvVar(key: string): StaticConfigurationException {
    return new StaticConfigurationException(
      `Missing required environment variable: ${key}`,
    );
  }

  static invalidEnvVar(
    key: string,
    value: string,
    expected: string,
  ): StaticConfigurationException {
    return new StaticConfigurationException(
      `Invalid environment variable ${key}="${value}". Expected: ${expected}`,
    );
  }
}
```

## Global Exception Filter

Creates RFC 9457 ProblemDetail responses for all errors.

```typescript
// src/common/filters/global-exception.filter.ts
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { FastifyReply, FastifyRequest } from 'fastify';
import { PrismaClientKnownRequestError } from '@prisma/client/runtime/library';
import { BaseException } from '../exceptions/base.exception';
import { getCorrelationId } from '../context/request-context.service';

interface ProblemDetail {
  type: string;
  title: string;
  status: number;
  detail: string;
  instance: string;
  errorCode?: string;
  correlationId?: string;
  timestamp: string;
  errors?: string[];
}

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const request = ctx.getRequest<FastifyRequest>();
    const reply = ctx.getResponse<FastifyReply>();

    const correlationId = getCorrelationId() ?? 'unknown';
    const instance = request.url;
    const timestamp = new Date().toISOString();

    let problemDetail: ProblemDetail;

    // Handle custom BaseException
    if (exception instanceof BaseException) {
      problemDetail = this.handleBaseException(
        exception,
        instance,
        correlationId,
        timestamp,
      );
    }
    // Handle Prisma errors
    else if (exception instanceof PrismaClientKnownRequestError) {
      problemDetail = this.handlePrismaError(
        exception,
        instance,
        correlationId,
        timestamp,
      );
    }
    // Handle NestJS HttpException
    else if (exception instanceof HttpException) {
      problemDetail = this.handleHttpException(
        exception,
        instance,
        correlationId,
        timestamp,
      );
    }
    // Handle unknown errors
    else {
      problemDetail = this.handleUnknownError(
        exception,
        instance,
        correlationId,
        timestamp,
      );
    }

    // Log error
    this.logError(request, problemDetail, exception);

    // Send response
    reply.status(problemDetail.status).send(problemDetail);
  }

  private handleBaseException(
    exception: BaseException,
    instance: string,
    correlationId: string,
    timestamp: string,
  ): ProblemDetail {
    const response = exception.getResponse() as {
      errorCode: string;
      message: string;
      details?: Record<string, unknown>;
    };

    return {
      type: 'about:blank',
      title: this.getHttpStatusText(exception.getStatus()),
      status: exception.getStatus(),
      detail: response.message,
      instance,
      errorCode: response.errorCode,
      correlationId,
      timestamp,
      ...(response.details?.errors && { errors: response.details.errors as string[] }),
    };
  }

  private handlePrismaError(
    exception: PrismaClientKnownRequestError,
    instance: string,
    correlationId: string,
    timestamp: string,
  ): ProblemDetail {
    let status: HttpStatus;
    let errorCode: string;
    let detail: string;

    switch (exception.code) {
      case 'P2002':
        // Unique constraint violation
        status = HttpStatus.CONFLICT;
        errorCode = 'DUPLICATE_RECORD';
        const field = (exception.meta?.target as string[])?.join(', ') ?? 'field';
        detail = `A record with this ${field} already exists`;
        break;

      case 'P2025':
        // Record not found
        status = HttpStatus.NOT_FOUND;
        errorCode = 'RECORD_NOT_FOUND';
        detail = exception.meta?.cause as string ?? 'Record not found';
        break;

      case 'P2003':
        // Foreign key constraint violation
        status = HttpStatus.BAD_REQUEST;
        errorCode = 'FOREIGN_KEY_VIOLATION';
        detail = 'Referenced record does not exist';
        break;

      default:
        status = HttpStatus.INTERNAL_SERVER_ERROR;
        errorCode = 'DATABASE_ERROR';
        detail = 'A database error occurred';
    }

    return {
      type: 'about:blank',
      title: this.getHttpStatusText(status),
      status,
      detail,
      instance,
      errorCode,
      correlationId,
      timestamp,
    };
  }

  private handleHttpException(
    exception: HttpException,
    instance: string,
    correlationId: string,
    timestamp: string,
  ): ProblemDetail {
    const status = exception.getStatus();
    const response = exception.getResponse();

    let detail: string;
    let errors: string[] | undefined;

    if (typeof response === 'string') {
      detail = response;
    } else if (typeof response === 'object' && response !== null) {
      const responseObj = response as Record<string, unknown>;
      detail = (responseObj.message as string) ?? exception.message;

      // Handle class-validator errors
      if (Array.isArray(responseObj.message)) {
        errors = responseObj.message as string[];
        detail = 'Validation failed';
      }
    } else {
      detail = exception.message;
    }

    return {
      type: 'about:blank',
      title: this.getHttpStatusText(status),
      status,
      detail,
      instance,
      errorCode: 'HTTP_ERROR',
      correlationId,
      timestamp,
      ...(errors && { errors }),
    };
  }

  private handleUnknownError(
    exception: unknown,
    instance: string,
    correlationId: string,
    timestamp: string,
  ): ProblemDetail {
    const error = exception instanceof Error ? exception : new Error(String(exception));

    return {
      type: 'about:blank',
      title: 'Internal Server Error',
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      detail: 'An unexpected error occurred',
      instance,
      errorCode: 'INTERNAL_ERROR',
      correlationId,
      timestamp,
    };
  }

  private logError(
    request: FastifyRequest,
    problemDetail: ProblemDetail,
    exception: unknown,
  ): void {
    const logContext = {
      method: request.method,
      url: request.url,
      correlationId: problemDetail.correlationId,
      errorCode: problemDetail.errorCode,
      status: problemDetail.status,
    };

    if (problemDetail.status >= 500) {
      this.logger.error(
        `${request.method} ${request.url} ${problemDetail.status}`,
        exception instanceof Error ? exception.stack : String(exception),
        logContext,
      );
    } else {
      this.logger.warn(
        `${request.method} ${request.url} ${problemDetail.status} - ${problemDetail.detail}`,
        logContext,
      );
    }
  }

  private getHttpStatusText(status: number): string {
    const statusTexts: Record<number, string> = {
      400: 'Bad Request',
      401: 'Unauthorized',
      403: 'Forbidden',
      404: 'Not Found',
      409: 'Conflict',
      422: 'Unprocessable Entity',
      500: 'Internal Server Error',
      502: 'Bad Gateway',
      503: 'Service Unavailable',
    };

    return statusTexts[status] ?? 'Error';
  }
}
```

## Security Middleware (Helmet)

Comprehensive security headers including CSP, HSTS, CORP, COEP, COOP.

```typescript
// src/common/middleware/security.middleware.ts
/**
 * Security Middleware Configuration
 *
 * Implements comprehensive security headers including:
 * - Content Security Policy (CSP)
 * - HTTP Strict Transport Security (HSTS)
 * - Cross-Origin Resource Policy (CORP)
 * - Cross-Origin Embedder Policy (COEP)
 * - Cross-Origin Opener Policy (COOP)
 */

import helmet from '@fastify/helmet';
import compression from '@fastify/compress';
import type { NestFastifyApplication } from '@nestjs/platform-fastify';
import type { MiddlewareConfigurationService } from './config/middleware-configuration.service';

export async function registerSecurityMiddleware(
  app: NestFastifyApplication,
  config: MiddlewareConfigurationService,
): Promise<void> {
  const environment = config.getEnvironment();
  const isProduction = environment === 'production';

  // Compression middleware
  await app.register(compression, {
    encodings: ['gzip', 'deflate'],
    threshold: 1024, // Only compress responses > 1KB
  });

  // Helmet security middleware with comprehensive headers
  await app.register(helmet, {
    // Content Security Policy
    contentSecurityPolicy: isProduction
      ? {
          directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"], // Swagger UI needs inline styles
            imgSrc: ["'self'", 'data:', 'https:'],
            fontSrc: ["'self'", 'https:', 'data:'],
            connectSrc: ["'self'"],
            objectSrc: ["'none'"],
            mediaSrc: ["'self'"],
            frameSrc: ["'none'"],
            baseUri: ["'self'"],
            formAction: ["'self'"],
            frameAncestors: ["'none'"],
            upgradeInsecureRequests: [],
          },
        }
      : false, // Disable CSP in development for easier debugging

    // Cross-Origin Embedder Policy
    crossOriginEmbedderPolicy: isProduction ? { policy: 'require-corp' } : false,

    // Cross-Origin Opener Policy
    crossOriginOpenerPolicy: { policy: 'same-origin' },

    // Cross-Origin Resource Policy
    crossOriginResourcePolicy: { policy: 'same-origin' },

    // DNS Prefetch Control
    dnsPrefetchControl: { allow: false },

    // Frameguard (X-Frame-Options)
    frameguard: { action: 'deny' },

    // Hide Powered By
    hidePoweredBy: true,

    // HTTP Strict Transport Security
    hsts: isProduction
      ? {
          maxAge: 31536000, // 1 year
          includeSubDomains: true,
          preload: true,
        }
      : false,

    // IE No Open
    ieNoOpen: true,

    // No Sniff (X-Content-Type-Options)
    noSniff: true,

    // Origin Agent Cluster
    originAgentCluster: true,

    // Permitted Cross-Domain Policies
    permittedCrossDomainPolicies: { permittedPolicies: 'none' },

    // Referrer Policy
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' },

    // X-XSS-Protection (legacy, but still useful for older browsers)
    xssFilter: true,
  });
}
```

## Rate Limiting (ThrottlerModule)

Multi-tier rate limiting with short, medium, and long windows.

```typescript
// src/app.module.ts (excerpt)
import { ThrottlerModule, ThrottlerModuleOptions } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService): ThrottlerModuleOptions => {
        const config = configService.get<IThrottlerConfig>('throttler');

        if (!config) {
          throw new Error('Throttler configuration is missing');
        }

        return {
          throttlers: [
            { name: 'short', ttl: config.short.ttl, limit: config.short.limit },
            { name: 'medium', ttl: config.medium.ttl, limit: config.medium.limit },
            { name: 'long', ttl: config.long.ttl, limit: config.long.limit },
          ],
        };
      },
    }),
  ],
})
export class AppModule {}
```

```typescript
// src/config/throttler.config.ts
import { registerAs } from '@nestjs/config';

export interface IThrottlerConfig {
  short: { ttl: number; limit: number };
  medium: { ttl: number; limit: number };
  long: { ttl: number; limit: number };
}

export default registerAs(
  'throttler',
  (): IThrottlerConfig => ({
    short: {
      ttl: 1000, // 1 second
      limit: 10, // 10 requests per second
    },
    medium: {
      ttl: 10000, // 10 seconds
      limit: 50, // 50 requests per 10 seconds
    },
    long: {
      ttl: 60000, // 60 seconds
      limit: 200, // 200 requests per minute
    },
  }),
);
```

## Swagger / OpenAPI Setup

Complete Swagger documentation with authentication and versioning.

```typescript
// src/main.ts (excerpt)
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter(),
  );

  const config = app.get(ConfigService);
  const port = config.get<number>('application.port', 3000);
  const apiPrefix = config.get<string>('application.apiPrefix', 'api');
  const version = config.get<string>('application.version', '1.0.0');
  const enableSwagger = config.get<boolean>('application.enableSwagger', true);
  const swaggerPath = config.get<string>('application.swaggerPath', 'api/docs');

  app.setGlobalPrefix(apiPrefix);

  // Swagger API documentation
  if (enableSwagger === true) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('NestJS API')
      .setDescription('Enterprise-grade REST API built with NestJS 11.x')
      .setVersion(version)
      .addBearerAuth()
      .addServer(`http://localhost:${port}`, 'Local Development')
      .addServer('https://api.staging.example.com', 'Staging')
      .addServer('https://api.example.com', 'Production')
      .addTag('health', 'Health check endpoints')
      .addTag('auth', 'Authentication endpoints')
      .addTag('users', 'User management')
      .build();

    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup(swaggerPath ?? 'api/docs', app, document, {
      swaggerOptions: {
        persistAuthorization: true,
        displayRequestDuration: true,
        filter: true,
        showExtensions: true,
      },
    });

    console.log(`Swagger documentation available at: http://localhost:${port}/${swaggerPath}`);
  }

  await app.listen(port, '0.0.0.0');
}

bootstrap();
```

## Health Checks (Terminus)

Kubernetes-ready health checks with liveness, readiness, and startup probes.

```typescript
// src/core/health/controllers/health.controller.ts
import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import {
  HealthCheck,
  HealthCheckService,
  HealthCheckResult,
  MemoryHealthIndicator,
  DiskHealthIndicator,
} from '@nestjs/terminus';
import { DatabaseHealthIndicator } from '../indicators/database.health-indicator';
import { RedisHealthIndicator } from '../indicators/redis.health-indicator';
import { ApplicationHealthIndicator } from '../indicators/application.health-indicator';

@Controller('health')
@ApiTags('health')
export class HealthController {
  private startupComplete = false;
  private startupTime: Date | null = null;

  constructor(
    private readonly health: HealthCheckService,
    private readonly memory: MemoryHealthIndicator,
    private readonly disk: DiskHealthIndicator,
    private readonly database: DatabaseHealthIndicator,
    private readonly redis: RedisHealthIndicator,
    private readonly application: ApplicationHealthIndicator,
  ) {}

  /**
   * Liveness probe - Is the application running?
   * Should return 200 if the app is alive (even if dependencies are down)
   */
  @Get('live')
  @HealthCheck()
  @ApiOperation({ summary: 'Liveness probe - is the application running?' })
  @ApiResponse({ status: 200, description: 'Application is alive' })
  @ApiResponse({ status: 503, description: 'Application is not responding' })
  async checkLive(): Promise<HealthCheckResult> {
    return this.health.check([
      // Only check if the process is running and has enough memory
      () => this.memory.checkHeap('memory_heap', 500 * 1024 * 1024), // 500MB
    ]);
  }

  /**
   * Readiness probe - Can the application accept traffic?
   * Should return 200 only if all dependencies are healthy
   */
  @Get('ready')
  @HealthCheck()
  @ApiOperation({ summary: 'Readiness probe - can the application accept traffic?' })
  @ApiResponse({ status: 200, description: 'Application is ready to accept traffic' })
  @ApiResponse({ status: 503, description: 'Application is not ready' })
  async checkReady(): Promise<HealthCheckResult> {
    return this.health.check([
      () => this.database.isHealthy('database'),
      () => this.redis.isHealthy('redis'),
      () => this.application.isHealthy('application'),
    ]);
  }

  /**
   * Startup probe - Has the application finished initializing?
   * Kubernetes uses this to know when to start liveness/readiness checks
   */
  @Get('startup')
  @HealthCheck()
  @ApiOperation({ summary: 'Startup probe - has the application finished initializing?' })
  @ApiResponse({ status: 200, description: 'Application startup complete' })
  @ApiResponse({ status: 503, description: 'Application still starting up' })
  async checkStartup(): Promise<HealthCheckResult> {
    if (!this.startupComplete) {
      return {
        status: 'error',
        info: {},
        error: {
          startup: {
            status: 'down',
            message: 'Application still starting up',
          },
        },
        details: {},
      };
    }

    return {
      status: 'ok',
      info: {
        startup: {
          status: 'up',
          startupTime: this.startupTime?.toISOString(),
        },
      },
      error: {},
      details: {
        startup: {
          status: 'up',
          startupTime: this.startupTime?.toISOString(),
        },
      },
    };
  }

  /**
   * Mark application as fully started
   */
  markStartupComplete(): void {
    this.startupComplete = true;
    this.startupTime = new Date();
  }

  /**
   * Detailed health check for monitoring dashboards
   */
  @Get()
  @HealthCheck()
  @ApiOperation({ summary: 'Full health check with all indicators' })
  async checkAll(): Promise<HealthCheckResult> {
    return this.health.check([
      () => this.memory.checkHeap('memory_heap', 500 * 1024 * 1024),
      () => this.memory.checkRSS('memory_rss', 1024 * 1024 * 1024), // 1GB
      () => this.database.isHealthy('database'),
      () => this.redis.isHealthy('redis'),
      () => this.application.isHealthy('application'),
    ]);
  }
}
```

### Custom Health Indicators

```typescript
// src/core/health/indicators/database.health-indicator.ts
import { Injectable } from '@nestjs/common';
import { HealthIndicator, HealthIndicatorResult, HealthCheckError } from '@nestjs/terminus';
import { PrismaService } from '../../database/services/prisma.service';

@Injectable()
export class DatabaseHealthIndicator extends HealthIndicator {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return this.getStatus(key, true, { status: 'up' });
    } catch (error) {
      throw new HealthCheckError(
        'Database check failed',
        this.getStatus(key, false, { status: 'down', error: error.message }),
      );
    }
  }
}

// src/core/health/indicators/redis.health-indicator.ts
import { Injectable } from '@nestjs/common';
import { HealthIndicator, HealthIndicatorResult, HealthCheckError } from '@nestjs/terminus';
import { RedisService } from '../../cache/services/redis.service';

@Injectable()
export class RedisHealthIndicator extends HealthIndicator {
  constructor(private readonly redis: RedisService) {
    super();
  }

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    try {
      await this.redis.ping();
      return this.getStatus(key, true, { status: 'up' });
    } catch (error) {
      throw new HealthCheckError(
        'Redis check failed',
        this.getStatus(key, false, { status: 'down', error: error.message }),
      );
    }
  }
}

// src/core/health/indicators/application.health-indicator.ts
import { Injectable } from '@nestjs/common';
import { HealthIndicator, HealthIndicatorResult } from '@nestjs/terminus';

@Injectable()
export class ApplicationHealthIndicator extends HealthIndicator {
  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    return this.getStatus(key, true, {
      name: 'application',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    });
  }
}
```

## Validation Pipe Configuration

Global validation with class-validator and class-transformer.

```typescript
// src/app.module.ts (excerpt)
import { Module, ValidationPipe } from '@nestjs/common';
import { APP_PIPE } from '@nestjs/core';

@Module({
  providers: [
    {
      provide: APP_PIPE,
      useFactory: (configService: ConfigService) => {
        const environment = configService.get<string>('application.environment');
        return new ValidationPipe({
          whitelist: true, // Strip unknown properties
          forbidNonWhitelisted: true, // Throw error on unknown properties
          transform: true, // Auto-transform payloads to DTO instances
          transformOptions: {
            enableImplicitConversion: true, // Convert primitive types
          },
          disableErrorMessages: environment === 'production', // Hide details in prod
          forbidUnknownValues: true, // Reject unknown object values
          validationError: {
            target: false, // Don't expose target object in errors
            value: false, // Don't expose value in errors (security)
          },
        });
      },
      inject: [ConfigService],
    },
  ],
})
export class AppModule {}
```

## API Versioning

URI-based versioning for backward compatibility.

```typescript
// src/main.ts (excerpt)
import { VersioningType } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter(),
  );

  // Enable URI versioning
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
    prefix: 'v',
  });

  await app.listen(3000);
}

bootstrap();
```

### Using Versioning in Controllers

```typescript
// src/features/users/controllers/users-v1.controller.ts
import { Controller, Get, Version } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

@Controller({ path: 'users', version: '1' })
@ApiTags('users')
export class UsersControllerV1 {
  @Get()
  findAll() {
    return { message: 'Users v1' };
  }
}

// src/features/users/controllers/users-v2.controller.ts
@Controller({ path: 'users', version: '2' })
@ApiTags('users')
export class UsersControllerV2 {
  @Get()
  findAll() {
    return { message: 'Users v2 with enhanced response' };
  }
}
```

URLs:
- `/v1/users` - Version 1
- `/v2/users` - Version 2

## Usage Notes

1. **Exception Handling**: All exceptions are caught by GlobalExceptionFilter and converted to RFC 9457 ProblemDetail format
2. **Prisma Errors**: Automatic handling of P2002 (unique constraint), P2025 (not found), P2003 (foreign key)
3. **Security**: Helmet middleware provides comprehensive security headers, disabled CSP in development
4. **Rate Limiting**: Three-tier throttling (short/medium/long windows) prevents abuse
5. **Health Checks**: Kubernetes-ready probes (liveness/readiness/startup) for zero-downtime deployments
6. **Validation**: Global ValidationPipe with whitelist and transform enabled, hiding errors in production
7. **Versioning**: URI-based versioning (`/v1/`, `/v2/`) with default version fallback
