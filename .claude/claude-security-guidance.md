# Security Guidance — claude-code-onboarding

This file is loaded by the security-guidance plugin's model-backed reviews.
It describes project-specific threat model and stack rules to apply on top of
the built-in vulnerability checklist.

---

## Stack

- **Java 21 / Spring Boot 3.5 WebFlux** — reactive, R2DBC, no blocking calls allowed
- **NestJS 11 / Fastify** — TypeScript, Prisma ORM, JWT auth, class-validator DTOs
- **Python 3.14 / FastAPI** — Pydantic v2, async SQLAlchemy, uv-managed deps
- **Angular 21** — SPA, RxJS, standalone components, daisyUI
- **Flutter 3.41** — Riverpod, Firebase Auth, cross-platform iOS + Android
- **PostgreSQL** — Row-Level Security enabled; Firebase Firestore for mobile real-time

---

## Mandatory Rules

### Auth & Authorization

- Every Spring WebFlux route not under `/actuator/health` or `/actuator/info` must be
  behind `@PreAuthorize` or a `SecurityWebFilterChain` rule. Actuator endpoints MUST
  have management-port isolation or IP allowlist — never expose full actuator on the
  public port.
- Every NestJS controller route that is not decorated with `@Public()` must have
  `@UseGuards(JwtAuthGuard)` applied at route or controller level. `@Public()` on
  any route that writes state or returns user data IS a finding.
- Every FastAPI router that handles `/admin` paths must call `require_role("admin")`
  before any database read or write.
- Firebase Firestore security rules must never allow `write: true` without `request.auth != null`.

### Logging & PII

- Do not log `user_id`, `customer_id`, `account_number`, `email`, `phone`, or any
  field whose name contains `token`, `secret`, `password`, or `key` at INFO or above.
- In Spring WebFlux, structured MDC fields must be cleared in a `doFinally` operator —
  missing cleanup leaks context across reactive threads.
- In FastAPI, never log `request.headers["authorization"]` or raw Bearer tokens.
- In Flutter, never log `FirebaseAuth.instance.currentUser.email` or any field from
  the user profile in production release builds.

### Cryptography

- Use `crypto.timingSafeEqual` (Node.js) or `hmac.compare_digest` (Python) for token
  comparison — never `===` or `==`.
- Never use `AES/ECB` in Spring or Python — use `AES/GCM/NoPadding` or `AES-CBC` with HMAC.
- Flutter: never store JWTs or API keys in `SharedPreferences`. Use `flutter_secure_storage`.
- NestJS: bcrypt cost must be >= 12. Never `bcrypt.compareSync` on the async request path.

### Input & Injection

- NestJS: all DTOs that flow into Prisma must be decorated with `class-validator`
  decorators. Raw `prisma.$queryRaw` with template-literal user input is SQL injection.
- Spring WebFlux: `r2dbcTemplate.execute(String sql)` with string-concatenated user
  input is SQL injection — use `DatabaseClient` with bind parameters.
- FastAPI: `text()` in SQLAlchemy with f-string user interpolation is SQL injection.
- Angular: `DomSanitizer.bypassSecurityTrustHtml()` / `bypassSecurityTrustUrl()` with
  user-supplied input is an XSS sink — must be flagged.
- Flutter `WebView`: `evaluateJavascript` with user content injected is an XSS sink.

### Reactive / Async Safety (Spring WebFlux)

- Any call to `.block()`, `.blockFirst()`, `.blockLast()`, or `blockingGet()` inside a
  reactive chain is a blocking-thread violation — flag as HIGH.
- `Mono.fromCallable` wrapping JDBC (not R2DBC) inside a reactive pipeline without
  `subscribeOn(Schedulers.boundedElastic())` is a blocking call on the event loop thread.

### SSRF

- Spring WebFlux `WebClient.get().uri(userInput)` without allowlist validation is SSRF.
- FastAPI `httpx.get(url)` or `requests.get(url)` where `url` is derived from a request
  parameter without scheme+host allowlist is SSRF.
- NestJS `axios.get(url)` where `url` is user-controlled is SSRF.

### Flutter Mobile

- `HttpClient.badCertificateCallback` set to `(_, __, ___) => true` disables TLS — HIGH.
- `dio` with `onError: (DioException e, handler) => handler.next(e)` swallowing auth
  errors is a silent failure — flag it.
- Firebase rules that allow reading another user's document by guessing UID are IDOR.

### Dependency & Supply Chain

- Never install packages from non-official registries without explicit user approval.
- `npm audit --audit-level=high` failures are blockers before any commit.
- Python: `pip install` from a VCS URL (git+https://) in production requirements is elevated risk.

---

## Review Checklist Additions (appended to built-in)

- [ ] Spring: no `.block()` calls on the event-loop thread
- [ ] NestJS: every non-public route has `@UseGuards`
- [ ] FastAPI: admin routes call `require_role("admin")`
- [ ] Angular: no `bypassSecurityTrustHtml` with user input
- [ ] Flutter: no secrets in `SharedPreferences`; no `badCertificateCallback = true`
- [ ] Firestore rules: `request.auth != null` on all write paths
- [ ] No `crypto.createCipher` (removed in Node 22) — use `createCipheriv`
- [ ] Token comparison uses timing-safe equals, not `===`
