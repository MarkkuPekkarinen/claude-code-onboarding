---
name: flutter-mobile
description: This skill provides patterns and templates for Flutter 3.38 / Dart 3.11 cross-platform mobile development. It should be activated when building Flutter screens, Riverpod providers, Freezed models, or widget tests.
allowed-tools: Bash, Read, Write, Edit
---

# Flutter Mobile Development Skill

## Code Conventions
- Use **Riverpod** for state management
- Follow feature-first folder structure: `lib/features/<feature>/`
- Separate `data/`, `domain/`, `presentation/` layers (clean architecture)
- Use `freezed` for immutable models
- Firebase integration via `firebase_core`, `cloud_firestore`, `firebase_auth`

## Quick Scaffold

```bash
flutter create --org com.company --platforms ios,android my_app
cd my_app

# Add core dependencies
flutter pub add flutter_riverpod riverpod_annotation
flutter pub add freezed_annotation json_annotation go_router firebase_core cloud_firestore firebase_auth
flutter pub add dev:riverpod_generator dev:freezed dev:json_serializable dev:build_runner dev:mocktail

# Run code generation
dart run build_runner build --delete-conflicting-outputs
```

## Process

1. **Read templates** - Use Read tool on `reference/flutter-templates.md` for all code templates (Freezed models, Riverpod providers, screens, GoRouter, tests, Firebase integration)
2. **Create feature structure** - Build `lib/features/<feature>/data/`, `domain/`, `presentation/` directories
3. **Define models** - Create Freezed data models in `data/models/` with Firestore serialization
4. **Build providers** - Create Riverpod notifiers with `@riverpod` annotation in `presentation/providers/`
5. **Design screens** - Build `ConsumerWidget` screens that watch `AsyncValue<T>` providers
6. **Run codegen** - Execute `dart run build_runner build --delete-conflicting-outputs`
7. **Write tests** - Create widget tests with `ProviderScope` overrides

## Key Patterns

| Pattern | Description |
|---------|-------------|
| `@freezed` models | Immutable data classes with `fromFirestore` factory |
| `@riverpod` providers | Code-generated state notifiers with `AsyncValue` |
| `ConsumerWidget` | Widgets that watch providers via `ref.watch()` |
| `AsyncValue.when()` | Handle loading/error/data states declaratively |
| Clean Architecture | Separate data/domain/presentation layers |
| GoRouter | Declarative routing with path parameters |
| Firebase Auth | Stream-based auth state with `authStateChanges()` |
| Firestore snapshots | Real-time data with `.snapshots()` streams |

## Modern Flutter Architecture (2025/2026)

For architecture patterns, accessibility, performance, UX, and premium polish guidelines:

Read [reference/flutter-architecture-patterns.md](reference/flutter-architecture-patterns.md) — Sealed classes, Result types, Riverpod AsyncNotifier
Read [reference/flutter-performance-ux.md](reference/flutter-performance-ux.md) — Accessibility, performance, haptic feedback, shimmer, animations
Read [reference/flutter-design-polish.md](reference/flutter-design-polish.md) — Glassmorphism, premium cards, dark/light themes, gradients
Read [reference/accessibility-audit-checklist.md](reference/accessibility-audit-checklist.md) — WCAG 2.1 audit checklist (used by `accessibility-auditor` agent)
Read [reference/flutter-security-hardening.md](reference/flutter-security-hardening.md) — Security hardening & privacy compliance (used by `flutter-security-expert` agent)

## Documentation Sources

Before generating code, consult these sources for current syntax and APIs:

| Source | URL / Tool | Purpose |
|--------|-----------|---------|
| Flutter / Dart | `Dart MCP server` | Latest Flutter widgets, Dart syntax, platform APIs |
| Riverpod | `Context7` MCP | Provider types, ref usage, AsyncValue patterns |
| Firebase Firestore | `Firebase MCP server` | Firestore operations, rules validation, auth flows |

## Common Commands

```bash
flutter run                          # Run on connected device/emulator
flutter test                         # Run tests
flutter build apk                    # Build Android APK
flutter build ios                    # Build iOS
flutter pub get                      # Install dependencies
flutter clean                        # Clean build artifacts
dart run build_runner build --delete-conflicting-outputs  # Run code generation
flutter analyze                      # Static analysis
```

## Error Handling

**Build runner fails**: Delete `.dart_tool/build/`, run `flutter clean`, retry codegen

**Missing generated files**: Ensure `part` directives match filename (e.g., `part 'user_model.g.dart';`)

**Provider not found**: Run `dart run build_runner build`, import generated `.g.dart` file

**Firestore Timestamp errors**: Use `(data['createdAt'] as Timestamp).toDate()` in `fromFirestore`

**Hot reload breaks state**: Restart app fully when changing provider signatures

**AsyncValue stuck loading**: Check repository returns data, use `AsyncValue.guard()` to catch errors

## Templates Reference

For all code templates (pubspec.yaml, Freezed models, Riverpod providers, screen widgets, GoRouter config, widget tests, Firebase integration, repository patterns):

Read `reference/flutter-templates.md`
