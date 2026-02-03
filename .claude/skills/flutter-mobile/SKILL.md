---
name: flutter-mobile
description: This skill provides patterns and templates for Flutter 3.38 / Dart 3.11 cross-platform mobile development. It should be activated when building Flutter screens, Riverpod providers, Freezed models, or widget tests.
allowed-tools: Bash, Read, Write, Edit
---

# Flutter Mobile Development Skill

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

### Architecture Patterns
- **Riverpod 3.x:** Use `@riverpod` annotations, `AsyncNotifier`, `Notifier`
- **Sealed Classes:** Use `sealed` for state modeling (Dart 3+)
- **Functional Error Handling:** Use `Result` types or `fpdart`
- **Code Generation:** Use `freezed`, `riverpod_generator`, `json_serializable`
- **Repository Pattern:** Abstract data sources behind repository interfaces

### Accessibility (A11y) — MANDATORY
- **Semantic Labels:** All interactive elements have `Semantics` or `semanticLabel`
- **Touch Targets:** Minimum 48x48 dp for all tappable elements
- **Color Contrast:** WCAG AA compliant (4.5:1 for text)
- **Screen Reader Support:** Logical focus order, meaningful announcements
- **Dynamic Text:** Support for system font scaling

### Performance
- **Efficient Queries:** Indexed Hive queries, paginated lists
- **Image Optimization:** `cached_network_image`, proper `cacheWidth`/`cacheHeight`
- **Animated Transitions:** `Hero`, `AnimatedSwitcher`, `PageRouteBuilder`
- **Avoid Rebuilds:** `const` constructors, `select()` in Riverpod, `RepaintBoundary`

### User Experience (UX)
- **Haptic Feedback:** `HapticFeedback.lightImpact()` on key interactions
- **Visual Validation:** Real-time form validation with clear indicators
- **Smooth Animations:** 60fps, `Curves.easeOutCubic`, meaningful motion
- **Loading States:** Skeleton loaders, shimmer effects (never empty screens)
- **Optimistic UI:** Update UI immediately, sync in background

### Premium Polish & Design
- **Glassmorphism:** Frosted glass effects with `BackdropFilter`
- **Premium Badges:** Visual distinction for premium features
- **Modern Styling:** Rounded corners (16-24dp), soft shadows, gradient accents
- **Dark/Light Themes:** Full theme support with `ThemeExtension`

For detailed code templates for all patterns above, read `reference/flutter-modern-architecture.md`

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
