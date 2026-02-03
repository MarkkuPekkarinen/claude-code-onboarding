---
name: angular-spa
description: This skill provides patterns and templates for Angular 21.x SPA development. It should be activated when building Angular standalone components, services, lazy-loaded routes, or unit tests.
allowed-tools: Bash, Read, Write, Edit
---

# Angular 21.x SPA Development Skill

## Quick Scaffold — New Angular Project
```bash
npx @angular/cli@latest new my-app \
  --routing --style=scss --standalone --ssr=false
cd my-app
```

## Code Templates

For standalone component, service, lazy routes, app.config, interceptor, and test templates:
**Read** `reference/angular-templates.md`

## Process

1. **Understand Requirements** — Clarify feature scope, API endpoints, data models, and UI requirements
2. **Scaffold Structure** — Create feature folder under `src/app/features/<feature-name>/`
3. **Generate Component** — Use Read tool to access standalone component template; create with signals-based state
4. **Create Service** — Use Read tool for service template; implement API calls with HttpClient + RxJS
5. **Configure Routes** — Add lazy-loaded route using `loadComponent` in `app.routes.ts` or feature routes
6. **Write Tests** — Use Read tool for test templates; write unit tests for component and service
7. **Style Component** — Create SCSS file with BEM naming (`.block__element--modifier`)
8. **Verify Build** — Run `ng build` to ensure no compilation errors

## Key Patterns

| Pattern | Description |
|---------|-------------|
| **Standalone Component** | Use `standalone: true`, no NgModule required |
| **Signals** | Use `signal()`, `computed()`, `effect()` for reactive state |
| **inject() Function** | Prefer `inject()` over constructor injection |
| **OnPush Change Detection** | Use `ChangeDetectionStrategy.OnPush` for performance |
| **Lazy Loading** | Use `loadComponent` for routes, `loadChildren` for feature routes |
| **Functional Interceptors** | Use `HttpInterceptorFn` instead of class-based interceptors |
| **Functional Guards** | Use `CanActivateFn` instead of class-based guards |
| **Control Flow Syntax** | Use `@if`, `@for`, `@switch` instead of `*ngIf`, `*ngFor` |
| **BEM Naming** | Use `.block__element--modifier` for CSS classes |
| **RxJS Observables** | Return `Observable<T>` from services, subscribe in components |

## Folder Structure

```
src/app/
├── core/               # Singletons: auth, interceptors, guards
│   ├── auth/
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
├── app.component.ts
├── app.routes.ts
└── app.config.ts
```

## Troubleshooting, CLI & Best Practices

For common errors (NullInjectorError, standalone issues, lazy loading, signals), Angular CLI commands, and best practices, Read `reference/angular-troubleshooting.md`.
