# Angular SSR & Hydration Reference

Server-Side Rendering, hydration configuration, and incremental hydration patterns.

---

## SSR Setup

```bash
ng add @angular/ssr
```

This adds:
- `@angular/ssr` package
- `server.ts` entry point
- `app.config.server.ts` for server-specific providers
- Build targets: `build` (browser) + `server` (SSR)

---

## Hydration Configuration

```typescript
// app.config.ts
import { ApplicationConfig } from "@angular/core";
import {
  provideClientHydration,
  withEventReplay,
} from "@angular/platform-browser";
import { provideRouter } from "@angular/router";
import { provideHttpClient, withFetch } from "@angular/common/http";

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    // withFetch() required for SSR — uses native fetch instead of XMLHttpRequest
    provideHttpClient(withFetch()),
    // withEventReplay() replays user events that happened before hydration
    provideClientHydration(withEventReplay()),
  ],
};
```

### Server config (app.config.server.ts)

```typescript
import { mergeApplicationConfig, ApplicationConfig } from "@angular/core";
import { provideServerRendering } from "@angular/platform-server";
import { appConfig } from "./app.config";

const serverConfig: ApplicationConfig = {
  providers: [provideServerRendering()],
};

export const config = mergeApplicationConfig(appConfig, serverConfig);
```

---

## Incremental Hydration with @defer (v20+)

Incremental hydration defers hydration of non-critical components until they are needed.

```typescript
import { Component } from "@angular/core";

@Component({
  selector: "app-page",
  standalone: true,
  template: `
    <!-- Critical content — hydrated immediately -->
    <app-hero />
    <app-nav />

    <!-- Hydrate when section scrolls into view -->
    @defer (hydrate on viewport) {
      <app-product-list />
    }

    <!-- Hydrate when user interacts with the element -->
    @defer (hydrate on interaction) {
      <app-chat-widget />
    }

    <!-- Hydrate when browser is idle -->
    @defer (hydrate on idle) {
      <app-analytics-panel />
    }

    <!-- Hydrate after a delay -->
    @defer (hydrate on timer(2000ms)) {
      <app-cookie-banner />
    }

    <!-- Hydrate when user hovers -->
    @defer (hydrate on hover) {
      <app-dropdown-menu />
    }
  `,
})
export class PageComponent {}
```

**Available hydration triggers:**

| Trigger | When it hydrates |
|---------|-----------------|
| `on idle` | Browser is idle (requestIdleCallback) |
| `on viewport` | Element enters the viewport |
| `on interaction` | User clicks, touches, or focuses the element |
| `on hover` | User hovers over the element |
| `on timer(Nms)` | After N milliseconds |
| `when condition` | When a signal/expression becomes truthy |

---

## TransferState (Avoiding Duplicate HTTP Requests)

Prevent server-fetched data from being re-fetched on the client:

```typescript
import { Component, inject } from "@angular/core";
import { TransferState, makeStateKey } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { isPlatformServer } from "@angular/common";
import { PLATFORM_ID } from "@angular/core";

const PRODUCTS_KEY = makeStateKey<Product[]>("products");

@Component({ ... })
export class ProductsComponent {
  private transferState = inject(TransferState);
  private http = inject(HttpClient);
  private platformId = inject(PLATFORM_ID);

  loadProducts() {
    if (this.transferState.hasKey(PRODUCTS_KEY)) {
      // Client: use server-fetched data
      return this.transferState.get(PRODUCTS_KEY, []);
    }

    // Server: fetch and store in TransferState
    return this.http.get<Product[]>('/api/products').pipe(
      tap(products => {
        if (isPlatformServer(this.platformId)) {
          this.transferState.set(PRODUCTS_KEY, products);
        }
      })
    );
  }
}
```

**Note:** When using `resource()` or `httpResource()`, Angular handles TransferState automatically — no manual setup needed.

---

## Common SSR Issues

| Issue | Solution |
|-------|---------|
| `window is not defined` | Guard with `isPlatformBrowser(platformId)` |
| Hydration mismatch | Ensure server and client render identical HTML |
| HTTP requests fire twice | Use `withFetch()` + let Angular handle transfer |
| SSR fetch fails | Use `provideHttpClient(withFetch())` — required for SSR |
| Slow TTFB | Use incremental hydration + `@defer` for below-fold content |
