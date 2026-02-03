# NestJS Code Templates

Production-ready code templates for NestJS 11.x with Fastify adapter, module aggregation, and feature modules.

## Main Entry Point (src/main.ts)

```typescript
/**
 * my-service - Main Application Entry Point
 *
 * NestJS backend service
 *
 * NestJS 11.x with enhanced shutdown hooks and logging
 */

import 'dotenv/config';
import { readFileSync } from 'fs';
import { join } from 'path';

import { Logger, VersioningType, LogLevel } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter } from '@nestjs/platform-fastify';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

import { AppModule } from './app.module';
import { MiddlewareConfigurationService } from './common/middleware/config/middleware-configuration.service';
import { registerSecurityMiddleware } from './common/middleware/security.middleware';
import { requestContext } from './common/context/request-context.service';

import type { NestFastifyApplication } from '@nestjs/platform-fastify';

interface IPackageJson {
  version?: string;
  name?: string;
}

let app: NestFastifyApplication | null = null;

/**
 * Determine log levels based on environment
 */
function getLogLevels(environment: string): LogLevel[] {
  if (environment === 'production') {
    return ['error', 'warn', 'log'];
  }
  if (environment === 'test') {
    return ['error', 'warn'];
  }
  return ['error', 'warn', 'log', 'debug', 'verbose'];
}

async function bootstrap(): Promise<void> {
  // NestJS 11.x: Enhanced Logger with timestamp option
  const logger = new Logger('Bootstrap', { timestamp: true });

  logger.log('Starting my-service with STRICT configuration mode');

  // Read version from package.json
  let version = '0.0.0';
  let serviceName = 'my-service';
  try {
    const packageJsonPath = join(process.cwd(), 'package.json');
    const packageJsonContent = readFileSync(packageJsonPath, 'utf8');
    const packageJson = JSON.parse(packageJsonContent) as unknown as IPackageJson;
    version = packageJson.version ?? '0.0.0';
    serviceName = packageJson.name ?? 'my-service';
  } catch (error) {
    logger.error('Failed to read version from package.json', error);
    throw new Error('Package.json must be accessible for version information');
  }

  // Determine environment early for log levels
  const nodeEnv = process.env.NODE_ENV ?? 'development';

  try {
    // Create NestJS application with Fastify adapter
    app = await NestFactory.create<NestFastifyApplication>(
      AppModule,
      new FastifyAdapter({
        logger: false,
        trustProxy: true,
        maxParamLength: 500,
        bodyLimit: 1048576, // 1MB
        keepAliveTimeout: 72000,
        connectionTimeout: 10000,
        caseSensitive: false,
        ignoreTrailingSlash: true,
        // Fastify request ID for correlation
        genReqId: (req) => {
          return req.headers['x-correlation-id'] as string ?? crypto.randomUUID();
        },
      }),
      {
        // NestJS 11.x: Configure log levels at creation
        logger: getLogLevels(nodeEnv),
        bufferLogs: true, // Buffer logs until logger is ready
      },
    );

    // Use buffered logger
    app.useLogger(app.get(Logger));

    const configService = app.get(ConfigService);

    // STRICT MODE: Validate required configuration
    const port = configService.get<number>('application.port');
    const environment = configService.get<string>('application.environment');
    const apiPrefix = configService.get<string>('application.apiPrefix');
    const enableSwagger = configService.get<boolean>('application.enableSwagger');
    const swaggerPath = configService.get<string>('application.swaggerPath');

    if (port === undefined) {
      throw new Error('Missing required configuration: PORT');
    }
    if (!environment) {
      throw new Error('Missing required configuration: NODE_ENV');
    }
    if (!apiPrefix) {
      throw new Error('Missing required configuration: API_PREFIX');
    }

    // Security & Performance middleware
    const middlewareConfigService = app.get(MiddlewareConfigurationService);
    await registerSecurityMiddleware(app, middlewareConfigService);

    // CORS configuration
    const corsOrigins = configService.get<string[]>('security.cors.origins');
    const corsCredentials = configService.get<boolean>('security.cors.credentials');

    if (!corsOrigins || corsOrigins.length === 0) {
      throw new Error('Missing required configuration: SECURITY_CORS_ORIGINS');
    }

    app.enableCors({
      origin: corsOrigins,
      credentials: corsCredentials ?? true,
      methods: configService.get<string[]>('security.cors.methods'),
      allowedHeaders: configService.get<string[]>('security.cors.allowedHeaders'),
      exposedHeaders: configService.get<string[]>('security.cors.exposedHeaders'),
      maxAge: configService.get<number>('security.cors.maxAge'),
    });

    // NestJS 11.x: More explicit shutdown hooks with signal array
    app.enableShutdownHooks(['SIGTERM', 'SIGINT', 'SIGUSR2']);

    // API Versioning
    app.enableVersioning({
      type: VersioningType.URI,
      defaultVersion: '1',
      prefix: 'v',
    });

    app.setGlobalPrefix(apiPrefix);

    // Swagger API documentation
    if (enableSwagger === true) {
      const config = new DocumentBuilder()
        .setTitle('my-service API')
        .setDescription('NestJS backend service')
        .setVersion(version)
        .addBearerAuth()
        .addServer(`http://localhost:${port}`, 'Local Development')
        .addTag('health', 'Health check endpoints')
        .addTag('config', 'Configuration management')
        .build();

      const document = SwaggerModule.createDocument(app, config);
      SwaggerModule.setup(swaggerPath ?? 'api/docs', app, document, {
        swaggerOptions: {
          persistAuthorization: true,
          displayRequestDuration: true,
          filter: true,
          showExtensions: true,
        },
        customSiteTitle: `${serviceName} API Documentation`,
      });

      logger.log(`API Documentation available at http://localhost:${port}/${swaggerPath}`);
    }

    // Start the application
    await app.listen(port, '0.0.0.0', () => {
      logger.log(`Server is listening on all network interfaces`);
    });

    logger.log(`my-service started successfully`);
    logger.log(`Server running on http://localhost:${port}`);
    logger.log(`Environment: ${environment}`);
    logger.log(`API Prefix: /${apiPrefix}/v1`);
    logger.log(`Version: ${version}`);

  } catch (error) {
    logger.error('Failed to start my-service', error);
    if (app) {
      await app.close();
    }
    process.exit(1);
  }
}

async function gracefulShutdown(signal: string): Promise<void> {
  const logger = new Logger('GracefulShutdown', { timestamp: true });
  logger.log(`Received ${signal} signal. Starting graceful shutdown...`);

  if (app) {
    try {
      const shutdownTimeout = setTimeout(() => {
        logger.error('Graceful shutdown timeout (10s) - forcing exit');
        process.exit(1);
      }, 10000);

      // Flush any pending logs/metrics
      logger.log('Flushing pending operations...');

      await app.close();
      clearTimeout(shutdownTimeout);
      logger.log('Application closed successfully');
    } catch (error) {
      logger.error('Error during graceful shutdown', error);
      process.exit(1);
    }
  }

  process.exit(0);
}

function registerProcessHandlers(): void {
  const logger = new Logger('ProcessHandlers', { timestamp: true });

  process.on('uncaughtException', (error: Error, origin: string) => {
    logger.error(`Uncaught Exception (${origin}):`, error);
    // Allow some time for logging before exit
    setTimeout(() => process.exit(1), 1000);
  });

  process.on('unhandledRejection', (reason: unknown, promise: Promise<unknown>) => {
    logger.error('Unhandled Rejection at:', promise);
    logger.error('Reason:', reason);
    // Allow some time for logging before exit
    setTimeout(() => process.exit(1), 1000);
  });

  // Note: SIGTERM/SIGINT/SIGUSR2 handled by app.enableShutdownHooks()
  // These are fallbacks if app is not yet initialized
  process.on('SIGTERM', () => void gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => void gracefulShutdown('SIGINT'));
  process.on('SIGUSR2', () => void gracefulShutdown('SIGUSR2'));
}

registerProcessHandlers();
void bootstrap();
```

## Root Module (src/app.module.ts)

```typescript
/**
 * my-service - Root Application Module
 *
 * Architecture Pattern: Module Aggregation
 * - ConfigModule aggregates all configuration files
 * - CommonModule aggregates all common utilities
 * - CoreModule aggregates all core infrastructure
 * - FeaturesModule aggregates all business feature modules
 */
import { Module, ValidationPipe, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { APP_FILTER, APP_INTERCEPTOR, APP_PIPE } from '@nestjs/core';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { ScheduleModule } from '@nestjs/schedule';
import { TerminusModule } from '@nestjs/terminus';
import { ThrottlerModule, ThrottlerModuleOptions } from '@nestjs/throttler';

// Aggregated modules
import { AuthModule } from './auth/auth.module';
import { CommonModule } from './common/common.module';
import { GlobalExceptionFilter } from './common/filters/global-exception.filter';
import { LoggingInterceptor } from './common/interceptors/implementations/logging.interceptor';
import { TransformInterceptor } from './common/interceptors/implementations/transform.interceptor';
import { ConfigModule } from './config/config.module';
import { CoreModule } from './core/core.module';
import { FeaturesModule } from './features/features.module';

interface IThrottlerConfig {
  short: { ttl: number; limit: number };
  medium: { ttl: number; limit: number };
  long: { ttl: number; limit: number };
}

@Module({
  imports: [
    // Configuration Module - Aggregates ALL configuration files
    ConfigModule,

    // Core NestJS modules
    ScheduleModule.forRoot(),
    EventEmitterModule.forRoot({
      wildcard: true,
      delimiter: '.',
      newListener: false,
      removeListener: false,
      maxListeners: 50,
      verboseMemoryLeak: true,
      ignoreErrors: false,
    }),
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService): ThrottlerModuleOptions => {
        const config = configService.get<IThrottlerConfig>('throttler');

        if (!config) {
          throw new Error('Throttler configuration is missing');
        }

        return [
          { name: 'short', ttl: config.short.ttl, limit: config.short.limit },
          { name: 'medium', ttl: config.medium.ttl, limit: config.medium.limit },
          { name: 'long', ttl: config.long.ttl, limit: config.long.limit },
        ];
      },
    }),
    TerminusModule,

    // Core infrastructure modules
    CommonModule,
    CoreModule,

    // Business Features
    FeaturesModule,

    // Cross-cutting concerns
    AuthModule,
  ],
  providers: [
    // Global exception filter
    {
      provide: APP_FILTER,
      useClass: GlobalExceptionFilter,
    },
    // Global validation pipe
    {
      provide: APP_PIPE,
      useFactory: (configService: ConfigService) => {
        const environment = configService.get<string>('application.environment');
        return new ValidationPipe({
          whitelist: true,
          forbidNonWhitelisted: true,
          transform: true,
          transformOptions: {
            enableImplicitConversion: true,
            enableCircularCheck: true,
          },
          disableErrorMessages: environment === 'production',
          forbidUnknownValues: true,
          stopAtFirstError: false,
          validationError: {
            target: false,
            value: environment !== 'production',
          },
        });
      },
      inject: [ConfigService],
    },
    // Global interceptors
    { provide: APP_INTERCEPTOR, useClass: LoggingInterceptor },
    { provide: APP_INTERCEPTOR, useClass: TransformInterceptor },
  ],
})
export class AppModule implements OnModuleInit {
  private readonly logger = new Logger(AppModule.name);

  public onModuleInit(): void {
    this.logger.log('my-service Application Module initialized');
    this.logger.log('Architecture: ConfigModule → CommonModule → CoreModule → FeaturesModule → AuthModule');
  }
}
```

## Core Module (src/core/core.module.ts)

```typescript
import { Global, Module, Logger, OnModuleInit } from '@nestjs/common';

import { ApiModule } from './api/api.module';
import { CacheModule } from './cache/cache.module';
import { DatabaseModule } from './database/database.module';
import { DynamicConfigurationModule } from './dynamic-configuration/dynamic-configuration.module';
import { HealthModule } from './health/health.module';
import { ResilienceModule } from './resilience/resilience.module';

/**
 * Unified Core Module
 *
 * THE CENTRAL MODULE that aggregates all core infrastructure.
 *
 * Architecture Principles:
 * 1. SINGLE ENTRY POINTS: Each module has ONE orchestrator service
 * 2. AUTOMATIC EVERYTHING: Resilience, metrics, health tracking
 * 3. ZERO DUPLICATION: No duplicate code or functionality
 * 4. POLICY-BASED: Configuration through policies
 */
@Global()
@Module({
  imports: [
    DynamicConfigurationModule,
    ResilienceModule,
    DatabaseModule,
    CacheModule,
    ApiModule,
    HealthModule,
  ],
  exports: [
    DynamicConfigurationModule,
    DatabaseModule,
    CacheModule,
    ApiModule,
  ],
})
export class CoreModule implements OnModuleInit {
  private readonly logger = new Logger(CoreModule.name);

  public onModuleInit(): void {
    this.logger.log('Core Module initialized with 6 infrastructure modules');
    this.logger.log('Available: DynamicConfiguration, Resilience, Database, Cache, Api, Health');
  }
}
```

## Feature Module Template

### Product Feature Module (src/features/products/products.module.ts)

```typescript
import { Module } from '@nestjs/common';
import { ProductsController } from './controllers/products.controller';
import { ProductsService } from './services/products.service';
import { ProductsRepository } from './repositories/products.repository';

@Module({
  controllers: [ProductsController],
  providers: [ProductsService, ProductsRepository],
  exports: [ProductsService],
})
export class ProductsModule {}
```

### Product Controller (src/features/products/controllers/products.controller.ts)

```typescript
import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  UseGuards,
  Logger,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
  ApiParam,
} from '@nestjs/swagger';

import { ProductsService } from '../services/products.service';
import { CreateProductDto } from '../dto/create-product.dto';
import { UpdateProductDto } from '../dto/update-product.dto';
import { ProductResponseDto } from '../dto/product-response.dto';
import { JwtAuthGuard } from '../../../auth/guards/jwt-auth.guard';

@ApiTags('products')
@Controller({ path: 'products', version: '1' })
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ProductsController {
  private readonly logger = new Logger(ProductsController.name);

  constructor(private readonly productsService: ProductsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new product' })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: 'Product created successfully',
    type: ProductResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: 'Invalid input data',
  })
  async create(@Body() dto: CreateProductDto): Promise<ProductResponseDto> {
    this.logger.log(`Creating product: ${dto.name}`);
    return this.productsService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all products' })
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'limit', required: false, type: Number, example: 10 })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Products retrieved successfully',
    type: [ProductResponseDto],
  })
  async findAll(
    @Query('page') page = 1,
    @Query('limit') limit = 10,
  ): Promise<ProductResponseDto[]> {
    this.logger.log(`Fetching products - page: ${page}, limit: ${limit}`);
    return this.productsService.findAll({ page, limit });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get product by ID' })
  @ApiParam({ name: 'id', type: String, description: 'Product ID' })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Product retrieved successfully',
    type: ProductResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Product not found',
  })
  async findOne(@Param('id') id: string): Promise<ProductResponseDto> {
    this.logger.log(`Fetching product: ${id}`);
    return this.productsService.findById(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update product' })
  @ApiParam({ name: 'id', type: String, description: 'Product ID' })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Product updated successfully',
    type: ProductResponseDto,
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Product not found',
  })
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateProductDto,
  ): Promise<ProductResponseDto> {
    this.logger.log(`Updating product: ${id}`);
    return this.productsService.update(id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete product' })
  @ApiParam({ name: 'id', type: String, description: 'Product ID' })
  @ApiResponse({
    status: HttpStatus.NO_CONTENT,
    description: 'Product deleted successfully',
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'Product not found',
  })
  async delete(@Param('id') id: string): Promise<void> {
    this.logger.log(`Deleting product: ${id}`);
    await this.productsService.delete(id);
  }
}
```

### Product Service (src/features/products/services/products.service.ts)

```typescript
import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ProductsRepository } from '../repositories/products.repository';
import { CreateProductDto } from '../dto/create-product.dto';
import { UpdateProductDto } from '../dto/update-product.dto';
import { ProductResponseDto } from '../dto/product-response.dto';

@Injectable()
export class ProductsService {
  private readonly logger = new Logger(ProductsService.name);

  constructor(private readonly repository: ProductsRepository) {}

  async create(dto: CreateProductDto): Promise<ProductResponseDto> {
    try {
      const product = await this.repository.create({
        name: dto.name,
        description: dto.description,
        price: dto.price,
        stock: dto.stock ?? 0,
        isActive: dto.isActive ?? true,
      });

      return this.toResponseDto(product);
    } catch (error) {
      this.logger.error('Failed to create product', error);
      throw error;
    }
  }

  async findAll(options: {
    page: number;
    limit: number;
  }): Promise<ProductResponseDto[]> {
    const { page, limit } = options;
    const skip = (page - 1) * limit;

    const products = await this.repository.findMany({
      skip,
      take: limit,
      where: { deletedAt: null },
      orderBy: { createdAt: 'desc' },
    });

    return products.map((p) => this.toResponseDto(p));
  }

  async findById(id: string): Promise<ProductResponseDto> {
    const product = await this.repository.findById(id);

    if (!product || product.deletedAt) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }

    return this.toResponseDto(product);
  }

  async update(id: string, dto: UpdateProductDto): Promise<ProductResponseDto> {
    const existing = await this.repository.findById(id);

    if (!existing || existing.deletedAt) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }

    const updated = await this.repository.update(id, {
      ...dto,
      version: existing.version + 1, // Optimistic locking
    });

    return this.toResponseDto(updated);
  }

  async delete(id: string): Promise<void> {
    const product = await this.repository.findById(id);

    if (!product || product.deletedAt) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }

    // Soft delete
    await this.repository.update(id, {
      deletedAt: new Date(),
    });

    this.logger.log(`Product ${id} soft-deleted`);
  }

  private toResponseDto(product: any): ProductResponseDto {
    return {
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      stock: product.stock,
      isActive: product.isActive,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    };
  }
}
```

### Create Product DTO (src/features/products/dto/create-product.dto.ts)

```typescript
import { ApiProperty } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsBoolean,
  Min,
  MaxLength,
} from 'class-validator';

export class CreateProductDto {
  @ApiProperty({ example: 'Laptop Pro', description: 'Product name' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name: string;

  @ApiProperty({
    example: 'High-performance laptop for professionals',
    description: 'Product description',
    required: false,
  })
  @IsString()
  @IsOptional()
  @MaxLength(1000)
  description?: string;

  @ApiProperty({ example: 1299.99, description: 'Product price' })
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty({ example: 50, description: 'Stock quantity', required: false })
  @IsNumber()
  @IsOptional()
  @Min(0)
  stock?: number;

  @ApiProperty({ example: true, description: 'Product active status', required: false })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
```

### Update Product DTO (src/features/products/dto/update-product.dto.ts)

```typescript
import { PartialType } from '@nestjs/swagger';
import { CreateProductDto } from './create-product.dto';

export class UpdateProductDto extends PartialType(CreateProductDto) {}
```

### Product Response DTO (src/features/products/dto/product-response.dto.ts)

```typescript
import { ApiProperty } from '@nestjs/swagger';

export class ProductResponseDto {
  @ApiProperty({ example: 'cm3a1b2c3d4e5f6g7h8i9' })
  id: string;

  @ApiProperty({ example: 'Laptop Pro' })
  name: string;

  @ApiProperty({ example: 'High-performance laptop for professionals' })
  description?: string;

  @ApiProperty({ example: 1299.99 })
  price: number;

  @ApiProperty({ example: 50 })
  stock: number;

  @ApiProperty({ example: true })
  isActive: boolean;

  @ApiProperty({ example: '2026-02-02T10:30:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2026-02-02T10:30:00.000Z' })
  updatedAt: Date;
}
```

### Product Repository (src/features/products/repositories/products.repository.ts)

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../core/database/services/prisma.service';
import { Prisma, Product } from '@prisma/client';

@Injectable()
export class ProductsRepository {
  private readonly logger = new Logger(ProductsRepository.name);

  constructor(private readonly prisma: PrismaService) {}

  async create(data: Prisma.ProductCreateInput): Promise<Product> {
    return this.prisma.product.create({ data });
  }

  async findById(id: string): Promise<Product | null> {
    return this.prisma.product.findUnique({ where: { id } });
  }

  async findMany(args: Prisma.ProductFindManyArgs): Promise<Product[]> {
    return this.prisma.product.findMany(args);
  }

  async update(id: string, data: Prisma.ProductUpdateInput): Promise<Product> {
    return this.prisma.product.update({
      where: { id },
      data,
    });
  }

  async delete(id: string): Promise<Product> {
    return this.prisma.product.delete({ where: { id } });
  }

  async count(where?: Prisma.ProductWhereInput): Promise<number> {
    return this.prisma.product.count({ where });
  }
}
```

## Dockerfile

```dockerfile
# my-service - Multi-Stage Production Dockerfile
# Security-hardened, minimal image with non-root user

# ============================================
# Stage 1: Base with pnpm
# ============================================
FROM node:24-alpine AS base

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Security: create non-root user early
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nestjs

# ============================================
# Stage 2: Dependencies
# ============================================
FROM base AS deps

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./
COPY prisma ./prisma/

# Install dependencies (including devDependencies for build)
RUN pnpm install --frozen-lockfile

# ============================================
# Stage 3: Builder
# ============================================
FROM base AS builder

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Generate Prisma client
RUN pnpm prisma generate

# Build the application
RUN pnpm build

# Remove devDependencies for production
RUN pnpm prune --prod

# ============================================
# Stage 4: Production Runner
# ============================================
FROM base AS runner

WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV PORT=3000

# Security: use non-root user
USER nestjs

# Copy built application with correct ownership
COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nestjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nestjs:nodejs /app/package.json ./
COPY --from=builder --chown=nestjs:nodejs /app/prisma ./prisma

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health/live || exit 1

# Expose port
EXPOSE 3000

# Start the application
CMD ["node", "dist/main.js"]
```

## Docker Compose (Development)

```yaml
# docker-compose.dev.yml - Development Environment
version: '3.9'

services:
  # Application
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: builder
    container_name: my-service-dev
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: development
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/myservice?schema=public
      REDIS_URL: redis://redis:6379
      REDIS_HOST: redis
      REDIS_PORT: 6379
      LOG_LEVEL: debug
    volumes:
      - ./src:/app/src
      - ./prisma:/app/prisma
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: pnpm run start:dev
    restart: unless-stopped
    networks:
      - my-service-network

  # PostgreSQL Database
  postgres:
    image: postgres:17-alpine
    container_name: my-service-postgres-dev
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: myservice
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - my-service-network

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: my-service-redis-dev
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped
    networks:
      - my-service-network

  # Prisma Studio (Database GUI)
  prisma-studio:
    build:
      context: .
      dockerfile: Dockerfile
      target: builder
    container_name: my-service-prisma-studio
    ports:
      - "5555:5555"
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/myservice?schema=public
    volumes:
      - ./prisma:/app/prisma
    depends_on:
      - postgres
    command: pnpm prisma studio --port 5555 --browser none
    restart: unless-stopped
    networks:
      - my-service-network

networks:
  my-service-network:
    driver: bridge

volumes:
  postgres-data:
    driver: local
  redis-data:
    driver: local
```

## Docker Ignore (.dockerignore)

```
# Dependencies
node_modules
.pnpm-store

# Build outputs
dist
coverage
test-results

# Development files
*.md
!README.md
.env*
!.env.example
.git
.gitignore
.vscode
.idea

# Test files
**/*.spec.ts
**/*.test.ts
**/*.e2e-spec.ts
test/

# Documentation
docs/

# Misc
*.log
*.tmp
.DS_Store
Thumbs.db
```

## Vitest Configuration (vitest.config.ts)

```typescript
import { resolve } from 'path';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',

    // Allow test runs with no tests (useful in CI)
    passWithNoTests: true,

    coverage: {
      provider: 'v8',
      thresholds: {
        lines: 90,
        branches: 80,
        functions: 90,
        statements: 90
      },
      exclude: [
        '**/*.spec.ts',
        '**/*.e2e-spec.ts',
        '**/dto/*.ts',
        '**/interfaces/*.ts',
        '**/types/*.ts',
        '**/index.ts',
        'dist/**',
        'coverage/**',
        'prisma/**',
        'test/**'
      ],
      reporter: ['text', 'json', 'html', 'lcov', 'cobertura']
    },

    include: [
      'src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'
    ],
    exclude: [
      'node_modules/**',
      'dist/**',
      '**/*.e2e-spec.ts'
    ],

    testTimeout: 10000,
    hookTimeout: 10000,
    teardownTimeout: 10000,

    // Thread pool configuration
    pool: 'threads',
    poolOptions: {
      threads: {
        singleThread: false,
        minThreads: 1,
        maxThreads: 4,
      },
    },

    // Retry flaky tests
    retry: 2,
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@common': resolve(__dirname, './src/common'),
      '@config': resolve(__dirname, './src/config'),
      '@core': resolve(__dirname, './src/core'),
      '@features': resolve(__dirname, './src/features'),
      '@auth': resolve(__dirname, './src/auth'),
    },
  },
});
```
