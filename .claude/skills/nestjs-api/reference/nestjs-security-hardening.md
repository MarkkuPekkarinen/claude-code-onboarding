# NestJS 11.x Security Hardening Guide

Enterprise-grade security patterns for NestJS 11.x with Fastify adapter, Prisma ORM, and TypeScript 5.x.

## 1. OWASP Dependency Scanning

### NPM Audit

```bash
# Run npm audit for known CVEs
npm audit --audit-level=high

# Fix automatically where possible
npm audit fix

# Production audit (fails CI on vulnerabilities)
npm audit --audit-level=high --production
```

### Snyk Integration

```bash
# Install Snyk CLI
npm install -g snyk

# Authenticate
snyk auth

# Test for vulnerabilities
npx snyk test

# Monitor project (sends results to Snyk dashboard)
npx snyk monitor

# Test for specific severity levels
npx snyk test --severity-threshold=high
```

### CI/CD Pipeline Integration

```yaml
# .github/workflows/security-audit.yml
name: Security Audit
on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '24'

      - name: Install dependencies
        run: npm ci

      - name: Run npm audit
        run: npm audit --audit-level=high --production

      - name: Run Snyk test
        run: npx snyk test --severity-threshold=high
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

## 2. ESLint Security Plugins

### Installation

```bash
npm install --save-dev eslint-plugin-security @typescript-eslint/eslint-plugin
```

### eslint.config.js Configuration

```javascript
import eslintPluginSecurity from 'eslint-plugin-security';
import typescriptEslint from '@typescript-eslint/eslint-plugin';
import typescriptParser from '@typescript-eslint/parser';

export default [
  {
    files: ['src/**/*.ts'],
    languageOptions: {
      parser: typescriptParser,
      parserOptions: {
        project: './tsconfig.json',
      },
    },
    plugins: {
      '@typescript-eslint': typescriptEslint,
      security: eslintPluginSecurity,
    },
    rules: {
      // Security rules
      'security/detect-object-injection': 'error',
      'security/detect-non-literal-fs-filename': 'error',
      'security/detect-eval-with-expression': 'error',
      'security/detect-non-literal-regexp': 'warn',
      'security/detect-unsafe-regex': 'error',
      'security/detect-buffer-noassert': 'error',
      'security/detect-child-process': 'warn',
      'security/detect-disable-mustache-escape': 'error',
      'security/detect-no-csrf-before-method-override': 'error',
      'security/detect-possible-timing-attacks': 'warn',

      // TypeScript security
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unsafe-assignment': 'error',
      '@typescript-eslint/no-unsafe-call': 'error',
      '@typescript-eslint/no-unsafe-member-access': 'error',
      '@typescript-eslint/no-unsafe-return': 'error',

      // Dangerous JavaScript patterns
      'no-eval': 'error',
      'no-implied-eval': 'error',
      'no-new-func': 'error',
      'no-script-url': 'error',
      'no-with': 'error',
    },
  },
];
```

## 3. Static Analysis — Grep Patterns for Security Review

### Secrets & Credentials Detection

```bash
# Hardcoded passwords
grep -rn 'password\s*=\s*["\x27]' src/
grep -rn 'PASSWORD\s*=\s*["\x27]' src/

# API keys and tokens
grep -rn 'apiKey\s*=\s*["\x27]' src/
grep -rn 'API_KEY\s*=\s*["\x27]' src/
grep -rn 'token\s*=\s*["\x27]' src/
grep -rn 'secret\s*=\s*["\x27]' src/

# AWS credentials
grep -rn 'aws_access_key_id' src/
grep -rn 'aws_secret_access_key' src/

# Database credentials
grep -rn 'DATABASE_URL\s*=\s*["\x27]postgres' src/
```

### SQL Injection Patterns

```bash
# Dangerous Prisma raw queries with string concatenation
grep -rn '\$queryRaw.*\${' src/
grep -rn '\$executeRaw.*\${' src/
grep -rn 'queryRaw(`' src/

# String concatenation in queries
grep -rn 'prisma\.\$queryRaw.*\+' src/
```

### Missing Input Validation

```bash
# Controllers without DTO validation
grep -rn '@Body()' src/ | grep -v '@Body(.*Dto)'
grep -rn '@Query()' src/ | grep -v '@Query(.*Dto)'
grep -rn '@Param()' src/ | grep -v '@Param(.*Dto)'
```

### CORS Misconfigurations

```bash
# Overly permissive CORS
grep -rn "origin:\s*'\*'" src/
grep -rn 'origin:\s*true' src/
```

### Exposed Stack Traces

```bash
# Stack traces in production
grep -rn 'error.stack' src/
grep -rn 'console.error' src/
grep -rn 'console.log' src/
```

### Comprehensive Security Scan Script

```bash
#!/bin/bash
# security-scan.sh

echo "=== Security Scan Report ==="
echo ""

echo "1. Searching for hardcoded secrets..."
grep -rn 'password\s*=\s*["\x27]' src/ || echo "✓ No hardcoded passwords found"
grep -rn 'apiKey\s*=\s*["\x27]' src/ || echo "✓ No hardcoded API keys found"

echo ""
echo "2. Checking for SQL injection risks..."
grep -rn '\$queryRaw.*\${' src/ || echo "✓ No unsafe raw queries found"

echo ""
echo "3. Checking for missing validation..."
grep -rn '@Body()' src/ | grep -v 'Dto' || echo "✓ All endpoints have DTO validation"

echo ""
echo "4. Checking for console.log statements..."
grep -rn 'console\.' src/ || echo "✓ No console statements in production code"

echo ""
echo "=== Scan Complete ==="
```

## 4. Security Headers — Comprehensive Helmet Configuration

### Installation

```bash
npm install @fastify/helmet
```

### main.ts Configuration

```typescript
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import helmet from '@fastify/helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter(),
  );

  // Comprehensive Helmet configuration
  await app.register(helmet, {
    // Content Security Policy — prevents XSS attacks
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'"],
        styleSrc: ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
        fontSrc: ["'self'", 'https://fonts.gstatic.com'],
        imgSrc: ["'self'", 'data:', 'https:'],
        connectSrc: ["'self'", process.env.API_URL],
        objectSrc: ["'none'"],
        upgradeInsecureRequests: [],
      },
    },

    // Strict Transport Security — enforces HTTPS
    hsts: {
      maxAge: 31536000, // 1 year
      includeSubDomains: true,
      preload: true,
    },

    // X-Frame-Options — prevents clickjacking
    frameguard: {
      action: 'deny', // or 'sameorigin' if you need iframes
    },

    // X-Content-Type-Options — prevents MIME sniffing
    noSniff: true,

    // X-DNS-Prefetch-Control — controls DNS prefetching
    dnsPrefetchControl: {
      allow: false,
    },

    // Cross-Origin-Resource-Policy — restricts resource loading
    crossOriginResourcePolicy: {
      policy: 'same-origin', // or 'same-site' or 'cross-origin'
    },

    // Cross-Origin-Opener-Policy — isolates browsing context
    crossOriginOpenerPolicy: {
      policy: 'same-origin',
    },

    // Cross-Origin-Embedder-Policy
    crossOriginEmbedderPolicy: {
      policy: 'require-corp',
    },

    // Referrer-Policy — controls referrer information
    referrerPolicy: {
      policy: 'no-referrer', // or 'strict-origin-when-cross-origin'
    },

    // Permissions-Policy — controls browser features
    permissionsPolicy: {
      camera: ['none'],
      microphone: ['none'],
      geolocation: ['self'],
      payment: ['none'],
      usb: ['none'],
    },
  });

  await app.listen(3000, '0.0.0.0');
}
bootstrap();
```

## 5. JWT Security Best Practices

### Installation

```bash
npm install @nestjs/jwt @nestjs/passport passport-jwt bcrypt
npm install --save-dev @types/passport-jwt @types/bcrypt
```

### JWT Strategy with RS256

```typescript
// src/features/auth/strategies/jwt.strategy.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { readFileSync } from 'fs';
import { RedisService } from '@/common/redis/redis.service';

interface JwtPayload {
  sub: string;
  email: string;
  iat: number;
  exp: number;
  aud: string;
  iss: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private redisService: RedisService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: readFileSync(
        configService.get<string>('JWT_PUBLIC_KEY_PATH'),
        'utf8',
      ),
      algorithms: ['RS256'], // Use RS256 instead of HS256
      audience: configService.get<string>('JWT_AUDIENCE'),
      issuer: configService.get<string>('JWT_ISSUER'),
    });
  }

  async validate(payload: JwtPayload) {
    // Check token revocation via Redis blacklist
    const isBlacklisted = await this.redisService.get(
      `blacklist:${payload.sub}:${payload.iat}`,
    );

    if (isBlacklisted) {
      throw new UnauthorizedException('Token has been revoked');
    }

    return {
      userId: payload.sub,
      email: payload.email,
    };
  }
}
```

### Token Service

```typescript
// src/features/auth/services/token.service.ts
import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { readFileSync } from 'fs';
import { RedisService } from '@/common/redis/redis.service';

@Injectable()
export class TokenService {
  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
    private redisService: RedisService,
  ) {}

  async generateAccessToken(userId: string, email: string): Promise<string> {
    const payload = {
      sub: userId,
      email,
      aud: this.configService.get<string>('JWT_AUDIENCE'),
      iss: this.configService.get<string>('JWT_ISSUER'),
    };

    return this.jwtService.sign(payload, {
      privateKey: readFileSync(
        this.configService.get<string>('JWT_PRIVATE_KEY_PATH'),
        'utf8',
      ),
      algorithm: 'RS256',
      expiresIn: '15m', // Short-lived access token
    });
  }

  async generateRefreshToken(userId: string): Promise<string> {
    return this.jwtService.sign(
      { sub: userId },
      {
        privateKey: readFileSync(
          this.configService.get<string>('JWT_PRIVATE_KEY_PATH'),
          'utf8',
        ),
        algorithm: 'RS256',
        expiresIn: '7d', // Long-lived refresh token
      },
    );
  }

  async revokeToken(userId: string, iat: number): Promise<void> {
    // Add to Redis blacklist with TTL matching token expiry
    await this.redisService.set(
      `blacklist:${userId}:${iat}`,
      'revoked',
      15 * 60, // 15 minutes
    );
  }
}
```

### Password Hashing

```typescript
// src/features/auth/services/password.service.ts
import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcrypt';

@Injectable()
export class PasswordService {
  private readonly SALT_ROUNDS = 12; // Cost factor for bcrypt

  async hash(password: string): Promise<string> {
    return bcrypt.hash(password, this.SALT_ROUNDS);
  }

  async compare(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }
}
```

### Rate Limiting on Auth Endpoints

```typescript
// src/features/auth/controllers/auth.controller.ts
import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';

@Controller('auth')
export class AuthController {
  // Stricter rate limiting: 5 requests per 15 minutes
  @Throttle({ default: { limit: 5, ttl: 900000 } })
  @Post('login')
  async login(@Body() loginDto: LoginDto) {
    // Login logic
  }

  @Throttle({ default: { limit: 3, ttl: 3600000 } }) // 3 per hour
  @Post('forgot-password')
  async forgotPassword(@Body() forgotPasswordDto: ForgotPasswordDto) {
    // Forgot password logic
  }
}
```

## 6. Secure Logging — PII Masking

### Log Sanitizer Service

```typescript
// src/common/logging/log-sanitizer.service.ts
import { Injectable } from '@nestjs/common';

@Injectable()
export class LogSanitizerService {
  private readonly sensitivePatterns: Array<{
    pattern: RegExp;
    replacement: string;
  }> = [
    // Password patterns
    { pattern: /"password":\s*"[^"]*"/gi, replacement: '"password":"***MASKED***"' },
    { pattern: /'password':\s*'[^']*'/gi, replacement: "'password':'***MASKED***'" },

    // Token patterns
    { pattern: /"token":\s*"[^"]*"/gi, replacement: '"token":"***MASKED***"' },
    { pattern: /"accessToken":\s*"[^"]*"/gi, replacement: '"accessToken":"***MASKED***"' },
    { pattern: /"refreshToken":\s*"[^"]*"/gi, replacement: '"refreshToken":"***MASKED***"' },

    // API key patterns
    { pattern: /"apiKey":\s*"[^"]*"/gi, replacement: '"apiKey":"***MASKED***"' },
    { pattern: /"api_key":\s*"[^"]*"/gi, replacement: '"api_key":"***MASKED***"' },

    // SSN pattern (XXX-XX-XXXX)
    { pattern: /\b\d{3}-\d{2}-\d{4}\b/g, replacement: '***-**-****' },

    // Credit card patterns (various formats)
    { pattern: /\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/g, replacement: '****-****-****-****' },

    // Email masking (keep first 2 and last 2 chars)
    {
      pattern: /\b([a-zA-Z0-9]{1,2})[a-zA-Z0-9._-]*([a-zA-Z0-9]{1,2})@/g,
      replacement: '$1***$2@'
    },
  ];

  sanitize(data: unknown): unknown {
    if (typeof data === 'string') {
      return this.sanitizeString(data);
    }

    if (Array.isArray(data)) {
      return data.map((item) => this.sanitize(item));
    }

    if (typeof data === 'object' && data !== null) {
      return this.sanitizeObject(data);
    }

    return data;
  }

  private sanitizeString(str: string): string {
    let sanitized = str;

    for (const { pattern, replacement } of this.sensitivePatterns) {
      sanitized = sanitized.replace(pattern, replacement);
    }

    return sanitized;
  }

  private sanitizeObject(obj: Record<string, unknown>): Record<string, unknown> {
    const sanitized: Record<string, unknown> = {};

    for (const [key, value] of Object.entries(obj)) {
      // Check if key itself is sensitive
      if (this.isSensitiveKey(key)) {
        sanitized[key] = this.maskValue(value);
      } else {
        sanitized[key] = this.sanitize(value);
      }
    }

    return sanitized;
  }

  private isSensitiveKey(key: string): boolean {
    const sensitiveKeys = [
      'password',
      'token',
      'accessToken',
      'refreshToken',
      'apiKey',
      'api_key',
      'secret',
      'ssn',
      'creditCard',
      'cvv',
    ];

    return sensitiveKeys.some((sensitive) =>
      key.toLowerCase().includes(sensitive.toLowerCase()),
    );
  }

  private maskValue(value: unknown): string {
    if (typeof value !== 'string') {
      return '***MASKED***';
    }

    // Preserve first 2 and last 2 characters
    if (value.length <= 4) {
      return '***';
    }

    return `${value.substring(0, 2)}***${value.substring(value.length - 2)}`;
  }
}
```

### Logging Interceptor

```typescript
// src/common/logging/logging.interceptor.ts
import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { LogSanitizerService } from './log-sanitizer.service';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger(LoggingInterceptor.name);

  constructor(private logSanitizer: LogSanitizerService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest();
    const { method, url, body } = request;
    const now = Date.now();

    // Sanitize request body before logging
    const sanitizedBody = this.logSanitizer.sanitize(body);
    this.logger.log(`Incoming Request: ${method} ${url}`, { body: sanitizedBody });

    return next.handle().pipe(
      tap({
        next: (data) => {
          const sanitizedResponse = this.logSanitizer.sanitize(data);
          this.logger.log(
            `Response: ${method} ${url} - ${Date.now() - now}ms`,
            { data: sanitizedResponse },
          );
        },
        error: (error) => {
          // Never log full error objects in production
          this.logger.error(`Error: ${method} ${url}`, {
            message: error.message,
            statusCode: error.status,
          });
        },
      }),
    );
  }
}
```

## 7. Input Validation Hardening

### Advanced DTO Validation

```typescript
// src/features/users/dto/create-user.dto.ts
import {
  IsEmail,
  IsString,
  IsNotEmpty,
  MinLength,
  MaxLength,
  Matches,
  IsOptional,
  IsPhoneNumber,
  ValidateNested,
  IsArray,
  ArrayMaxSize,
  ArrayMinSize,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import * as DOMPurify from 'isomorphic-dompurify';

class AddressDto {
  @IsString()
  @MaxLength(100)
  street: string;

  @IsString()
  @MaxLength(50)
  city: string;

  @IsString()
  @Matches(/^[A-Z]{2}$/, { message: 'State must be 2-letter code' })
  state: string;

  @IsString()
  @Matches(/^\d{5}(-\d{4})?$/, { message: 'Invalid ZIP code' })
  zipCode: string;
}

export class CreateUserDto {
  // Email validation
  @IsEmail({}, { message: 'Invalid email format' })
  @MaxLength(255)
  email: string;

  // Strong password requirements
  @IsString()
  @MinLength(12, { message: 'Password must be at least 12 characters' })
  @MaxLength(128)
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]+$/,
    {
      message:
        'Password must contain uppercase, lowercase, number, and special character',
    },
  )
  password: string;

  // Name validation with sanitization
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(50)
  @Matches(/^[a-zA-Z\s'-]+$/, { message: 'Name contains invalid characters' })
  @Transform(({ value }) => DOMPurify.sanitize(value.trim()))
  firstName: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(50)
  @Matches(/^[a-zA-Z\s'-]+$/, { message: 'Name contains invalid characters' })
  @Transform(({ value }) => DOMPurify.sanitize(value.trim()))
  lastName: string;

  // Phone validation
  @IsOptional()
  @IsPhoneNumber('US', { message: 'Invalid US phone number' })
  phoneNumber?: string;

  // Nested object validation
  @ValidateNested()
  @Type(() => AddressDto)
  @IsOptional()
  address?: AddressDto;

  // Array validation
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(10)
  @IsString({ each: true })
  @MaxLength(50, { each: true })
  tags: string[];
}
```

### Global Validation Pipe Configuration

```typescript
// src/main.ts
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter(),
  );

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Strip unknown properties
      forbidNonWhitelisted: true, // Throw error if unknown properties present
      transform: true, // Auto-transform payloads to DTO types
      transformOptions: {
        enableImplicitConversion: false, // Explicit type conversion only
      },
      disableErrorMessages: process.env.NODE_ENV === 'production', // Hide validation details in prod
    }),
  );

  await app.listen(3000);
}
bootstrap();
```

## 8. Rate Limiting Deep Dive

### Installation

```bash
npm install @nestjs/throttler
```

### Multi-Tier Rate Limiting

```typescript
// src/common/throttler/throttler.config.ts
import { ThrottlerModuleOptions } from '@nestjs/throttler';
import { ConfigService } from '@nestjs/config';

export const getThrottlerConfig = (
  configService: ConfigService,
): ThrottlerModuleOptions => ({
  throttlers: [
    {
      name: 'short',
      ttl: 1000, // 1 second
      limit: 10, // 10 requests per second
    },
    {
      name: 'medium',
      ttl: 60000, // 1 minute
      limit: 100, // 100 requests per minute
    },
    {
      name: 'long',
      ttl: 3600000, // 1 hour
      limit: 1000, // 1000 requests per hour
    },
  ],
  storage: configService.get('REDIS_URL')
    ? require('@nestjs/throttler-storage-redis').ThrottlerStorageRedisService
    : undefined,
});
```

### Custom Throttler Guard

```typescript
// src/common/throttler/custom-throttler.guard.ts
import { Injectable, ExecutionContext } from '@nestjs/common';
import { ThrottlerGuard, ThrottlerException } from '@nestjs/throttler';
import { FastifyRequest } from 'fastify';

@Injectable()
export class CustomThrottlerGuard extends ThrottlerGuard {
  // Override to use user ID instead of IP for authenticated routes
  protected async getTracker(req: FastifyRequest): Promise<string> {
    const user = req['user'];

    // Use user ID for authenticated requests
    if (user?.userId) {
      return `user:${user.userId}`;
    }

    // Fall back to IP for unauthenticated requests
    return req.ip || 'unknown';
  }

  // Custom error message
  protected throwThrottlingException(context: ExecutionContext): void {
    throw new ThrottlerException(
      'Rate limit exceeded. Please try again later.',
    );
  }
}
```

### Per-Endpoint Configuration

```typescript
// src/features/auth/controllers/auth.controller.ts
import { Controller, Post, UseGuards } from '@nestjs/common';
import { SkipThrottle, Throttle } from '@nestjs/throttler';
import { CustomThrottlerGuard } from '@/common/throttler/custom-throttler.guard';

@Controller('auth')
@UseGuards(CustomThrottlerGuard)
export class AuthController {
  // Very strict: 5 attempts per 15 minutes
  @Throttle({ short: { limit: 5, ttl: 900000 } })
  @Post('login')
  async login() {}

  // Moderate: 3 attempts per hour
  @Throttle({ medium: { limit: 3, ttl: 3600000 } })
  @Post('forgot-password')
  async forgotPassword() {}

  // Skip throttling for health check
  @SkipThrottle()
  @Post('health')
  async health() {}
}
```

## 9. CORS Best Practices

### Production CORS Configuration

```typescript
// src/main.ts
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter } from '@nestjs/platform-fastify';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, new FastifyAdapter());
  const configService = app.get(ConfigService);

  // Environment-specific CORS
  const allowedOrigins = configService
    .get<string>('ALLOWED_ORIGINS')
    .split(',')
    .map((origin) => origin.trim());

  app.enableCors({
    // Explicit origin whitelist — NEVER use wildcard in production
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },

    // Allow credentials (cookies, authorization headers)
    credentials: true,

    // Allowed HTTP methods
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],

    // Allowed request headers
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'X-Correlation-Id',
    ],

    // Exposed response headers
    exposedHeaders: ['X-Total-Count', 'X-Page-Number'],

    // Preflight cache duration (24 hours)
    maxAge: 86400,

    // Respond to OPTIONS requests
    preflightContinue: false,
    optionsSuccessStatus: 204,
  });

  await app.listen(3000);
}
bootstrap();
```

### Environment Variables

```env
# .env.production
ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com

# .env.development
ALLOWED_ORIGINS=http://localhost:4200,http://localhost:3000
```

## 10. Prisma Security

### Avoid SQL Injection

```typescript
// ❌ DANGEROUS — SQL injection risk
async findUserBad(email: string) {
  return this.prisma.$queryRaw`SELECT * FROM users WHERE email = ${email}`;
}

// ✅ SAFE — Parameterized query
import { Prisma } from '@prisma/client';

async findUserSafe(email: string) {
  return this.prisma.$queryRaw(
    Prisma.sql`SELECT * FROM users WHERE email = ${email}`,
  );
}

// ✅ BEST — Use Prisma Client methods
async findUserBest(email: string) {
  return this.prisma.user.findUnique({
    where: { email },
  });
}
```

### Field-Level Encryption

```typescript
// src/common/encryption/encryption.service.ts
import { Injectable } from '@nestjs/common';
import { createCipheriv, createDecipheriv, randomBytes, scryptSync } from 'crypto';

@Injectable()
export class EncryptionService {
  private readonly algorithm = 'aes-256-gcm';
  private readonly key: Buffer;

  constructor() {
    this.key = scryptSync(process.env.ENCRYPTION_KEY, 'salt', 32);
  }

  encrypt(text: string): string {
    const iv = randomBytes(16);
    const cipher = createCipheriv(this.algorithm, this.key, iv);

    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const authTag = cipher.getAuthTag();

    return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`;
  }

  decrypt(encryptedText: string): string {
    const [ivHex, authTagHex, encrypted] = encryptedText.split(':');

    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');

    const decipher = createDecipheriv(this.algorithm, this.key, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
  }
}
```

### Row-Level Security via Middleware

```typescript
// src/common/prisma/prisma.service.ts
import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect();

    // Row-level security middleware
    this.$use(async (params, next) => {
      // Example: Filter deleted records
      if (params.action === 'findMany' || params.action === 'findFirst') {
        params.args.where = {
          ...params.args.where,
          deletedAt: null,
        };
      }

      // Example: Prevent hard delete
      if (params.action === 'delete') {
        params.action = 'update';
        params.args.data = { deletedAt: new Date() };
      }

      return next(params);
    });
  }
}
```

### Soft Delete Pattern

```typescript
// prisma/schema.prisma
model User {
  id        String    @id @default(uuid())
  email     String    @unique
  deletedAt DateTime? @map("deleted_at")

  @@map("users")
}

// src/features/users/repositories/user.repository.ts
@Injectable()
export class UserRepository {
  constructor(private prisma: PrismaService) {}

  async softDelete(id: string): Promise<void> {
    await this.prisma.user.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  async findActive(id: string) {
    return this.prisma.user.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });
  }
}
```

## 11. Security Checklist

### OWASP Top 10 Mitigations

- [ ] **A01: Broken Access Control**
  - [ ] Implement RBAC with guards on all protected routes
  - [ ] Validate user permissions on every request
  - [ ] Use `@UseGuards(JwtAuthGuard, RolesGuard)` consistently

- [ ] **A02: Cryptographic Failures**
  - [ ] Use bcrypt with cost factor >=12 for passwords
  - [ ] Use RS256 for JWT signing (not HS256)
  - [ ] Encrypt sensitive fields in database (SSN, credit cards)
  - [ ] Use HTTPS in production (HSTS enabled)

- [ ] **A03: Injection**
  - [ ] Never use string concatenation in Prisma queries
  - [ ] Use Prisma.sql for parameterized raw queries
  - [ ] Validate all inputs with class-validator DTOs
  - [ ] Sanitize HTML input to prevent XSS

- [ ] **A04: Insecure Design**
  - [ ] Implement rate limiting on all endpoints
  - [ ] Add circuit breakers for external service calls
  - [ ] Use fail-fast configuration (app crashes if env missing)
  - [ ] Implement request correlation IDs

- [ ] **A05: Security Misconfiguration**
  - [ ] Run `npm audit` in CI/CD pipeline
  - [ ] Configure Helmet with all security headers
  - [ ] Disable stack traces in production
  - [ ] Remove console.log statements from production code

- [ ] **A06: Vulnerable and Outdated Components**
  - [ ] Automate dependency scanning (Snyk, npm audit)
  - [ ] Keep Node.js, NestJS, and dependencies up to date
  - [ ] Pin dependency versions in package-lock.json

- [ ] **A07: Identification and Authentication Failures**
  - [ ] Implement short-lived access tokens (15 min)
  - [ ] Use refresh token rotation
  - [ ] Add token revocation via Redis blacklist
  - [ ] Rate limit auth endpoints (5 attempts per 15 min)
  - [ ] Implement MFA for sensitive operations

- [ ] **A08: Software and Data Integrity Failures**
  - [ ] Verify JWT audience and issuer claims
  - [ ] Use integrity checks for dependencies (package-lock.json)
  - [ ] Implement audit logging for sensitive operations

- [ ] **A09: Security Logging and Monitoring Failures**
  - [ ] Mask PII in logs (passwords, tokens, SSN)
  - [ ] Log all authentication attempts (success and failure)
  - [ ] Implement centralized logging (ELK stack, Datadog)
  - [ ] Set up alerts for suspicious patterns

- [ ] **A10: Server-Side Request Forgery (SSRF)**
  - [ ] Validate and sanitize URLs before making HTTP requests
  - [ ] Whitelist allowed domains for external calls
  - [ ] Use circuit breakers to prevent abuse

### Additional Security Measures

- [ ] Enable CORS with explicit origin whitelist
- [ ] Implement CSP to prevent XSS
- [ ] Use `whitelist: true` in ValidationPipe
- [ ] Soft delete pattern to prevent data loss
- [ ] Field-level encryption for sensitive data
- [ ] Automated security scanning in CI/CD
- [ ] Regular penetration testing
- [ ] Security training for development team

---

**Next Steps:**
1. Run security scan script: `bash security-scan.sh`
2. Configure ESLint security rules: `npm run lint`
3. Review and apply all checklist items
4. Set up automated security audits in CI/CD pipeline
