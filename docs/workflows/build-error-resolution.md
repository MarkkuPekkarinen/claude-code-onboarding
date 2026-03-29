# Build Error Resolution

> **When to use**: `./mvnw compile` fails, dependency resolution errors, Spring Boot autoconfiguration conflicts, R2DBC/WebFlux classpath issues
> **Agent**: `java-build-resolver`
> **Scope**: Java 21 / Spring Boot 3.5.x / Maven — surgical fix only

## Overview

The `java-build-resolver` agent diagnoses and fixes Maven/Spring Boot build failures using a 12-error pattern lookup table and a structured diagnostic sequence. It fixes exactly what is broken — no refactoring, no version upgrades as workarounds.

## When to Use

- `./mvnw compile` exits non-zero
- `NoSuchBeanDefinitionException` or `UnsatisfiedDependencyException` at startup
- R2DBC/WebFlux class not found errors
- Dependency version conflicts (`duplicate class`, `symbol not found`)
- Port conflicts, JDK mismatch, missing config files

## Workflow

```
1. Run ./mvnw compile -e 2>&1 | tail -100
   ↓ error identified
2. Match error to lookup table in java-build-resolver agent
   ↓ fix identified
3. Apply minimum fix (one file, one change)
   ↓
4. Run ./mvnw compile -q → verify EXIT 0
   ↓
5. Run ./mvnw test -q → confirm no regressions
```

## Diagnostic Commands

```bash
# Full error output
./mvnw compile -e 2>&1 | tail -100

# Dependency conflicts
./mvnw dependency:tree -Dverbose 2>&1 | grep -E "(conflict|omitted)"

# R2DBC classpath check
./mvnw dependency:build-classpath 2>&1 | tr ':' '\n' | grep r2dbc
```

## Common Errors → Quick Fix

| Error | Fix |
|-------|-----|
| `NoSuchBeanDefinitionException` | Add `@Service`/`@Component` or `@Bean` method |
| `ClassNotFoundException: r2dbc.*` | Add `spring-boot-starter-data-r2dbc` |
| `duplicate class` | Add `<exclusion>` + pin version in `<dependencyManagement>` |
| `cannot find symbol` | Check Spring Boot 3.x migration guide for removed API |
| `Unsupported class file major version` | Verify `JAVA_HOME` points to JDK 21 |

## Rules

- Fix only files named in the error output
- Do NOT bump Spring Boot parent version to resolve a build error
- Do NOT switch constructor injection to field injection as a workaround
- 3-attempt stop: after 3 failed attempts, escalate to human with attempt log

## Related

- Skill: `.claude/skills/java-spring-api/SKILL.md`
- Agent: `.claude/agents/java-build-resolver.md`
