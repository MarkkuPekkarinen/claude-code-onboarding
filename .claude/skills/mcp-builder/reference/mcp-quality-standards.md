# MCP Quality Standards

## Security Best Practices

### Authentication and Authorization

**OAuth 2.1 with PKCE** (Production Auth):
- Use OAuth 2.1 with PKCE (Proof Key for Code Exchange) — required for all clients
- Validate access tokens before processing requests
- Only accept tokens specifically intended for your server
- Implement token refresh with `refresh_token` grant type
- Use Redis-backed token storage for production (TTL-based expiry)
- Require `code_challenge` with S256 method for all authorization requests
- See [production-deployment.md](production-deployment.md) for full OAuth implementation

**API Keys**:
- Store API keys in environment variables, never in code
- Validate keys on server startup
- Provide clear error messages when authentication fails

### Input Validation

- Sanitize file paths to prevent directory traversal
- Validate URLs and external identifiers
- Check parameter sizes and ranges
- Prevent command injection in system calls
- Use schema validation (Pydantic/Zod) for all inputs

### Error Handling

- Don't expose internal errors to clients
- Log security-relevant errors server-side
- Provide helpful but not revealing error messages
- Clean up resources after errors

### DNS Rebinding Protection

For streamable HTTP servers running locally:
- Enable DNS rebinding protection
- Validate the `Origin` header on all incoming connections
- Bind to `127.0.0.1` rather than `0.0.0.0`

---

## Tool Annotations

Provide annotations to help clients understand tool behavior:

| Annotation | Type | Default | Description |
|-----------|------|---------|-------------|
| `readOnlyHint` | boolean | false | Tool does not modify its environment |
| `destructiveHint` | boolean | true | Tool may perform destructive updates |
| `idempotentHint` | boolean | false | Repeated calls with same args have no additional effect |
| `openWorldHint` | boolean | true | Tool interacts with external entities |

**Important**: Annotations are hints, not security guarantees. Clients should not make security-critical decisions based solely on annotations.

---

## Error Handling

- Use standard JSON-RPC error codes
- Report tool errors within result objects (not protocol-level errors)
- Provide helpful, specific error messages with suggested next steps
- Don't expose internal implementation details
- Clean up resources properly on errors

Example error handling:
```typescript
try {
  const result = performOperation();
  return { content: [{ type: "text", text: result }] };
} catch (error) {
  return {
    isError: true,
    content: [{
      type: "text",
      text: `Error: ${error.message}. Try using filter='active_only' to reduce results.`
    }]
  };
}
```

---

## Testing Requirements

Comprehensive testing should cover:

- **Functional testing**: Verify correct execution with valid/invalid inputs
- **Integration testing**: Test interaction with external systems
- **Security testing**: Validate auth, input sanitization, rate limiting
- **Performance testing**: Check behavior under load, timeouts
- **Error handling**: Ensure proper error reporting and cleanup

---

## Documentation Requirements

- Provide clear documentation of all tools and capabilities
- Include working examples (at least 3 per major feature)
- Document security considerations
- Specify required permissions and access levels
- Document rate limits and performance characteristics

---

## Audit Logging Requirements

Every MCP server MUST implement audit logging:

- Generate a `correlation_id` for every incoming request
- Log tool invocations with: tool name, input hash (not raw input), output status, duration
- Include tenant context if multi-tenant (tenant_id, organization_id)
- Track the full tool chain for multi-step operations
- Log all security-relevant events (auth failures, attack pattern detections, escalations)
- See [error-taxonomy.md](error-taxonomy.md) for AuditLogger implementation

---

## MCP Protocol Primitives

MCP has THREE core primitives — implement all three:

| Primitive | Purpose | Control | Registration |
|-----------|---------|---------|-------------|
| **Tools** | Actions with side effects | Model-invoked | `server.registerTool()` |
| **Resources** | Read-only data access | App-controlled | `server.registerResource()` |
| **Prompts** | Reusable templates | User-triggered | `server.registerPrompt()` |

### Prompts Registration

Prompts are reusable templates that users can trigger:

```typescript
server.registerPrompt(
  "code_review",
  {
    title: "Code Review",
    description: "Generate a structured code review for the given code",
    argsSchema: {
      code: z.string().describe("Code to review"),
      language: z.string().describe("Programming language"),
      focus: z.enum(["security", "performance", "readability"]).optional(),
    },
  },
  async ({ code, language, focus }) => ({
    messages: [{
      role: "user",
      content: {
        type: "text",
        text: `Review this ${language} code${focus ? ` with focus on ${focus}` : ''}:\n\n\`\`\`${language}\n${code}\n\`\`\`\n\nProvide:\n1. Summary\n2. Issues found (with severity)\n3. Suggested improvements\n4. Security considerations`,
      },
    }],
  })
);
```

Always register Prompts for common workflows that agents or users frequently need.
