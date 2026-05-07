---
name: angular
description: "Angular 21.x core patterns and APIs — Signals, Standalone components, Zoneless change detection, SSR/Hydration, Dependency Injection, Component composition, Signal-based state, Testing. Load when writing Angular code for API reference, testing patterns, or SSR configuration."
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, WebFetch, mcp__context7__resolve-library-id, mcp__context7__query-docs, mcp__angular-cli__get_best_practices, mcp__angular-cli__search_documentation
metadata:
  triggers: Angular signals, Angular standalone, Angular zoneless, Angular SSR, Angular hydration, Angular DI, Angular testing, Angular state management, Angular 21
  related-skills: angular-spa, angular-best-practices, angular-ui-patterns
  domain: frontend
  role: specialist
  scope: reference
  output-format: code
last-reviewed: "2026-03-15"
---

## Iron Law

**READ `angular-spa` skill for TailwindCSS 4.x, daisyUI 5.5.5, and workspace conventions BEFORE implementing. This skill is API reference only — no design token or styling patterns here.**

## When to Use This Skill

- Building new Angular applications (v20+)
- Implementing Signals-based reactive patterns
- Creating Standalone Components and migrating from NgModules
- Configuring Zoneless Angular applications
- Implementing SSR, prerendering, and hydration
- Optimizing Angular performance
- Adopting modern Angular patterns and best practices

## Do Not Use This Skill When

- Migrating from AngularJS (1.x) — use `angular-migration` skill
- Working with legacy Angular apps that cannot upgrade
- General TypeScript issues — use `typescript-expert` skill

---

**Version context:** Angular 20 (Signals/Zoneless stable), Angular 21 (Signals-first default, Signal Forms available — current), Angular 22 (Signal Forms further enhancements).

---

## Angular 21 Zoneless Note

Angular 21 is **zoneless by default**. Do NOT add `provideZonelessChangeDetection()` — it is implicit and adding it causes warnings.

- Angular 20: `provideZonelessChangeDetection()` required explicitly
- Angular 21+: Zoneless is the default. No provider needed. No `zone.js` import.

This workspace uses Angular 21+. The patterns below show v20-style explicit providers for reference — in Angular 21 omit those providers.

---

## 1. Signals: The New Reactive Primitive

Signals are Angular's fine-grained reactivity system, replacing zone.js-based change detection.

### Core signal / computed / effect

```typescript
import { signal, computed, effect } from "@angular/core";

const count = signal(0);
count.set(5);
count.update((v) => v + 1);

const doubled = computed(() => count() * 2);

effect(() => {
  console.log(`Count changed to: ${count()}`);
});
```

### Signal inputs, outputs, and model

```typescript
import { Component, input, output, model } from "@angular/core";

@Component({
  selector: "app-user-card",
  standalone: true,
  template: `
    <div class="card">
      <h3>{{ name() }}</h3>
      <span>{{ role() }}</span>
      <button (click)="select.emit(id())">Select</button>
    </div>
  `,
})
export class UserCardComponent {
  id = input.required<string>();
  name = input.required<string>();
  role = input<string>("User");
  select = output<string>();
  isSelected = model(false);
}
// <app-user-card [id]="'123'" [name]="'John'" [(isSelected)]="selected" />
```

Signal queries (viewChild, viewChildren, contentChild): See [references/signals-core.md](references/signals-core.md)

---

## 1b. linkedSignal — Derived Writable Signals

`linkedSignal` creates a writable signal whose default resets when its source changes.

| Use | Tool |
|-----|------|
| Derived read-only value | `computed()` |
| Writable value that resets on source change | `linkedSignal()` |
| Local state with no dependency | `signal()` |

```typescript
import { signal, linkedSignal } from '@angular/core';

const items = signal(['a', 'b', 'c']);
const selectedItem = linkedSignal(() => items()[0]);

selectedItem.set('b');      // 'b'
items.set(['x', 'y', 'z']); // selectedItem resets to 'x'
```

Full examples (advanced + pagination): [references/signals-core.md](references/signals-core.md)

---

## 1c. resource() — Reactive Async Data Fetching

`resource()` is Angular's built-in reactive primitive for async data.

| Scenario | Use |
|----------|-----|
| Component-local async data tied to signals | `resource()` |
| Service-level shared HTTP calls | `HttpClient` + `inject()` |
| Complex async pipelines (retry, cancel, merge) | `HttpClient` + RxJS |
| One-time data loads | Either |

```typescript
import { httpResource } from '@angular/common/http';

// HTTP GET shorthand — refetches when userId() changes
userResource = httpResource<User>(() => `/api/users/${this.userId()}`);
```

Full API (resource() component, abort signal, status signals): [references/signals-core.md](references/signals-core.md)

---

## 1d. afterNextRender / afterRender — DOM Lifecycle Hooks

In zoneless Angular 21, `afterNextRender` and `afterRender` replace `NgZone` lifecycle hacks for DOM-dependent initialization. Use these instead of `ngAfterViewInit` for code that requires a real DOM (chart init, third-party widget, scroll position).

```typescript
import { Component, afterNextRender, afterRender, ElementRef, viewChild } from '@angular/core';

@Component({ selector: 'app-chart', template: '<canvas #canvas></canvas>' })
export class ChartComponent {
  canvas = viewChild.required<ElementRef<HTMLCanvasElement>>('canvas');

  constructor() {
    // Runs once after the first render — DOM is guaranteed to exist
    afterNextRender(() => {
      initChart(this.canvas().nativeElement);
    });

    // Runs after every render — use sparingly (performance cost)
    afterRender(() => {
      updateScrollPosition();
    });
  }
}
```

**Rule:** Prefer `afterNextRender` over `afterRender` — it runs once. Both run in the browser only (SSR-safe).

---

## 1e. @let — Template Variable Declaration (Angular 18+)

`@let` declares a local template variable — replaces the `*ngIf as` alias hack and verbose `ng-template` patterns.

```html
<!-- Declare a local alias for a long expression -->
@let user = currentUser();
@let greeting = 'Hello, ' + user.name + '!';

<h1>{{ greeting }}</h1>
<p>{{ user.email }}</p>

<!-- Useful with async resources -->
@let data = userResource.value();
@if (data) {
  <app-user-profile [user]="data" />
}
```

**Rule:** Use `@let` to avoid repeating computed signal calls in templates. Do not use it as a substitute for `computed()` — `@let` re-evaluates on every render pass.

---

## 1f. Testing: Vitest (Stable in Angular 21)

Angular 21 ships with **Vitest as the stable test runner** (replaces Karma). New projects default to Vitest. Migrate existing Karma setups.

```typescript
// vitest.config.ts (Angular CLI generates this)
import { defineConfig } from 'vitest/config';
import angular from '@analogjs/vite-plugin-angular';

export default defineConfig({
  plugins: [angular()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['src/test-setup.ts'],
  },
});
```

```typescript
// Component test with zoneless TestBed
import { TestBed } from '@angular/core/testing';
import { provideExperimentalZonelessChangeDetection } from '@angular/core';

beforeEach(() => {
  TestBed.configureTestingModule({
    providers: [provideExperimentalZonelessChangeDetection()],
    imports: [MyComponent],
  });
});
```

Run: `ng test` (uses Vitest by default in Angular 21 workspaces). See `reference/testing-vitest.md` for full patterns.

---

## 2. Standalone Components

Standalone components are self-contained and don't require NgModule declarations.

### Creating Standalone Components

```typescript
import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";
import { RouterLink } from "@angular/router";

@Component({
  // standalone: true is the default in Angular v20+ — omit it
  selector: "app-header",
  imports: [RouterLink], // CommonModule is a compat shim — don't import it
  template: `
    <header>
      <a routerLink="/">Home</a>
      <a routerLink="/about">About</a>
    </header>
  `,
})
export class HeaderComponent {}
```

### Bootstrapping Without NgModule

```typescript
// main.ts
import { bootstrapApplication } from "@angular/platform-browser";
import { provideRouter } from "@angular/router";
import { provideHttpClient } from "@angular/common/http";
import { AppComponent } from "./app/app.component";
import { routes } from "./app/app.routes";

bootstrapApplication(AppComponent, {
  providers: [provideRouter(routes), provideHttpClient()],
});
```

### Lazy Loading Standalone Components

```typescript
export const routes: Routes = [
  {
    path: "dashboard",
    loadComponent: () =>
      import("./dashboard/dashboard.component").then((m) => m.DashboardComponent),
  },
  {
    path: "admin",
    loadChildren: () =>
      import("./admin/admin.routes").then((m) => m.ADMIN_ROUTES),
  },
];
```

---

## 3. Zoneless Angular

> **Angular 21 reminder:** Zoneless is the default. The `provideZonelessChangeDetection()` call below is v20-style — omit it in Angular 21 projects.

```typescript
// main.ts (Angular 20 style — NOT needed in Angular 21+)
bootstrapApplication(AppComponent, {
  providers: [provideZonelessChangeDetection()],
});
```

### Zoneless Component Pattern

```typescript
import { Component, signal, ChangeDetectionStrategy } from "@angular/core";

@Component({
  selector: "app-counter",
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div>Count: {{ count() }}</div>
    <button (click)="increment()">+</button>
  `,
})
export class CounterComponent {
  count = signal(0);
  increment() { this.count.update((v) => v + 1); }
}
```

Benefits: no zone.js patches, cleaner stack traces, ~15KB bundle savings, better Web Component interop.

---

## 4. Server-Side Rendering & Hydration

See [references/ssr-hydration.md](references/ssr-hydration.md) for SSR setup, hydration configuration, incremental hydration patterns, TransferState, and common SSR troubleshooting.

---

## 5. Modern Routing Patterns

> See [references/api-reference.md](references/api-reference.md) for full routing examples (functional guards, resolvers).

**Key patterns:**
- `CanActivateFn` with `inject()` for functional guards
- `ResolveFn<T>` for route-level data pre-fetching
- `toSignal(route.data.pipe(...))` to consume resolved data

---

## 6. Dependency Injection

> See [references/api-reference.md](references/api-reference.md) for full DI examples (inject(), InjectionToken).

**Key patterns:**
- `inject()` function (no constructor required)
- `InjectionToken<T>` for typed configuration values

---

## 7. Component Composition

> See [references/api-reference.md](references/api-reference.md) for full composition examples (ng-content slots, hostDirectives).

**Key patterns:**
- `<ng-content select="[attr]">` for named slots
- `hostDirectives` for behavior composition without inheritance

---

## 8. Signal-Based State Management

> See [references/api-reference.md](references/api-reference.md) for full state service and component store examples.

**Key patterns:**
- Private `signal()` + public `computed()` for encapsulated state
- `@Injectable()` (no `providedIn: 'root'`) for scoped component stores

---

## 9. Forms with Signals

> See [references/api-reference.md](references/api-reference.md) for full reactive forms and signal form patterns.

**Key patterns:**
- Signal Forms (preferred for Angular 21+) — see `signal-forms.md` reference below
- `FormBuilder` + `Validators` for reactive forms (legacy, still supported)
- Signal-based validation via `computed()` for derived validation state

> **Angular 21+:** Prefer Signal Forms over reactive forms for new apps. See [`references/signal-forms.md`](references/signal-forms.md).

---

## 10. Performance Optimization

### Change Detection Strategies

Always use `ChangeDetectionStrategy.OnPush`. Triggers re-check only when: input signal/reference changes, event handler runs, async pipe emits, or signal value changes.

### Defer Blocks for Lazy Loading

```typescript
@defer (on viewport) {
  <app-heavy-chart />
} @placeholder {
  <div class="skeleton" />
} @loading (minimum 200ms) {
  <app-spinner />
} @error {
  <p>Failed to load chart</p>
}
```

### NgOptimizedImage

```typescript
import { NgOptimizedImage } from '@angular/common';

@Component({
  imports: [NgOptimizedImage],
  template: `
    <img ngSrc="hero.jpg" width="800" height="600" priority />
    <img ngSrc="thumbnail.jpg" width="200" height="150" loading="lazy" placeholder="blur" />
  `
})
```

---

## 11. Testing Modern Angular

> See [references/api-reference.md](references/api-reference.md) for full testing examples (signal components, setInput).

**Key patterns:**
- Import standalone components directly in `TestBed.configureTestingModule({ imports: [...] })`
- Use `componentRef.setInput('name', value)` to set signal inputs in tests
- Call `fixture.detectChanges()` after signal mutations to trigger DOM update

---

## Key Decision Tables

> See [references/api-reference.md](references/api-reference.md) for full Signals vs RxJS table and Pattern Do/Don't summary.

| Use Case              | Use Signals  | Use RxJS                      |
| --------------------- | ------------ | ----------------------------- |
| Local component state | Yes          | No — overkill                 |
| HTTP requests         | No           | Yes — HttpClient Observable   |
| Complex async flows   | No           | Yes — switchMap, mergeMap     |

---

## Common Troubleshooting

> See [references/api-reference.md](references/api-reference.md) for the full troubleshooting table.

| Issue                          | Solution                                            |
| ------------------------------ | --------------------------------------------------- |
| Signal not updating UI         | Ensure `OnPush` + call signal as function `count()` |
| `provideZonelessChangeDetection` warning in v21 | Remove call — zoneless is the default in v21+ |
| SSR fetch fails                | Use `TransferState` or `withFetch()`                |

---

## Related Skills

- `angular-spa` — workspace skill with TailwindCSS 4.x, daisyUI 5.5.5, conventions
- `angular-best-practices` — impact-prioritized rules (CRITICAL to LOW-MEDIUM)
- `angular-ui-patterns` — loading, error, empty state patterns
