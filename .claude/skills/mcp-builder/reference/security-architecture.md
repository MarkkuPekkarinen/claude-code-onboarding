# Security Architecture for Production MCP Servers

## Security Layers Diagram

```
External Request
    ↓
Security Headers
    ↓
Input Sanitization (DOMPurify)
    ↓
Attack Pattern Detection
    ↓
Threat Monitoring
    ↓
Audit Logging
    ↓
Business Logic
```

## Security Manager Implementation

### SecurityConfig Interface

```typescript
export interface SecurityConfig {
  sanitizationEnabled: boolean;
  attackDetectionEnabled: boolean;
  sqlInjectionDetection: boolean;
  xssDetection: boolean;
  pathTraversalDetection: boolean;
  commandInjectionDetection: boolean;
  maxInputLength: number;
}
```

### SecurityManager Class

```typescript
import { JSDOM } from 'jsdom';
import DOMPurify from 'dompurify';

export class SecurityManager {
  private config: SecurityConfig;
  private domPurify: DOMPurify.DOMPurifyI;

  constructor(config: SecurityConfig) {
    this.config = config;

    // Initialize DOMPurify with jsdom for server-side sanitization
    const window = new JSDOM('').window;
    this.domPurify = DOMPurify(window as unknown as Window);
  }

  /**
   * Recursively sanitize input data (strings, arrays, objects)
   */
  sanitizeInput(input: any): any {
    if (!this.config.sanitizationEnabled) {
      return input;
    }

    if (typeof input === 'string') {
      // Check max length
      if (this.config.maxInputLength > 0 && input.length > this.config.maxInputLength) {
        throw new Error(`Input exceeds maximum length of ${this.config.maxInputLength}`);
      }

      // Sanitize HTML content
      return this.domPurify.sanitize(input, {
        ALLOWED_TAGS: [], // Strip all HTML tags by default
        ALLOWED_ATTR: [],
        KEEP_CONTENT: true, // Keep text content
      });
    }

    if (Array.isArray(input)) {
      return input.map(item => this.sanitizeInput(item));
    }

    if (input !== null && typeof input === 'object') {
      const sanitized: Record<string, any> = {};
      for (const [key, value] of Object.entries(input)) {
        const sanitizedKey = this.sanitizeInput(key);
        sanitized[sanitizedKey] = this.sanitizeInput(value);
      }
      return sanitized;
    }

    return input;
  }

  /**
   * Detect common attack patterns in input strings
   */
  containsAttackPatterns(input: string): boolean {
    if (!this.config.attackDetectionEnabled) {
      return false;
    }

    const patterns = [
      // SQL Injection patterns
      ...(this.config.sqlInjectionDetection ? [
        /(\bSELECT\b.*\bFROM\b)/i,
        /(\bINSERT\b.*\bINTO\b)/i,
        /(\bUPDATE\b.*\bSET\b)/i,
        /(\bDELETE\b.*\bFROM\b)/i,
        /(\bUNION\b.*\bALL\b)/i,
        /(\bUNION\b.*\bSELECT\b)/i,
        /(\bOR\b\s+['"]*\d+\s*=\s*\d+)/i,
        /(\bAND\b\s+['"]*\d+\s*=\s*\d+)/i,
        /(--\s*$)/,
        /(;\s*DROP\b.*\bTABLE\b)/i,
        /('OR'.*'=')/i,
        /(\bEXEC\b|\bEXECUTE\b)/i,
      ] : []),

      // XSS patterns
      ...(this.config.xssDetection ? [
        /<script[^>]*>.*?<\/script>/gi,
        /javascript:/gi,
        /on\w+\s*=\s*["'][^"']*["']/gi, // onerror=, onclick=, etc.
        /<iframe/gi,
        /<object/gi,
        /<embed/gi,
        /eval\s*\(/gi,
        /expression\s*\(/gi,
      ] : []),

      // Path Traversal patterns
      ...(this.config.pathTraversalDetection ? [
        /\.\.\//g,
        /\.\.\\/g,
        /%2e%2e%2f/gi,
        /%2e%2e%5c/gi,
        /\/etc\/passwd/i,
        /\/etc\/shadow/i,
        /c:\\windows/i,
      ] : []),

      // Command Injection patterns
      ...(this.config.commandInjectionDetection ? [
        /[|&;`$()]/,
        /\$\{.*\}/,
        /\$\(.*\)/,
        /&&/,
        /\|\|/,
        />\s*&/,
        /<\s*&/,
      ] : []),
    ];

    return patterns.some(pattern => pattern.test(input));
  }

  /**
   * Validate and sanitize input, throw if attack patterns detected
   */
  validateInput(input: any): any {
    // First check for attack patterns (before sanitization to catch attempts)
    if (typeof input === 'string' && this.containsAttackPatterns(input)) {
      throw new Error('Potential attack pattern detected in input');
    }

    // Then sanitize
    return this.sanitizeInput(input);
  }

  /**
   * Get security headers for HTTP responses
   */
  getSecurityHeaders(): Record<string, string> {
    return {
      // Prevent XSS attacks
      'Content-Security-Policy': [
        "default-src 'self'",
        "script-src 'self'",
        "style-src 'self' 'unsafe-inline'",
        "img-src 'self' data: https:",
        "font-src 'self'",
        "connect-src 'self'",
        "frame-ancestors 'none'",
        "base-uri 'self'",
        "form-action 'self'",
      ].join('; '),

      // Prevent MIME type sniffing
      'X-Content-Type-Options': 'nosniff',

      // Prevent clickjacking
      'X-Frame-Options': 'DENY',

      // Enable browser XSS protection
      'X-XSS-Protection': '1; mode=block',

      // Enforce HTTPS
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',

      // Control referrer information
      'Referrer-Policy': 'strict-origin-when-cross-origin',

      // Control browser features
      'Permissions-Policy': [
        'geolocation=()',
        'microphone=()',
        'camera=()',
        'payment=()',
        'usb=()',
      ].join(', '),
    };
  }
}
```

### Default Security Configuration

```typescript
export const DEFAULT_SECURITY_CONFIG: SecurityConfig = {
  sanitizationEnabled: true,
  attackDetectionEnabled: true,
  sqlInjectionDetection: true,
  xssDetection: true,
  pathTraversalDetection: true,
  commandInjectionDetection: true,
  maxInputLength: 10000, // 10KB
};
```

## Security Middleware Integration

### Pre-Tool-Execution Hook

```typescript
import { SecurityManager, DEFAULT_SECURITY_CONFIG } from './security-manager.js';

export class SecureMCPServer {
  private securityManager: SecurityManager;

  constructor() {
    this.securityManager = new SecurityManager(DEFAULT_SECURITY_CONFIG);
  }

  /**
   * Middleware to sanitize and validate all tool arguments
   */
  private async securityMiddleware(toolName: string, args: any): Promise<any> {
    try {
      // Validate and sanitize all arguments
      const sanitizedArgs = this.securityManager.validateInput(args);

      // Log security event (audit trail)
      console.log('[SECURITY] Tool execution:', {
        tool: toolName,
        timestamp: new Date().toISOString(),
        sanitized: JSON.stringify(sanitizedArgs) !== JSON.stringify(args),
      });

      return sanitizedArgs;
    } catch (error) {
      // Log security violation
      console.error('[SECURITY VIOLATION]', {
        tool: toolName,
        error: error.message,
        args: JSON.stringify(args).substring(0, 200), // Log first 200 chars
        timestamp: new Date().toISOString(),
      });

      throw new Error(`Security validation failed: ${error.message}`);
    }
  }

  /**
   * Wrap tool handler with security checks
   */
  registerSecureTool(name: string, handler: (args: any) => Promise<any>) {
    return async (args: any) => {
      // Pre-execution: sanitize and validate
      const sanitizedArgs = await this.securityMiddleware(name, args);

      // Execute tool with sanitized arguments
      const result = await handler(sanitizedArgs);

      // Post-execution: sanitize output (if needed)
      return this.securityManager.sanitizeInput(result);
    };
  }
}
```

### HTTP Response Headers

```typescript
import express from 'express';
import { SecurityManager, DEFAULT_SECURITY_CONFIG } from './security-manager.js';

const app = express();
const securityManager = new SecurityManager(DEFAULT_SECURITY_CONFIG);

// Apply security headers to all responses
app.use((req, res, next) => {
  const headers = securityManager.getSecurityHeaders();
  Object.entries(headers).forEach(([key, value]) => {
    res.setHeader(key, value);
  });
  next();
});
```

### Complete Integration Example

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { SecurityManager, DEFAULT_SECURITY_CONFIG } from './security-manager.js';

export class ProductionMCPServer {
  private server: Server;
  private securityManager: SecurityManager;

  constructor() {
    this.server = new Server(
      { name: 'secure-mcp-server', version: '1.0.0' },
      { capabilities: { tools: {} } }
    );

    this.securityManager = new SecurityManager(DEFAULT_SECURITY_CONFIG);
    this.setupSecureTools();
  }

  private setupSecureTools() {
    this.server.setRequestHandler('tools/list', async () => ({
      tools: [
        {
          name: 'example_tool',
          description: 'Example secure tool',
          inputSchema: {
            type: 'object',
            properties: {
              query: { type: 'string' },
            },
          },
        },
      ],
    }));

    this.server.setRequestHandler('tools/call', async (request) => {
      const { name, arguments: args } = request.params;

      try {
        // Security layer: validate and sanitize
        const sanitizedArgs = this.securityManager.validateInput(args);

        // Execute tool
        const result = await this.executeTool(name, sanitizedArgs);

        // Sanitize output
        const sanitizedResult = this.securityManager.sanitizeInput(result);

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(sanitizedResult),
            },
          ],
        };
      } catch (error) {
        // Audit log security failures
        console.error('[SECURITY]', {
          tool: name,
          error: error.message,
          timestamp: new Date().toISOString(),
        });

        throw error;
      }
    });
  }

  private async executeTool(name: string, args: any): Promise<any> {
    // Tool implementation here
    return { status: 'success' };
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
  }
}
```

## Recommended Dependencies

```json
{
  "dependencies": {
    "dompurify": "~3.2.0",
    "jsdom": "~25.0.0"
  },
  "devDependencies": {
    "@types/dompurify": "~3.2.0",
    "@types/jsdom": "~21.1.0"
  }
}
```

## Installation

```bash
npm install dompurify jsdom
npm install --save-dev @types/dompurify @types/jsdom
```

## Testing Security Patterns

```typescript
import { describe, it, expect } from 'vitest';
import { SecurityManager, DEFAULT_SECURITY_CONFIG } from './security-manager.js';

describe('SecurityManager', () => {
  const manager = new SecurityManager(DEFAULT_SECURITY_CONFIG);

  it('should detect SQL injection patterns', () => {
    expect(manager.containsAttackPatterns("SELECT * FROM users WHERE id=1")).toBe(true);
    expect(manager.containsAttackPatterns("admin' OR '1'='1")).toBe(true);
    expect(manager.containsAttackPatterns("'; DROP TABLE users--")).toBe(true);
  });

  it('should detect XSS patterns', () => {
    expect(manager.containsAttackPatterns("<script>alert('xss')</script>")).toBe(true);
    expect(manager.containsAttackPatterns("javascript:alert(1)")).toBe(true);
    expect(manager.containsAttackPatterns("<img onerror='alert(1)'>")).toBe(true);
  });

  it('should detect path traversal patterns', () => {
    expect(manager.containsAttackPatterns("../../etc/passwd")).toBe(true);
    expect(manager.containsAttackPatterns("%2e%2e%2f")).toBe(true);
  });

  it('should detect command injection patterns', () => {
    expect(manager.containsAttackPatterns("file.txt; rm -rf /")).toBe(true);
    expect(manager.containsAttackPatterns("$(whoami)")).toBe(true);
    expect(manager.containsAttackPatterns("file.txt | cat")).toBe(true);
  });

  it('should sanitize HTML from strings', () => {
    const input = "<script>alert('test')</script>Hello";
    const sanitized = manager.sanitizeInput(input);
    expect(sanitized).not.toContain('<script>');
    expect(sanitized).toContain('Hello');
  });

  it('should recursively sanitize objects', () => {
    const input = {
      name: "<b>John</b>",
      nested: {
        value: "<script>alert(1)</script>",
      },
    };
    const sanitized = manager.sanitizeInput(input);
    expect(sanitized.name).toBe('John');
    expect(sanitized.nested.value).not.toContain('<script>');
  });

  it('should throw on input exceeding max length', () => {
    const longInput = 'a'.repeat(20000);
    expect(() => manager.sanitizeInput(longInput)).toThrow('exceeds maximum length');
  });
});
```

## Security Checklist

- [ ] Enable all security detection patterns
- [ ] Set appropriate `maxInputLength` for your use case
- [ ] Apply security headers to all HTTP responses
- [ ] Log all security violations to audit trail
- [ ] Sanitize both inputs and outputs
- [ ] Test with known attack patterns
- [ ] Rate-limit tool calls (not shown here, use library like `express-rate-limit`)
- [ ] Implement authentication/authorization before security layer
- [ ] Monitor logs for repeated security violations
- [ ] Keep DOMPurify and dependencies updated
