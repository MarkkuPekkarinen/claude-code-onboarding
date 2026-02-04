---
name: angular-spa
description: "Angular 21.x SPA development skill with TailwindCSS 4.x and daisyUI 5.5.5. Use when building Angular standalone components, services, lazy-loaded routes, unit tests, or creating UI with TailwindCSS + daisyUI. Covers component scaffolding, UI/UX design, accessibility audits, and design systems."
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, WebFetch, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Angular 21.x SPA Development Skill

> **Tech Stack**: Angular 21+, TailwindCSS 4.x, daisyUI 5.5.5

## Code Conventions
- Standalone components (no NgModules unless legacy)
- Signals for state management: `signal()`, `computed()`, `input()`, `output()`
- Control flow: `@if`, `@for`, `@switch`, `@defer` — no `*ngIf`/`*ngFor`
- `ChangeDetectionStrategy.OnPush` on all components
- Lazy-loaded routes via `loadComponent`
- Use `HttpClient` with RxJS operators
- **TailwindCSS 4.x** + **daisyUI 5.5.5** for styling (CSS-native config, no `tailwind.config.js`)
- Use daisyUI semantic colors only — never hardcode hex values
- Folder structure: `features/ → shared/ → core/`
- 
## When to Use

Activate when: building Angular standalone components, services, lazy-loaded routes, unit tests, creating UI mockups, scaffolding Angular SPAs, designing forms, running accessibility audits, or creating design systems with TailwindCSS + daisyUI.

## Documentation Sources

Before generating code, consult these sources for current syntax and APIs:

| Source | URL / Tool | Purpose |
|--------|-----------|---------|
| Angular v21 | `angular-cli` MCP (ng mcp) | Workspace-aware help, schematics, builds, best practices |
| Angular v21 | `https://angular.dev/assets/context/llms-full.txt` | Static docs bundle — API reference, deprecated features |
| daisyUI v5.5.5 | `https://daisyui.com/llms.txt` | Component reference, color system, themes |
| TailwindCSS / RxJS | `Context7` MCP | Latest syntax, utilities, operators |

Cross-check all Angular APIs and CLI flags against fetched docs — do NOT use deprecated or removed features.

> For Angular & TypeScript best practices, read reference/angular-best-practices.md

## Styling

- **daisyUI semantic colors only** — never hardcode hex values (`bg-primary`, not `bg-[#3b82f6]`)
- **TailwindCSS 4.x** uses CSS-native config (`@theme {}` in CSS, no `tailwind.config.js`)
- **PostCSS config** must be `.postcssrc.json` — Angular's `@angular/build:application` builder ignores `postcss.config.js`
- **Global styles** must be `.css` (not `.scss`) — Sass intercepts TailwindCSS 4.x directives (`@import`, `@theme`, `@plugin`)
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

## Common Commands

```bash
ng serve                             # Dev server at localhost:4200
ng build --configuration=production  # Production build
ng test                              # Unit tests (Karma/Jest)
ng generate component <name>         # Scaffold component
ng generate service <name>           # Scaffold service
ng lint                              # Run linter
npx tsc --noEmit                     # Type check only
```

## Reference Files

Detailed patterns are in `reference/`:

### Angular Best Practices & Code Templates
- `angular-best-practices.md` — TypeScript, component, template, state management, services, forms, zoneless, accessibility, and testing best practices
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
