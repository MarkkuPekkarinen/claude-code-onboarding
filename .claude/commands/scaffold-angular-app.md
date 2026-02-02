---
description: Scaffold a new Angular 21.x SPA with standalone components, lazy routing, and a sample feature module
allowed-tools: Bash, Read, Write, Edit
---

# Scaffold Angular SPA

Create a new Angular 21.x SPA project with the following:

**App name:** $ARGUMENTS (default to "my-app" if not provided)

## Steps
1. Run `npx @angular/cli@latest new <name> --routing --style=scss --standalone --ssr=false`
2. Set up folder structure: `core/`, `shared/`, `features/`
3. Configure `app.config.ts` with `provideRouter`, `provideHttpClient`
4. Create a sample feature (e.g., Dashboard) as a standalone component with signals
5. Set up lazy-loaded routes in `app.routes.ts`
6. Create a sample service that calls a mock API endpoint
7. Add an auth interceptor stub in `core/interceptors/`
8. Add an auth guard stub in `core/guards/`
9. Create `environments/environment.ts` with `apiUrl` config
10. Add a basic unit test for the sample component
11. Print a summary of created files and how to run

Use the angular-spa skill for patterns and templates.
