# Workflow Documentation

Multi-phase workflow guides for every development process in this workspace. Each file covers phases, commands, agents, gates, and common pitfalls.

---

## Ideation & Design

| Workflow | When to Use |
|----------|------------|
| `/brainstorm [topic]` | Solution space still open — explore ≥3 alternatives with trade-offs before committing to an approach |
| [ideation-to-spec.md](ideation-to-spec.md) | Turning an idea into a reviewed spec and plan |
| [architecture-design.md](architecture-design.md) | Designing a new service or system before coding |
| [plan-review.md](plan-review.md) | Structured review + adversarial challenge of an implementation plan |
| [adr-creation.md](adr-creation.md) | Documenting architectural decisions |
| [threat-modeling.md](threat-modeling.md) | STRIDE analysis before building security-sensitive features |

---

## Feature Development

| Workflow | Stack |
|----------|-------|
| [feature-java-spring.md](feature-java-spring.md) | Java 21 / Spring Boot 3.5.x WebFlux |
| [feature-nestjs.md](feature-nestjs.md) | NestJS 11.x / Fastify / Prisma / TypeScript |
| [feature-python-fastapi.md](feature-python-fastapi.md) | Python 3.14 / FastAPI / Pydantic v2 |
| [feature-agentic-ai.md](feature-agentic-ai.md) | LangChain v1.2.8 / LangGraph v1.0.7 |
| [feature-google-adk.md](feature-google-adk.md) | Google ADK / Gemini agents |
| [feature-angular-spa.md](feature-angular-spa.md) | Angular 21.x / TailwindCSS / daisyUI |
| [feature-a2ui-renderer.md](feature-a2ui-renderer.md) | Agent-to-UI renderer for Angular |
| [feature-flutter-mobile.md](feature-flutter-mobile.md) | Flutter 3.38 / Riverpod / iOS + Android |

---

## Database & Vector

| Workflow | When to Use |
|----------|------------|
| [database-schema-design.md](database-schema-design.md) | PostgreSQL schema design, Flyway migrations, ERDs |
| [pgvector-rag-pipeline.md](pgvector-rag-pipeline.md) | pgvector schema + RAG pipeline with PostgreSQL |
| [weaviate-collection-pipeline.md](weaviate-collection-pipeline.md) | Weaviate collection design + RAG pipeline |
| [weaviate-operations.md](weaviate-operations.md) | Day-to-day Weaviate search, Q&A, explore |
| [embedding-model-migration.md](embedding-model-migration.md) | Migrating to a new embedding model (zero downtime) |

---

## Quality & Testing

| Workflow | When to Use |
|----------|------------|
| [test-driven-development.md](test-driven-development.md) | Red-Green-Refactor TDD cycle, all stacks |
| [api-testing.md](api-testing.md) | Integration and contract testing for REST APIs |
| [browser-e2e-testing.md](browser-e2e-testing.md) | E2E testing with Chrome DevTools + Browser-Use MCPs |
| [code-review.md](code-review.md) | Giving code review — `/review-code`, `/review-pr` |
| [receiving-code-review.md](receiving-code-review.md) | Processing and responding to review feedback |
| [pre-commit-validation.md](pre-commit-validation.md) | `/pr-risk`, `/validate-changes` before committing |
| [design-system-compliance.md](design-system-compliance.md) | Design token enforcement, WCAG 2.1 audit |
| [accessibility-audit.md](accessibility-audit.md) | WCAG 2.1 AA audit, axe-core + flutter_test automation, manual keyboard/screen reader testing, CI/CD gate |

---

## Security

| Workflow | When to Use |
|----------|------------|
| [security-audit.md](security-audit.md) | OWASP audit, SAST, CVE scan before release |
| [security-hardening.md](security-hardening.md) | Remediating findings from security audit |
| `claude-actions-auditor` skill | Auditing GitHub Actions workflows that invoke `anthropics/claude-code-action` for 9 CI/CD attack vectors |

---

## Shipping & Deployment

| Workflow | When to Use |
|----------|------------|
| [pr-shipping.md](pr-shipping.md) | `/ship`, `/review-pr`, merge, branch cleanup |
| [iterate-pr.md](iterate-pr.md) | Autonomous CI fix loop until green |
| [deployment-ci-cd.md](deployment-ci-cd.md) | GitHub Actions pipeline, Docker, Cloud Run |
| [cloud-run-terraform.md](cloud-run-terraform.md) | GCP infrastructure with Terraform |
| [ios-app-store-release.md](ios-app-store-release.md) | TestFlight → App Store via `asc` CLI |
| [android-google-play-release.md](android-google-play-release.md) | Internal → Play Store via `gpd` CLI |

---

## Operations & Incidents

| Workflow | When to Use |
|----------|------------|
| [bug-fix.md](bug-fix.md) | Structured bug fix with regression test — use `/debug` as entry point |
| [production-incident.md](production-incident.md) | Detect → mitigate → diagnose → post-mortem |
| [tech-debt-cleanup.md](tech-debt-cleanup.md) | Deduplication, dead code removal, dependency audit |
| [documentation-generation.md](documentation-generation.md) | OpenAPI specs, CHANGELOG, diagrams, guides |

---

## Workspace & Tooling

| Workflow | When to Use |
|----------|------------|
| [developer-onboarding.md](developer-onboarding.md) | New developer setup — Claude Code, MCP, stacks |
| [new-skill-creation.md](new-skill-creation.md) | Adding a new skill to `.claude/skills/` |
| [hookify-management.md](hookify-management.md) | Creating and managing Hookify enforcement rules |
| [mcp-server-setup.md](mcp-server-setup.md) | Configuring or building a custom MCP server |
| [subagent-driven-development.md](subagent-driven-development.md) | 3-role SDD pipeline for plan-driven multi-agent work |
| [ralph-loop-autonomous.md](ralph-loop-autonomous.md) | Autonomous iteration loop until completion |
