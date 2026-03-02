# Flutter Architecture Patterns

Core architecture patterns for modern Flutter (2025/2026) — sealed classes, Result types, and Riverpod AsyncNotifier.

## Sealed Classes for State Modeling

```dart
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// Usage with pattern matching
Widget buildFromState(AuthState state) {
  return switch (state) {
    AuthInitial() => const SplashScreen(),
    AuthLoading() => const LoadingOverlay(),
    AuthAuthenticated(:final user) => HomeScreen(user: user),
    AuthUnauthenticated() => const LoginScreen(),
    AuthError(:final message) => ErrorScreen(message: message),
  };
}
```

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
