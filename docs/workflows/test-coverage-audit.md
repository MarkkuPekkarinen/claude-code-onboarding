# Test Coverage Audit

> **When to use**: Before a PR, after adding features, or when coverage drops below 80%
> **Commands**: `/test-coverage`, `/tdd`
> **Agents**: `tdd-guide`

## Overview

Multi-stack coverage reporting that detects all present stacks and reports files below the 80% threshold, sorted worst-first. Coverage is measured — not assumed.

## Thresholds

| Code Type | Minimum Coverage |
|-----------|-----------------|
| General logic | 80% |
| Auth / JWT / sessions | 100% |
| Crypto / password handling | 100% |
| Payment processing | 100% |
| Data migrations | 100% |

## Quick Usage

```bash
# Run coverage for all detected stacks
/test-coverage

# Start TDD cycle on a specific component
/tdd UserService

# Coverage report only (no new tests)
/tdd coverage
```

## Stack Detection + Commands

| Stack | Detected By | Coverage Command |
|-------|-------------|-----------------|
| Spring Boot | `pom.xml` with spring-boot | `./mvnw test jacoco:report` |
| Python/FastAPI | `pyproject.toml` with fastapi | `pytest --cov=src --cov-fail-under=80` |
| NestJS | `package.json` with @nestjs/core | `npm run test:cov` |
| Flutter | `pubspec.yaml` with flutter | `flutter test --coverage` |

## TDD Cycle (Red-Green-Refactor)

```
RED   → Write failing test describing desired behavior
GREEN → Write minimum code to pass
REFACTOR → Clean up (tests must still pass)
```

**Iron Law**: Write the failing test BEFORE the implementation.

## 8 Edge Case Categories

Every test suite must cover: (1) happy path, (2) null/empty input, (3) boundary values, (4) invalid types, (5) duplicates, (6) auth failures, (7) external dependency failures, (8) concurrent access.

## Related

- Command: `.claude/commands/test-coverage.md`
- Command: `.claude/commands/tdd.md`
- Agent: `.claude/agents/tdd-guide.md`
