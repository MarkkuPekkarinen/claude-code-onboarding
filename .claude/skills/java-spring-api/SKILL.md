---
name: java-spring-api
description: This skill provides patterns and templates for Java 21 Spring Boot 3.5.x WebFlux REST API development. It should be activated when creating controllers, services, repositories, DTOs, or reactive tests.
allowed-tools: Bash, Read, Write, Edit
---

# Java 21 + Spring Boot 3.5.x WebFlux REST API Skill

## Quick Scaffold — New Spring Boot Project

```bash
# Using Spring Initializr via curl
curl https://start.spring.io/starter.zip \
  -d type=maven-project \
  -d language=java \
  -d javaVersion=21 \
  -d bootVersion=3.5.0 \
  -d dependencies=webflux,r2dbc,postgresql,flyway,validation,actuator,lombok \
  -d groupId=com.company \
  -d artifactId=my-service \
  -d name=my-service \
  -o my-service.zip && unzip my-service.zip -d my-service
```

## Process

1. **Scaffold** using Spring Initializr or the command above
2. **Configure** pom.xml and application.yml — read `reference/spring-boot-config.md`
3. **Create files** using templates — read `reference/spring-boot-templates.md` for DTO, Entity, Repository, Service, Controller, and Test templates
4. **Follow conventions** below for package layout and reactive rules
5. **Write tests** with `@SpringBootTest` + `WebTestClient`
6. **Format and check**: `./mvnw spotless:apply` or IDE formatter

## Key Patterns

| Pattern | Implementation |
|---------|---------------|
| **DTOs** | Java records with `jakarta.validation` annotations |
| **Entities** | Classes with `@Table`, `@Id` R2DBC annotations |
| **Repositories** | Extend `ReactiveCrudRepository<T, UUID>` |
| **Services** | `@Service` + `@RequiredArgsConstructor`, return `Mono`/`Flux` |
| **Controllers** | `@RestController` + `@RequestMapping("/api/v1/...")` |
| **Error handling** | `@ControllerAdvice` returning `ProblemDetail` (RFC 9457) |
| **Config** | `application.yml` with `${ENV_VAR:default}` placeholders |
| **Migrations** | Flyway in `src/main/resources/db/migration/` |

## Package Layout

```
com.company.service/
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
- Always return `Mono<ResponseEntity<T>>` or annotate with `@ResponseStatus`
- Use `@Validated` on controller params, `jakarta.validation` on DTOs

## Reference Files

| File | Content |
|------|---------|
| `reference/spring-boot-config.md` | pom.xml template, application.yml configuration |
| `reference/spring-boot-templates.md` | DTO, Entity, Repository, Service, Controller, Test, Error Handler templates |
| `reference/spring-boot-enterprise.md` | Exception hierarchy, Security (OAuth2/JWT), Resilience4j, WebClient pool, Health indicators, Swagger |
| `reference/spring-boot-rest-service-guide.md` | OpenAPI+DDL driven workflow, MapStruct mapping, External service clients, WireMock testing |
| `reference/spring-boot-testing-guide.md` | BlockHound, Resilience4j testing, test data builders, Testcontainers, contract testing |
| `reference/spring-boot-reactive-debugging.md` | Reactor Hooks (onOperatorError, onNextDropped, onErrorDropped), checkpoint patterns, debug mode control |
| `reference/spring-boot-security-hardening.md` | OWASP dependency scanning, static analysis patterns, HSTS, JWT role extraction, secure logging |
| `reference/spring-boot-reactive-patterns.md` | Resilience4j operators, Redis reactive, SSE, Spring Cloud Stream, custom operators, threading anti-patterns |

## Error Handling

**Validation errors**: Use `jakarta.validation` annotations on DTO records. Handle via `@ControllerAdvice` returning `ProblemDetail` with `HttpStatus.BAD_REQUEST` (400).

**Not-found errors**: Use `switchIfEmpty(Mono.error(new NotFoundException(...)))` in services.

**Duplicate errors**: Catch `DataIntegrityViolationException` in services and convert to `409 Conflict`.
