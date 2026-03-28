# Flutter Architecture Patterns

Core architecture patterns for modern Flutter (2025/2026) — sealed classes, Result types, and Riverpod AsyncNotifier.

## Freezed Sealed State Classes (Riverpod 3.x standard)

Use `@freezed sealed class` for all state objects. This generates `when()`, `map()`,
`maybeWhen()`, and `copyWith()` automatically — do NOT use plain `sealed class` for state.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:your_app/features/auth/domain/entities/user.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial()                    = _Initial;
  const factory AuthState.loading()                    = _Loading;
  const factory AuthState.authenticated(User user)     = _Authenticated;
  const factory AuthState.unauthenticated()            = _Unauthenticated;
  const factory AuthState.error(String message)        = _Error;
}
```

Always place in its own file: `presentation/providers/auth_state.dart`
Always add `part 'auth_state.freezed.dart';` — run `dart run build_runner build --delete-conflicting-outputs` after changes.

Usage in notifier:
```dart
// In auth_provider.dart
state = const AuthState.loading();
state = AuthState.authenticated(user);
state = AuthState.error(failure.message);
```

Usage in widget (exhaustive pattern matching — compile-time safe):
```dart
ref.watch(authProvider).when(
  initial:         ()      => const SplashScreen(),
  loading:         ()      => const CircularProgressIndicator(),
  authenticated:   (user)  => HomeScreen(user: user),
  unauthenticated: ()      => const LoginScreen(),
  error:           (msg)   => ErrorWidget(msg),
);
```

**Rule:** Every feature state file MUST be a separate `*_state.dart` file.
Never define state inline in the provider file.

## Functional Error Handling with Result Type

```dart
// Simple Result type (no external dependency)
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error);
}

// Usage in repository
Future<Result<User>> getUser(String id) async {
  try {
    final doc = await _firestore.collection('users').doc(id).get();
    if (!doc.exists) return Failure(NotFoundException('User not found'));
    return Success(UserModel.fromFirestore(doc).toEntity());
  } on FirebaseException catch (e) {
    return Failure(NetworkException(e.message ?? 'Firestore error'));
  }
}

// Usage in provider
@riverpod
class UserDetail extends _$UserDetail {
  @override
  FutureOr<User> build(String userId) async {
    final result = await ref.read(userRepositoryProvider).getUser(userId);
    return switch (result) {
      Success(:final value) => value,
      Failure(:final error) => throw error,
    };
  }
}
```

## Riverpod 3.x AsyncNotifier Pattern

```dart
@riverpod
class WorkoutList extends _$WorkoutList {
  @override
  FutureOr<List<Workout>> build() async {
    final repo = ref.read(workoutRepositoryProvider);
    return repo.getWorkouts();
  }

  Future<void> addWorkout(CreateWorkoutDto dto) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(workoutRepositoryProvider).create(dto);
      return ref.read(workoutRepositoryProvider).getWorkouts();
    });
  }

  Future<void> deleteWorkout(String id) async {
    // Optimistic UI: remove immediately, restore on failure
    final previous = state.valueOrNull ?? [];
    state = AsyncValue.data(previous.where((w) => w.id != id).toList());

    final result = await ref.read(workoutRepositoryProvider).delete(id);
    if (result case Failure(:final error)) {
      state = AsyncValue.data(previous); // Restore on failure
      throw error;
    }
  }
}
```

## Repository Error Handling with Crashlytics

Every repository catch block MUST do two things: log locally AND record to Crashlytics.
This pattern applies regardless of which database or backend you use.

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// ✅ REQUIRED pattern — applies to ALL repositories (REST, Firebase, local DB, etc.)
Future<Result<List<Order>>> getOrders(String userId) async {
  try {
    final response = await _apiClient.get('/orders/$userId');
    return Success(response.map(Order.fromJson).toList());
  } on NetworkException catch (e, stackTrace) {
    _logger.error('getOrders failed', userId: userId, error: e);
    await FirebaseCrashlytics.instance.recordError(e, stackTrace,
        reason: 'getOrders failed for user $userId');
    return Failure(e);
  } catch (e, stackTrace) {
    _logger.error('getOrders unexpected error', error: e);
    await FirebaseCrashlytics.instance.recordError(e, stackTrace,
        reason: 'getOrders unexpected error');
    return Failure(UnexpectedException(e.toString()));
  }
}

// ❌ FORBIDDEN — silent failure, user sees blank screen with no explanation
Future<List<Order>> getOrders(String userId) async {
  try {
    return await _apiClient.getOrders(userId);
  } catch (e) {
    return []; // Never do this
  }
}
```

**Rules:**
- `recordError()` takes `(error, stackTrace)` — always pass both
- Pass a `reason:` string with enough context to identify the call site in Crashlytics dashboard
- Always use `await` — `recordError` is async and dropping it silently loses crash reports
- Use `Result<T>` return type so callers are forced to handle the failure case

## Patterns

### Riverpod: Unnecessary flutter_riverpod Import

When using `riverpod_annotation`, `flutter_riverpod` is often redundant.
Use `package:riverpod_annotation/riverpod_annotation.dart` only, unless you
explicitly need `ProviderScope`, `ConsumerWidget`, etc. from `flutter_riverpod`.

### Test Error Propagation

Do NOT use `Future.then(..., onError: ...)` to capture typed exceptions — the
return type constraint causes a runtime error. Use try/catch instead:
```dart
Object? err;
try { await container.read(provider.future); } catch (e) { err = e; }
expect(err, isA<MyException>());
```

### StatefulShellRoute for Bottom Nav (GoRouter 17+)

Use `StatefulShellRoute.indexedStack` + `StatefulShellBranch` per tab.
Access navigation via `StatefulNavigationShell.goBranch()`. Do NOT use the old
`ShellRoute` pattern — it does not preserve per-tab state.

### Auth Provider with Sealed State

Wrapping a sealed class in `AsyncValue<AuthState>` works well.
Set state as `AsyncValue.data(AuthLoading())` during operations,
`AsyncValue.data(AuthAuthenticated(...))` on success.
Initial build reads from TokenStore to determine initial state.

### Code Generation After Provider Changes

Run `dart run build_runner build --delete-conflicting-outputs` after ANY
provider signature or model field change. Generated `.g.dart` files
reflect the parameter field names used in notifier methods.

### GoRouter + Riverpod Auth Integration

Connect `authProvider` state changes to GoRouter redirects using `refreshListenable`:
```dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = _RouterNotifier();
  ref.listen(authProvider, (_, __) => notifier.notifyListeners());
  return GoRouter(
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider).valueOrNull;
      final isAuthenticated = authState is AuthAuthenticated;
      // ... redirect logic
    },
  );
}
class _RouterNotifier extends ChangeNotifier {}
```

### Correct Error State in AsyncNotifier Mutations

WRONG — hides errors from the framework:
```dart
state = AsyncValue.data(AuthError(e.toString())); // hasError == false
```
CORRECT — uses native AsyncValue error:
```dart
state = AsyncValue.error(e, st); // hasError == true
```

### TextEditingController in Bottom Sheets

Extract to a `StatefulWidget` with `dispose()` — never create controllers inside
`ConsumerWidget` methods or `showModalBottomSheet` builder callbacks without disposal.

### ref.watch vs ref.read in build()

- `ref.watch(dep)` in `build()` = reactive (rebuilds when dep changes) — USE THIS
- `ref.read(dep)` in `build()` = one-time read, no tracking — only for `keepAlive` singletons, must be commented

### Async Operations in Sync Notifier

If a `Notifier<T>` has async methods, errors must be surfaced:
- Option A: Convert to `AsyncNotifier<T?>` — state machine includes loading/error
- Option B: Keep sync, catch errors in every method, store in separate error field, emit SnackBar via `ref.listen`

### BuildContext Usage After Async Gap

WRONG — widget may have been disposed during the await; context is stale:
```dart
Future<void> _submit() async {
  await ref.read(authProvider.notifier).signIn(email, password);
  // Widget may be gone by now — context is invalid
  Navigator.of(context).pushReplacementNamed('/home');
}
```

CORRECT — check mounted before any context access after an await:
```dart
Future<void> _submit() async {
  await ref.read(authProvider.notifier).signIn(email, password);
  if (!mounted) return; // Guard: widget was disposed during await
  Navigator.of(context).pushReplacementNamed('/home');
}
```

Rule: every `await` that is followed by a `context` usage (Navigator, ScaffoldMessenger,
Theme, etc.) MUST be preceded by `if (!mounted) return;`.

### StreamBuilder Firestore Write Loop

WRONG — writing to Firestore inside a StreamBuilder builder creates an infinite loop:
```dart
StreamBuilder<QuerySnapshot>(
  stream: _firestore.collection('items').snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      // Each write → Firestore emits new snapshot → builder reruns → write again
      _firestore.collection('log').add({'event': 'viewed'});
      return ItemList(snapshot.data!.docs);
    }
    return const CircularProgressIndicator();
  },
)
```

CORRECT — perform side effects and writes in a StreamSubscription, not the builder:
```dart
class _ItemScreenState extends ConsumerState<ItemScreen> {
  StreamSubscription<QuerySnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('items')
        .snapshots()
        .listen((snapshot) {
      // Side effects and writes belong here — runs once per snapshot, not in build
      FirebaseFirestore.instance.collection('log').add({'event': 'viewed'});
      ref.read(itemsProvider.notifier).updateFromSnapshot(snapshot);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Builder is pure — no writes, no side effects
    final items = ref.watch(itemsProvider);
    return ItemList(items);
  }
}
```

### StreamBuilder Expensive Computation on Every Rebuild

WRONG — heavy computation runs on every Firestore snapshot, blocking the UI thread:
```dart
StreamBuilder<QuerySnapshot>(
  stream: _firestore.collection('items').snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const CircularProgressIndicator();
    // Runs synchronously on the UI thread for every snapshot
    final sorted = snapshot.data!.docs
        .map((d) => ItemModel.fromFirestore(d))
        .where((i) => i.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ItemList(sorted);
  },
)
```

CORRECT — move data transformation into a Riverpod provider so it is computed once
per snapshot and widgets use select() to avoid unnecessary rebuilds:
```dart
@riverpod
Stream<List<ItemModel>> activeItems(Ref ref) {
  return FirebaseFirestore.instance
      .collection('items')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((d) => ItemModel.fromFirestore(d))
          .where((i) => i.isActive)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
}

// Widget is now pure and efficient
class ItemScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(activeItemsProvider);
    return itemsAsync.when(
      data: (items) => ItemList(items),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => ErrorDisplay(error: e),
    );
  }
}
```
