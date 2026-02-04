---
name: riverpod-patterns
description: "This skill provides Riverpod state management patterns and best practices for Flutter applications. Use when reviewing or writing Riverpod providers, AsyncValue handling, ref usage, or provider lifecycle management."
allowed-tools: Read
---

# Riverpod Patterns

Correct Riverpod patterns for Flutter state management with code_generation style.

**When to use:** Writing or reviewing Riverpod providers, AsyncNotifier, AsyncValue.when, ref.watch vs ref.read, family providers, or provider lifecycle.

**Process:**

1. **Identify pattern needed** from user request
2. **Load reference:** Read `reference/riverpod-core-patterns.md` for code examples and rules
3. **Apply patterns** using loaded reference
4. **Verify:** Confirm ref.watch is only in build(), ref.read only in callbacks, all AsyncValue states handled visibly
