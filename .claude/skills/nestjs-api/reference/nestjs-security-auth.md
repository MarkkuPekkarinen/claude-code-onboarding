# NestJS Security — Authentication & Authorization

Enterprise authentication patterns for NestJS 11.x with JWT, bcrypt, and rate limiting.

## JWT Security Best Practices

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

## Rate Limiting Deep Dive

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
