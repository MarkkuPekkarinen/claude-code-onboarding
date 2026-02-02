---
name: flutter-mobile
description: Patterns and templates for Flutter 3.38 / Dart 3.11 cross-platform mobile development with Riverpod, clean architecture, and Firebase. Activate when building Flutter screens, providers, models, or tests.
allowed-tools: Bash, Read, Write, Edit
---

# Flutter Mobile Development Skill

## Quick Scaffold — New Flutter Project
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

## pubspec.yaml Essentials
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.4.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  go_router: ^14.0.0
  firebase_core: ^3.6.0
  cloud_firestore: ^5.5.0
  firebase_auth: ^5.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  build_runner: ^2.4.0
  mocktail: ^1.0.0
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
