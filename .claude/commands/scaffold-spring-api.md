---
description: Scaffold a new Spring Boot 3.5.x WebFlux REST API project with standard structure, build config, and sample endpoint
allowed-tools: Bash, Read, Write, Edit
---

# Scaffold Spring Boot WebFlux API

Create a new Java 21 / Spring Boot 3.5.x WebFlux project with the following:

**Project name:** $ARGUMENTS (default to "my-api" if not provided)

## Steps
1. Create the Gradle project structure with `build.gradle.kts`
2. Set up package: `com.company.<projectname>`
3. Create directory structure:
   - `controller/`, `service/`, `repository/`, `model/entity/`, `model/dto/`, `config/`, `exception/`
4. Add `application.yml` with R2DBC + Flyway config (PostgreSQL)
5. Create a sample `HealthController` at `GET /api/v1/health`
6. Create a sample entity, DTO (record), repository, service, and controller for a "hello world" resource
7. Add a `V1__initial_schema.sql` Flyway migration
8. Add a basic integration test using `WebTestClient`
9. Add a `Dockerfile` and `docker-compose.yml` with PostgreSQL
10. Print a summary of created files and next steps

Use the java-spring-api skill for patterns and templates.
