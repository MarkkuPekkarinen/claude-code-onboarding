# A2UI Protocol — Action Model, Streaming, and A2A Integration

## Action Model

Actions are declared on interactive components (e.g., Button). When a user triggers the action, the renderer resolves any `{"path": "..."}` references against the current data model and sends a `userAction` message to the agent.

```json
{
  "action": {
    "name": "confirm_booking",
    "context": [
      {"key": "details", "value": {"path": "/reservation"}},
      {"key": "userId", "value": {"literalString": "u-123"}}
    ]
  }
}
```

### Action Context Fields

| Field | Description |
|-------|-------------|
| `name` | Action identifier — sent to the agent to identify which action was triggered |
| `context` | Array of key-value pairs providing data to the agent |
| `context[].key` | Named parameter for the agent |
| `context[].value` | Either `{"literalString": "..."}` for a static value or `{"path": "/..."}` for a reactive data model reference |

### Action Flow

```
User clicks "Book Now" button
    |
Renderer extracts action name + context from component definition
    |
Resolves any {"path": "..."} references against current data model
    |
userAction message sent to agent (same transport channel)
    |
Agent processes action and returns new A2UI JSONL payload
    |
Renderer applies surfaceUpdate / dataModelUpdate messages
```

---

## Streaming Protocol

A2UI uses **JSONL** (newline-delimited JSON) — one complete JSON message per line. This enables incremental rendering without buffering a full response.

| Transport | Format | Use Case |
|-----------|--------|----------|
| **SSE** (Server-Sent Events) | Each event data = one JSONL line | Simple, HTTP-based, auto-reconnect |
| **WebSocket** | Each message = one JSONL line | Bidirectional, actions sent on same connection |
| **REST** | Full response = multiple JSONL lines | Simplest, no streaming |
| **A2A** (Agent-to-Agent) | A2UI embedded in A2A messages | Multi-agent orchestration |

### JSONL Streaming Example

Each line is a complete, independently parseable JSON message:

```
{"surfaceUpdate":{"surfaceId":"main","components":[{"id":"root","component":{"type":"Column","children":{"explicitList":["card-1"]}}},{"id":"card-1","component":{"type":"Card","child":"text-1"}},{"id":"text-1","component":{"type":"Text","literalString":"Loading..."}}]}}
{"dataModelUpdate":{"surfaceId":"main","contents":[{"key":"price","valueString":"$450"}]}}
{"surfaceUpdate":{"surfaceId":"main","components":[{"id":"text-1","component":{"type":"Text","path":"/price","usageHint":"body"}}]}}
{"beginRendering":{"surfaceId":"main","root":"root"}}
```

A `surfaceUpdate` with a component ID that already exists replaces the previous version — this enables progressive updates as the agent streams more detail.

---

## A2A Integration

A2UI integrates with the Agent-to-Agent (A2A) protocol for multi-agent orchestration scenarios.

| Integration Detail | Value |
|--------------------|-------|
| A2A extension URI | `https://a2ui.org/a2a-extension/a2ui/v0.8` |
| MIME type | `application/json+a2ui` |

### Agent Card (server advertises capabilities)

```json
{
  "capabilities": {
    "extensions": [{
      "uri": "https://a2ui.org/a2a-extension/a2ui/v0.8",
      "params": {
        "supportedCatalogIds": ["https://example.com/catalog/v1"],
        "acceptsInlineCatalogs": true
      }
    }]
  }
}
```

### A2A Message Metadata (client declares capabilities)

```json
{
  "metadata": {
    "a2uiClientCapabilities": {
      "supportedCatalogIds": ["https://example.com/catalog/v1"],
      "inlineCatalogs": [
        {
          "catalogId": "https://example.com/catalog/v1",
          "components": {},
          "styles": {}
        }
      ]
    }
  }
}
```

### Python ADK Integration

The Python ADK (Google ADK) provides schema manager and validation utilities for A2UI:

- LLM output is validated against the effective catalog before transmission
- The schema manager enforces component property types and required fields
- Unknown component types are rejected at the ADK layer before the client receives them

---

## Versioning

- Renderers should handle unknown properties gracefully (ignore, don't crash)
- Renderers must reject unknown component types (not in catalog)
- The `v0.8` extension URI in A2A messages identifies the protocol version in multi-agent contexts
