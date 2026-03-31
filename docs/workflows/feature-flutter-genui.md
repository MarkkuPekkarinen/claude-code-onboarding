# Flutter GenUI — Conversational AI Widget Rendering

> **When to use**: Building conversational AI UIs in Flutter where LLM responses render as native widgets via the A2UI protocol
> **Time estimate**: 4–8 hours for initial GenUI integration; 1–2 hours per additional custom widget type
> **Prerequisites**: Flutter app scaffolded; backend agent generating A2UI payloads; `flutter-genui` skill loaded
> **Related**: [`feature-a2ui-renderer.md`](feature-a2ui-renderer.md) (Angular equivalent), [`feature-flutter-mobile.md`](feature-flutter-mobile.md), [`feature-google-adk.md`](feature-google-adk.md)

## Overview

Flutter GenUI turns LLM conversation responses into interactive native Flutter widgets. The SDK uses the A2UI (Agent-to-User Interface) protocol under the hood — the agent sends structured JSON messages, and Flutter renders them as real widgets (not webviews, not markdown).

The core loop: **User input → Conversation → Transport → A2UI messages → SurfaceController → Catalog lookup → Native widgets → User interaction → next turn**.

---

## Iron Law (from `skills/flutter-genui/SKILL.md`)

> **GENUI PAYLOADS ARE UNTRUSTED. VALIDATE COMPONENT TYPES AGAINST THE CATALOG BEFORE RENDERING.**
> Only registered CatalogItems render. Everything else is silently dropped.

---

## A2UI Message Types

The A2UI protocol uses 5 message types over JSONL streaming:

| Message Type | Purpose |
|-------------|---------|
| `surfaceUpdate` | Add/update components in the surface |
| `dataModelUpdate` | Update observable state values |
| `beginRendering` | Signal that the surface is ready to display |
| `deleteSurface` | Remove a surface entirely |
| `userAction` | Client → server: user interaction events |

Key difference from Angular A2UI: GenUI uses **flat component arrays** with `explicitList` for children (not nested trees).

---

## Phases

### Phase 1 — Load Skill and Design Catalog

**Skill**: Load `flutter-genui`
**Reference**: `reference/genui-catalog-design.md`

Define your CatalogItems — each maps a type name to a JSON schema (for the AI model) and a Dart builder (for rendering):

```dart
final triageCatalog = Catalog(items: [
  CatalogItem(
    name: 'dropdown',
    description: 'Single-selection dropdown for categorizing issues',
    jsonSchema: JsonSchema.object({
      'label': JsonSchema.string(description: 'Dropdown label'),
      'options': JsonSchema.array(
        items: JsonSchema.string(),
        description: 'Available options',
      ),
      'dataPath': JsonSchema.string(description: 'JSON Pointer for binding'),
    }),
    builder: (context, component) => TriageDropdown(component: component),
  ),
  // ... other items
]);
```

**Gate**: All widget types registered with name + schema + builder.

---

### Phase 2 — Set Up Conversation and Transport

**Reference**: `reference/genui-conversation-orchestration.md`, `reference/genui-a2ui-transport.md`

```dart
// Conversation setup — the orchestration engine
final conversation = Conversation(
  catalog: triageCatalog,
  transport: A2uiTransportAdapter(
    sendMessage: (message) => triageApiClient.postTriage(message),
  ),
  systemPrompt: 'You are a maintenance triage assistant...',
);
```

For custom SSE streaming from your backend:

```dart
class TriageTransport {
  Stream<A2uiMessage> streamTriage(String ticketId, String description) async* {
    final request = http.Request('POST', Uri.parse('$baseUrl/triage/start'));
    request.body = jsonEncode({'ticket_id': ticketId, 'description': description});
    final response = await http.Client().send(request);

    await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final json = jsonDecode(line.substring(6));
        yield A2uiMessage.fromJson(_normalizeGeminiOutput(json));
      }
    }
  }
}
```

**Gate**: Transport connects to backend, receives A2UI messages.

---

### Phase 3 — State Binding with DataModel and SurfaceController

**Reference**: `reference/genui-state-binding.md`

The `SurfaceController` processes incoming A2UI messages and maintains the widget tree state. The `DataModel` holds observable state that widgets bind to via JSON Pointer paths.

```dart
// Widget binding to DataModel via JSON Pointer
DropdownButtonFormField<String>(
  value: component.properties['dataPath'] != null
      ? surfaceState.dataModel.getValue(component.properties['dataPath'])
      : null,
  onChanged: (value) {
    conversation.updateData(component.properties['dataPath'], value);
  },
  items: (component.properties['options'] as List)
      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
      .toList(),
);
```

**Gate**: Widgets read from and write to DataModel. Changes propagate across the surface.

---

### Phase 4 — Custom Widget Implementations

**Reference**: `reference/genui-custom-widgets.md`

Each custom widget needs: CatalogItem registration + widget implementation + action handling.

Example — photo upload widget:

```dart
class TriagePhotoUpload extends StatelessWidget {
  final GenUIComponent component;
  const TriagePhotoUpload({required this.component});

  @override
  Widget build(BuildContext context) {
    final maxPhotos = component.properties['maxPhotos'] as int? ?? 5;
    // ... ImagePicker integration, thumbnail grid, upload to GCS
  }
}
```

5 custom widget types for maintenance triage: `photo_upload`, `dropdown`, `free_text`, `rating`, `confirmation`.

**Gate**: All custom widgets render correctly from A2UI payloads. Touch targets >= 48dp.

---

### Phase 5 — Security Validation

**Reference**: `reference/genui-security.md`

Security is enforced at multiple layers:

| Check | What It Prevents |
|-------|-----------------|
| Catalog type allowlist | Arbitrary widget injection |
| Property type validation (`safeString`, `safeBool`, `safeInt`) | Type confusion attacks |
| URL sanitization (https-only, no javascript:) | Script injection via URLs |
| Action allowlist (`_allowedActions` set) | Unauthorized operations |
| Payload size limits (200 components, 1MB max) | DoS via oversized payloads |
| No `dart:mirrors` / no `eval` equivalent | Code execution |

```dart
// Required: validate every component type before rendering
Widget buildComponent(GenUIComponent component) {
  if (!catalog.hasItem(component.type)) {
    logger.warn('Unknown component type dropped: ${component.type}');
    return const SizedBox.shrink(); // Silent drop — not crash
  }
  return catalog.buildItem(component);
}
```

**Gate**: `security-reviewer` agent — no CRITICAL or HIGH findings.

---

### Phase 6 — Riverpod Integration

**Reference**: `reference/genui-conversation-orchestration.md` (Riverpod section)

```dart
@riverpod
class TriageConversation extends _$TriageConversation {
  @override
  FutureOr<Conversation> build(String ticketId) async {
    final catalog = ref.watch(triageCatalogProvider);
    final transport = ref.watch(triageTransportProvider);

    final conversation = Conversation(
      catalog: catalog,
      transport: transport,
      systemPrompt: _systemPrompt,
    );

    ref.onDispose(() => conversation.dispose());
    return conversation;
  }
}
```

**Gate**: Provider lifecycle correct — conversation disposes on widget unmount.

---

### Phase 7 — Gemini Quirk Handling

**Reference**: `reference/genui-a2ui-transport.md` (Gemini normalization section)

Gemini models have 2 known output quirks that must be handled:

1. **Missing `surfaceUpdate` wrapper** — Gemini sometimes outputs component arrays without the message type wrapper. Normalize by wrapping in `{"type": "surfaceUpdate", "components": [...]}`.

2. **Concatenated JSON objects** — Gemini sometimes emits multiple JSON objects on a single line without delimiters. Use Python's `json.JSONDecoder.raw_decode()` on the backend or iterative parsing on the client.

```dart
Map<String, dynamic> normalizeGeminiOutput(Map<String, dynamic> json) {
  if (json.containsKey('components') && !json.containsKey('type')) {
    return {'type': 'surfaceUpdate', ...json};
  }
  return json;
}
```

**Gate**: Malformed Gemini output handled gracefully — no crashes.

---

### Phase 8 — Fallback Path

Every GenUI flow must have a fallback to static UI when AI fails:

```dart
// If GenUI stream fails → fall back to static form
try {
  await for (final message in transport.streamTriage(ticketId, description)) {
    surfaceController.processMessage(message);
  }
} catch (e) {
  logger.error('GenUI stream failed, falling back to static form', error: e);
  // Show manual triage form with category dropdown, description field, photo upload
  // Ticket keeps status=Open, needs_classification=true
}
```

**Gate**: Fallback renders a usable form. No dead ends.

---

## Quick Reference

| Phase | Action | Skill Reference | Gate |
|-------|--------|----------------|------|
| 1 — Catalog | Define CatalogItems with schema + builder | `genui-catalog-design.md` | All types registered |
| 2 — Transport | Connect Conversation to backend SSE | `genui-conversation-orchestration.md`, `genui-a2ui-transport.md` | Messages stream |
| 3 — State | Wire DataModel binding + SurfaceController | `genui-state-binding.md` | Bidirectional binding works |
| 4 — Widgets | Implement custom widget types | `genui-custom-widgets.md` | All render from payloads |
| 5 — Security | Allowlist, validation, size limits | `genui-security.md` | security-reviewer passes |
| 6 — Riverpod | Provider integration + lifecycle | `genui-conversation-orchestration.md` | Dispose on unmount |
| 7 — Gemini | Normalize quirky output | `genui-a2ui-transport.md` | Malformed JSON handled |
| 8 — Fallback | Static form when AI fails | SKILL.md §Error Handling | No dead ends |

---

## Common Pitfalls

- **No catalog validation** — rendering arbitrary types from agent output is a widget injection vector
- **Nested tree assumption** — GenUI uses flat arrays with `explicitList`, not nested `children` trees like Angular A2UI
- **Missing Gemini normalization** — raw Gemini output crashes the parser without wrapper/concatenation handling
- **No fallback path** — GenUI stream failure leaves user stuck with no way to submit their request
- **Blocking the UI thread** — JSON parsing of large payloads must happen off the main isolate
- **Hardcoded colors/spacing** — use `Theme.of(context).colorScheme` and `AppSpacing.*` tokens, not raw values
- **Touch targets < 48dp** — all interactive widgets (buttons, dropdowns, rating stars) must meet 48dp minimum

## Combined Skill Stack

For a complete GenUI implementation, load these skills in order:

1. `flutter-genui` — GenUI SDK patterns, catalog, transport, security
2. `flutter-mobile` — Flutter architecture, Riverpod, design system
3. `google-adk` — Backend agent that generates A2UI payloads
4. Dispatch `security-reviewer` after implementation

## Related Workflows

- [`feature-a2ui-renderer.md`](feature-a2ui-renderer.md) — Angular equivalent (A2UI renderer)
- [`feature-flutter-mobile.md`](feature-flutter-mobile.md) — base Flutter patterns
- [`feature-google-adk.md`](feature-google-adk.md) — backend agent generating A2UI payloads
- [`security-audit.md`](security-audit.md) — security review of the GenUI boundary
