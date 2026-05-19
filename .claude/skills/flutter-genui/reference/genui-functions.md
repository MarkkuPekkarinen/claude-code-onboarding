# Flutter GenUI — A2UI Declarative Functions

A2UI components support **declarative function calls** inside property value objects. Instead of sending a literal string or a data-model path, the agent sends a `call` descriptor. The Flutter renderer evaluates it using its own Dart implementation — no agent code runs.

## How It Works

In the JSON payload received from the agent:

```json
{
  "id": "price-text",
  "component": {
    "type": "Text",
    "text": {
      "call": {
        "name": "formatCurrency",
        "args": [{"path": "/booking/totalPrice"}, {"literalString": "USD"}],
        "returnType": "string"
      }
    }
  }
}
```

The Flutter renderer resolves the `call` node via `A2UIFunctionEvaluator` before passing the result to the widget builder. Args can themselves be `call` nodes — enabling composition like `not(and(required(x), required(y)))`.

---

## Function Reference

### Validation Functions

Used in widget `validation` properties and form submission gates.

| Name | Args | Returns | Description |
|------|------|---------|-------------|
| `required` | `(value)` | `bool` | True if value is non-null and non-empty |
| `regex` | `(value, pattern)` | `bool` | True if value matches the regex pattern |
| `length` | `(value, min, max)` | `bool` | True if string length is within [min, max] |
| `numeric` | `(value, min?, max?)` | `bool` | True if value is a number, optionally in range |
| `email` | `(value)` | `bool` | True if value matches email format |

### Formatting Functions

Used in `Text` widget `text` properties for display.

| Name | Args | Returns | Description |
|------|------|---------|-------------|
| `formatString` | `(template, ...args)` | `String` | Substitutes `{0}`, `{1}` in template with args |
| `formatNumber` | `(value, decimalPlaces?)` | `String` | Locale-aware number: `"1,234.50"` |
| `formatCurrency` | `(value, currencyCode)` | `String` | `"$1,234.56"` for USD |
| `formatDate` | `(value, pattern?)` | `String` | ISO 8601 input → `"May 19, 2026"` |
| `pluralize` | `(count, singular, plural)` | `String` | `"1 item"` vs `"3 items"` |

### Logical Functions

Used in widget `visible` or `disabled` properties for conditional rendering.

| Name | Args | Returns | Description |
|------|------|---------|-------------|
| `and` | `(...booleans)` | `bool` | True if all args are truthy |
| `or` | `(...booleans)` | `bool` | True if any arg is truthy |
| `not` | `(boolean)` | `bool` | Logical negation |

### Navigation Functions

| Name | Args | Returns | Description |
|------|------|---------|-------------|
| `openUrl` | `(url)` | `void` | Opens URL externally — `https://` only, validated before launch |

---

## Dart Implementation: `A2UIFunctionEvaluator`

```dart
// lib/widgets/gen_ui/a2ui_function_evaluator.dart

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Evaluates A2UI declarative function call descriptors.
/// This is a renderer-side implementation — agent never sends executable code.
class A2UIFunctionEvaluator {
  static const _allowed = {
    'required', 'regex', 'length', 'numeric', 'email',
    'formatString', 'formatNumber', 'formatCurrency', 'formatDate', 'pluralize',
    'and', 'or', 'not', 'openUrl',
  };

  final Map<String, dynamic> dataModel;

  const A2UIFunctionEvaluator({required this.dataModel});

  dynamic evaluate(Map<String, dynamic> call) {
    final name = call['name'] as String?;
    if (name == null || !_allowed.contains(name)) {
      // Unknown function — silently skip, log for debugging
      assert(() { debugPrint('A2UI: unknown function "$name" — rejected'); return true; }());
      return null;
    }
    final rawArgs = (call['args'] as List<dynamic>? ?? []);
    final args = rawArgs.map((a) => _resolveArg(a as Map<String, dynamic>)).toList();
    return _dispatch(name, args);
  }

  dynamic _resolveArg(Map<String, dynamic> arg) {
    if (arg.containsKey('literalString')) return arg['literalString'];
    if (arg.containsKey('path')) return _resolvePath(arg['path'] as String);
    if (arg.containsKey('call')) return evaluate(arg['call'] as Map<String, dynamic>);
    return null;
  }

  dynamic _resolvePath(String path) {
    final parts = path.replaceFirst(RegExp(r'^/'), '').split('/');
    dynamic current = dataModel;
    for (final part in parts) {
      if (current is! Map) return null;
      current = current[part];
    }
    return current;
  }

  dynamic _dispatch(String name, List<dynamic> args) {
    switch (name) {
      // Validation
      case 'required':
        final v = args[0];
        return v != null && v.toString().isNotEmpty;
      case 'email':
        return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(args[0]?.toString() ?? '');
      case 'regex':
        return RegExp(args[1]?.toString() ?? '').hasMatch(args[0]?.toString() ?? '');
      case 'length':
        final len = args[0]?.toString().length ?? 0;
        return len >= (args[1] as num? ?? 0) && len <= (args[2] as num? ?? double.infinity);
      case 'numeric':
        final n = num.tryParse(args[0]?.toString() ?? '');
        if (n == null) return false;
        final min = args.length > 1 ? args[1] as num? : null;
        final max = args.length > 2 ? args[2] as num? : null;
        return (min == null || n >= min) && (max == null || n <= max);

      // Formatting
      case 'formatCurrency':
        final value = (args[0] as num? ?? 0).toDouble();
        final code = args[1]?.toString() ?? 'USD';
        return NumberFormat.currency(symbol: _currencySymbol(code), decimalDigits: 2).format(value);
      case 'formatNumber':
        final value = (args[0] as num? ?? 0).toDouble();
        final decimals = (args.length > 1 ? args[1] as int? : null) ?? 2;
        return NumberFormat.decimalPattern().format(value);
      case 'formatDate':
        final d = DateTime.tryParse(args[0]?.toString() ?? '');
        if (d == null) return args[0]?.toString() ?? '';
        return DateFormat(args.length > 1 ? args[1]?.toString() : 'MMM d, yyyy').format(d);
      case 'formatString':
        String result = args[0]?.toString() ?? '';
        for (var i = 1; i < args.length; i++) {
          result = result.replaceAll('{${i - 1}}', args[i]?.toString() ?? '');
        }
        return result;
      case 'pluralize':
        final count = (args[0] as num? ?? 0).toInt();
        return '$count ${count == 1 ? args[1] : args[2]}';

      // Logical
      case 'and':
        return args.every((a) => a == true || (a is num && a != 0) || (a is String && a.isNotEmpty));
      case 'or':
        return args.any((a) => a == true || (a is num && a != 0) || (a is String && a.isNotEmpty));
      case 'not':
        return !(args[0] == true || (args[0] is num && args[0] != 0) || (args[0] is String && (args[0] as String).isNotEmpty));

      // Navigation
      case 'openUrl':
        final url = args[0]?.toString() ?? '';
        if (!url.startsWith('https://')) {
          debugPrint('A2UI: openUrl blocked non-https URL: $url');
          return null;
        }
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return null;

      default:
        return null;
    }
  }

  String _currencySymbol(String code) {
    const symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥', 'AUD': 'A\$'};
    return symbols[code] ?? code;
  }
}
```

---

## Integration with the Catalog Builder

Pass the evaluator to widget builders so they can resolve function-valued properties:

```dart
// In your CatalogItem builder function:
CatalogItem(
  type: 'text',
  schema: JsonSchema.object({
    'text': JsonSchema.object({}), // accepts literalString, path, or call
  }),
  builder: (properties, conversation, dataModel) {
    final evaluator = A2UIFunctionEvaluator(dataModel: dataModel);
    final textProp = properties['text'];
    final resolvedText = textProp is Map
        ? evaluator.evaluate(textProp as Map<String, dynamic>)?.toString() ?? ''
        : textProp?.toString() ?? '';
    return Text(resolvedText);
  },
),
```

## Integration with the Renderer

In `gen_ui_renderer.dart`, evaluate function calls before rendering conditional properties (`visible`, `disabled`):

```dart
Widget _buildWidget(Map<String, dynamic> spec, Map<String, dynamic> dataModel) {
  final evaluator = A2UIFunctionEvaluator(dataModel: dataModel);

  // Evaluate conditional visibility
  final visibleProp = spec['visible'];
  if (visibleProp is Map && visibleProp.containsKey('call')) {
    final visible = evaluator.evaluate(visibleProp['call'] as Map<String, dynamic>) as bool? ?? true;
    if (!visible) return const SizedBox.shrink();
  }

  return catalog.build(spec, evaluator);
}
```

---

## Example: Validation-Gated Submit Button

Agent sends a submit button that is disabled until both name and email are valid:

```json
{
  "id": "submit-btn",
  "component": {
    "type": "button",
    "label": {"literalString": "Submit"},
    "disabled": {
      "call": {
        "name": "not",
        "args": [{
          "call": {
            "name": "and",
            "args": [
              {"call": {"name": "required", "args": [{"path": "/user/name"}], "returnType": "boolean"}},
              {"call": {"name": "email", "args": [{"path": "/user/email"}], "returnType": "boolean"}}
            ],
            "returnType": "boolean"
          }
        }],
        "returnType": "boolean"
      }
    }
  }
}
```

---

## Security Rule

The `_allowed` set in `A2UIFunctionEvaluator` is a **security boundary** — identical in purpose to the catalog allowlist. An agent sending an unknown function name results in a null return and a debug log, never execution. Never add dynamic dispatch (e.g., using `mirrors` or `Function.apply` with agent-provided names).
