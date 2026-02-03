# MCP Server Best Practices

## Quick Reference

### Server Naming
- **Python**: `{service}_mcp` (e.g., `slack_mcp`)
- **Node/TypeScript**: `{service}-mcp-server` (e.g., `slack-mcp-server`)

### Tool Naming
- Use snake_case with service prefix
- Format: `{service}_{action}_{resource}`
- Example: `slack_send_message`, `github_create_issue`

### Response Formats
- Support both JSON and Markdown formats
- JSON for programmatic processing
- Markdown for human readability

### Pagination
- Always respect `limit` parameter
- Return `has_more`, `next_offset`, `total_count`
- Default to 20-50 items

### Agent-Directive Responses
- Every tool response MUST include `next_actions` (machine-readable) and `suggestion` (human-readable)
- Use `formatAgentResponse<T>()` helper (see agent-design-patterns.md)
- Include `context` for state chaining between tool calls

### Tool Count Limits
- IDEAL: 10-15 tools — optimal agent performance
- ACCEPTABLE: 16-25 tools — manageable with good descriptions
- WARNING: 26-30 tools — consider consolidation
- CRITICAL: 31+ tools — agent decision paralysis

### Transport
- **Streamable HTTP**: For remote servers, multi-client scenarios
- **stdio**: For local integrations, command-line tools
- Avoid SSE (deprecated in favor of streamable HTTP)

---

## Server Naming Conventions

Follow these standardized naming patterns:

**Python**: Use format `{service}_mcp` (lowercase with underscores)
- Examples: `slack_mcp`, `github_mcp`, `jira_mcp`

**Node/TypeScript**: Use format `{service}-mcp-server` (lowercase with hyphens)
- Examples: `slack-mcp-server`, `github-mcp-server`, `jira-mcp-server`

The name should be general, descriptive of the service being integrated, easy to infer from the task description, and without version numbers.

---

## Tool Naming and Design

### Tool Naming

1. **Use snake_case**: `search_users`, `create_project`, `get_channel_info`
2. **Include service prefix**: Anticipate that your MCP server may be used alongside other MCP servers
   - Use `slack_send_message` instead of just `send_message`
   - Use `github_create_issue` instead of just `create_issue`
3. **Be action-oriented**: Start with verbs (get, list, search, create, etc.)
4. **Be specific**: Avoid generic names that could conflict with other servers

### Tool Design

- Tool descriptions must narrowly and unambiguously describe functionality
- Descriptions must precisely match actual functionality
- Provide tool annotations (readOnlyHint, destructiveHint, idempotentHint, openWorldHint)
- Keep tool operations focused and atomic

### Intent-Based Tool Consolidation

Consolidate CRUD operations into intent-based tools to reduce agent cognitive load:

```typescript
// WRONG: 6 separate tools (decision paralysis for agents)
tools: ["createUser", "readUser", "updateUser", "deleteUser", "getUserById", "searchUsers"]

// RIGHT: 2 intent-based tools (clear purpose)
tools: ["manageUser", "searchUsers"]

// manageUser tool definition
{
  name: "manageUser",
  description: "Unified user management (create/read/update/delete)",
  inputSchema: z.object({
    action: z.enum(["create", "read", "update", "delete"]),
    userId: z.string().optional(),
    data: z.record(z.any()).optional(),
  }),
}
```

### escalate_to_human Tool (Mandatory)

Every MCP server MUST include an `escalate_to_human` tool for:
- Life-safety decisions
- Fraud detection requiring human review
- High-value operations above threshold
- Ambiguous situations where confidence is low

```typescript
server.registerTool(
  "escalate_to_human",
  {
    title: "Escalate to Human",
    description: "Escalate to human operator for review. MUST be used for life-safety, fraud, or high-value decisions.",
    inputSchema: {
      reason: z.string().describe("Why human review is needed"),
      severity: z.enum(["low", "medium", "high", "critical"]),
      context: z.record(z.any()).describe("Relevant context for the human reviewer"),
    },
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false }
  },
  async ({ reason, severity, context }) => {
    // Log escalation and notify human operator
    return {
      content: [{ type: "text", text: JSON.stringify({
        success: true,
        data: { escalation_id: generateId(), status: "pending_review" },
        next_actions: ["check_escalation_status"],
        suggestion: "Escalation submitted. Wait for human review before proceeding.",
      })}]
    };
  }
);
```

---

## Response Formats

All tools that return data should support multiple formats:

### JSON Format (`response_format="json"`)
- Machine-readable structured data
- Include all available fields and metadata
- Consistent field names and types
- Use for programmatic processing

### Markdown Format (`response_format="markdown"`, typically default)
- Human-readable formatted text
- Use headers, lists, and formatting for clarity
- Convert timestamps to human-readable format
- Show display names with IDs in parentheses
- Omit verbose metadata

---

## Pagination

For tools that list resources:

- **Always respect the `limit` parameter**
- **Implement pagination**: Use `offset` or cursor-based pagination
- **Return pagination metadata**: Include `has_more`, `next_offset`/`next_cursor`, `total_count`
- **Never load all results into memory**: Especially important for large datasets
- **Default to reasonable limits**: 20-50 items is typical

Example pagination response:
```json
{
  "total": 150,
  "count": 20,
  "offset": 0,
  "items": [...],
  "has_more": true,
  "next_offset": 20
}
```

---

## Transport Options

### Streamable HTTP

**Best for**: Remote servers, web services, multi-client scenarios

**Characteristics**:
- Bidirectional communication over HTTP
- Supports multiple simultaneous clients
- Can be deployed as a web service
- Enables server-to-client notifications

**Use when**:
- Serving multiple clients simultaneously
- Deploying as a cloud service
- Integration with web applications

### stdio

**Best for**: Local integrations, command-line tools

**Characteristics**:
- Standard input/output stream communication
- Simple setup, no network configuration needed
- Runs as a subprocess of the client

**Use when**:
- Building tools for local development environments
- Integrating with desktop applications
- Single-user, single-session scenarios

**Note**: stdio servers should NOT log to stdout (use stderr for logging)

### Transport Selection

| Criterion | stdio | Streamable HTTP |
|-----------|-------|-----------------|
| **Deployment** | Local | Remote |
| **Clients** | Single | Multiple |
| **Complexity** | Low | Medium |
| **Real-time** | No | Yes |
