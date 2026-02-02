---
name: openapi-spec-generation
description: Generate and maintain OpenAPI 3.1 specifications from code, design-first specs, and validation patterns. Use when creating API documentation, generating SDKs, or ensuring API contract compliance.
globs:
  - "**/openapi.yaml"
  - "**/openapi.yml"
  - "**/openapi.json"
  - "**/swagger.yaml"
  - "**/swagger.json"
  - "**/*.openapi.yaml"
  - "**/api-docs/**"
triggers:
  - "generate openapi spec"
  - "create api documentation"
  - "write swagger spec"
  - "document this api"
  - "openapi from code"
  - "api spec"
---

# OpenAPI Spec Generation

Generate, validate, and maintain OpenAPI 3.1 specifications for RESTful APIs. Supports design-first, code-first, and hybrid approaches across Java/Spring, Python/FastAPI, and TypeScript stacks.

## When to Use

- Creating API documentation from scratch
- Generating OpenAPI specs from existing code
- Designing API contracts (design-first approach)
- Validating API implementations against specs
- Generating client SDKs from specs
- Setting up API documentation portals

## Quick Start

**Design-First:**
1. Copy the minimal skeleton from `reference/openapi-skeleton-template.md` into `openapi.yaml`
2. Add paths and schemas for the domain
3. Validate: `spectral lint openapi.yaml`
4. Preview: `redocly preview-docs openapi.yaml`

**Code-First:**

| Stack | Command |
|-------|---------|
| FastAPI | `python -c "import json; from main import app; print(json.dumps(app.openapi(), indent=2))" > openapi.json` |
| Spring Boot | `curl http://localhost:8080/v3/api-docs > openapi.json` |
| tsoa | `npx tsoa spec` |

## Process Steps

### Step 1: Choose Approach

| Approach | When to Use | Reference |
|----------|-------------|-----------|
| **Design-First** | New APIs, contracts, external consumers | `reference/openapi-skeleton-template.md` |
| **Code-First** | Existing APIs, rapid iteration | `reference/code-first-patterns.md` |
| **Hybrid** | Evolving APIs, keep spec in sync | Both references above |

### Step 2: Generate the Spec

**Design-first** -- Read `reference/openapi-skeleton-template.md` for the starter template. Copy the minimal skeleton, then customize paths, schemas, and security for the domain.

**Code-first** -- Read `reference/code-first-patterns.md` for annotated examples in:
- Java/Spring Boot (springdoc-openapi) -- annotations, config bean, DTOs
- Python/FastAPI -- Pydantic models, type hints, endpoint decorators
- TypeScript/tsoa -- decorators, interfaces, route controllers

### Step 3: Add a Complete Example (if needed)

Read `reference/complete-api-example.md` for a full User Management API spec demonstrating all features: CRUD paths, pagination, filtering, error responses, rate limiting headers, security schemes, and reusable components.

### Step 4: Validate and Lint

Read `reference/validation-and-linting.md` for:
- Spectral configuration (`.spectral.yaml`)
- Redocly configuration
- Validation commands
- Custom linting rules (naming conventions, required fields)

### Step 5: Generate SDKs and Set Up CI/CD

Read `reference/sdk-and-cicd.md` for:
- SDK generation commands (TypeScript, Python, Java, Dart)
- GitHub Actions workflow for validation
- Full CI/CD pipeline (validate, generate, publish)

## Reference Files

| File | Content | Size |
|------|---------|------|
| `reference/openapi-skeleton-template.md` | Minimal starter skeleton, structure overview, customization checklist | ~5KB |
| `reference/code-first-patterns.md` | Java/Spring, Python/FastAPI, TypeScript/tsoa annotated examples | ~10KB |
| `reference/validation-and-linting.md` | Spectral rules, Redocly config, validation commands | ~4KB |
| `reference/sdk-and-cicd.md` | SDK generation commands, GitHub Actions workflows | ~5KB |
| `reference/complete-api-example.md` | Full User Management API with all OpenAPI features | ~10KB |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing `operationId` | Add unique operationId to every endpoint -- SDK generators need it |
| No error schemas | Define an Error schema and use it for all 4xx/5xx responses |
| Examples don't match schema | Use `$ref` for examples and validate with Spectral |
| Inconsistent naming (`user_id` vs `userId`) | Pick one style (camelCase), enforce with linter |
| Missing `nullable: true` | Be explicit: `nullable: true` (3.0) or `type: ["string", "null"]` (3.1) |
| No pagination on list endpoints | Always paginate and document limits |
| Hardcoded server URLs | Use server variables or multiple server entries |

## Best Practices

**Do:**
- Use `$ref` to reuse schemas, parameters, and responses
- Add real-world examples to every endpoint
- Document all error codes and responses
- Version the API in the URL (`/v1/`) or header
- Validate the spec in CI on every PR
- Use semantic versioning for spec changes

**Avoid:**
- Generic descriptions -- be specific about what each field and endpoint does
- Skipping security definitions -- define all auth schemes
- Mixing naming styles -- stay consistent throughout the spec
- Hardcoding URLs -- use server variables for environment flexibility

## Resources

- [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/v3.1.0)
- [Swagger Editor](https://editor.swagger.io/)
- [Redocly](https://redocly.com/)
- [Spectral](https://stoplight.io/open-source/spectral)
- [OpenAPI Generator](https://openapi-generator.tech/)
- [springdoc-openapi](https://springdoc.org/)
