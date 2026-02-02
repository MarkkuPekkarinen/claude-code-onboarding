---
name: angular-spa
description: Patterns and templates for Angular 21.x SPA development with standalone components, signals, and lazy routing. Activate when building Angular components, services, routes, or tests.
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
**Read** [`reference/angular-templates.md`](/Users/kumaraniyyasamysrinivasan/mydrive/personal/claude-code-onboarding/.claude/skills/angular-spa/reference/angular-templates.md)

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

## Error Handling

### Common Compilation Errors

**Error:** `NullInjectorError: No provider for HttpClient`
- **Fix:** Add `provideHttpClient()` to `app.config.ts` providers

**Error:** `Component is not standalone`
- **Fix:** Add `standalone: true` to `@Component` decorator

**Error:** `Cannot find module './feature.component'`
- **Fix:** Ensure component is exported with `export class FeatureComponent`

**Error:** `ExpressionChangedAfterItHasBeenCheckedError`
- **Fix:** Use `ChangeDetectionStrategy.OnPush` or wrap state changes in `setTimeout` / `effect`

### Runtime Errors

**Error:** Route not lazy loading
- **Fix:** Verify `loadComponent` returns a Promise; use dynamic import `() => import('./...')`

**Error:** Interceptor not firing
- **Fix:** Register with `provideHttpClient(withInterceptors([...]))` in `app.config.ts`

**Error:** Signal not updating UI
- **Fix:** Ensure you're calling `.set()` or `.update()`, not mutating signal value directly

**Error:** Guard not protecting route
- **Fix:** Add `canActivate: [guardFn]` to route config

## Angular CLI Commands

```bash
# Generate component (standalone)
ng generate component features/users/user-list --standalone

# Generate service
ng generate service core/services/user

# Generate guard (functional)
ng generate guard core/guards/auth --functional

# Run dev server
ng serve

# Build for production
ng build --configuration=production

# Run tests
ng test

# Run linter
ng lint
```

## Best Practices

- Always use `ChangeDetectionStrategy.OnPush` for performance
- Prefer signals over BehaviorSubject for component state
- Use `inject()` instead of constructor injection (modern Angular style)
- Lazy load all feature routes to reduce initial bundle size
- Use `trackBy` in `@for` loops for performance with large lists
- Unsubscribe from observables using `takeUntilDestroyed()` or `async` pipe
- Write unit tests for all components and services
- Use environment files for API URLs and configuration
- Follow BEM naming for CSS classes
- Keep components small and focused (Single Responsibility Principle)
