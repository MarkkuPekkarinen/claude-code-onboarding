# Error Taxonomy and Branded Types for Production MCP Servers

This document provides production-ready patterns for consistent error handling, type-safe IDs, and audit logging in MCP servers.

## 1. Error Taxonomy

### MCPErrorCode Enum

```typescript
export enum MCPErrorCode {
  // Client errors (4xx)
  INVALID_INPUT = 'INVALID_INPUT',
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',
  NOT_FOUND = 'NOT_FOUND',
  RATE_LIMITED = 'RATE_LIMITED',
  VALIDATION_FAILED = 'VALIDATION_FAILED',

  // Server errors (5xx)
  INTERNAL_ERROR = 'INTERNAL_ERROR',
  SERVICE_UNAVAILABLE = 'SERVICE_UNAVAILABLE',
  TIMEOUT = 'TIMEOUT',
  CIRCUIT_OPEN = 'CIRCUIT_OPEN',
  DEPENDENCY_FAILED = 'DEPENDENCY_FAILED',

  // Business logic errors
  BUSINESS_RULE_VIOLATION = 'BUSINESS_RULE_VIOLATION',
  INSUFFICIENT_BALANCE = 'INSUFFICIENT_BALANCE',
  DUPLICATE_OPERATION = 'DUPLICATE_OPERATION',
  OPERATION_NOT_ALLOWED = 'OPERATION_NOT_ALLOWED',
}
```

### MCPError Interface

```typescript
export interface MCPError {
  code: MCPErrorCode;
  message: string;
  details?: Record<string, unknown>;
  retry_after_ms?: number;
  recovery_actions: string[];
  fallback_tool?: string;
  correlation_id: string;
  timestamp: string;
}
```

### MCPErrorFactory Class

```typescript
import { randomUUID } from 'node:crypto';

export class MCPErrorFactory {
  private static readonly RECOVERY_MAP: Record<MCPErrorCode, string[]> = {
    [MCPErrorCode.RATE_LIMITED]: ['wait_and_retry', 'use_cached_data'],
    [MCPErrorCode.CIRCUIT_OPEN]: ['use_fallback_service', 'check_service_status'],
    [MCPErrorCode.TIMEOUT]: ['retry_with_timeout', 'reduce_request_scope'],
    [MCPErrorCode.VALIDATION_FAILED]: ['check_input_format', 'get_schema_info'],
    [MCPErrorCode.NOT_FOUND]: ['verify_resource_id', 'list_available_resources'],
    [MCPErrorCode.UNAUTHORIZED]: ['refresh_token', 'reauthenticate'],
    [MCPErrorCode.FORBIDDEN]: ['check_permissions', 'escalate_to_human'],
    [MCPErrorCode.INVALID_INPUT]: ['check_input_format', 'get_schema_info'],
    [MCPErrorCode.INTERNAL_ERROR]: ['retry_once', 'contact_support'],
    [MCPErrorCode.SERVICE_UNAVAILABLE]: ['wait_and_retry', 'use_fallback'],
    [MCPErrorCode.DEPENDENCY_FAILED]: ['use_fallback_service', 'retry_later'],
    [MCPErrorCode.BUSINESS_RULE_VIOLATION]: ['review_business_rules', 'escalate_to_human'],
    [MCPErrorCode.INSUFFICIENT_BALANCE]: ['check_balance', 'add_funds'],
    [MCPErrorCode.DUPLICATE_OPERATION]: ['get_existing_result', 'skip_operation'],
    [MCPErrorCode.OPERATION_NOT_ALLOWED]: ['check_permissions', 'escalate_to_human'],
  };

  static create(
    code: MCPErrorCode,
    message: string,
    options?: {
      details?: Record<string, unknown>;
      retry_after_ms?: number;
      fallback_tool?: string;
      correlation_id?: string;
    }
  ): MCPError {
    return {
      code,
      message,
      details: options?.details,
      retry_after_ms: options?.retry_after_ms,
      recovery_actions: this.getDefaultRecovery(code),
      fallback_tool: options?.fallback_tool,
      correlation_id: options?.correlation_id ?? randomUUID(),
      timestamp: new Date().toISOString(),
    };
  }

  static getDefaultRecovery(code: MCPErrorCode): string[] {
    return this.RECOVERY_MAP[code] ?? ['contact_support'];
  }
}
```

### Usage Example

```typescript
import { MCPErrorFactory, MCPErrorCode, MCPError } from './errors.js';

// In a tool handler
async function handleGetOrder(orderId: string): Promise<{ content: Array<{ type: string; text: string }> } | { isError: true; content: Array<{ type: string; text: string }> }> {
  try {
    const order = await orderService.getById(orderId);

    if (!order) {
      const error = MCPErrorFactory.create(
        MCPErrorCode.NOT_FOUND,
        `Order ${orderId} not found`,
        {
          details: { orderId },
          fallback_tool: 'list_orders',
        }
      );

      return {
        isError: true,
        content: [{ type: 'text', text: JSON.stringify(error, null, 2) }],
      };
    }

    return {
      content: [{ type: 'text', text: JSON.stringify(order, null, 2) }],
    };
  } catch (err) {
    const error = MCPErrorFactory.create(
      MCPErrorCode.INTERNAL_ERROR,
      'Failed to retrieve order',
      {
        details: {
          orderId,
          originalError: err instanceof Error ? err.message : String(err)
        },
      }
    );

    return {
      isError: true,
      content: [{ type: 'text', text: JSON.stringify(error, null, 2) }],
    };
  }
}
```

## 2. Branded Types (Type-Safe IDs)

### Brand Utility Type

```typescript
declare const brand: unique symbol;
export type Brand<T, B> = T & { [brand]: B };
```

### Branded Type Definitions

```typescript
export type UserId = Brand<string, 'UserId'>;
export type OrderId = Brand<string, 'OrderId'>;
export type SessionId = Brand<string, 'SessionId'>;
export type CorrelationId = Brand<string, 'CorrelationId'>;
```

### Type-Safe Constructors with Validation

```typescript
export const UserId = {
  from(value: string): UserId {
    if (!this.validate(value)) {
      throw new Error(`Invalid UserId format: ${value}`);
    }
    return value as UserId;
  },

  validate(value: string): boolean {
    return /^usr_[a-z0-9]{24}$/.test(value);
  },
};

export const OrderId = {
  from(value: string): OrderId {
    if (!this.validate(value)) {
      throw new Error(`Invalid OrderId format: ${value}`);
    }
    return value as OrderId;
  },

  validate(value: string): boolean {
    return /^ord_[a-z0-9]{24}$/.test(value);
  },
};

export const SessionId = {
  from(value: string): SessionId {
    if (!this.validate(value)) {
      throw new Error(`Invalid SessionId format: ${value}`);
    }
    return value as SessionId;
  },

  validate(value: string): boolean {
    return /^ses_[a-z0-9]{24}$/.test(value);
  },
};

export const CorrelationId = {
  from(value: string): CorrelationId {
    // UUIDs are valid correlation IDs
    if (!this.validate(value)) {
      throw new Error(`Invalid CorrelationId format: ${value}`);
    }
    return value as CorrelationId;
  },

  validate(value: string): boolean {
    return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
  },
};
```

### Integration with Zod Schemas

```typescript
import { z } from 'zod';

const orderSchema = z.object({
  orderId: z.string().refine(OrderId.validate, 'Invalid order ID format').transform(OrderId.from),
  userId: z.string().refine(UserId.validate, 'Invalid user ID format').transform(UserId.from),
  sessionId: z.string().refine(SessionId.validate, 'Invalid session ID format').transform(SessionId.from),
  amount: z.number().positive(),
  currency: z.enum(['USD', 'EUR', 'GBP']),
});

type OrderInput = z.infer<typeof orderSchema>;
// Type: { orderId: OrderId; userId: UserId; sessionId: SessionId; amount: number; currency: "USD" | "EUR" | "GBP"; }

// Validation
const result = orderSchema.safeParse({
  orderId: 'ord_abc123def456ghi789jkl012',
  userId: 'usr_xyz789uvw456rst123qpo987',
  sessionId: 'ses_lmn456opq789rst012uvw345',
  amount: 99.99,
  currency: 'USD',
});

if (result.success) {
  const order = result.data;
  await processOrder(order.orderId, order.userId);
}
```

### Compile-Time Error Prevention

```typescript
function processOrder(orderId: OrderId, userId: UserId): Promise<void> {
  // Implementation
  return Promise.resolve();
}

const userId = UserId.from('usr_abc123def456ghi789jkl012');
const orderId = OrderId.from('ord_xyz789uvw456rst123qpo987');

// OK: correct parameter order
await processOrder(orderId, userId);

// Type error: UserId is not assignable to OrderId parameter
// await processOrder(userId, orderId);

// Type error: string is not assignable to OrderId
// await processOrder('ord_123', userId);
```

## 3. Audit Logging

### AuditEntry Interface

```typescript
export interface AuditEntry {
  correlation_id: string;
  tool_name: string;
  tenant_id?: string;
  action: string;
  timestamp: string;
  input_hash: string;
  output_status: 'success' | 'error' | 'partial';
  duration_ms: number;
  user_id?: string;
  metadata?: Record<string, unknown>;
}
```

### AuditLogger Class

```typescript
import { createHash } from 'node:crypto';
import { appendFile } from 'node:fs/promises';
import { join } from 'node:path';

export class AuditLogger {
  private readonly logPath: string;

  constructor(logPath: string = './logs/audit.jsonl') {
    this.logPath = logPath;
  }

  async log(entry: Omit<AuditEntry, 'timestamp'>): Promise<void> {
    const fullEntry: AuditEntry = {
      ...entry,
      timestamp: new Date().toISOString(),
    };

    const logLine = JSON.stringify(fullEntry) + '\n';

    try {
      await appendFile(this.logPath, logLine, 'utf8');
    } catch (err) {
      console.error('Failed to write audit log:', err);
      // Don't throw - audit logging should not break app flow
    }
  }

  static hashInput(input: unknown): string {
    const hash = createHash('sha256');
    hash.update(JSON.stringify(input));
    return hash.digest('hex').substring(0, 16);
  }
}

// Usage in tool handler
const auditLogger = new AuditLogger();

async function handleToolCall(toolName: string, input: unknown, correlationId: string): Promise<unknown> {
  const startTime = Date.now();

  try {
    const result = await executeToolLogic(input);

    await auditLogger.log({
      correlation_id: correlationId,
      tool_name: toolName,
      action: 'execute',
      input_hash: AuditLogger.hashInput(input),
      output_status: 'success',
      duration_ms: Date.now() - startTime,
    });

    return result;
  } catch (err) {
    await auditLogger.log({
      correlation_id: correlationId,
      tool_name: toolName,
      action: 'execute',
      input_hash: AuditLogger.hashInput(input),
      output_status: 'error',
      duration_ms: Date.now() - startTime,
      metadata: {
        error: err instanceof Error ? err.message : String(err),
      },
    });

    throw err;
  }
}

async function executeToolLogic(input: unknown): Promise<unknown> {
  // Tool implementation
  return { success: true };
}
```

### Full Integration Example

```typescript
import { MCPErrorFactory, MCPErrorCode } from './errors.js';
import { OrderId, UserId } from './branded-types.js';
import { AuditLogger } from './audit.js';
import { z } from 'zod';

const orderInputSchema = z.object({
  orderId: z.string().refine(OrderId.validate).transform(OrderId.from),
  userId: z.string().refine(UserId.validate).transform(UserId.from),
});

const auditLogger = new AuditLogger();

async function getOrderTool(
  input: unknown,
  correlationId: string
): Promise<{ content: Array<{ type: string; text: string }> } | { isError: true; content: Array<{ type: string; text: string }> }> {
  const startTime = Date.now();

  // Validate input
  const parseResult = orderInputSchema.safeParse(input);
  if (!parseResult.success) {
    const error = MCPErrorFactory.create(
      MCPErrorCode.VALIDATION_FAILED,
      'Invalid input parameters',
      {
        details: { errors: parseResult.error.errors },
        correlation_id: correlationId,
      }
    );

    await auditLogger.log({
      correlation_id: correlationId,
      tool_name: 'get_order',
      action: 'validate_input',
      input_hash: AuditLogger.hashInput(input),
      output_status: 'error',
      duration_ms: Date.now() - startTime,
    });

    return {
      isError: true,
      content: [{ type: 'text', text: JSON.stringify(error, null, 2) }],
    };
  }

  const { orderId, userId } = parseResult.data;

  try {
    const order = await fetchOrder(orderId, userId);

    await auditLogger.log({
      correlation_id: correlationId,
      tool_name: 'get_order',
      action: 'fetch_order',
      input_hash: AuditLogger.hashInput(input),
      output_status: 'success',
      duration_ms: Date.now() - startTime,
      user_id: userId,
    });

    return {
      content: [{ type: 'text', text: JSON.stringify(order, null, 2) }],
    };
  } catch (err) {
    const error = MCPErrorFactory.create(
      MCPErrorCode.INTERNAL_ERROR,
      'Failed to fetch order',
      {
        details: { orderId, error: err instanceof Error ? err.message : String(err) },
        correlation_id: correlationId,
      }
    );

    await auditLogger.log({
      correlation_id: correlationId,
      tool_name: 'get_order',
      action: 'fetch_order',
      input_hash: AuditLogger.hashInput(input),
      output_status: 'error',
      duration_ms: Date.now() - startTime,
      user_id: userId,
      metadata: { error: err instanceof Error ? err.message : String(err) },
    });

    return {
      isError: true,
      content: [{ type: 'text', text: JSON.stringify(error, null, 2) }],
    };
  }
}

async function fetchOrder(orderId: OrderId, userId: UserId): Promise<unknown> {
  // Implementation
  return { orderId, userId, status: 'completed' };
}
```

## Best Practices

1. **Always use branded types for IDs** - Prevents passing wrong ID types to functions
2. **Validate at boundaries** - Use Zod schemas to validate and transform at API entry points
3. **Structured error responses** - Return MCPError objects with recovery actions, not plain strings
4. **Audit all tool calls** - Log correlation ID, duration, and outcome for observability
5. **Don't throw in audit logging** - Logging failures should not break application flow
6. **Hash sensitive inputs** - Store only SHA-256 hash prefixes in audit logs
7. **Use correlation IDs** - Propagate through entire request chain for distributed tracing
