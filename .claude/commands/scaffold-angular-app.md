---
description: Scaffold a new Angular 21.x SPA with standalone components, lazy routing, TailwindCSS + daisyUI, and a sample feature module
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, WebFetch, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Scaffold Angular SPA

Create a new Angular 21.x SPA project with the following:

**App name:** $ARGUMENTS (default to "my-app" if not provided)

## Pre-requisites — Verify Angular 21.x Conventions

Before generating any code, you MUST:

1. Read the `angular-spa` skill (`SKILL.md` and `reference/angular-templates.md`) for project conventions, code templates, and patterns.
2. Fetch `https://angular.dev/assets/context/llms-full.txt` using WebFetch to get the latest Angular API reference, deprecated features, and current conventions.
3. Use Context7 MCP (`resolve-library-id` then `query-docs`) to verify any APIs you are unsure about (e.g., `bootstrapApplication`, `provideRouter`, component decorator options, control flow syntax).
4. Cross-check the `ng new` CLI flags — do NOT pass flags that have been removed or are now defaults (e.g., `--standalone` is the default since v19 and the flag was removed; `--ssr=false` may have changed).

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

### Accessibility (WCAG 2.1 AA minimum)
- Must pass all AXE checks
- Must follow WCAG AA minimums: focus management, color contrast, ARIA attributes
- Text contrast >= 4.5:1, UI component contrast >= 3:1
- Touch targets >= 44x44px on mobile
- All icon-only buttons need `aria-label`
- Keyboard navigable: Tab, Enter, Space, Arrow keys
- `aria-live="polite"` for dynamic content updates
- `prefers-reduced-motion` respected for all animations

### Zoneless (Angular 21 default)
- Angular 21 is zoneless by default — do NOT add `provideZoneChangeDetection()` or import `zone.js`
- Do NOT install `zone.js` as a dependency
- Do NOT add `provideZonelessChangeDetection()` either — it is the default and unnecessary in v21+

## Steps

1. **Scaffold the project** — Run the Angular CLI to create the app. Verify the correct `ng new` flags from the fetched docs. At minimum:
   ```
   npx @angular/cli@latest new <name> --style=scss --ssr=false
   ```
   Do NOT pass `--standalone` (removed/default). Verify other flags against the fetched docs.

2. **Install TailwindCSS 4.x + daisyUI 5.5.5** — Inside the project directory:
   ```bash
   npm install tailwindcss @tailwindcss/postcss daisyui@latest
   ```
   Create `.postcssrc.json` in the project root (**NOT** `postcss.config.js` — Angular's `@angular/build:application` builder only reads `.postcssrc.json`):
   ```json
   { "plugins": { "@tailwindcss/postcss": {} } }
   ```
   Create `src/styles.css` (NOT `.scss` — TailwindCSS 4.x uses CSS-native directives that conflict with Sass) and update `angular.json` to reference `src/styles.css`:
   ```css
   @import "tailwindcss";

   @theme {
     --font-sans: "Inter", "system-ui", sans-serif;
   }

   @plugin "daisyui" {
     themes: light --default, dark --prefersdark;
   }
   ```
   Do NOT add `@import "daisyui"` — daisyUI is loaded via the `@plugin` directive in TailwindCSS 4.x.
   Use daisyUI semantic colors only — never hardcode hex values. Use BEM naming for custom CSS classes (`.block__element--modifier`).

3. **Set up folder structure** inside `src/app/`:
   ```
   core/services/
   core/interceptors/
   core/guards/
   shared/components/
   shared/pipes/
   shared/directives/
   features/dashboard/
   ```

4. **Configure `app.config.ts`** — Provide only what is needed:
   ```typescript
   import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
   import { provideRouter } from '@angular/router';
   import { provideHttpClient, withInterceptors } from '@angular/common/http';
   import { routes } from './app.routes';
   import { authInterceptor } from './core/interceptors/auth.interceptor';

   export const appConfig: ApplicationConfig = {
     providers: [
       provideBrowserGlobalErrorListeners(),
       provideRouter(routes),
       provideHttpClient(withInterceptors([authInterceptor])),
     ],
   };
   ```
   Do NOT add `provideZoneChangeDetection` or `provideZonelessChangeDetection`.

5. **Create a Dashboard feature** as a standalone component with:
   - `ChangeDetectionStrategy.OnPush`
   - Signals for state (`signal()`, `computed()`)
   - `inject()` for dependency injection
   - `input()` / `output()` functions (not decorators)
   - `@if`/`@for` (with `track`) control flow in template
   - Inline template and styles (small component)
   - Use daisyUI classes for styling (`card`, `btn`, `badge`, `stat`, etc.)
   - Must render meaningful content without a backend (use static/mock data directly in the component so the page is never blank)
   - All interactive elements must have loading, error, empty, and success states

6. **Set up lazy-loaded routes** in `app.routes.ts`:
   - Root `''` redirects to `dashboard`
   - Dashboard route uses `loadComponent` for lazy loading
   - Wildcard `**` redirects to `dashboard`

7. **Create a sample service** in `features/dashboard/`:
   - Uses `inject(HttpClient)` (not constructor injection)
   - `providedIn: 'root'`
   - Calls `${environment.apiUrl}/api/v1/dashboard/stats`

8. **Dashboard component must handle missing backend gracefully**:
   - Show static/fallback data when the API call fails (not just an error message)
   - The page must never appear blank, even without a running backend

9. **Add an auth interceptor stub** in `core/interceptors/auth.interceptor.ts` using `HttpInterceptorFn`

10. **Add an auth guard stub** in `core/guards/auth.guard.ts` using functional guard style (`CanActivateFn`)

11. **Create environment config** at `src/environments/environment.ts` with `apiUrl`

12. **Add a unit test** for the dashboard component using TestBed with zoneless setup:
    ```typescript
    await TestBed.configureTestingModule({
      imports: [DashboardComponent],
      providers: [
        provideZonelessChangeDetection(),
        provideHttpClient(),
        provideHttpClientTesting(),
      ],
    }).compileComponents();
    // Use await fixture.whenStable() instead of fixture.detectChanges()
    ```

13. **Verify the app compiles and renders** — Run `npx ng build` to catch errors before finishing.

14. **Print a summary** of created files and how to run (`npm start`, then open `http://localhost:4200`).

## Reference

For detailed code templates, patterns, and troubleshooting, refer to the `angular-spa` skill:
- `reference/angular-templates.md` — Component, service, routes, config, interceptor, guard, and test templates
- `reference/angular-troubleshooting.md` — Common errors (NG0908, blank screen), CLI commands, best practices
- `reference/daisyui-v5-components.md` — daisyUI component reference, color system, themes
- `reference/tailwind-v4-config.md` — TailwindCSS 4.x setup and breaking changes from v3
- `reference/accessibility-checklist.md` — WCAG 2.1 AA checklist, ARIA patterns, test protocol
