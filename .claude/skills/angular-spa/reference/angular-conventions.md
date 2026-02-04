# Angular Conventions & Project Structure

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
