---
name: ui-standards-tokens
description: "This skill provides design token definitions, theming patterns, and UI standards for Flutter applications. Use when auditing UI compliance, implementing design systems, or ensuring consistent token usage."
allowed-tools: Read
---

# UI Standards - Design Tokens & Patterns

Design token system and accessibility patterns for Flutter applications.

**When to use:** Auditing UI compliance, implementing spacing/radius/size tokens, theme usage, accessibility, or responsive layouts.

**Process:**

1. **Identify domain** from user request
2. **Load reference:**
   - Design tokens, theme colors, typography, responsive layouts → Read `reference/ui-design-tokens.md`
   - Accessibility, semantics, focus management, reduced motion → Read `reference/ui-accessibility-patterns.md`
3. **Apply patterns** using loaded reference
4. **Verify:** No hardcoded colors, all touch targets >= 48px, semantic widgets on interactive elements
