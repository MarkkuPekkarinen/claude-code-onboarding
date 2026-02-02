---
name: mcp-builder
description: Guide for creating high-quality MCP (Model Context Protocol) servers that enable LLMs to interact with external services through well-designed tools. Use when building MCP servers to integrate external APIs or services, whether in Python (FastMCP) or Node/TypeScript (MCP SDK).
license: Complete terms in LICENSE.txt
---

# MCP Server Development Guide

Create MCP servers that enable LLMs to interact with external services through well-designed tools. Quality is measured by how well the server enables LLMs to accomplish real-world tasks.

## High-Level Workflow

### Phase 1: Deep Research and Planning

Research the target API, study the MCP protocol, and plan tool coverage.

- Study MCP spec starting from sitemap: `https://modelcontextprotocol.io/sitemap.xml` (append `.md` for markdown format)
- For MCP design principles and guidelines -> Read [reference/mcp_best_practices.md](reference/mcp_best_practices.md)
- For TypeScript SDK docs -> Fetch `https://raw.githubusercontent.com/modelcontextprotocol/typescript-sdk/main/README.md`
- For Python SDK docs -> Fetch `https://raw.githubusercontent.com/modelcontextprotocol/python-sdk/main/README.md`
- Prioritize comprehensive API coverage over workflow-specific tools
- Use clear, action-oriented tool names with consistent prefixes (e.g., `github_create_issue`)

### Phase 2: Implementation

Set up project structure, implement core infrastructure, then build tools.

- For TypeScript project setup and patterns -> Read [reference/node_mcp_server.md](reference/node_mcp_server.md)
- For Python project setup and patterns -> Read [reference/python_mcp_server.md](reference/python_mcp_server.md)
- **Recommended stack**: TypeScript with streamable HTTP (remote) or stdio (local)
- Create shared utilities: API client, error handling, response formatting, pagination
- For each tool: define input schema (Zod/Pydantic), output schema, description, annotations, and async implementation

### Phase 3: Review and Test

Verify code quality and test the server.

- Review for: no duplication, consistent error handling, full type coverage, clear tool descriptions
- TypeScript: `npm run build` then test with `npx @modelcontextprotocol/inspector`
- Python: `python -m py_compile your_server.py` then test with MCP Inspector
- See language-specific guides for detailed quality checklists

### Phase 4: Create Evaluations

Build 10 evaluation questions to test server effectiveness.

- For complete evaluation guidelines -> Read [reference/evaluation.md](reference/evaluation.md)
- Create 10 complex, realistic questions requiring multiple tool calls
- Each question must be: independent, read-only, complex, realistic, verifiable, stable
- Output as XML with `<evaluation>` root containing `<qa_pair>` elements

## Tool Implementation Checklist

For each tool, define:
- **Input schema** - Zod (TypeScript) or Pydantic (Python) with constraints and descriptions
- **Output schema** - Use `outputSchema` and `structuredContent` where possible
- **Description** - Concise summary, parameter docs, return type
- **Annotations** - `readOnlyHint`, `destructiveHint`, `idempotentHint`, `openWorldHint`
- **Implementation** - Async/await, proper error handling, pagination support

## Reference Files

Load these as needed during development:

| Resource | When to Load |
|----------|-------------|
| [MCP Best Practices](reference/mcp_best_practices.md) | Phase 1 - design principles |
| [TypeScript Guide](reference/node_mcp_server.md) | Phase 2 - TypeScript implementation |
| [Python Guide](reference/python_mcp_server.md) | Phase 2 - Python implementation |
| [Evaluation Guide](reference/evaluation.md) | Phase 4 - creating evaluations |
| MCP Protocol Spec | Phase 1 - fetch from `modelcontextprotocol.io` |
| TypeScript SDK README | Phase 1 - fetch from GitHub |
| Python SDK README | Phase 1 - fetch from GitHub |
