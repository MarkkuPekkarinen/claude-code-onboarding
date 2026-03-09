# Skills Guide

> Complete skill catalog for Claude Code Onboarding Kit. Use this to find the right skill for any task.
>
> 37 skills across 7 domains. Each skill is loaded with `/skill-name` or via `Skill` tool.

---

## Quick Reference by Domain

### Backend (8 skills)
- **agentic-ai-coding-standard**: Provides coding standards for Python agentic AI services with LangChain/LangGraph, covering state management, tool definitions, graph structure, error handling, and observability.
- **agentic-ai-dev**: Provides patterns and templates for building production AI agents with Python 3.14, LangChain v1.2.8, LangGraph v1.0.7, and FastAPI 0.128.x.
- **java-coding-standard**: Activated when reviewing Java code or enforcing coding standards in Spring Boot services, covering naming conventions, immutability patterns, Optional usage, streams, and exception handling.
- **java-spring-api**: Provides patterns and templates for Java 21 Spring Boot 3.5.x WebFlux REST API development, activated when creating controllers, services, repositories, DTOs, or reactive tests.
- **mcp-builder**: Used when building MCP (Model Context Protocol) servers to integrate external APIs or services, providing guides for Python (FastMCP) and Node/TypeScript (MCP SDK) implementations.
- **nestjs-api**: Provides patterns and templates for NestJS 11.x with Fastify, Prisma ORM, and TypeScript 5.x development, activated when creating modules, controllers, services, DTOs, guards, interceptors, or tests.
- **nestjs-coding-standard**: Activated when reviewing NestJS/TypeScript code or enforcing coding standards in NestJS 11.x services, covering naming conventions, TypeScript strictness, DTO patterns, and module organization.
- **python-dev**: Provides patterns and templates for Python 3.14 development with FastAPI and modern tooling, activated when creating Python APIs, scripts, data processing pipelines, or pytest tests.

### Frontend (5 skills)
- **angular-spa**: Angular 21.x SPA development skill with TailwindCSS 4.x and daisyUI 5.5.5, covering component scaffolding, UI/UX design, accessibility audits, and design systems.
- **flutter-mobile**: Provides patterns and templates for Flutter 3.38 / Dart 3.11 cross-platform mobile development, activated when building Flutter screens, Riverpod providers, Freezed models, or widget tests.
- **frontend-design**: Creative frontend design skill providing visual design principles, typography and color guidance, motion patterns, and anti-patterns for building distinctive production-grade UIs.
- **riverpod-patterns**: Provides Riverpod state management patterns and best practices for Flutter applications, covering providers, AsyncValue handling, ref usage, and provider lifecycle management.
- **ui-standards-tokens**: Provides design token definitions, theming patterns, and UI standards for Flutter applications, used when auditing UI compliance, implementing design systems, or ensuring consistent token usage.

### API & Architecture (6 skills)
- **architecture-decision-records**: Used when documenting significant technical decisions, reviewing past architectural choices, or establishing decision processes; provides ADR templates and best practices.
- **architecture-design**: Used when designing system architecture, API contracts, deployment topologies, or making technology decisions for full-stack applications.
- **database-schema-designer**: Used when designing database schemas for SQL or NoSQL databases, providing normalization guidelines, indexing strategies, migration patterns, and performance optimization. (domain: infrastructure)
- **ddd-architect**: Comprehensive Domain-Driven Design analysis and architecture generation for bounded contexts, domain models, aggregates, context maps, and microservice decomposition.
- **openapi-spec-generation**: Used when creating API documentation, generating SDKs, or ensuring API contract compliance by generating and maintaining OpenAPI 3.1 specifications.
- **mcp-builder**: Used when building MCP servers to integrate external APIs — also listed under Backend as it produces implementation code.

### Quality & Testing (6 skills)
- **browser-testing**: Browser automation and testing using Chrome DevTools MCP and Browser-Use MCP for debugging, performance analysis, E2E flows, and UI interaction.
- **code-reviewer**: General-purpose code review skill providing checklists for security, code quality, performance, and best practices when reviewing code changes, PRs, or performing quality audits.
- **dedup-code-agent**: Code duplication detection and technical debt analysis skill providing methodology for finding duplicate code, dead code, and dependency bloat.
- **pr-review**: Used when reviewing someone else's PR or preparing review comments for GitHub, implementing a two-stage approval process with internal analysis before any public posting.
- **systematic-debugging**: Used when encountering any bug, test failure, or unexpected behavior, before proposing fixes; always finds root cause before attempting a fix.
- **test-driven-development**: Used when implementing new features or logic that requires tests before writing implementation code, covering Red-Green-Refactor cycle and stack-specific test patterns.

### Security (3 skills)
- **sast-configuration**: Static Application Security Testing (SAST) configuration skill for setting up security scanning, configuring Semgrep rules, running SAST in CI/CD, or writing custom security rules.
- **security-reviewer**: Security vulnerability detection and remediation skill providing OWASP Top 10 checklists, secret scanning patterns, and security review methodology.
- **threat-modeling**: Threat modeling skill for STRIDE analysis, attack tree construction, and security requirement extraction when designing new features or reviewing architecture.

### Workflow & Process (10 skills)
- **changelog-generator**: Used when preparing releases, writing app store updates, or maintaining a CHANGELOG.md by parsing conventional commits and outputting polished release notes.
- **documentation-generation**: Documentation generation skill for README creation, docstring patterns, and CI/CD doc pipelines when generating project documentation or creating README files.
- **domain-finder**: Used when starting a new project or brand and needing to find a registrable domain by brainstorming creative names and checking real availability via DNS/WHOIS.
- **plan-mode-review**: Structured plan review with Phase 0 self-review, 5-phase code review, approval scope triage, decision logging, and blast radius assessment for non-trivial changes.
- **receiving-code-review**: Used when receiving code review feedback before implementing any suggestion, requiring verification and technical rigor rather than performative agreement.
- **subagent-driven-development**: 3-role pipeline (Implementer -> Spec Reviewer -> Quality Reviewer) for plan-driven multi-task implementation supporting subagent dispatch and Agent Teams.
- **verification-before-completion**: Used when about to claim work is complete, fixed, or passing, requiring verification commands and confirmed output before any success claims.
- **writing-skills**: Used when creating a new Claude Code skill from scratch, extending an existing skill, or reviewing a skill for structure compliance.
- **the-fool**: Challenge ideas, plans, and decisions using structured adversarial reasoning — devil's advocate, pre-mortem, red team, Socratic questioning, and evidence falsification.
- **feature-forge**: Used when defining new features, gathering requirements, or writing specifications before implementation starts. Runs PM+Dev dual-perspective interview, produces EARS-format functional requirements and Given/When/Then acceptance criteria saved to `specs/{feature}.spec.md`.

---

## Skill Workflows

> Ordered sequences for common development tasks.

### New Java/Spring API Feature
1. **java-spring-api** — Scaffold controller, service, repository, DTOs
2. **java-coding-standard** — Enforce naming, immutability, Optional patterns
3. **openapi-spec-generation** — Generate OpenAPI 3.1 spec from the new endpoints
4. **database-schema-designer** — Design schema for new entities
5. **code-reviewer** — Final quality and security review

### New NestJS API Feature
1. **nestjs-api** — Scaffold module, controller, service, DTOs, Prisma queries
2. **nestjs-coding-standard** — Enforce TypeScript strictness, DTO patterns
3. **openapi-spec-generation** — Generate API spec
4. **database-schema-designer** — Design Prisma schema
5. **code-reviewer** — Final review

### Flutter Mobile Feature
1. **flutter-mobile** — Build screens, Riverpod providers, Freezed models
2. **riverpod-patterns** — Review provider types, AsyncValue, ref usage
3. **ui-standards-tokens** — Audit design token compliance
4. **code-reviewer** — Final quality review

### Angular SPA Feature
1. **angular-spa** — Build standalone components, services, routes with TailwindCSS
2. **frontend-design** — Apply visual design principles
3. **browser-testing** — E2E test the new flow
4. **code-reviewer** — Final review

### AI Agent Development
1. **agentic-ai-dev** — Build LangGraph agent, RAG system, tools
2. **agentic-ai-coding-standard** — Enforce state management, tool definitions, guardrails
3. **python-dev** — FastAPI layer, Pydantic models, tests
4. **mcp-builder** — Add MCP server integration if needed
5. **security-reviewer** — Review for prompt injection, data exposure

### Security Hardening Session
1. **threat-modeling** — STRIDE analysis, DFD mapping, risk scoring
2. **sast-configuration** — Configure Semgrep/Bandit/gosec rules
3. **security-reviewer** — OWASP Top 10 review of changed code

### Architecture & Planning Session
1. **ddd-architect** — Domain analysis, bounded contexts, aggregates
2. **architecture-design** — System design, API contracts, deployment topology
3. **architecture-decision-records** — Document key decisions as ADRs
4. **openapi-spec-generation** — Generate API spec before implementation

---

## Decision Trees

> Use `->` to find the right skill for any task.

### What am I building?
- **Java REST API / reactive service** -> java-spring-api
- **NestJS REST API / TypeScript service** -> nestjs-api
- **Python FastAPI service** -> python-dev
- **AI agent or RAG pipeline** -> agentic-ai-dev
- **Angular SPA** -> angular-spa
- **Flutter mobile app (iOS/Android)** -> flutter-mobile
- **MCP server integration** -> mcp-builder
- **Database schema** -> database-schema-designer

### What review do I need?
- **General code quality** -> code-reviewer
- **Security vulnerabilities / OWASP** -> security-reviewer
- **Static analysis configuration** -> sast-configuration
- **Threat model for new system** -> threat-modeling
- **PR review for GitHub** -> pr-review
- **Receiving feedback on my PR** -> receiving-code-review
- **Duplicate code / tech debt** -> dedup-code-agent
- **Plan or architecture review** -> plan-mode-review

### What architecture work?
- **New system design (C4, ADR, sequences)** -> architecture-design
- **Domain-driven design (DDD, bounded contexts)** -> ddd-architect
- **Document architectural decisions** -> architecture-decision-records
- **OpenAPI / Swagger spec** -> openapi-spec-generation
- **Database schema design** -> database-schema-designer

### What testing task?
- **Write tests first (TDD cycle)** -> test-driven-development
- **E2E browser / UI testing** -> browser-testing
- **Debug failing test or error** -> systematic-debugging

### What security task?
- **STRIDE threat model** -> threat-modeling
- **Configure SAST tools** -> sast-configuration
- **Code vulnerability review** -> security-reviewer

### What documentation?
- **OpenAPI / Swagger** -> openapi-spec-generation
- **README / docstrings** -> documentation-generation
- **Changelog / release notes** -> changelog-generator
- **Architecture decision records** -> architecture-decision-records

### What workflow / process task?
- **Verify work before claiming done** -> verification-before-completion
- **Debug unexpected behavior** -> systematic-debugging
- **Multi-agent implementation pipeline** -> subagent-driven-development
- **Create a new skill** -> writing-skills
- **Find a domain name** -> domain-finder

---

## Skill Combinations

> Common multi-skill patterns for compound tasks.

### Full Java API Feature
java-spring-api + java-coding-standard + openapi-spec-generation + database-schema-designer + code-reviewer

### Full NestJS API Feature
nestjs-api + nestjs-coding-standard + openapi-spec-generation + database-schema-designer + code-reviewer

### Flutter Mobile App
flutter-mobile + riverpod-patterns + ui-standards-tokens + code-reviewer

### Angular SPA
angular-spa + frontend-design + ui-standards-tokens + browser-testing

### AI Agent Stack
agentic-ai-dev + agentic-ai-coding-standard + python-dev + security-reviewer

### Complete Security Audit
security-reviewer + sast-configuration + threat-modeling + code-reviewer

### Architecture Session
ddd-architect + architecture-design + architecture-decision-records + openapi-spec-generation

### Code Cleanup Sprint
code-reviewer + dedup-code-agent + systematic-debugging + test-driven-development

### Release Preparation
verification-before-completion + changelog-generator + pr-review

### New Skill Authoring
writing-skills + subagent-driven-development + plan-mode-review

---

## Examples

> Real scenarios mapped to skills.

- "Build a Spring Boot REST API for user management" -> java-spring-api + java-coding-standard + openapi-spec-generation
- "Add JWT auth to my NestJS service" -> nestjs-api + security-reviewer + nestjs-coding-standard
- "Create a Flutter screen with Riverpod state" -> flutter-mobile + riverpod-patterns + ui-standards-tokens
- "Build an Angular dashboard with charts" -> angular-spa + frontend-design + browser-testing
- "Build a LangGraph RAG agent with FastAPI" -> agentic-ai-dev + agentic-ai-coding-standard + python-dev
- "Design the database schema for a SaaS platform" -> database-schema-designer + architecture-design
- "Do a DDD analysis for our e-commerce domain" -> ddd-architect + architecture-decision-records
- "Review this PR for security issues" -> code-reviewer + security-reviewer
- "Debug this NullPointerException in production" -> systematic-debugging + verification-before-completion
- "Set up Semgrep rules for our Python codebase" -> sast-configuration + security-reviewer
- "Generate OpenAPI spec from my Spring controllers" -> openapi-spec-generation + java-spring-api
- "Write a README for our Flutter app" -> documentation-generation + flutter-mobile
- "Generate release notes from our git history" -> changelog-generator
- "Build an MCP server for our internal Jira API" -> mcp-builder + python-dev
- "Model threats for our new auth microservice" -> threat-modeling + security-reviewer + architecture-design

---

## Metadata Index

> Filter skills by domain, role, scope, or output type.

| Skill | Domain | Role | Scope | Output |
|-------|--------|------|-------|--------|
| agentic-ai-coding-standard | backend | specialist | review | report |
| agentic-ai-dev | backend | specialist | implementation | code |
| angular-spa | frontend | specialist | implementation | code |
| architecture-decision-records | api-architecture | architect | design | document |
| architecture-design | api-architecture | architect | design | architecture |
| browser-testing | quality | specialist | testing | report |
| changelog-generator | workflow | specialist | analysis | document |
| code-reviewer | quality | specialist | review | report |
| database-schema-designer | infrastructure | architect | design | document |
| ddd-architect | api-architecture | architect | system-design | architecture |
| dedup-code-agent | quality | specialist | analysis | report |
| documentation-generation | workflow | specialist | design | document |
| domain-finder | workflow | specialist | analysis | report |
| flutter-mobile | frontend | specialist | implementation | code |
| frontend-design | frontend | specialist | design | code |
| java-coding-standard | backend | specialist | review | report |
| java-spring-api | backend | specialist | implementation | code |
| mcp-builder | backend | specialist | implementation | code |
| nestjs-api | backend | specialist | implementation | code |
| nestjs-coding-standard | backend | specialist | review | report |
| openapi-spec-generation | api-architecture | specialist | design | specification |
| plan-mode-review | workflow | architect | review | report |
| pr-review | quality | specialist | review | report |
| python-dev | backend | specialist | implementation | code |
| receiving-code-review | workflow | specialist | review | document |
| riverpod-patterns | frontend | specialist | implementation | code |
| sast-configuration | security | specialist | infrastructure | document |
| security-reviewer | security | specialist | review | report |
| subagent-driven-development | workflow | architect | design | document |
| systematic-debugging | quality | specialist | analysis | analysis |
| test-driven-development | quality | specialist | testing | code |
| threat-modeling | security | architect | design | document |
| ui-standards-tokens | frontend | specialist | design | document |
| verification-before-completion | workflow | specialist | review | report |
| writing-skills | workflow | specialist | design | document |
| the-fool | workflow | expert | review | report |
| feature-forge | workflow | specialist | design | document |
