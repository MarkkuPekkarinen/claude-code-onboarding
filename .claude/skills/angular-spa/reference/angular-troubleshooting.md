# Angular - Troubleshooting, CLI Commands & Best Practices

## Common Compilation Errors

**Error:** `NullInjectorError: No provider for HttpClient`
- **Fix:** Add `provideHttpClient()` to `app.config.ts` providers

**Error:** `Component is not standalone`
- **Fix:** Add `standalone: true` to `@Component` decorator

**Error:** `Cannot find module './feature.component'`
- **Fix:** Ensure component is exported with `export class FeatureComponent`

**Error:** `ExpressionChangedAfterItHasBeenCheckedError`
- **Fix:** Use `ChangeDetectionStrategy.OnPush` or wrap state changes in `setTimeout` / `effect`

## Runtime Errors

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
