# UI Standards - Design Tokens & Patterns Reference

## Design Token System

### Spacing Tokens
```dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
```

### Radius Tokens
```dart
class AppRadius {
  static const double none = 0;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}
```

### Size Tokens
```dart
class AppSize {
  static const double iconSm = 16;
  static const double icon = 24;
  static const double iconLg = 32;
  static const double touchTarget = 48;
  static const double avatar = 40;
  static const double avatarLg = 64;
}
```

## Accessibility Patterns

### Semantic Widget
```dart
Semantics(
  label: 'Add new item',
  button: true,
  enabled: true,
  onTapHint: 'Double tap to add',
  child: IconButton(
    onPressed: _addItem,
    icon: Icon(Icons.add),
  ),
)
```

### Reduced Motion
```dart
final reduceMotion = MediaQuery.disableAnimationsOf(context);
AnimatedContainer(
  duration: reduceMotion ? Duration.zero : Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  // ...
)
```

### Touch Target
```dart
SizedBox(
  width: AppSize.touchTarget,
  height: AppSize.touchTarget,
  child: InkWell(
    onTap: _onTap,
    borderRadius: BorderRadius.circular(AppRadius.full),
    child: Icon(Icons.close),
  ),
)
```

## Theme Usage

### Colors
```dart
// Never
Color(0xFF2196F3)
Colors.blue

// Always
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.onSurface
Theme.of(context).colorScheme.surfaceContainerHighest
```

### Typography
```dart
// Never
TextStyle(fontSize: 16, fontWeight: FontWeight.bold)

// Always
Theme.of(context).textTheme.titleMedium
Theme.of(context).textTheme.bodyLarge?.copyWith(
  fontWeight: FontWeight.bold,
)
```

## Responsive Patterns

```dart
class ResponsiveLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return DesktopLayout();
        } else if (constraints.maxWidth >= 600) {
          return TabletLayout();
        }
        return MobileLayout();
      },
    );
  }
}
```
