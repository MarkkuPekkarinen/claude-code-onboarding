# Spring Boot Conventions & Rules

## Code Conventions

- Use **Java 21** features: records, sealed classes, pattern matching, virtual threads
- Spring Boot 3.5.x Reactive stack: `WebFlux` + `Mono`/`Flux` — no blocking calls in reactive chains
- Follow package structure: `controller → service → repository → model/dto`
- Use `@RestController` with `@RequestMapping("/api/v1/...")`
- DTOs as Java records, entities as classes with JPA/R2DBC annotations
- Tests: JUnit 5 + WebTestClient for reactive endpoints

## Package Layout

```
com.company.<service>/
├── controller/     # REST controllers
├── service/        # Business logic
├── repository/     # R2DBC repositories
├── model/
│   ├── entity/     # Database entities
│   └── dto/        # Request/response DTOs (records)
├── config/         # Spring config, security, CORS
└── exception/      # Global error handling
```

## Reactive Rules

- NEVER call `.block()` inside a reactive chain
- Use `Mono.zip()` for parallel calls
- Use `switchIfEmpty()` with `Mono.error()` for not-found cases
- Use `@ResponseStatus` for non-200 responses (e.g., `201 Created`); default 200 OK is implicit for GET endpoints
- Use `@Valid` on `@RequestBody` params, `@Validated` on controller class for path/query param validation, `jakarta.validation` on DTOs
