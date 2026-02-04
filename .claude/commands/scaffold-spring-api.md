---
description: Scaffold a new Spring Boot 3.5.x WebFlux REST API project with standard structure, build config, and sample endpoint
argument-hint: "[project name]"
allowed-tools: Bash, Read, Write, Edit
disable-model-invocation: true
---

# Scaffold Spring Boot WebFlux API

Create a new Java 21 / Spring Boot 3.5.x WebFlux project with the following:

**Project name:** $ARGUMENTS (default to "my-api" if not provided)

## Steps
1. Create the Maven project structure with `pom.xml`
2. Set up package: `com.company.<projectname>`
3. Create directory structure:
   - `controller/`, `service/`, `repository/`, `model/entity/`, `model/dto/`, `config/`, `exception/`
4. Add `application.yml` with R2DBC + Flyway config (PostgreSQL, Flyway disabled by default via `enabled: ${FLYWAY_ENABLED:false}`)
5. Create a sample `HealthController` at `GET /api/v1/health`
6. Create a sample entity, DTO (record), repository, service, and controller for a "hello world" resource
7. Add a `GlobalExceptionHandler` with `@ControllerAdvice` returning `ProblemDetail` (RFC 9457)
8. Add a `V1__initial_schema.sql` Flyway migration
9. Add a basic integration test using `WebTestClient`
10. Add a `Dockerfile` and `docker-compose.yml` with PostgreSQL
11. Print a summary of created files and next steps

Use the java-spring-api skill for patterns and templates, and the java-coding-standard skill for naming, immutability, and style rules.
