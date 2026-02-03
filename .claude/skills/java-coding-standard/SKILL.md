---
name: java-coding-standard
description: This skill should be activated when reviewing Java code or enforcing coding standards in Spring Boot services. It covers naming conventions, immutability patterns, Optional usage, streams, and exception handling.
allowed-tools: Read
---

# Java Coding Standards

Standards for readable, maintainable Java (21+) code in Spring Boot Reactive Web Flux services.

## Core Principles

- Prefer clarity over cleverness
- Immutable by default; minimize shared mutable state
- Fail fast with meaningful exceptions
- Consistent naming and package structure

## Key Rules

| Rule | Standard |
|------|----------|
| **Naming** | Classes: `PascalCase`, methods/fields: `camelCase`, constants: `UPPER_SNAKE_CASE` |
| **Immutability** | Favor records and final fields; getters only, no setters |
| **Optional** | Return `Optional` from `find*` methods; use `map`/`flatMap`, never `.get()` |
| **Streams** | Short pipelines for transforms; prefer loops for complex logic |
| **Exceptions** | Unchecked domain exceptions; avoid broad `catch (Exception)` |
| **Generics** | No raw types; prefer bounded generics for reusable utilities |
| **Null handling** | `@NonNull` by default; Bean Validation on inputs |
| **Logging** | SLF4J with structured key=value pairs |
| **Testing** | JUnit 5 + AssertJ + Mockito; deterministic, no sleeps |

## Project Structure

```
src/main/java/com/example/app/
  config/ → controller/ → service/ → repository/ → domain/ → dto/ → util/
src/main/resources/application.yml
src/test/java/... (mirrors main)
```

## Code Examples & Detailed Patterns

For naming examples, immutability patterns, Optional usage, streams, exception handling, generics, logging, formatting, code smells, and testing expectations, Read `reference/java-standards-examples.md`.

**Remember**: Keep code intentional, typed, and observable. Optimize for maintainability over micro-optimizations unless proven necessary.