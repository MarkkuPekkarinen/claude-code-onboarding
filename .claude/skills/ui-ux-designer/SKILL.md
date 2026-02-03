---
name: ui-ux-designer
description: UI/UX design skill for Angular 21+ with TailwindCSS 4.x and daisyUI 5.5.5. Covers component scaffolding, accessibility audits, design systems, and user research.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
---

# UI/UX Designer Skill

> **Tech Stack**: Angular 21+, TailwindCSS 4.x, daisyUI 5.5.5

## When to Use

Activate when: creating UI mockups, scaffolding Angular SPAs, building reusable components, designing forms, running accessibility audits, or creating design systems with TailwindCSS + daisyUI.

## Core Rules

### Styling
- **daisyUI semantic colors only** — never hardcode hex values (`bg-primary`, not `bg-[#3b82f6]`)
- **TailwindCSS 4.x** uses CSS-native config (`@theme {}` in CSS, no `tailwind.config.js`)
- **Mobile-first** — start with base styles, add `sm:`, `md:`, `lg:` breakpoints
- **Spacing**: 4px base unit (4, 8, 12, 16, 24, 32, 48, 64)

### Angular Component Standards
- Standalone components, `ChangeDetectionStrategy.OnPush`
- Signal-based: `signal()`, `computed()`, `input()`, `output()`, `inject()`
- Control flow: `@if`, `@for`, `@switch`, `@defer` — no `*ngIf`/`*ngFor`
- All interactive elements must have loading, error, empty, and success states

### Accessibility (WCAG 2.1 AA minimum)
- Text contrast >= 4.5:1, UI component contrast >= 3:1
- Touch targets >= 44x44px on mobile
- All icon-only buttons need `aria-label`
- Keyboard navigable: Tab, Enter, Space, Arrow keys
- `aria-live="polite"` for dynamic content updates
- `prefers-reduced-motion` respected for all animations

### Design Principles
1. **Visual hierarchy** — size, color, spacing, contrast guide attention
2. **Consistency** — reuse daisyUI components, don't invent custom variants
3. **Feedback** — instant response (<100ms hover/click), loading states for >300ms async
4. **Progressive disclosure** — primary actions visible, secondary behind menus/accordions
5. **Affordance** — buttons look clickable, inputs have borders, interactive elements change cursor

## Key Patterns

### TailwindCSS 4.x Setup
```css
/* src/styles.css */
@import "tailwindcss";
@import "daisyui";

@theme {
  --font-sans: "Inter", "system-ui", sans-serif;
}

@plugin "daisyui" {
  themes: light --default, dark --prefersdark, corporate, business;
}
```

### daisyUI v5.5.5 Modal (required pattern)
```html
<dialog id="my_modal" class="modal">
  <div class="modal-box">
    <h3 class="text-lg font-bold">Title</h3>
    <p class="py-4">Content</p>
    <div class="modal-action">
      <form method="dialog"><button class="btn">Close</button></form>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop"><button>close</button></form>
</dialog>
```

### daisyUI v5.5.5 Drawer (required pattern)
```html
<div class="drawer lg:drawer-open">
  <input id="drawer" type="checkbox" class="drawer-toggle" />
  <div class="drawer-content"><!-- page content --></div>
  <div class="drawer-side">
    <label for="drawer" aria-label="close sidebar" class="drawer-overlay"></label>
    <ul class="menu bg-base-200 min-h-full w-80 p-4"><!-- nav items --></ul>
  </div>
</div>
```

### Color System
```
bg-base-100/200/300     — backgrounds
bg-primary/secondary/accent — brand colors
bg-info/success/warning/error — states
text-base-content       — primary text
text-base-content/60    — secondary text
border-base-300         — default borders
```

## Reference Files

Detailed patterns are in `reference/`:
- `tailwind-v4-config.md` — TailwindCSS 4.x setup, breaking changes from v3
- `daisyui-v5-components.md` — Full component reference, color system, themes
- `angular-ui-components.md` — Reusable component code (form-field, data-table, toast, theme, etc.)
- `accessibility-checklist.md` — WCAG 2.1 AA checklist, ARIA patterns, test protocol
- `animations.md` — Timing standards, keyframes, utility classes
- `user-research.md` — Persona templates, journey mapping, usability testing, SUS survey
