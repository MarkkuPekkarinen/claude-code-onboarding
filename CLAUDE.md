# Project: Claude Code Onboarding Kit

## Overview
This is a **team onboarding repository** for learning and practicing Claude Code — the AI coding assistant by Anthropic.
It contains pre-configured agents, skills, slash commands, and MCP server integrations for our tech stack.

## Tech Stack
- **Backend (Java)**: Java 21, Spring Boot 3.5.x (WebFlux / Reactive), REST APIs
- **Backend (Node.js)**: Node.js 24.13, TypeScript 5.x, Express/Fastify
- **Backend (Python)**: Python 3.14, FastAPI, Pydantic v2, SQLAlchemy async
- **Frontend**: Angular 21.x (SPA), TypeScript 5.x, RxJS, SCSS
- **Mobile**: Flutter 3.38 (Dart 3.11), cross-platform (iOS + Android)
- **Database**: PostgreSQL (primary), Firebase Firestore (mobile real-time)
- **Infrastructure**: Firebase (Auth, Firestore, Cloud Messaging), Docker
- **Build Tools**: Maven (Java), npm (Node.js/Angular), uv/pip (Python), flutter CLI

## Code Conventions

### Java / Spring Boot
- Use **Java 21** features: records, sealed classes, pattern matching, virtual threads
- Reactive stack: `WebFlux` + `Mono`/`Flux` — no blocking calls in reactive chains
- Follow package structure: `controller → service → repository → model/dto`
- Use `@RestController` with `@RequestMapping("/api/v1/...")`
- DTOs as Java records, entities as classes with JPA/R2DBC annotations
- Tests: JUnit 5 + WebTestClient for reactive endpoints

### Node.js / TypeScript
- Use **Node.js 24** with **TypeScript 5.x**, ESM (`"type": "module"`)
- `strict: true` in tsconfig, target `ES2024`, module `NodeNext`
- Use `zod` for runtime validation and type inference
- Express or Fastify for REST APIs
- Folder structure: `routes/ → services/ → models/ → middleware/`
- Tests: Vitest + supertest

### Python
- Use **Python 3.14** with type hints everywhere
- **FastAPI** for REST APIs, **Pydantic v2** for validation
- Async by default: `async def` endpoints, `asyncpg` for PostgreSQL
- Use `uv` for package management, `ruff` for linting, `mypy` for types
- Folder structure: `api/routes/ → services/ → repositories/ → models/`
- Tests: pytest + pytest-asyncio + httpx

### Angular
- Standalone components (no NgModules unless legacy)
- Signals for state management: `signal()`, `computed()`, `input()`, `output()`
- Control flow: `@if`, `@for`, `@switch`, `@defer` — no `*ngIf`/`*ngFor`
- `ChangeDetectionStrategy.OnPush` on all components
- Lazy-loaded routes via `loadComponent`
- Use `HttpClient` with RxJS operators
- **TailwindCSS 4.x** + **daisyUI 5.5.5** for styling (CSS-native config, no `tailwind.config.js`)
- Use daisyUI semantic colors only — never hardcode hex values
- Folder structure: `features/ → shared/ → core/`

### Flutter
- Use **Riverpod** for state management
- Follow feature-first folder structure: `lib/features/<feature>/`
- Separate `data/`, `domain/`, `presentation/` layers (clean architecture)
- Use `freezed` for immutable models
- Firebase integration via `firebase_core`, `cloud_firestore`, `firebase_auth`

### Database
- PostgreSQL naming: `snake_case` for tables and columns
- Always include `id`, `created_at`, `updated_at` columns
- Use UUID for primary keys
- Write migrations with Flyway (Spring Boot) or raw SQL scripts
- Firebase Firestore: use collection/document hierarchy, denormalize for reads

## Common Commands
```bash
# Java / Spring Boot
./mvnw spring-boot:run               # Run backend
./mvnw test                          # Run tests
./mvnw package                       # Build JAR

# Node.js / TypeScript
npm run dev                          # Dev server with hot reload (tsx)
npm run build                        # Compile TypeScript
npm run start                        # Run compiled JS
npm test                             # Run Vitest tests
npx tsc --noEmit                     # Type check only

# Python / FastAPI
uvicorn src.my_service.main:app --reload  # Dev server
pytest -v                            # Run tests
ruff check src/ --fix                # Lint and auto-fix
ruff format src/                     # Format code
mypy src/                            # Type check
alembic upgrade head                 # Run DB migrations

# Angular
ng serve                             # Dev server at localhost:4200
ng build --configuration=production  # Production build
ng test                              # Unit tests
ng generate component <name>         # Scaffold component

# Flutter
flutter run                          # Run on connected device/emulator
flutter test                         # Run tests
flutter build apk                    # Build Android APK
flutter build ios                    # Build iOS
flutter pub get                      # Install dependencies

# Docker
docker-compose up -d                 # Start all services
docker-compose down                  # Stop all services
```

## Git Workflow
- Branch naming: `feature/<ticket>-<description>`, `bugfix/<ticket>-<description>`
- Commit messages: conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`)
- Always create PR — no direct push to `develop`
- Squash merge to keep history clean

## Important Rules
- **Never commit secrets** — use environment variables or `.env` files
- **Always write tests** for new features
- **Use the agents/skills** in `.claude/` — they encode our team patterns
- Run `/project-status` to get a quick summary of the codebase state

## Working Standards

### Verify Before Claiming
- Before saying something is "missing" or "implemented", read the actual code — not just file names
- Trace the full chain: UI component, service/logic, data connection
- Cite `file:line` as evidence. No guessing, no "I believe it's..."
- If challenged, re-verify from source — don't flip your answer without re-reading

### Status Reporting
- Binary: "works" or "doesn't work" — no percentages, no "mostly functional"
- Details must match the summary — never say "works" then list why it doesn't
- Use `/status-check` for structured reports

### Plan Execution
- If a plan is approved, implement 100% of it before saying "done"
- If an item can't be completed, stop and explain why — don't silently skip it

### Error Handling
- Every catch block must log the error AND either rethrow or return an error state
- Never return empty list/null/default to hide a failure
- Never swallow exceptions silently
- No mock data or fallback data unless explicitly requested

### Documentation Freshness
- Use `Context7` MCP or `Dart MCP server` to verify current API signatures when unsure
- Never use deprecated methods, classes, or patterns — check docs if in doubt
