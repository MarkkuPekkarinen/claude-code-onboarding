---
name: scaffold-genui
description: Scaffold a Flutter GenUI (A2UI) conversational UI feature module — widget catalog, SurfaceController, Conversation setup, agent transport, and chat screen
argument-hint: "[feature name, default: gen-ui-chat]"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, WebFetch, mcp__dart-mcp-server__dart, mcp__context7__resolve-library-id, mcp__context7__query-docs
disable-model-invocation: true
---

# Scaffold Flutter GenUI Feature

Creates a Flutter GenUI conversational UI feature module in an existing Flutter project.

**Feature name:** $ARGUMENTS (default to "gen-ui-chat" if not provided)

## Pre-requisites

1. Read the `flutter-genui` skill (`SKILL.md` and all `reference/*.md` files) for SDK concepts, catalog design, security rules, and state binding patterns.
2. Read the `flutter-mobile` skill's `reference/flutter-conventions.md` for Flutter coding standards.
3. Verify Flutter/Dart APIs using `dart-mcp-server` MCP or Context7 MCP before using any API.

## Steps

1. **Add GenUI dependencies to `pubspec.yaml`**

   ```yaml
   dependencies:
     genui:
       git:
         url: https://github.com/flutter/genui.git
         path: packages/genui
     genui_a2a:
       git:
         url: https://github.com/flutter/genui.git
         path: packages/genui_a2a
     intl: ^0.19.0          # for A2UIFunctionEvaluator formatting
     url_launcher: ^6.3.0   # for openUrl function
   ```

2. **Create feature folder structure**

   ```
   lib/features/<name>/
   ├── models/
   │   └── gen_ui_message.dart          # ChatMessage, SurfaceState models
   ├── services/
   │   └── gen_ui_agent_service.dart    # SSE transport + Conversation setup
   ├── widgets/
   │   ├── gen_ui_renderer.dart         # SurfaceController + rendering logic
   │   ├── widget_catalog.dart          # Catalog with all registered CatalogItems
   │   ├── widget_types.dart            # Custom widget builders
   │   └── a2ui_function_evaluator.dart # Declarative functions evaluator
   ├── screens/
   │   └── gen_ui_chat_screen.dart      # Chat screen with history + GenUI surfaces
   └── <name>_page.dart                 # Lazy-loaded page entry point
   ```

3. **Create models** (`gen_ui_message.dart`)
   - `ChatMessage` — role (user/assistant), text content, optional surfaceId
   - `GenUIState` — message history, loading flag, error state
   Use Riverpod `StateNotifier` or `AsyncNotifier` for state management.

4. **Create widget catalog** (`widget_catalog.dart`)
   - Register all A2UI v0.8 standard types: `text`, `button`, `text_field`, `checkbox`, `date_time_input`, `row`, `column`, `card`, `list`, `tabs`, `divider`, `image`, `icon`
   - Register extended types: `slider`, `audio_player`, `video` (see `genui-custom-widgets.md`)
   - Each `CatalogItem` must validate agent properties before passing to builder
   - Follow the security rules in `genui-security.md` — unknown types are silently skipped

5. **Create `A2UIFunctionEvaluator`** (`a2ui_function_evaluator.dart`)
   - Copy the full implementation from `reference/genui-functions.md`
   - Allowlisted functions only: validation, formatting, logical, navigation
   - Inject into catalog builders for property resolution

6. **Create renderer** (`gen_ui_renderer.dart`)
   - `SurfaceController` to process A2UI messages from agent
   - Recursive widget building using catalog + function evaluator
   - Evaluate `visible` and `disabled` function calls before rendering
   - Handle `createSurface`, `updateComponents`, `updateDataModel`, `deleteSurface` message types

7. **Create agent service** (`gen_ui_agent_service.dart`)
   - `Conversation` initialization with catalog and `A2uiTransportAdapter`
   - `sendMessage(String text)` — sends user text, returns streamed A2UI messages
   - `sendUserAction(Map<String, dynamic> action)` — sends widget interactions back to agent
   - SSE/JSONL stream parsing following `genui-a2ui-transport.md`
   - Graceful fallback: if GenUI unavailable, surface error state (never swallow silently)

8. **Create chat screen** (`gen_ui_chat_screen.dart`)
   - Message history with chat bubbles (user + assistant)
   - `GenUIRenderer` widget for surfaces from agent
   - Text input field with send button
   - Loading indicator during streaming
   - Wire widget actions back to agent via `sendUserAction`
   - Handle `deleteSurface` to clean up rendered surfaces from history

9. **Write unit tests**
   ```
   test/features/<name>/
   ├── widget_catalog_test.dart         # allow known types, reject unknown
   ├── a2ui_function_evaluator_test.dart # formatCurrency, required, email, and/or/not
   └── gen_ui_renderer_test.dart        # renders card, skips unknown type, handles empty surface
   ```

10. **Verify**
    ```bash
    flutter pub get
    flutter analyze lib/features/<name>/
    flutter test test/features/<name>/
    ```

11. **Print summary** — list created files, how to wire the screen into the app's router, next steps (connect to real agent backend endpoint).

## Reference

- `flutter-genui` skill: all `reference/*.md` files — catalog, conversation, state binding, transport, functions, security
- `flutter-mobile` skill: `reference/flutter-conventions.md`

$ARGUMENTS
