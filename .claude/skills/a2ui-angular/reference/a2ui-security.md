# A2UI Security Reference

## Threat Model

A2UI payloads originate from AI agents — which are untrusted sources. The protocol's declarative
constraint guarantees: "agent-generated UIs are safe like data but expressive like code."
Agents cannot:

1. Execute arbitrary code on the client
2. Render components outside the approved catalog
3. Inject HTML, scripts, or event handlers
4. Access client-side state, cookies, or storage
5. Trigger actions not defined by the client application

## Security Architecture

```
Agent Output (untrusted)
    |
A2UI JSON Payload
    |
+--------------------------------------+
|  SERVER-SIDE VALIDATION BOUNDARY     |
|  Schema validation against catalog   |
|  BEFORE transmission to client       |
+--------------------------------------+
    |
+--------------------------------------+
|  CLIENT-SIDE SECURITY BOUNDARY       |
|  1. JSON Schema Validation           |
|  2. Component Type Allowlist         |
|  3. Property Format Sanitization     |
|  4. Action Allowlist                 |
|  5. Rate / Payload Size Limiting     |
+--------------------------------------+
    |
Native Component Rendering (trusted)
```

## Required Security Checks

### 1. Server-Side Schema Validation (Mandatory — Before Transmission)

Per v0.8 spec, LLM output MUST be validated against the effective catalog schema server-side
before the payload is transmitted to any client. Malformed or out-of-catalog output is rejected
at this boundary — not silently forwarded.

Custom components require registration with schema validation before they are added to the
effective catalog.

### 2. Component Type Allowlist (Mandatory)

Every component `type` MUST be validated against the client's catalog before rendering.
Official v0.8 component types:

```typescript
// ✅ REQUIRED: Allowlist validation with official type names
@Injectable({ providedIn: 'root' })
export class A2UICatalogService {
  private readonly allowedTypes = new Set([
    'Row', 'Column',                                              // Layout
    'Text', 'Image', 'Icon',                                      // Display
    'Button', 'TextField', 'Checkbox', 'DateTimeInput',           // Interactive
    'Card', 'Modal', 'Tabs', 'List', 'Divider',                   // Containers / Structure
  ]);

  isAllowed(type: string): boolean {
    return this.allowedTypes.has(type);
  }

  filterPayload(components: A2UIComponent[]): A2UIComponent[] {
    return components.filter(c => this.isAllowed(c.type));
  }
}
```

```typescript
// ❌ FORBIDDEN: Rendering any type the agent sends
renderComponent(comp: A2UIComponent) {
  const ComponentClass = this.registry[comp.type]; // Agent controls what gets rendered
}
```

### 3. Property Format Sanitization (Mandatory)

In v0.8, all property values use a typed-value format. A value is either a literal string or a
JSON Pointer path reference — never a raw string or executable content.

```typescript
// Official property value shapes:
// { "literalString": "some text" }
// { "path": "/json/pointer" }

sanitizePropertyValue(value: unknown): string {
  if (typeof value === 'object' && value !== null) {
    const v = value as Record<string, unknown>;
    if ('literalString' in v && typeof v['literalString'] === 'string') {
      return v['literalString'].slice(0, 10_000);
    }
    if ('path' in v && typeof v['path'] === 'string') {
      // JSON Pointer: must start with /
      if (!v['path'].startsWith('/')) return '';
      return v['path'];
    }
  }
  // Reject raw strings, numbers, booleans, or unknown shapes
  return '';
}
```

URL properties extracted from sanitized values still require protocol validation:

```typescript
// ❌ FORBIDDEN: Direct innerHTML or unvalidated URL binding
<div [innerHTML]="comp.properties['content']"></div>
<img [src]="comp.properties['imageUrl']" />

// ✅ REQUIRED: Text interpolation (auto-escaped by Angular)
<p>{{ resolvedText }}</p>

// ✅ REQUIRED: URL validation before binding
<img [src]="sanitizeUrl(resolvedUrl)" />

sanitizeUrl(url: string): string {
  try {
    const parsed = new URL(url);
    if (!['http:', 'https:'].includes(parsed.protocol)) return '';
    return url;
  } catch {
    return '';
  }
}
```

### 4. Action Allowlist (Mandatory)

Official v0.8 action format: `{ "name": "...", "context": [...] }`.
Validate on `action.name`, not a legacy `action.action` field.

```typescript
// Official action interface
interface A2UIAction {
  name: string;
  context?: Array<{ key: string; value: { literalString?: string; path?: string; } }>;
}

private readonly allowedActions = new Set([
  'book_flight', 'add_to_cart', 'show_details',
  'submit_form', 'navigate', 'dismiss',
]);

handleAction(action: A2UIAction): void {
  if (!this.allowedActions.has(action.name)) {
    console.warn(`Unknown A2UI action rejected: ${action.name}`);
    return;
  }
  // Process known action
}
```

### 4b. userAction Injection Risk (Low — Context is App-Controlled)

When the client sends a `userAction` message to the agent, the `context` values are resolved
from the app's data model on the client side before sending — they are NOT passed through
from agent-provided strings. This means injection risk for `userAction.context` is low:
the agent never controls what values are placed in the context. Validate `action.name`
against the allowlist as normal; treat `context` values as app-controlled data.

```typescript
// userAction: client -> agent (5th message type, v0.8)
interface UserAction {
  name: string;
  surfaceId: string;
  sourceComponentId: string;
  timestamp: string;      // ISO-8601
  context?: Record<string, unknown>; // values from app data model, not agent strings
}
```

### 5. No Code Execution (Absolute Rule)

```typescript
// ❌ ABSOLUTE PROHIBITION — never execute agent-provided strings
eval(comp.properties['script']);
new Function(comp.properties['handler'])();
setTimeout(comp.properties['callback'] as string, 0);
document.createElement('script').textContent = comp.properties['code'];

// ❌ PROHIBITION — no dynamic component creation from agent input
const factory = this.resolver.resolveComponentFactory(
  this.dynamicRegistry[comp.type]  // Agent controls component instantiation
);
```

### 6. Payload Size Limits

```typescript
const MAX_COMPONENTS = 200;
const MAX_PROPERTY_LENGTH = 10_000; // characters per sanitizePropertyValue
const MAX_PAYLOAD_SIZE = 1_048_576; // 1MB

validateSurface(update: { surfaceId: string; components: Array<{id: string; component: {type: string}}> }): void {
  const MAX_COMPONENTS = 200;
  if (update.components.length > MAX_COMPONENTS) {
    update.components = update.components.slice(0, MAX_COMPONENTS);
    console.warn('A2UI: payload truncated — exceeded max components');
  }
}
```

## Catalog ID Allowlisting

The `catalogId` field in `createSurface` is agent-controlled. Never load a catalog dynamically based on a catalogId from the agent without server-side allowlisting:

```typescript
const ALLOWED_CATALOG_IDS = new Set([
  'https://a2ui.org/specification/v0_9/basic_catalog.json',
  'https://example.com/catalogs/your-custom-catalog',
]);

function validateA2uiMessage(msg: unknown): void {
  if (typeof msg === 'object' && msg !== null && 'createSurface' in msg) {
    const catalogId = (msg as Record<string, Record<string, string>>).createSurface?.catalogId;
    if (catalogId && !ALLOWED_CATALOG_IDS.has(catalogId)) {
      throw new Error(`Disallowed catalogId: ${catalogId}`);
    }
  }
}
```

Validate all incoming A2UI messages server-side before they reach the client.

## sendCatalogDescription: false in Production

`sendCatalogDescription: true` (a development convenience) sends component descriptions and schema examples into the agent prompt automatically. This expands the prompt injection surface — a malicious or compromised agent can exploit those descriptions.

Safe production posture:
```
Client sends catalogId only (no descriptions)
  ↓
Agent validates catalogId against server-side allowlist
  ↓
Agent loads catalog schema from internal trusted registry
  ↓
LLM receives only approved catalog instructions
  ↓
Server validates generated A2UI before sending to client
```

Set `sendCatalogDescription: false` on all custom catalog registrations in production:
```typescript
provideA2uiCatalog({
  id: 'https://example.com/custom_catalog.json',
  components: [...],
  sendCatalogDescription: false, // REQUIRED in production
});
```

## Rate Limits (Server-Side)

A misbehaving or compromised agent can DoS the client by spamming messages. These limits belong on the server or agent gateway — client-side limits are bypassable.

| Limit | Recommended Cap | Rationale |
|-------|----------------|-----------|
| Surfaces per session | ~50 | Catches runaway loops without affecting normal use |
| Actions per second per surface | ~10 | Prevents button spam / click flooding |
| `updateDataModel` payload size | Set a max bytes limit | Prevents oversized payloads that freeze the renderer |

## Server-Side Validation Loop

LLM-generated A2UI is not safe to render without validation. The required production loop:

```
LLM generates A2UI
  ↓
Schema validation (Zod against component catalog)
  ↓
[FAIL] → Send structured error back to LLM → retry (max 2-3 retries)
[PASS] → Wrap in AG-UI/A2A event → ship to client
```

A spike in validation failure rate is often the earliest signal that an LLM regression or prompt change has destabilized UI generation — before users notice.

## Security Checklist

- [ ] LLM output validated against catalog schema server-side before transmission
- [ ] Custom components registered with schema validation before catalog inclusion
- [ ] Component types validated against official v0.8 allowlist before rendering
- [ ] Property values validated as literalString or JSON Pointer path — raw strings rejected
- [ ] JSON Pointer paths verified to start with "/"
- [ ] literalString values length-capped (10,000 chars)
- [ ] URLs extracted from properties validated for http/https protocol
- [ ] No `innerHTML`, `outerHTML`, or `bypassSecurityTrust*` used with agent data
- [ ] No `eval()`, `Function()`, or dynamic script creation from agent data
- [ ] Actions validated against allowlist using `action.name` (v0.8 format)
- [ ] Payload size limits enforced (200 components, 1MB total)
- [ ] Error boundaries prevent malformed components from crashing the entire UI
