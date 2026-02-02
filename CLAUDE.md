# Project: Claude Code Onboarding Kit

## Overview
This is a **team onboarding repository** for learning and practicing Claude Code — the AI coding assistant by Anthropic.
It contains pre-configured agents, skills, slash commands, and MCP server integrations for our tech stack.

## Tech Stack
- **Backend**: Java 21, Spring Boot 3.5 (WebFlux / Reactive), REST APIs, Python 3.14.x
- **Frontend**: Angular 21+ (SPA), TypeScript, RxJS, SCSS
- **Mobile**: Flutter 3.x (Dart), cross-platform (iOS + Android)
- **Database**: PostgreSQL (primary), Firebase Firestore (mobile real-time)
- **Infrastructure**: Firebase (Auth, Firestore, Cloud Messaging), Docker
- **Build Tools**: Gradle (Java), npm (Angular), flutter CLI

## Code Conventions

### Java / Spring Boot
- Use **Java 21** features: records, sealed classes, pattern matching, virtual threads
- Reactive stack: `WebFlux` + `Mono`/`Flux` — no blocking calls in reactive chains
- Follow package structure: `controller → service → repository → model/dto`
- Use `@RestController` with `@RequestMapping("/api/v1/...")`
- DTOs as Java records, entities as classes with JPA/R2DBC annotations
- Tests: JUnit 5 + WebTestClient for reactive endpoints

### Angular
- Standalone components (no NgModules unless legacy)
- Signals for state management (Angular 21+ style)
- Lazy-loaded routes via `loadComponent`
- Use `HttpClient` with RxJS operators
- SCSS for styling, follow BEM naming
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
./gradlew bootRun                    # Run backend
./gradlew test                       # Run tests
./gradlew build                      # Build JAR

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
- Always create PR — no direct push to `main`
- Squash merge to keep history clean

## Important Rules
- **Never commit secrets** — use environment variables or `.env` files
- **Always write tests** for new features
- **Use the agents/skills** in `.claude/` — they encode our team patterns
- Run `/project-status` to get a quick summary of the codebase state
