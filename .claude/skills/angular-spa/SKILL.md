---
name: angular-spa
description: Angular 21.x SPA development skill with TailwindCSS 4.x and daisyUI 5.5.5. Covers component scaffolding, services, lazy routing, UI/UX design, accessibility audits, and design systems.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, WebFetch, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Angular 21.x SPA Development Skill

> **Tech Stack**: Angular 21+, TailwindCSS 4.x, daisyUI 5.5.5

## When to Use

Activate when: building Angular standalone components, services, lazy-loaded routes, unit tests, creating UI mockups, scaffolding Angular SPAs, designing forms, running accessibility audits, or creating design systems with TailwindCSS + daisyUI.

## Pre-requisites — Verify Angular 21.x Conventions

Before generating any code, you MUST fetch the latest Angular documentation to verify current syntax, APIs, deprecated features, and best practices:

1. Fetch `https://angular.dev/assets/context/llms-full.txt` using WebFetch to get the latest Angular API reference, deprecated features, and current conventions.
2. Use Context7 MCP (`resolve-library-id` then `query-docs`) to verify any APIs you are unsure about (e.g., `bootstrapApplication`, `provideRouter`, component decorator options, control flow syntax).
3. Cross-check all Angular APIs and CLI flags against the fetched docs — do NOT use deprecated or removed features.

## Angular & TypeScript Best Practices (MUST follow)

### TypeScript
- Use strict type checking (`strict: true` in tsconfig)
- Prefer type inference when the type is obvious
- Avoid the `any` type; use `unknown` when type is uncertain

### Components
- Always use standalone components — do NOT set `standalone: true` in decorators (it is the default in Angular v20+)
- Use `input()` and `output()` functions instead of `@Input`/`@Output` decorators
- Use `signal()` for local state, `computed()` for derived state
- Set `changeDetection: ChangeDetectionStrategy.OnPush` in every `@Component` decorator
- Prefer inline templates for small components
- Do NOT use `@HostBinding`/`@HostListener` — use the `host` object in the decorator instead
- Do NOT use `ngClass` — use `class` bindings instead
- Do NOT use `ngStyle` — use `style` bindings instead
- Use `NgOptimizedImage` for all static images
- All interactive elements must have loading, error, empty, and success states

### Templates
- Use native control flow: `@if`, `@for`, `@switch`, `@defer` — never `*ngIf`, `*ngFor`, `*ngSwitch`
- Use `track` in `@for` loops for performance (e.g., `@for (item of items(); track item.id)`)
- Keep templates simple; avoid complex logic
- Use the async pipe to handle observables in templates
- Do not write arrow functions in templates (not supported)
- Do not assume globals like `new Date()` are available in templates

### State Management
- Use signals for local component state
- Use `computed()` for derived state
- Keep state transformations pure and predictable
- Do NOT use `mutate` on signals — use `update` or `set` instead

### Services
- Design services around a single responsibility
- Use `providedIn: 'root'` for singleton services
- Use the `inject()` function instead of constructor injection

### Forms
- Prefer Reactive forms over Template-driven forms

### Zoneless (Angular 21 default)
- Angular 21 is zoneless by default — do NOT add `provideZoneChangeDetection()` or import `zone.js`
- Do NOT install `zone.js` as a dependency
- Do NOT add `provideZonelessChangeDetection()` either — it is the default and unnecessary in v21+

### Accessibility (WCAG 2.1 AA minimum)
- Must pass all AXE checks
- Must follow WCAG AA minimums: focus management, color contrast, ARIA attributes
- Text contrast >= 4.5:1, UI component contrast >= 3:1
- Touch targets >= 44x44px on mobile
- All icon-only buttons need `aria-label`
- Keyboard navigable: Tab, Enter, Space, Arrow keys
- `aria-live="polite"` for dynamic content updates
- `prefers-reduced-motion` respected for all animations

### Testing
- Use `provideZonelessChangeDetection()` in TestBed (required for tests even though it's the app default)
- Use `await fixture.whenStable()` instead of `fixture.detectChanges()` for zoneless
- Use `provideHttpClient()` and `provideHttpClientTesting()` for HTTP mocking
- See `reference/angular-templates.md` for full component and service test templates

## Styling

- **daisyUI semantic colors only** — never hardcode hex values (`bg-primary`, not `bg-[#3b82f6]`)
- **TailwindCSS 4.x** uses CSS-native config (`@theme {}` in CSS, no `tailwind.config.js`)
- **Mobile-first** — start with base styles, add `sm:`, `md:`, `lg:` breakpoints
- **Spacing**: 4px base unit (4, 8, 12, 16, 24, 32, 48, 64)
- **BEM Naming** for custom CSS: `.block__element--modifier`

## Design Principles

1. **Visual hierarchy** — size, color, spacing, contrast guide attention
2. **Consistency** — reuse daisyUI components, don't invent custom variants
3. **Feedback** — instant response (<100ms hover/click), loading states for >300ms async
4. **Progressive disclosure** — primary actions visible, secondary behind menus/accordions
5. **Affordance** — buttons look clickable, inputs have borders, interactive elements change cursor

## Quick Scaffold — New Angular Project

```bash
npx @angular/cli@latest new my-app --style=scss --ssr=false
cd my-app
```

Do NOT pass `--standalone` (removed/default since v19). Verify flags against fetched docs.

## Process

1. **Understand Requirements** — Clarify feature scope, API endpoints, data models, and UI requirements
2. **Scaffold Structure** — Create feature folder under `src/app/features/<feature-name>/`
3. **Generate Component** — Read `reference/angular-templates.md` for templates; create with signals-based state
4. **Create Service** — Read `reference/angular-templates.md` for service template; implement API calls with HttpClient + RxJS
5. **Configure Routes** — Add lazy-loaded route using `loadComponent` in `app.routes.ts` or feature routes
6. **Write Tests** — Read `reference/angular-templates.md` for test templates; write unit tests with zoneless TestBed
7. **Style Component** — Use daisyUI components + TailwindCSS utilities; fallback to SCSS with BEM naming
8. **Verify Build** — Run `ng build` to ensure no compilation errors

## Key Patterns

| Pattern | Description |
|---------|-------------|
| **Standalone Component** | Default in Angular v20+ — do NOT set `standalone: true` in decorators |
| **Signals** | Use `signal()`, `computed()`, `effect()` for reactive state |
| **input() / output()** | Use function-based `input()` and `output()` — not `@Input`/`@Output` decorators |
| **inject() Function** | Prefer `inject()` over constructor injection |
| **OnPush Change Detection** | Use `ChangeDetectionStrategy.OnPush` on all components |
| **Zoneless** | Angular 21 default — no `zone.js`, no zone providers needed |
| **Lazy Loading** | Use `loadComponent` for routes, `loadChildren` for feature routes |
| **Functional Interceptors** | Use `HttpInterceptorFn` instead of class-based interceptors |
| **Functional Guards** | Use `CanActivateFn` instead of class-based guards |
| **Control Flow Syntax** | Use `@if`, `@for`, `@switch`, `@defer` — never `*ngIf`/`*ngFor` |
| **RxJS Observables** | Return `Observable<T>` from services, subscribe in components |

## Folder Structure

```
src/app/
├── core/               # Singletons: auth, interceptors, guards
│   ├── services/
│   ├── interceptors/
│   └── guards/
├── shared/             # Reusable components, pipes, directives
│   ├── components/
│   ├── pipes/
│   └── directives/
├── features/           # Feature modules (lazy loaded)
│   ├── dashboard/
│   │   ├── dashboard.component.ts
│   │   ├── dashboard.component.html
│   │   ├── dashboard.component.scss
│   │   └── dashboard.component.spec.ts
│   ├── users/
│   │   ├── users.routes.ts
│   │   ├── user-list.component.ts
│   │   └── user-detail.component.ts
│   └── settings/
├── app.ts
├── app.html
├── app.routes.ts
└── app.config.ts
```

## Reference Files

Detailed patterns are in `reference/`:

### Angular Code Templates & Troubleshooting
- `angular-templates.md` — Standalone component, service, lazy routes, app.config, interceptor, guard, and test templates
- `angular-troubleshooting.md` — Common errors (NG0908, NullInjectorError, blank screen), CLI commands, and best practices

### UI/UX & Design System
- `tailwind-v4-config.md` — TailwindCSS 4.x setup, breaking changes from v3
- `daisyui-v5-components.md` — Full component reference, color system, themes, quick setup patterns
- `angular-ui-form-components.md` — Form fields and validation components
- `angular-ui-data-components.md` — Cards, tables, skeletons, empty states, navigation
- `angular-ui-feedback-components.md` — Toasts, dialogs, themes, error handling, utilities
- `accessibility-checklist.md` — WCAG 2.1 AA checklist, ARIA patterns, test protocol
- `animations.md` — Timing standards, keyframes, utility classes
- `user-research.md` — Persona templates, journey mapping, usability testing, SUS survey
