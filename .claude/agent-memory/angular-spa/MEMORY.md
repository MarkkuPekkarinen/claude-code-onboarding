# Angular SPA Agent Memory

## Angular 21 Project Conventions (verified 2026-03-08)

- CLI generates `app.ts` (class `App`) and `app.html` — NOT `app.component.ts` / `AppComponent`
- `standalone: true` is NOT set in decorators — it is the default in v20+
- Zoneless is the default in Angular 21 — do NOT add `provideZonelessChangeDetection()` or `provideZoneChangeDetection()`
- `app.config.ts` uses `provideBrowserGlobalErrorListeners()` as the default provider in v21
- Global styles MUST be `.css` (not `.scss`) for TailwindCSS 4.x — Sass intercepts `@import "tailwindcss"` directives
  - Update `angular.json` styles array from `src/styles.scss` to `src/styles.css`
  - Create `src/styles.css` with `@import "tailwindcss";` and `@plugin "daisyui";`
- PostCSS config must be `.postcssrc.json` (not `postcss.config.js`) for `@angular/build:application`

## Key File Paths (fitness-tracker project)

- `/Users/kumaran/mydrive/work/claude-code-onboarding/fitness-tracker/` — project root
