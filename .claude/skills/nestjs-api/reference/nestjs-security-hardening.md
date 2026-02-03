# NestJS Security Hardening Guide

Enterprise security hardening for NestJS 11.x covering OWASP protections, headers, CORS, validation, logging, and Prisma security.

**Note:** For authentication and authorization patterns (JWT, passwords, rate limiting), see `nestjs-security-auth.md`.

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
      action: 'deny',
    },

    // X-Content-Type-Options — prevents MIME sniffing
    noSniff: true,

    // X-DNS-Prefetch-Control
    dnsPrefetchControl: {
      allow: false,
    },

    // Cross-Origin-Resource-Policy
    crossOriginResourcePolicy: {
      policy: 'same-origin',
    },

    // Cross-Origin-Opener-Policy
    crossOriginOpenerPolicy: {
      policy: 'same-origin',
    },

    // Referrer-Policy
    referrerPolicy: {
      policy: 'no-referrer',
    },

    // Permissions-Policy
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

## 5. CORS Best Practices

### Production CORS Configuration

```typescript
// src/main.ts
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter } from '@nestjs/platform-fastify';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, new FastifyAdapter());
  const configService = app.get(ConfigService);

  const allowedOrigins = configService
    .get<string>('ALLOWED_ORIGINS')
    .split(',')
    .map((origin) => origin.trim());

  app.enableCors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'X-Correlation-Id',
    ],
    exposedHeaders: ['X-Total-Count', 'X-Page-Number'],
    maxAge: 86400,
    preflightContinue: false,
    optionsSuccessStatus: 204,
  });

  await app.listen(3000);
}
bootstrap();
```

## 6. Input Validation Hardening

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
  ValidateNested,
  IsArray,
  ArrayMaxSize,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import * as DOMPurify from 'isomorphic-dompurify';

export class CreateUserDto {
  @IsEmail({}, { message: 'Invalid email format' })
  @MaxLength(255)
  email: string;

  @IsString()
  @MinLength(12, { message: 'Password must be at least 12 characters' })
  @MaxLength(128)
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]+$/,
    {
      message: 'Password must contain uppercase, lowercase, number, and special character',
    },
  )
  password: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(50)
  @Matches(/^[a-zA-Z\s'-]+$/, { message: 'Name contains invalid characters' })
  @Transform(({ value }) => DOMPurify.sanitize(value.trim()))
  firstName: string;

  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  tags: string[];
}
```

### Global Validation Pipe

```typescript
// src/main.ts
import { ValidationPipe } from '@nestjs/common';

app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
    disableErrorMessages: process.env.NODE_ENV === 'production',
  }),
);
```

## 7. Secure Logging — PII Masking

### Log Sanitizer Service

```typescript
// src/common/logging/log-sanitizer.service.ts
import { Injectable } from '@nestjs/common';

@Injectable()
export class LogSanitizerService {
  private readonly sensitivePatterns = [
    { pattern: /"password":\s*"[^"]*"/gi, replacement: '"password":"***MASKED***"' },
    { pattern: /"token":\s*"[^"]*"/gi, replacement: '"token":"***MASKED***"' },
    { pattern: /\b\d{3}-\d{2}-\d{4}\b/g, replacement: '***-**-****' }, // SSN
    { pattern: /\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/g, replacement: '****-****-****-****' }, // Credit card
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
      sanitized[key] = this.isSensitiveKey(key) ? this.maskValue(value) : this.sanitize(value);
    }
    return sanitized;
  }

  private isSensitiveKey(key: string): boolean {
    const sensitiveKeys = ['password', 'token', 'apiKey', 'secret', 'ssn', 'creditCard'];
    return sensitiveKeys.some((s) => key.toLowerCase().includes(s.toLowerCase()));
  }

  private maskValue(value: unknown): string {
    if (typeof value !== 'string' || value.length <= 4) return '***';
    return `${value.substring(0, 2)}***${value.substring(value.length - 2)}`;
  }
}
```

## 8. Prisma Security

### Avoid SQL Injection

```typescript
// ❌ DANGEROUS
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
  return this.prisma.user.findUnique({ where: { email } });
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

### Soft Delete Pattern

```typescript
// prisma/schema.prisma
model User {
  id        String    @id @default(uuid())
  email     String    @unique
  deletedAt DateTime? @map("deleted_at")

  @@map("users")
}

// Repository
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
      where: { id, deletedAt: null },
    });
  }
}
```

## 9. Security Checklist

### OWASP Top 10 Mitigations

- [ ] **A01: Broken Access Control** — Implement RBAC with guards on protected routes
- [ ] **A02: Cryptographic Failures** — Use bcrypt (cost >=12), RS256 for JWT, encrypt sensitive DB fields
- [ ] **A03: Injection** — Never use string concatenation in queries, validate all inputs with DTOs
- [ ] **A04: Insecure Design** — Implement rate limiting, circuit breakers, fail-fast config
- [ ] **A05: Security Misconfiguration** — Run npm audit in CI/CD, configure Helmet, disable stack traces in prod
- [ ] **A06: Vulnerable Components** — Automate dependency scanning (Snyk), keep dependencies updated
- [ ] **A07: Auth Failures** — Short-lived tokens (15 min), refresh token rotation, token revocation, rate limit auth endpoints
- [ ] **A08: Data Integrity Failures** — Verify JWT claims, use integrity checks, implement audit logging
- [ ] **A09: Logging Failures** — Mask PII in logs, log all auth attempts, centralized logging, alerting
- [ ] **A10: SSRF** — Validate/sanitize URLs, whitelist allowed domains, use circuit breakers

### Additional Measures

- [ ] Enable CORS with explicit origin whitelist
- [ ] Implement CSP to prevent XSS
- [ ] Use `whitelist: true` in ValidationPipe
- [ ] Soft delete pattern to prevent data loss
- [ ] Field-level encryption for sensitive data
- [ ] Automated security scanning in CI/CD
- [ ] Regular penetration testing

---

**Next Steps:**
1. Run security scan: `bash security-scan.sh`
2. Configure ESLint security rules: `npm run lint`
3. Review and apply all checklist items
4. Set up automated security audits in CI/CD
