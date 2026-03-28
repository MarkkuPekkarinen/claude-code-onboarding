# Flutter Code Templates

This file contains all code templates for Flutter development with Riverpod, Freezed, and Firebase.

## Design System Token File Structure

Tokens flow in one direction — never reference raw values in widget code.

```
lib/design_system/
├── tokens/
│   ├── color_tokens.dart       # Raw hex palette constants — NEVER used directly in widgets
│   ├── spacing_tokens.dart     # 4pt grid: xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48
│   ├── radius_tokens.dart      # Corner radius constants
│   ├── elevation_tokens.dart   # Elevation levels
│   ├── motion_tokens.dart      # Duration + Curve constants
│   └── index.dart              # Barrel export
├── typography/
│   ├── font_families.dart      # Font name string constants only
│   ├── app_text_styles.dart    # Full M3 TextStyle map (displayLarge → labelSmall)
│   └── app_text_theme.dart     # Assembles TextTheme from app_text_styles
└── theme/
    ├── app_color_scheme.dart   # Semantic ColorScheme (maps ColorTokens → M3 roles)
    ├── app_theme_extension.dart # ThemeExtension<T> for custom fields (brandPrimary, surfaceCard…)
    ├── app_theme.dart          # AppTheme.light() / .dark() factories — import in bootstrap.dart
    └── theme_provider.dart     # @riverpod ThemeMode notifier
```

**Token layering — one direction only:**
```
color_tokens.dart  →  app_color_scheme.dart  →  app_theme_extension.dart  →  Widget
```

**Rules:**
- Widget code: `Theme.of(context).extension<AppThemeExtension>()!.brandPrimary` for custom colors
- Widget code: `Theme.of(context).colorScheme.*` for M3 semantic colors
- Widget code: `SpacingTokens.lg` or `AppSpacing.lg` for spacing — never raw `16.0`
- Widget code: `Theme.of(context).textTheme.*` for typography
- Never add `examples/` or `demo/` files under `lib/` — they ship in the production build

## pubspec.yaml Essentials

```yaml
environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.41.0"

dependencies:
  flutter:
    sdk: flutter

  # State management — Riverpod 3.x codegen-first
  flutter_riverpod: ^3.2.1
  riverpod_annotation: ^3.0.0

  # Navigation
  go_router: ^15.0.0

  # Data / serialisation
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0

  # Network
  dio: ^5.7.0

  # Storage
  flutter_secure_storage: ^9.2.0  # sensitive data (tokens, keys)
  hive_flutter: ^1.1.0            # non-sensitive local storage (preferences, cache)

  # Firebase (add only what the project uses)
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  firebase_crashlytics: ^4.1.8
  firebase_app_check: ^0.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^3.0.0
  freezed: ^3.0.0
  json_serializable: ^6.8.0
  build_runner: ^2.4.0
  custom_lint: ^0.7.0
  riverpod_lint: ^3.0.0
  mocktail: ^1.0.4
```

## build.yaml

Required for correct codegen behaviour — without this, json_serializable uses camelCase by default and freezed skips map/when helpers.

```yaml
targets:
  $default:
    builders:
      riverpod_generator:
        options:
          riverpod_version: 3
      json_serializable:
        options:
          explicit_to_json: true
          field_rename: snake
      freezed:
        options:
          map: true
          when: true
```

## analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - custom_lint          # enables riverpod_lint rules
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    missing_required_param: error
    missing_return: error

linter:
  rules:
    - always_use_package_imports
    - avoid_dynamic_calls
    - prefer_final_locals
    - prefer_const_constructors
    - prefer_const_declarations
```

## Entry Point Pattern (main / bootstrap / app)

### main.dart — one line only
```dart
void main() => bootstrap(() => const App());
```

### bootstrap.dart — all async init here
```dart
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Framework-level error hook — catches Flutter rendering errors
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  // Dart async errors not caught by Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider:   kDebugMode ? AppleProvider.debug   : AppleProvider.deviceCheck,
  );

  runApp(
    ProviderScope(
      observers: kDebugMode ? [RiverpodLogger()] : [],
      child: await builder(),
    ),
  );
}
```

### app.dart — MaterialApp.router only
```dart
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider),
      theme:      AppTheme.light(),
      darkTheme:  AppTheme.dark(),
      themeMode:  themeMode,
    );
  }
}
```

## ThemeExtension — Custom Semantic Colors

Use `ThemeExtension<T>` for any color that is not covered by Material 3's built-in `ColorScheme`.
Widget code accesses it via `Theme.of(context).extension<AppThemeExtension>()!`.

```dart
// design_system/theme/app_theme_extension.dart
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.brandPrimary,
    required this.surfaceCard,
    required this.success,
    required this.warning,
  });

  final Color brandPrimary;
  final Color surfaceCard;
  final Color success;
  final Color warning;

  static const light = AppThemeExtension(
    brandPrimary: ColorTokens.brandPrimary500,
    surfaceCard:  ColorTokens.neutral50,
    success:      ColorTokens.success500,
    warning:      ColorTokens.warning500,
  );

  static const dark = AppThemeExtension(
    brandPrimary: ColorTokens.brandPrimary300,
    surfaceCard:  ColorTokens.neutral800,
    success:      ColorTokens.success400,
    warning:      ColorTokens.warning400,
  );

  @override
  AppThemeExtension copyWith({Color? brandPrimary, Color? surfaceCard, Color? success, Color? warning}) =>
      AppThemeExtension(
        brandPrimary: brandPrimary ?? this.brandPrimary,
        surfaceCard:  surfaceCard  ?? this.surfaceCard,
        success:      success      ?? this.success,
        warning:      warning      ?? this.warning,
      );

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other == null) return this;
    return AppThemeExtension(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      surfaceCard:  Color.lerp(surfaceCard,  other.surfaceCard,  t)!,
      success:      Color.lerp(success,      other.success,      t)!,
      warning:      Color.lerp(warning,      other.warning,      t)!,
    );
  }
}

// In widget code:
final ext = Theme.of(context).extension<AppThemeExtension>()!;
Container(color: ext.brandPrimary);
```

## Global DI Providers — core/di/providers.dart

All `@Riverpod(keepAlive: true)` singletons live here. Never scatter them across features.

```dart
// Riverpod 3.x codegen generates a specific ref type per provider (e.g., DioRef, AuthRepositoryRef).
// Always use the generated ref type, not the generic Ref, for type-safety and IDE support.
part 'providers.g.dart';

@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  final dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));
  dio.interceptors.addAll([
    AuthInterceptor(ref),
    LogInterceptor(logResponseBody: kDebugMode),
  ]);
  return dio;
}

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(SecureStorageRef ref) => const FlutterSecureStorage();

// Repository singletons — example
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) => AuthRepositoryImpl(
  remote: ref.watch(authRemoteDataSourceProvider),
  local:  ref.watch(authLocalDataSourceProvider),
);
```

## Domain Value Objects

Validate business constraints inside the domain layer — never in the UI.

```dart
// features/auth/domain/value_objects/email.dart
class Email {
  final String value;

  Email._(this.value);

  factory Email(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(trimmed)) {
      throw const FormatException('Invalid email address');
    }
    return Email._(trimmed);
  }

  @override
  String toString() => value;
  @override
  bool operator ==(Object other) => other is Email && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

// features/auth/domain/value_objects/password.dart
class Password {
  final String value;

  Password._(this.value);

  factory Password(String raw) {
    if (raw.length < 8) throw const FormatException('Password must be at least 8 characters');
    return Password._(raw);
  }
}
```

## Freezed Model Template

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String displayName,
    @Default('') String photoUrl,
    required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
```

## Riverpod Provider Template

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

@riverpod
class UserList extends _$UserList {
  @override
  FutureOr<List<UserModel>> build() async {
    return ref.read(userRepositoryProvider).getUsers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).getUsers(),
    );
  }

  Future<void> add(CreateUserDto dto) async {
    await ref.read(userRepositoryProvider).createUser(dto);
    await refresh();
  }
}
```

## Screen Template

```dart
class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.displayName),
              subtitle: Text(user.email),
              onTap: () => context.go('/users/${user.id}'),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/users/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## GoRouter Configuration

```dart
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/users', builder: (_, __) => const UserListScreen()),
        GoRoute(path: '/users/:id', builder: (_, state) =>
          UserDetailScreen(userId: state.pathParameters['id']!)),
      ],
    ),
  ],
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (!isLoggedIn && state.uri.path != '/login') return '/login';
    if (isLoggedIn && state.uri.path == '/login') return '/home';
    return null;
  },
);
```

## Widget Test Template

```dart
void main() {
  testWidgets('UserListScreen shows users', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userListProvider.overrideWith((ref) => [
            UserModel(id: '1', email: 'a@b.com', displayName: 'Alice', createdAt: DateTime.now()),
          ]),
        ],
        child: const MaterialApp(home: UserListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);
  });
}
```

## Firebase Integration Patterns

### Firestore Data Source

```dart
class UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  UserRemoteDataSource(this._firestore);

  Stream<List<UserModel>> watchUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  Future<UserModel> getUser(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (!doc.exists) throw Exception('User not found');
    return UserModel.fromFirestore(doc);
  }

  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }
}
```

### Firebase Auth Integration

```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Stream<User?> build() {
    return FirebaseAuth.instance.authStateChanges();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
```

## Clean Architecture Repository Pattern

```dart
// Domain layer - abstract repository
abstract class UserRepository {
  Stream<List<User>> watchUsers();
  Future<User> getUser(String id);
  Future<void> createUser(User user);
}

// Data layer - implementation
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<User>> watchUsers() {
    return _remoteDataSource.watchUsers()
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<User> getUser(String id) async {
    final model = await _remoteDataSource.getUser(id);
    return model.toEntity();
  }

  @override
  Future<void> createUser(User user) async {
    final model = UserModel.fromEntity(user);
    await _remoteDataSource.createUser(model);
  }
}
```
