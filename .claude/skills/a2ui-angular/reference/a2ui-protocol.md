# A2UI Protocol Reference

## Overview

A2UI (Agent-to-User Interface) is a declarative protocol that enables AI agents to generate rich, interactive UIs safely. Agents describe UIs using structured JSONL messages; clients render using their own native components.

- **Spec version:** v0.8 (public preview)
- **Official site:** https://a2ui.org/
- **GitHub:** https://github.com/google/A2UI
- **Angular package:** `npm install @a2ui/angular`

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Security** | Declarative data format — no executable code. Agents use pre-approved component catalog only |
| **LLM-Friendly** | Flat component array — models stream components incrementally without managing nested brackets |
| **Framework-Agnostic** | Same payload renders on Angular, React, Flutter, SwiftUI — each uses native components |
| **Progressive Rendering** | UIs update in real-time as components stream in via JSONL |

## Architecture Flow

```
User sends message
    |
AI Agent processes request
    |
Agent generates A2UI JSONL response (one message per line)
    |
Transport: REST / WebSocket / SSE / A2A protocol
    |
Client receives A2UI messages
    |
Renderer validates components against catalog (allowlist)
    |
Renderer maps validated components to native framework components
    |
User sees interactive UI
    |
User interacts (click, input, etc.)
    |
userAction sent back to agent as structured data
    |
Agent responds with updated A2UI JSONL payload
```

## Message Types

A2UI defines five message types delivered as JSONL (newline-delimited JSON — one JSON object per line). Four are agent-to-client; one is client-to-agent.

| Message Type | Direction | Purpose |
|--------------|-----------|---------|
| `surfaceUpdate` | agent → client | Adds or updates UI components on a named surface |
| `dataModelUpdate` | agent → client | Populates reactive state with typed values |
| `beginRendering` | agent → client | Signals client to render a surface with a specified root component |
| `deleteSurface` | agent → client | Removes a surface and all associated components and data |
| `userAction` | client → agent | Reports a user interaction back to the agent |

### Recommended Message Order (agent → client)

1. `surfaceUpdate` — define components
2. `dataModelUpdate` — populate data
3. `beginRendering` — signal ready to render

---

## surfaceUpdate

Defines or updates a surface's component tree. Components are stored as a flat array of `{id, component}` objects; parent-child relationships are declared via `explicitList` on the parent's `children` field.

```json
{
  "surfaceUpdate": {
    "surfaceId": "main",
    "components": [
      {
        "id": "root",
        "component": {
          "type": "Column",
          "children": {"explicitList": ["card-1", "btn-book"]}
        }
      },
      {
        "id": "card-1",
        "component": {
          "type": "Card",
          "child": "text-1"
        }
      },
      {
        "id": "btn-book",
        "component": {
          "type": "Button",
          "child": "btn-label",
          "action": {
            "name": "book_flight",
            "context": [{"key": "flightId", "value": {"literalString": "FL-123"}}]
          },
          "primary": true
        }
      },
      {
        "id": "btn-label",
        "component": {
          "type": "Text",
          "literalString": "Book Now"
        }
      },
      {
        "id": "text-1",
        "component": {
          "type": "Text",
          "literalString": "Price valid until March 15",
          "usageHint": "body"
        }
      }
    ]
  }
}
```

CRITICAL: `components` is an **array** of `{id, component}` objects — NOT a Record/map keyed by component ID.

### Component Field Structure

| Field | Format | Description |
|-------|--------|-------------|
| `id` | string | Unique identifier for this component within the surface |
| `component` | object | The component definition (type + properties) |
| `type` | string | Component type — must exist in client's catalog |
| `children` | `{"explicitList": ["id1", "id2"]}` | Ordered list of child component IDs (Row, Column, etc.) |
| `child` | string | Single child component ID (Card, Button, Modal, etc.) |
| Text fields | `{"literalString": "value"}` or `{"path": "/json/pointer"}` | Static string or JSON Pointer into reactive data model |
| `action` | `{"name": "...", "context": [...]}` | Action triggered on interaction |

### Property Value Formats

```json
{"literalString": "static text"}
{"path": "/json/pointer"}
{"path": "/user/name", "literalString": "Guest"}
```

The combined form `{path, literalString}` binds to the path but falls back to the `literalString` default when the path resolves to null or is absent.

### Why Flat Array, Not Nested?

| Nested Tree | Flat Component Array (A2UI) |
|---|---|
| Model must track bracket depth | Model emits one component entry at a time |
| Partial JSON is unparseable | Each component is independently parseable |
| Streaming requires buffering | Components render as they arrive |
| Errors cascade (unclosed bracket breaks everything) | Malformed component is skipped, rest renders |

Children are referenced by ID via `explicitList` (or `child` for single-child components) rather than nesting — this is the mechanism that replaces `parentId` from earlier drafts.

---

## dataModelUpdate

Populates the reactive data model for a surface. Components reference this data via JSON Pointer paths using the `{"path": "/..."}` field format.

```json
{
  "dataModelUpdate": {
    "surfaceId": "main",
    "path": "/reservation",
    "contents": [
      {"key": "date", "valueString": "2026-04-01"},
      {"key": "guests", "valueNumber": 2},
      {"key": "details", "valueMap": [{"key": "hotel", "valueString": "Grand Paris"}]}
    ]
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `surfaceId` | No | Target surface (omit for global data) |
| `path` | No | JSON Pointer (RFC 6901) — root path within the data model to write into |
| `contents` | Yes | Array of typed key-value entries |

### Typed Value Variants in `contents[]`

| Variant | Type | Example |
|---------|------|---------|
| `valueString` | string | `{"key": "date", "valueString": "2026-04-01"}` |
| `valueNumber` | number | `{"key": "guests", "valueNumber": 2}` |
| `valueMap` | array | `{"key": "details", "valueMap": [...]}` |

Components bind to these values using JSON Pointer paths, for example:

```json
{"path": "/reservation/date"}
```

---

## beginRendering

Signals the client that a surface is ready to render. The client mounts the root component and displays the surface.

```json
{
  "beginRendering": {
    "surfaceId": "main",
    "root": "root",
    "catalogId": "https://example.com/catalog/v1"
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `surfaceId` | Yes | Surface to begin rendering |
| `root` | Yes | Component ID to use as the root of the surface |
| `catalogId` | No | URI identifying which component catalog to use for this surface |

This message is typically sent after the initial `surfaceUpdate` and `dataModelUpdate` messages have populated the surface.

---

## deleteSurface

Removes a named surface and all its associated components and data model entries.

```json
{
  "deleteSurface": {
    "surfaceId": "main"
  }
}
```

---

## userAction

Sent from the **client to the agent** when the user interacts with an A2UI component (e.g., clicks a Button). This is the only client-to-agent message type.

```json
{
  "userAction": {
    "name": "book_flight",
    "surfaceId": "main",
    "sourceComponentId": "btn-book",
    "timestamp": "2026-03-10T14:23:00Z",
    "context": {
      "flightId": "FL-123",
      "passengerCount": 2
    }
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Action identifier — matches the `action.name` on the component that was triggered |
| `surfaceId` | Yes | Surface where the interaction occurred |
| `sourceComponentId` | No | ID of the component that triggered the action |
| `timestamp` | No | ISO 8601 timestamp of when the interaction occurred |
| `context` | No | Key-value map of contextual data resolved from the component's action context |

`userAction` contrasts with the four agent-to-client message types: where `surfaceUpdate`, `dataModelUpdate`, `beginRendering`, and `deleteSurface` flow from agent to client, `userAction` flows from client to agent.


> Action model, streaming protocol, A2A integration, and versioning are in `a2ui-protocol-advanced.md`.
