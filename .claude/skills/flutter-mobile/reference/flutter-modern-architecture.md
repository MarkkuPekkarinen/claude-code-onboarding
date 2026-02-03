# Modern Flutter Architecture Templates (2025/2026)

## Architecture Patterns

### Sealed Classes for State Modeling

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

### Functional Error Handling with Result Type

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

### Riverpod 3.x AsyncNotifier Pattern

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

## Accessibility (A11y) Templates

### Semantic Labels on Interactive Elements

```dart
// Always wrap tappable elements with Semantics
Semantics(
  label: 'Delete workout',
  hint: 'Double tap to delete this workout entry',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.delete),
    onPressed: () => _deleteWorkout(workout.id),
  ),
)

// Use semanticLabel on images
Image.network(
  user.photoUrl,
  semanticLabel: '${user.displayName} profile photo',
)

// Exclude decorative elements from semantics
Semantics(
  excludeSemantics: true,
  child: Icon(Icons.decorative_star, color: Colors.amber),
)
```

### Minimum Touch Targets (48x48 dp)

```dart
// Ensure all tappable elements meet minimum size
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: const Icon(Icons.close),
    onPressed: onClose,
  ),
)

// For custom tappable widgets
GestureDetector(
  onTap: onTap,
  child: ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    child: content,
  ),
)
```

### Screen Reader Focus Order

```dart
// Use FocusTraversalGroup for logical ordering
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(
    children: [
      FocusTraversalOrder(
        order: const NumericFocusOrder(1),
        child: TextField(decoration: const InputDecoration(labelText: 'Email')),
      ),
      FocusTraversalOrder(
        order: const NumericFocusOrder(2),
        child: TextField(decoration: const InputDecoration(labelText: 'Password')),
      ),
      FocusTraversalOrder(
        order: const NumericFocusOrder(3),
        child: ElevatedButton(onPressed: _submit, child: const Text('Login')),
      ),
    ],
  ),
)

// Announce dynamic changes
SemanticsService.announce('Workout saved successfully', TextDirection.ltr);
```

### Dynamic Text / Font Scaling Support

```dart
// Use MediaQuery.textScalerOf for responsive text
final textScaler = MediaQuery.textScalerOf(context);

// Never constrain text containers to fixed heights
// DO:
Text('Workout Title', style: Theme.of(context).textTheme.headlineMedium)
// DON'T:
SizedBox(height: 24, child: Text('Workout Title')) // Clips at large font sizes

// Test with: flutter run --dart-define=FLUTTER_TEXT_SCALE_FACTOR=2.0
```

## Performance Templates

### Paginated Lists

```dart
@riverpod
class PaginatedWorkouts extends _$PaginatedWorkouts {
  static const _pageSize = 20;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  @override
  FutureOr<List<Workout>> build() async {
    _lastDoc = null;
    _hasMore = true;
    return _fetchPage();
  }

  Future<List<Workout>> _fetchPage() async {
    var query = FirebaseFirestore.instance
        .collection('workouts')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();
    if (snapshot.docs.length < _pageSize) _hasMore = false;
    if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;

    return snapshot.docs.map((d) => Workout.fromFirestore(d)).toList();
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    final nextPage = await _fetchPage();
    state = AsyncValue.data([...current, ...nextPage]);
  }
}
```

### Image Optimization

```dart
// Always specify cacheWidth/cacheHeight for memory efficiency
CachedNetworkImage(
  imageUrl: workout.imageUrl,
  cacheKey: workout.id,
  memCacheWidth: 300,  // Match display size
  memCacheHeight: 300,
  placeholder: (_, __) => const ShimmerPlaceholder(),
  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
  fadeInDuration: const Duration(milliseconds: 200),
)
```

### Avoid Unnecessary Rebuilds

```dart
// Use const constructors everywhere possible
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({super.key, required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context) { /* ... */ }
}

// Use select() to watch specific fields only
final userName = ref.watch(
  userProvider.select((user) => user.valueOrNull?.displayName ?? ''),
);

// Wrap expensive widgets with RepaintBoundary
RepaintBoundary(
  child: CustomPaint(painter: ChartPainter(data: chartData)),
)
```

## User Experience (UX) Templates

### Haptic Feedback

```dart
import 'package:flutter/services.dart';

// On key interactions
GestureDetector(
  onTap: () {
    HapticFeedback.lightImpact();
    _onItemSelected(item);
  },
  child: itemWidget,
)

// On destructive actions
onPressed: () {
  HapticFeedback.heavyImpact();
  _showDeleteConfirmation();
}

// On success
void _onSaveSuccess() {
  HapticFeedback.mediumImpact();
  ScaffoldMessenger.of(context).showSnackBar(/* ... */);
}
```

### Skeleton / Shimmer Loading States

```dart
// Never show empty screens — always show skeleton loaders
class WorkoutListSkeleton extends StatelessWidget {
  const WorkoutListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ShimmerEffect(
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

// Usage in AsyncValue.when()
usersAsync.when(
  loading: () => const WorkoutListSkeleton(),
  error: (err, stack) => ErrorRetryWidget(error: err, onRetry: ref.invalidate(workoutListProvider)),
  data: (workouts) => WorkoutListView(workouts: workouts),
)
```

### Shimmer Effect Widget

```dart
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: [
            _controller.value - 0.3,
            _controller.value,
            _controller.value + 0.3,
          ],
        ).createShader(bounds),
        blendMode: BlendMode.srcATop,
        child: child,
      ),
      child: widget.child,
    );
  }
}
```

### Smooth Animations

```dart
// Page transitions with curves
PageRouteBuilder(
  pageBuilder: (_, __, ___) => const DetailScreen(),
  transitionsBuilder: (_, animation, __, child) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  },
  transitionDuration: const Duration(milliseconds: 300),
)

// AnimatedSwitcher for state changes
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  switchInCurve: Curves.easeOutCubic,
  switchOutCurve: Curves.easeInCubic,
  child: isCompleted
      ? const Icon(Icons.check_circle, key: ValueKey('done'), color: Colors.green)
      : const Icon(Icons.circle_outlined, key: ValueKey('pending')),
)
```

### Real-time Form Validation

```dart
class WorkoutForm extends ConsumerStatefulWidget {
  const WorkoutForm({super.key});

  @override
  ConsumerState<WorkoutForm> createState() => _WorkoutFormState();
}

class _WorkoutFormState extends ConsumerState<WorkoutForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Workout Name',
              hintText: 'e.g., Morning Run',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Workout name is required';
              }
              if (value.trim().length < 3) {
                return 'Name must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: const Text('Save Workout'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      // Save workout...
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
```

## Premium Polish & Design Templates

### Glassmorphism with BackdropFilter

```dart
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(opacity),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
```

### Modern Card Styling

```dart
class PremiumCard extends StatelessWidget {
  final Widget child;
  final bool isPremium;

  const PremiumCard({
    super.key,
    required this.child,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: isPremium
            ? Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
          if (isPremium)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PRO',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

### Dark/Light Theme with ThemeExtension

```dart
// Custom theme extension for app-specific colors
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color warning;
  final Color cardGradientStart;
  final Color cardGradientEnd;

  const AppColors({
    required this.success,
    required this.warning,
    required this.cardGradientStart,
    required this.cardGradientEnd,
  });

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? cardGradientStart,
    Color? cardGradientEnd,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      cardGradientStart: cardGradientStart ?? this.cardGradientStart,
      cardGradientEnd: cardGradientEnd ?? this.cardGradientEnd,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      cardGradientStart: Color.lerp(cardGradientStart, other.cardGradientStart, t)!,
      cardGradientEnd: Color.lerp(cardGradientEnd, other.cardGradientEnd, t)!,
    );
  }

  static const light = AppColors(
    success: Color(0xFF2E7D32),
    warning: Color(0xFFF57F17),
    cardGradientStart: Color(0xFF6366F1),
    cardGradientEnd: Color(0xFF8B5CF6),
  );

  static const dark = AppColors(
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFD54F),
    cardGradientStart: Color(0xFF818CF8),
    cardGradientEnd: Color(0xFFA78BFA),
  );
}

// Register in theme
ThemeData lightTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6366F1),
    brightness: Brightness.light,
  ),
  extensions: const [AppColors.light],
);

ThemeData darkTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6366F1),
    brightness: Brightness.dark,
  ),
  extensions: const [AppColors.dark],
);

// Usage
final appColors = Theme.of(context).extension<AppColors>()!;
Container(color: appColors.success)
```

### Gradient Accent Decorations

```dart
// Gradient app bar or header
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.tertiary,
      ],
    ),
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
  ),
  padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Good Morning',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
      ),
    ],
  ),
)
```
