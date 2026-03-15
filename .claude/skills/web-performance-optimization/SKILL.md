---
name: web-performance-optimization
description: "Optimize Angular 21.x web application performance including Core Web Vitals, bundle size, lazy loading with @defer, NgOptimizedImage, OnPush+Signals, SSR TransferState, and Angular CLI build optimization"
risk: low
source: community (adapted for Angular 21.x)
date_added: "2026-02-27"
updated: "2026-03-15"
---

# Web Performance Optimization — Angular 21.x

## Overview

Help developers optimize Angular 21.x SPA performance to improve user experience, SEO rankings, and Core Web Vitals scores. This skill provides systematic approaches to measure, analyze, and improve loading speed, runtime performance, and bundle size — all grounded in Angular-native patterns (signals, `@defer`, `NgOptimizedImage`, lazy routes, SSR TransferState).

## When to Use This Skill

- Angular SPA loads slowly or scores poorly on Lighthouse
- Optimizing for Core Web Vitals (LCP, FID/INP, CLS)
- Reducing JavaScript bundle size output by `ng build`
- Improving Time to Interactive (TTI) or First Contentful Paint (FCP)
- Optimizing images and assets inside Angular templates
- Implementing lazy loading via routes or `@defer` blocks
- Debugging Angular change detection performance
- Preparing for performance audits on an Angular production build

## How It Works

### Step 1: Measure Current Performance

Establish baseline metrics before touching any code:

- Run Lighthouse audit (Chrome DevTools → Lighthouse tab)
- Measure Core Web Vitals: LCP, INP (replaced FID in 2024), CLS
- Inspect Angular bundle with `ng build --configuration=production --stats-json`
- Analyze bundle composition: `npx webpack-bundle-analyzer dist/browser/stats.json`
- Check network waterfall in Chrome DevTools → Network tab
- Profile change detection with Angular DevTools browser extension

### Step 2: Identify Issues

Angular-specific performance bottlenecks to look for:

- Large initial bundle — missing lazy routes or barrel file imports pulling everything in
- Default change detection (`ChangeDetectionStrategy.Default`) triggering excessive re-renders
- `BehaviorSubject` + `async` pipe causing unnecessary subscriptions instead of signals
- Images without `ngSrc` (NgOptimizedImage) missing auto-sizing and LCP hints
- Below-fold heavy components not wrapped in `@defer` blocks
- Double HTTP fetches in SSR (server + client both calling the same endpoint) — missing TransferState
- Third-party scripts loaded synchronously in `index.html`

### Step 3: Prioritize Optimizations

Focus on highest-impact Angular improvements first:

1. **Critical rendering path** — `NgOptimizedImage` with `priority` on LCP image, `<link rel="preload">` for fonts
2. **Bundle size** — lazy routes (`loadComponent`/`loadChildren`), `@defer` for below-fold components
3. **Runtime rendering** — `OnPush` + signals on all components, eliminate `Default` change detection
4. **Image pipeline** — convert to AVIF/WebP, serve responsive srcsets via `NgOptimizedImage`
5. **SSR double-fetch** — TransferState to hydrate state from server render without re-fetching

### Step 4: Implement Optimizations

Apply improvements in priority order — measure after each step.

### Step 5: Verify Improvements

- Re-run Lighthouse — compare scores before/after
- Re-run `ng build --stats-json` — compare bundle sizes
- Verify no layout shifts introduced (Chrome DevTools → Rendering → Layout Shift Regions)
- Test on throttled mobile: Chrome DevTools → Network 3G + CPU 4x slowdown
- Monitor INP in PageSpeed Insights with real-user data after deploy

---

## Examples

### Example 1: Core Web Vitals on Angular SPA

```markdown
## Performance Audit Results

### Current Metrics (Before Optimization)
- **LCP (Largest Contentful Paint):** 4.2s ❌ (target: < 2.5s)
- **INP (Interaction to Next Paint):** 320ms ❌ (target: < 200ms)
- **CLS (Cumulative Layout Shift):** 0.25 ❌ (target: < 0.1)
- **Lighthouse Score:** 58/100

### Issues Identified

1. **LCP:** Hero image (2.5MB JPEG) loads without priority hint — browser discovers it late
2. **INP:** All components use `ChangeDetectionStrategy.Default` — full tree re-renders on every event
3. **CLS:** Product images have no width/height — browser cannot reserve layout space

---

### Fix LCP — NgOptimizedImage with priority

**Before:**
```html
<img src="/hero.jpg" alt="Hero banner">
```

**After (app.component.ts):**
```typescript
import { NgOptimizedImage } from '@angular/common';

@Component({
  imports: [NgOptimizedImage],
  template: `
    <!-- priority tells Angular to add fetchpriority="high" + preload link -->
    <img ngSrc="/hero.jpg"
         width="1200"
         height="600"
         priority
         alt="Hero banner" />
  `
})
export class AppComponent {}
```

`NgOptimizedImage` automatically:
- Adds `fetchpriority="high"` and a `<link rel="preload">` for the LCP image
- Enforces `width`/`height` — eliminating CLS from that image
- Lazy-loads all non-priority images by default

**Additional LCP steps:**
- Compress hero image to < 200KB (use `sharp` pipeline — see Example 3)
- Serve from CDN with proper `Cache-Control: public, max-age=31536000, immutable`
- Preload critical font: `<link rel="preload" as="font" href="/fonts/inter.woff2" crossorigin>`

---

### Fix INP — OnPush + Signals

**Before:**
```typescript
@Component({
  // Default CD: re-renders on EVERY async event in the app
  template: `<div>{{ user.name }}</div>`
})
export class ProfileComponent {
  @Input() user!: User;
}
```

**After:**
```typescript
import { Component, input, computed, ChangeDetectionStrategy } from '@angular/core';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div>{{ fullName() }}</div>
    <button (click)="updateName('Jane')">Update</button>
  `
})
export class ProfileComponent {
  user = input.required<User>();

  // Computed only re-evaluates when user signal changes
  fullName = computed(() => `${this.user().firstName} ${this.user().lastName}`);

  updateName(first: string) {
    // Signal update — Angular knows exactly which components to re-render
  }
}
```

**Rule:** Every component must have `ChangeDetectionStrategy.OnPush`. Without it, a single button click anywhere in the app triggers a full-tree check.

---

### Fix CLS — NgOptimizedImage dimensions + skeleton loaders

NgOptimizedImage enforces `width` and `height` on every `ngSrc` image — this eliminates image-induced CLS at the framework level.

For dynamically-loaded content (lists, cards that appear after API response):

```html
<!-- Reserve space before data arrives — prevents layout jump -->
@if (products()) {
  @for (product of products(); track product.id) {
    <app-product-card [product]="product" />
  }
} @else {
  @for (i of skeletonCount; track i) {
    <div class="skeleton h-48 w-full rounded-lg"></div>
  }
}
```

```css
/* Always specify aspect ratio so the browser reserves exact space */
.product-image {
  aspect-ratio: 4 / 3;
  width: 100%;
  height: auto;
}
```

### Results After Optimization
- **LCP:** 1.7s ✅ (improved by 60%)
- **INP:** 80ms ✅ (improved by 75%)
- **CLS:** 0.04 ✅ (improved by 84%)
- **Lighthouse Score:** 93/100 ✅
```

---

### Example 2: Reducing Angular Bundle Size

```markdown
## Bundle Size Optimization

### Current State
- **Initial Bundle:** 820KB (gzipped: 265KB) — exceeds angular.json 500KB warning budget
- **Load Time (3G):** 9.1s
- **ng build output:** WARNING: budget exceeded by 320KB

### Step 1: Diagnose with Stats JSON

```bash
# Production build with stats output
ng build --configuration=production --stats-json

# Visualize bundle composition
npx webpack-bundle-analyzer dist/browser/stats.json
```

**Findings from analyzer:**
1. `moment.js` — 67KB (only `format()` used — replace with `date-fns`)
2. `lodash` — 72KB (full import, only 3 functions needed)
3. Admin feature loaded eagerly — 180KB that 95% of users never need
4. No `@defer` on heavy chart component — 95KB loaded on every page visit

---

### Step 2: Replace Heavy Dependencies

```bash
# Remove moment.js (67KB) → date-fns (tree-shakable, 12KB for format())
npm uninstall moment
npm install date-fns
```

```typescript
// Before
import moment from 'moment';
const formatted = moment(date).format('YYYY-MM-DD');

// After — only imports the format function (~2KB)
import { format } from 'date-fns';
const formatted = format(date, 'yyyy-MM-dd');
```

**Savings: ~55KB**

```typescript
// Before — full lodash (72KB)
import _ from 'lodash';
const unique = _.uniq(array);

// After — named cherry-pick (4KB) or native
import { uniq } from 'lodash-es';
// or just:
const unique = [...new Set(array)];
```

**Savings: ~68KB**

---

### Step 3: Lazy-Load Feature Routes

```typescript
// app.routes.ts — BEFORE: eager imports
import { AdminComponent } from './admin/admin.component';    // 180KB loaded upfront
import { DashboardComponent } from './dashboard/dashboard.component';

export const routes: Routes = [
  { path: 'admin', component: AdminComponent },
  { path: 'dashboard', component: DashboardComponent }
];

// AFTER: lazy-loaded routes — each chunk only fetches when the user navigates there
export const routes: Routes = [
  {
    path: 'admin',
    loadComponent: () => import('./admin/admin.component')
      .then(m => m.AdminComponent)
  },
  {
    path: 'dashboard',
    loadChildren: () => import('./dashboard/dashboard.routes')
      .then(m => m.DASHBOARD_ROUTES)
  }
];
```

**Savings: ~180KB removed from initial bundle**

---

### Step 4: @defer for Below-Fold Components

```html
<!-- Before: HeavyChartComponent (95KB) loaded at startup even if user never scrolls -->
<app-heavy-chart [data]="chartData()" />

<!-- After: deferred until the element enters the viewport -->
@defer (on viewport) {
  <app-heavy-chart [data]="chartData()" />
} @loading (minimum 300ms) {
  <div class="skeleton h-64 w-full rounded-lg"></div>
} @placeholder {
  <div class="h-64 w-full bg-base-200 rounded-lg flex items-center justify-center">
    <span class="text-base-content/50">Chart</span>
  </div>
} @error {
  <div class="alert alert-error">Failed to load chart</div>
}
```

**Savings: ~95KB removed from initial bundle**

---

### Step 5: Configure Build Budgets in angular.json

Budgets fail the build before a bloated bundle reaches production:

```json
"configurations": {
  "production": {
    "budgets": [
      {
        "type": "initial",
        "maximumWarning": "500kb",
        "maximumError": "1mb"
      },
      {
        "type": "anyComponentStyle",
        "maximumWarning": "2kb",
        "maximumError": "4kb"
      }
    ]
  }
}
```

---

### Step 6: Defer Third-Party Analytics

```typescript
// app.component.ts — load analytics after Angular bootstraps
import { Component, AfterViewInit } from '@angular/core';

@Component({ ... })
export class AppComponent implements AfterViewInit {
  ngAfterViewInit(): void {
    // Deferred until after first paint — does not block TTI
    if (typeof window !== 'undefined') {
      window.addEventListener('load', () => {
        const script = document.createElement('script');
        script.src = 'https://analytics.example.com/script.js';
        script.async = true;
        document.body.appendChild(script);
      });
    }
  }
}
```

### Results

- **Initial Bundle:** 340KB ✅ (reduced by 59%)
- **Gzipped:** 108KB ✅
- **Load Time (3G):** 3.4s ✅ (improved by 63%)
- **ng build:** No budget warnings ✅
```

---

### Example 3: Image Optimization with NgOptimizedImage + AVIF/WebP Pipeline

```markdown
## Image Optimization Strategy

### Current Issues
- 18 images totaling 14MB — all uncompressed JPEG
- No modern formats (WebP, AVIF)
- No responsive srcsets
- No dimensions — causing CLS
- Hero image not marked as LCP priority

---

### Step 1: Build AVIF/WebP Pipeline with sharp

```bash
npm install --save-dev sharp
```

```javascript
// scripts/optimize-images.mjs
import sharp from 'sharp';
import { readdirSync } from 'fs';
import { join, basename, extname } from 'path';

const INPUT_DIR = './src/assets/images/raw';
const OUTPUT_DIR = './src/assets/images/optimized';

async function optimizeImage(inputPath) {
  const name = basename(inputPath, extname(inputPath));

  // AVIF — best compression (~50% smaller than WebP)
  await sharp(inputPath)
    .avif({ quality: 70 })
    .toFile(join(OUTPUT_DIR, `${name}.avif`));

  // WebP — broad browser support
  await sharp(inputPath)
    .webp({ quality: 80 })
    .toFile(join(OUTPUT_DIR, `${name}.webp`));

  // JPEG fallback — progressive for perceived speed
  await sharp(inputPath)
    .jpeg({ quality: 80, progressive: true })
    .toFile(join(OUTPUT_DIR, `${name}.jpg`));

  // Responsive sizes
  for (const width of [400, 800, 1200]) {
    await sharp(inputPath)
      .resize({ width })
      .avif({ quality: 70 })
      .toFile(join(OUTPUT_DIR, `${name}-${width}.avif`));

    await sharp(inputPath)
      .resize({ width })
      .webp({ quality: 80 })
      .toFile(join(OUTPUT_DIR, `${name}-${width}.webp`));
  }
}

const images = readdirSync(INPUT_DIR).filter(f => /\.(jpg|jpeg|png)$/i.test(f));
await Promise.all(images.map(img => optimizeImage(join(INPUT_DIR, img))));
console.log(`Optimized ${images.length} images`);
```

```bash
node scripts/optimize-images.mjs
```

---

### Step 2: NgOptimizedImage — Above-fold (LCP) Images

```typescript
// hero.component.ts
import { Component } from '@angular/core';
import { NgOptimizedImage } from '@angular/common';

@Component({
  imports: [NgOptimizedImage],
  template: `
    <!-- priority = fetchpriority="high" + <link rel="preload"> automatically injected -->
    <img ngSrc="/assets/images/optimized/hero.avif"
         width="1200"
         height="600"
         sizes="(max-width: 768px) 100vw, 50vw"
         priority
         alt="Hero banner" />
  `
})
export class HeroComponent {}
```

NgOptimizedImage serves the browser-appropriate format automatically when an image CDN loader is configured. Without a loader, point `ngSrc` directly at AVIF/WebP files and the browser picks the best supported format via the Accept header.

---

### Step 3: NgOptimizedImage — Below-fold (Lazy) Images

```typescript
// product-list.component.ts
import { Component, inject } from '@angular/core';
import { NgOptimizedImage } from '@angular/common';
import { ProductService } from './product.service';

@Component({
  imports: [NgOptimizedImage],
  template: `
    @for (product of products(); track product.id) {
      <!-- No priority attribute = loading="lazy" applied automatically -->
      <img ngSrc="/assets/images/optimized/{{ product.imageSlug }}.avif"
           width="400"
           height="300"
           sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
           [alt]="product.name" />
    }
  `
})
export class ProductListComponent {
  private productService = inject(ProductService);
  products = this.productService.products;
}
```

---

### Step 4: Configure Image CDN Loader (Optional — for automatic format negotiation)

```typescript
// app.config.ts
import { provideImgixLoader } from '@angular/common';

export const appConfig: ApplicationConfig = {
  providers: [
    // Imgix, Cloudinary, Cloudflare Images, or custom loader
    provideImgixLoader('https://your-subdomain.imgix.net')
  ]
};
```

With a CDN loader, you only set `ngSrc="/hero.jpg"` — the loader appends format/width parameters automatically, serving AVIF to supporting browsers with no manual file variants needed.

---

### Results

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Total Image Size | 14MB | 1.9MB | 86% reduction |
| LCP | 4.8s | 1.6s | 67% faster |
| CLS (images) | 0.22 | 0.00 | 100% eliminated |
| Page Load (3G) | 21s | 4.8s | 77% faster |
```

---

## Best Practices

### Do This

- **Measure First** — always run Lighthouse and `ng build --stats-json` before any optimization
- **OnPush Everywhere** — every component must declare `ChangeDetectionStrategy.OnPush`
- **Signals for State** — use `signal()` and `computed()` instead of `BehaviorSubject` + `async` pipe
- **Lazy Routes** — use `loadComponent`/`loadChildren` for every feature — nothing should be eagerly imported in `app.routes.ts`
- **@defer for Below-Fold** — any component not visible on first paint belongs in an `@defer (on viewport)` block
- **NgOptimizedImage** — replace every `<img>` in Angular templates with `ngSrc`; never bypass it
- **Build Budgets** — set `maximumWarning: 500kb` / `maximumError: 1mb` in `angular.json` so CI fails before a bloated build ships
- **Preload Critical Resources** — `<link rel="preload">` for critical fonts; `priority` attribute on LCP image
- **TransferState in SSR** — prevent double HTTP fetch by serializing API responses on the server and rehydrating on the client
- **Use CDN** — serve `dist/browser/` from a CDN with immutable cache headers

### Do Not Do This

- **Do not use `ChangeDetectionStrategy.Default`** — this is the single largest Angular runtime performance killer
- **Do not import barrel files (`index.ts`)** in feature modules — they pull in everything, killing tree shaking
- **Do not lazy-load too granularly** — chunks under 10KB create more HTTP overhead than they save; colocate small components
- **Do not block rendering** — no synchronous `<script>` in `index.html`; use `defer` or post-bootstrap dynamic injection
- **Do not skip `width`/`height`** on `ngSrc` images — NgOptimizedImage will throw in dev mode, and CLS will spike in prod
- **Do not optimize without evidence** — profile first with Chrome DevTools and Angular DevTools; fix the proven bottleneck

---

## Common Pitfalls

### Problem: Good Desktop Score, Poor Mobile Score
**Symptoms:** Lighthouse passes on desktop, fails on mobile throttling
**Solution:**
- Test with CPU 4x slowdown + 3G in Chrome DevTools
- Check INP: Angular Default change detection collapses on slow CPUs — switch all components to OnPush + signals
- Remove `@defer` triggers that never fire on mobile (e.g., hover-based triggers on touch devices)
```bash
lighthouse https://yoursite.com --throttling.cpuSlowdownMultiplier=4 --preset=desktop
```

### Problem: Bundle Size Exceeds angular.json Budget
**Symptoms:** `ng build` exits with "ERROR: bundle initial exceeded maximum budget"
**Solution:**
- Run bundle analyzer to find the culprit: `npx webpack-bundle-analyzer dist/browser/stats.json`
- Convert eager feature imports to lazy routes
- Replace heavy libraries (moment → date-fns, full lodash → lodash-es cherry-picks)
- Wrap heavy components in `@defer`
```bash
ng build --configuration=production --stats-json
npx webpack-bundle-analyzer dist/browser/stats.json
```

### Problem: Images Cause Layout Shifts (High CLS)
**Symptoms:** CLS > 0.1 in Lighthouse, content jumps on load
**Solution:**
- Use `ngSrc` — NgOptimizedImage requires `width`/`height` and enforces them at build time
- For dynamic image lists, render skeleton placeholders at the correct height before data arrives
```css
/* Prevent CLS on any image not using NgOptimizedImage */
img {
  aspect-ratio: attr(width) / attr(height);
  width: 100%;
  height: auto;
}
```

### Problem: Slow TTFB with Angular SSR
**Symptoms:** Time to First Byte > 600ms, server HTML arrives late
**Solution:**
- Ensure API responses are cached server-side (Redis, CDN edge cache)
- Use `TransferState` to avoid re-fetching data the server already fetched
- Enable incremental hydration with `withIncrementalHydration()` — defer hydration of below-fold components
```typescript
// app.config.ts
import { provideClientHydration, withIncrementalHydration } from '@angular/platform-browser';

export const appConfig: ApplicationConfig = {
  providers: [
    provideClientHydration(withIncrementalHydration())
  ]
};
```

### Problem: SSR Double HTTP Fetch
**Symptoms:** Network tab shows the same API call twice (once server, once client)
**Solution:** Use TransferState — serialize data on the server, read it on the client without re-fetching
```typescript
// product.service.ts
import { Injectable, inject, PLATFORM_ID } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { TransferState, makeStateKey } from '@angular/core';
import { isPlatformServer } from '@angular/common';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';

const PRODUCTS_KEY = makeStateKey<Product[]>('products');

@Injectable({ providedIn: 'root' })
export class ProductService {
  private http = inject(HttpClient);
  private transferState = inject(TransferState);
  private platformId = inject(PLATFORM_ID);

  getProducts(): Observable<Product[]> {
    if (this.transferState.hasKey(PRODUCTS_KEY)) {
      const products = this.transferState.get(PRODUCTS_KEY, []);
      this.transferState.remove(PRODUCTS_KEY);
      return of(products);
    }

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

---

## Performance Checklist

### Angular Architecture
- [ ] `ChangeDetectionStrategy.OnPush` on ALL components — no exceptions
- [ ] Signals (`signal()`, `computed()`) used for all reactive state — no `BehaviorSubject` for component state
- [ ] No barrel file imports (`index.ts`) — import directly from the source file
- [ ] `trackBy` or `track` expression on every `@for` loop

### Bundle Size
- [ ] All feature routes use `loadComponent` or `loadChildren` — zero eagerly imported feature components in `app.routes.ts`
- [ ] `@defer` blocks wrapping all below-fold heavy components
- [ ] `ng build --configuration=production` used (esbuild, tree shaking, minification enabled)
- [ ] Angular build budgets configured in `angular.json` (`maximumWarning: 500kb`, `maximumError: 1mb`)
- [ ] Bundle analyzed with `ng build --stats-json` + `webpack-bundle-analyzer` — no unexpected large chunks
- [ ] Heavy libraries replaced: `moment` → `date-fns`, full `lodash` → cherry-picked `lodash-es`

### Images
- [ ] Every `<img>` uses `ngSrc` (NgOptimizedImage directive) — no raw `src` on images
- [ ] All `ngSrc` images have explicit `width` and `height` attributes
- [ ] LCP image has `priority` attribute
- [ ] Non-LCP images have NO `priority` attribute (browser lazy-loads automatically)
- [ ] Images converted to AVIF/WebP with JPEG fallback
- [ ] Images served from CDN with `Cache-Control: public, max-age=31536000, immutable`

### CSS
- [ ] Critical CSS inlined (Angular SSR handles this automatically via server render)
- [ ] No unused CSS (PurgeCSS or TailwindCSS tree-shaking handles this at build time)
- [ ] Component styles stay under `anyComponentStyle` budget (2KB warning)

### Core Web Vitals Targets
- [ ] LCP < 2.5s
- [ ] INP < 200ms
- [ ] CLS < 0.1
- [ ] TTFB < 600ms
- [ ] TTI < 3.8s

### SSR (if using @angular/ssr)
- [ ] `TransferState` used for all API responses fetched during server render
- [ ] `withIncrementalHydration()` enabled for below-fold sections
- [ ] No `document` or `window` access in services without `isPlatformBrowser()` guard

---

## Performance Tools

### Measurement
- **Lighthouse** — Comprehensive audit; run in Chrome DevTools → Lighthouse tab
- **PageSpeed Insights** — Real user metrics (CrUX data) + lab data: https://pagespeed.web.dev
- **Chrome DevTools Performance tab** — Frame-level profiling and long task identification
- **Angular DevTools** — Component tree profiler, change detection cycle inspector
- **Web Vitals Chrome Extension** — Overlay CWV metrics on any live page

### Bundle Analysis
- `ng build --configuration=production --stats-json` — generate `stats.json`
- `npx webpack-bundle-analyzer dist/browser/stats.json` — visual treemap of all chunks
- **Bundlephobia** (https://bundlephobia.com) — check npm package size before installing
- **source-map-explorer** — `npx source-map-explorer dist/browser/main*.js` — byte-level breakdown

### Image Optimization
- **sharp** (`npm install --save-dev sharp`) — Node.js image conversion pipeline
- **Squoosh** (https://squoosh.app) — browser-based manual AVIF/WebP conversion
- **ImageOptim** — macOS GUI for batch compression

### Monitoring (Post-Deploy)
- **Google Search Console** — Core Web Vitals report from real users
- **Sentry Performance** — Transaction tracing, INP tracking
- **Datadog RUM** — Real User Monitoring with Angular integration

---

## Related Skills

- `angular-spa` — Angular component scaffolding, lazy routing, and daisyUI styling
- `angular-best-practices` — OnPush, signals, rendering performance, and SSR hydration patterns
- `angular` — Angular 21.x core API reference: Signals, `@defer`, TransferState, incremental hydration
- `browser-testing` — Chrome DevTools performance profiling via MCP; record traces, inspect long tasks
- `systematic-debugging` — Root-cause methodology for performance regressions

---

## Additional Resources

- [NgOptimizedImage Guide](https://angular.dev/guide/image-optimization) — official directive reference
- [@defer Blocks](https://angular.dev/guide/defer) — all trigger types (`on viewport`, `on idle`, `on interaction`, `when`)
- [Angular SSR](https://angular.dev/guide/ssr) — TransferState, incremental hydration, server rendering
- [Core Web Vitals](https://web.dev/vitals/) — LCP, INP, CLS definitions and thresholds
- [Web.dev Performance](https://web.dev/performance/) — General web performance techniques

---

**Key principle:** Measure before optimizing. `ng build --stats-json` + `webpack-bundle-analyzer` takes 2 minutes and reveals exactly where your bundle weight is — every other optimization is guesswork without it.
