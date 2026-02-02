# Node/TypeScript MCP Server -- Setup and Configuration

## Overview

Node/TypeScript-specific setup for MCP servers using the MCP TypeScript SDK. Covers project structure, package configuration, server initialization, naming conventions, and build/run workflow.

---

## Quick Reference

### Key Imports
```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import express from "express";
import { z } from "zod";
```

### Server Initialization
```typescript
const server = new McpServer({
  name: "service-mcp-server",
  version: "1.0.0"
});
```

### Tool Registration Pattern
```typescript
server.registerTool(
  "tool_name",
  {
    title: "Tool Display Name",
    description: "What the tool does",
    inputSchema: { param: z.string() },
    outputSchema: { result: z.string() }
  },
  async ({ param }) => {
    const output = { result: `Processed: ${param}` };
    return {
      content: [{ type: "text", text: JSON.stringify(output) }],
      structuredContent: output
    };
  }
);
```

---

## MCP TypeScript SDK

The official MCP TypeScript SDK provides:
- `McpServer` class for server initialization
- `registerTool` method for tool registration
- Zod schema integration for runtime input validation
- Type-safe tool handler implementations

**IMPORTANT - Use Modern APIs Only:**
- **DO use**: `server.registerTool()`, `server.registerResource()`, `server.registerPrompt()`
- **DO NOT use**: Old deprecated APIs such as `server.tool()`, `server.setRequestHandler(ListToolsRequestSchema, ...)`, or manual handler registration
- The `register*` methods provide better type safety, automatic schema handling, and are the recommended approach

## Server Naming Convention

Node/TypeScript MCP servers must follow this naming pattern:
- **Format**: `{service}-mcp-server` (lowercase with hyphens)
- **Examples**: `github-mcp-server`, `jira-mcp-server`, `stripe-mcp-server`

The name should be:
- General (not tied to specific features)
- Descriptive of the service/API being integrated
- Easy to infer from the task description
- Without version numbers or dates

## Project Structure

```
{service}-mcp-server/
├── package.json
├── tsconfig.json
├── README.md
├── src/
│   ├── index.ts          # Main entry point with McpServer initialization
│   ├── types.ts          # TypeScript type definitions and interfaces
│   ├── tools/            # Tool implementations (one file per domain)
│   ├── services/         # API clients and shared utilities
│   ├── schemas/          # Zod validation schemas
│   └── constants.ts      # Shared constants (API_URL, CHARACTER_LIMIT, etc.)
└── dist/                 # Built JavaScript files (entry point: dist/index.js)
```

## Package Configuration

### package.json

```json
{
  "name": "{service}-mcp-server",
  "version": "1.0.0",
  "description": "MCP server for {Service} API integration",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "start": "node dist/index.js",
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "clean": "rm -rf dist"
  },
  "engines": {
    "node": ">=18"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.6.1",
    "axios": "^1.7.9",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/node": "^22.10.0",
    "tsx": "^4.19.2",
    "typescript": "^5.7.2"
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "allowSyntheticDefaultImports": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Building and Running

Always build TypeScript code before running:

```bash
# Build the project
npm run build

# Run the server
npm start

# Development with auto-reload
npm run dev
```

Always ensure `npm run build` completes successfully before considering the implementation complete.
