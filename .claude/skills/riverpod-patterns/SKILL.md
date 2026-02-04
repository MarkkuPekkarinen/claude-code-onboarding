---
name: riverpod-patterns
description: "This skill provides Riverpod state management patterns and best practices for Flutter applications. Use when reviewing or writing Riverpod providers, AsyncValue handling, ref usage, or provider lifecycle management."
allowed-tools: Read
---

# Riverpod Correct Patterns Reference

## AsyncNotifier Pattern
```dart
@riverpod
class TodoList extends _$TodoList {
  @override
  FutureOr<List<Todo>> build() async {
    return _fetchTodos();
  }

  Future<void> addTodo(String title) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(todoRepositoryProvider).add(title);
      return _fetchTodos();
    });
  }
}
```

## Proper AsyncValue.when
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final todosAsync = ref.watch(todoListProvider);

  return todosAsync.when(
    data: (todos) => ListView.builder(
      itemCount: todos.length,
      itemBuilder: (_, i) => TodoTile(todos[i]),
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => ErrorWidget(error.toString()),
  );
}
```

## Correct ref.watch vs ref.read
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CORRECT: watch in build for reactivity
    final count = ref.watch(counterProvider);

    return ElevatedButton(
      onPressed: () {
        // CORRECT: read in callback for one-time access
        ref.read(counterProvider.notifier).increment();
      },
      child: Text('Count: $count'),
    );
  }
}
```

## Family Provider Pattern
```dart
@riverpod
Future<User> user(Ref ref, String userId) async {
  return ref.watch(userRepositoryProvider).getUser(userId);
}

// Usage
final user = ref.watch(userProvider(userId));
```
