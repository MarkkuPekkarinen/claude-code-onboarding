# NestJS REST Controllers

Complete guide for building REST API controllers with NestJS 11.x, Fastify, Prisma ORM, and TypeScript 5.x.

## 1. REST Service Development Workflow

### Step-by-Step Process

1. **Gather Requirements**
   - Parse OpenAPI spec or requirement documents
   - Extract entities, relationships, and endpoint definitions
   - Identify DTOs, validation rules, and business logic

2. **Database Schema**
   - Design Prisma schema with proper relations
   - Run migrations: `npx prisma migrate dev`
   - Generate Prisma Client: `npx prisma generate`

3. **Generate Feature Module**
   ```bash
   nest g module features/products
   nest g controller features/products
   nest g service features/products
   ```

4. **Create DTOs**
   - Request DTOs with `class-validator` decorators
   - Response DTOs with `@ApiProperty` for Swagger
   - Reusable pagination and filter DTOs

5. **Implement Layers**
   - Repository: Prisma database access
   - Service: Business logic + external service calls with circuit breaker
   - Controller: HTTP endpoints with Swagger documentation

6. **Add Integrations**
   - External service clients with circuit breaker pattern
   - Type-safe configuration for API endpoints
   - Error mapping and retry logic

7. **Write Tests**
   - Unit tests for services and repositories
   - Integration tests with supertest
   - Contract tests for external APIs

8. **Configure Documentation**
   - Swagger decorators on controllers
   - Export OpenAPI JSON for API gateway
   - Add example requests/responses

---

## 2. OpenAPI/Swagger-Driven Development

### Controller with Complete Swagger Documentation

```typescript
import { Controller, Get, Post, Put, Delete, Body, Param, Query, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam, ApiQuery, ApiBody } from '@nestjs/swagger';
import { ProductService } from './product.service';
import { CreateProductDto, UpdateProductDto, ProductResponseDto, ProductFilterDto } from './dto';
import { PaginatedResponse } from '@/common/dto/paginated-response.dto';

@ApiTags('Products')
@Controller({ path: 'products', version: '1' })
export class ProductController {
  constructor(private readonly productService: ProductService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Create a new product',
    description: 'Creates a product with validation and returns the created entity'
  })
  @ApiBody({ type: CreateProductDto })
  @ApiResponse({
    status: 201,
    description: 'Product created successfully',
    type: ProductResponseDto
  })
  @ApiResponse({ status: 400, description: 'Invalid input data' })
  @ApiResponse({ status: 409, description: 'Product with SKU already exists' })
  async create(@Body() dto: CreateProductDto): Promise<ProductResponseDto> {
    const product = await this.productService.create(dto);
    return ProductResponseDto.fromEntity(product);
  }

  @Get()
  @ApiOperation({ summary: 'List products with pagination and filters' })
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'limit', required: false, type: Number, example: 20 })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({ name: 'status', required: false, enum: ['ACTIVE', 'INACTIVE', 'ARCHIVED'] })
  @ApiResponse({
    status: 200,
    description: 'Paginated list of products',
    type: PaginatedResponse<ProductResponseDto>
  })
  async findAll(@Query() filter: ProductFilterDto): Promise<PaginatedResponse<ProductResponseDto>> {
    return this.productService.findAll(filter);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get product by ID' })
  @ApiParam({ name: 'id', description: 'Product UUID', example: '123e4567-e89b-12d3-a456-426614174000' })
  @ApiResponse({ status: 200, description: 'Product found', type: ProductResponseDto })
  @ApiResponse({ status: 404, description: 'Product not found' })
  async findOne(@Param('id') id: string): Promise<ProductResponseDto> {
    const product = await this.productService.findOne(id);
    return ProductResponseDto.fromEntity(product);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update product' })
  @ApiParam({ name: 'id', description: 'Product UUID' })
  @ApiBody({ type: UpdateProductDto })
  @ApiResponse({ status: 200, description: 'Product updated', type: ProductResponseDto })
  @ApiResponse({ status: 404, description: 'Product not found' })
  async update(@Param('id') id: string, @Body() dto: UpdateProductDto): Promise<ProductResponseDto> {
    const product = await this.productService.update(id, dto);
    return ProductResponseDto.fromEntity(product);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete product (soft delete)' })
  @ApiParam({ name: 'id', description: 'Product UUID' })
  @ApiResponse({ status: 204, description: 'Product deleted' })
  @ApiResponse({ status: 404, description: 'Product not found' })
  async remove(@Param('id') id: string): Promise<void> {
    await this.productService.remove(id);
  }
}
```

### Swagger Setup in main.ts

```typescript
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { writeFileSync } from 'fs';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: true })
  );

  // Global validation pipe
  app.useGlobalPipes(new ValidationPipe({
    transform: true,
    whitelist: true,
    forbidNonWhitelisted: true,
  }));

  // API versioning
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // Swagger configuration
  const config = new DocumentBuilder()
    .setTitle('Product Service API')
    .setDescription('REST API for product management')
    .setVersion('1.0')
    .addTag('Products')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  // Export OpenAPI JSON for API gateway
  writeFileSync('./openapi.json', JSON.stringify(document, null, 2));

  await app.listen(process.env.PORT ?? 3000, '0.0.0.0');
}
bootstrap();
```

---

## 3. DTO Mapping Patterns

### Pattern 1: Static Factory Methods

```typescript
import { ApiProperty } from '@nestjs/swagger';
import { Product } from '@prisma/client';

export class ProductResponseDto {
  @ApiProperty({ example: '123e4567-e89b-12d3-a456-426614174000' })
  id: string;

  @ApiProperty({ example: 'Wireless Mouse' })
  name: string;

  @ApiProperty({ example: 'MOUSE-001' })
  sku: string;

  @ApiProperty({ example: 29.99 })
  price: number;

  @ApiProperty({ enum: ['ACTIVE', 'INACTIVE', 'ARCHIVED'] })
  status: string;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;

  // Static factory method for single entity
  static fromEntity(entity: Product): ProductResponseDto {
    const dto = new ProductResponseDto();
    dto.id = entity.id;
    dto.name = entity.name;
    dto.sku = entity.sku;
    dto.price = entity.price.toNumber(); // Prisma Decimal → number
    dto.status = entity.status;
    dto.createdAt = entity.createdAt;
    dto.updatedAt = entity.updatedAt;
    return dto;
  }

  // Static factory method for entity list
  static fromEntityList(entities: Product[]): ProductResponseDto[] {
    return entities.map(entity => this.fromEntity(entity));
  }
}
```

### Pattern 2: class-transformer with @Expose/@Exclude

```typescript
import { Expose, Exclude, plainToInstance } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';
import { Product } from '@prisma/client';

@Exclude()
export class ProductResponseDto {
  @Expose()
  @ApiProperty()
  id: string;

  @Expose()
  @ApiProperty()
  name: string;

  @Expose()
  @ApiProperty()
  sku: string;

  @Expose()
  @ApiProperty()
  price: number;

  @Expose()
  @ApiProperty()
  status: string;

  @Expose()
  @ApiProperty()
  createdAt: Date;

  @Expose()
  @ApiProperty()
  updatedAt: Date;

  // Factory using plainToInstance
  static fromEntity(entity: Product): ProductResponseDto {
    return plainToInstance(ProductResponseDto, entity, {
      excludeExtraneousValues: true,
    });
  }
}
```

### Pattern 3: Dedicated Mapper Service

```typescript
import { Injectable } from '@nestjs/common';
import { Prisma, Product } from '@prisma/client';
import { CreateProductDto, UpdateProductDto, ProductResponseDto } from './dto';

@Injectable()
export class ProductMapper {
  toResponse(entity: Product): ProductResponseDto {
    return {
      id: entity.id,
      name: entity.name,
      sku: entity.sku,
      price: entity.price.toNumber(),
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    };
  }

  toResponseList(entities: Product[]): ProductResponseDto[] {
    return entities.map(e => this.toResponse(e));
  }

  toCreateInput(dto: CreateProductDto): Prisma.ProductCreateInput {
    return {
      name: dto.name,
      sku: dto.sku,
      price: new Prisma.Decimal(dto.price),
      status: dto.status ?? 'ACTIVE',
      description: dto.description,
    };
  }

  toUpdateInput(dto: UpdateProductDto): Prisma.ProductUpdateInput {
    const data: Prisma.ProductUpdateInput = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.price !== undefined) data.price = new Prisma.Decimal(dto.price);
    if (dto.status !== undefined) data.status = dto.status;
    if (dto.description !== undefined) data.description = dto.description;
    return data;
  }
}
```

---

## 4. Pagination, Filtering & Sorting

### Generic Pagination DTO

```typescript
import { IsOptional, IsInt, Min, Max, IsString, IsEnum } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export enum SortOrder {
  ASC = 'asc',
  DESC = 'desc',
}

export class PaginationQueryDto {
  @ApiPropertyOptional({ minimum: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ minimum: 1, maximum: 100, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 20;

  @ApiPropertyOptional({ default: 'createdAt' })
  @IsOptional()
  @IsString()
  sortBy: string = 'createdAt';

  @ApiPropertyOptional({ enum: SortOrder, default: SortOrder.DESC })
  @IsOptional()
  @IsEnum(SortOrder)
  sortOrder: SortOrder = SortOrder.DESC;

  get skip(): number {
    return (this.page - 1) * this.limit;
  }

  get take(): number {
    return this.limit;
  }
}
```

### Generic Paginated Response

```typescript
import { ApiProperty } from '@nestjs/swagger';

export class PaginationMeta {
  @ApiProperty()
  page: number;

  @ApiProperty()
  limit: number;

  @ApiProperty()
  total: number;

  @ApiProperty()
  totalPages: number;

  @ApiProperty()
  hasNextPage: boolean;

  @ApiProperty()
  hasPreviousPage: boolean;
}

export class PaginatedResponse<T> {
  @ApiProperty({ isArray: true })
  data: T[];

  @ApiProperty({ type: PaginationMeta })
  meta: PaginationMeta;

  static create<T>(
    data: T[],
    total: number,
    page: number,
    limit: number,
  ): PaginatedResponse<T> {
    const totalPages = Math.ceil(total / limit);
    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    };
  }
}
```

### Product Filter DTO

```typescript
import { IsOptional, IsString, IsEnum, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto } from '@/common/dto/pagination-query.dto';

export enum ProductStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  ARCHIVED = 'ARCHIVED',
}

export class ProductFilterDto extends PaginationQueryDto {
  @ApiPropertyOptional({ description: 'Search in name, SKU, or description' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: ProductStatus })
  @IsOptional()
  @IsEnum(ProductStatus)
  status?: ProductStatus;

  @ApiPropertyOptional({ minimum: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  minPrice?: number;

  @ApiPropertyOptional({ minimum: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  maxPrice?: number;
}
```

### Repository with Pagination Implementation

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/core/prisma/prisma.service';
import { Prisma, Product } from '@prisma/client';
import { ProductFilterDto } from './dto';

@Injectable()
export class ProductRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findManyWithPagination(filter: ProductFilterDto): Promise<[Product[], number]> {
    const where = this.buildWhereClause(filter);
    const orderBy = { [filter.sortBy]: filter.sortOrder };

    const [data, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        orderBy,
        skip: filter.skip,
        take: filter.take,
      }),
      this.prisma.product.count({ where }),
    ]);

    return [data, total];
  }

  private buildWhereClause(filter: ProductFilterDto): Prisma.ProductWhereInput {
    const where: Prisma.ProductWhereInput = {};

    if (filter.search) {
      where.OR = [
        { name: { contains: filter.search, mode: 'insensitive' } },
        { sku: { contains: filter.search, mode: 'insensitive' } },
        { description: { contains: filter.search, mode: 'insensitive' } },
      ];
    }

    if (filter.status) {
      where.status = filter.status;
    }

    if (filter.minPrice !== undefined || filter.maxPrice !== undefined) {
      where.price = {};
      if (filter.minPrice !== undefined) {
        where.price.gte = new Prisma.Decimal(filter.minPrice);
      }
      if (filter.maxPrice !== undefined) {
        where.price.lte = new Prisma.Decimal(filter.maxPrice);
      }
    }

    return where;
  }
}
```

---

## 5. File Upload Pattern

### Fastify Multipart Setup

```typescript
// In main.ts
import multipart from '@fastify/multipart';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter()
  );

  await app.register(multipart, {
    limits: {
      fileSize: 10 * 1024 * 1024, // 10MB
      files: 5,
    },
  });

  await app.listen(3000);
}
```

### File Upload Controller

```typescript
import { Controller, Post, UseInterceptors, UploadedFile, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiConsumes, ApiBody, ApiOperation } from '@nestjs/swagger';

interface MulterFile {
  fieldname: string;
  originalname: string;
  encoding: string;
  mimetype: string;
  buffer: Buffer;
  size: number;
}

@Controller({ path: 'products', version: '1' })
export class ProductController {
  @Post('upload')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Upload product image' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
      },
    },
  })
  async uploadFile(@UploadedFile() file: MulterFile) {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
    const maxSize = 5 * 1024 * 1024; // 5MB

    if (!allowedTypes.includes(file.mimetype)) {
      throw new BadRequestException('Only JPEG, PNG, and WebP images are allowed');
    }

    if (file.size > maxSize) {
      throw new BadRequestException('File size must not exceed 5MB');
    }

    const uploadResult = await this.productService.uploadImage(file);

    return {
      filename: file.originalname,
      size: file.size,
      mimetype: file.mimetype,
      url: uploadResult.url,
    };
  }
}
```

---

## 6. API Versioning

### Controller Versioning

```typescript
import { Controller, VERSION_NEUTRAL } from '@nestjs/common';

// Version 1
@Controller({ path: 'products', version: '1' })
export class ProductV1Controller {
  // /v1/products
}

// Version 2 with breaking changes
@Controller({ path: 'products', version: '2' })
export class ProductV2Controller {
  // /v2/products
}

// Neutral version (no prefix)
@Controller({ path: 'health', version: VERSION_NEUTRAL })
export class HealthController {
  // /health
}
```

---

## 7. Error Response Standardization

### RFC 9457 ProblemDetail Format

```typescript
export class ProblemDetail {
  type: string;
  title: string;
  status: number;
  detail: string;
  instance: string;
  timestamp: string;
  errors?: Record<string, string[]>;
}

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();

    let problem: ProblemDetail;

    if (exception instanceof HttpException) {
      problem = this.handleHttpException(exception, request);
    } else if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      problem = this.handlePrismaError(exception, request);
    } else {
      problem = this.handleUnknownError(exception, request);
    }

    response.status(problem.status).send(problem);
  }

  private handlePrismaError(error: Prisma.PrismaClientKnownRequestError, request: any): ProblemDetail {
    switch (error.code) {
      case 'P2002': // Unique constraint violation
        return {
          type: 'about:blank',
          title: 'Conflict',
          status: 409,
          detail: `Duplicate entry: ${error.meta?.target}`,
          instance: request.url,
          timestamp: new Date().toISOString(),
        };
      case 'P2025': // Record not found
        return {
          type: 'about:blank',
          title: 'Not Found',
          status: 404,
          detail: 'The requested resource was not found',
          instance: request.url,
          timestamp: new Date().toISOString(),
        };
      default:
        return {
          type: 'about:blank',
          title: 'Internal Server Error',
          status: 500,
          detail: 'A database error occurred',
          instance: request.url,
          timestamp: new Date().toISOString(),
        };
    }
  }
}
```
