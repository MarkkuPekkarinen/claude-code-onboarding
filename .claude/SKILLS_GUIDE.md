# Skills Guide

> Complete skill catalog for Claude Code Onboarding Kit. Use this to find the right skill for any task.
>
> 60 skills across 9 domains. Each skill is loaded with `/skill-name` or via `Skill` tool.
>
> **Lazy-load pattern:** Each SKILL.md is a routing document only. Detailed patterns live in `reference/` files within each skill directory. Load the reference file explicitly when the detail is needed — do not expect it to be loaded automatically.

---

## Quick Reference by Domain

### Backend (12 skills)
- **adk-deploy-guide**: Used before deploying any ADK agent to Google Cloud — covers Cloud Run, Agent Engine, event-driven (Pub/Sub, Eventarc, BigQuery Remote Function), Terraform, and CI/CD.
- **adk-eval-guide**: Used when evaluating ADK agents, running `adk eval`, writing evalsets, configuring eval metrics (all 8 criteria), LLM-as-judge configuration, user simulation, multimodal evaluation, and debugging eval failures.
- **adk-observability-guide**: Used when configuring tracing (Cloud Trace), prompt-response logging, or BigQuery Agent Analytics for ADK agents — covers 3 observability tiers.
- **agentic-ai-coding-standard**: Provides coding standards for Python agentic AI services with LangChain/LangGraph, covering state management, tool definitions, graph structure, error handling, and observability.
- **agentic-ai-dev**: Provides patterns and templates for building production AI agents with Python 3.14, LangChain v1.2.8, LangGraph v1.0.7, and FastAPI 0.128.x.
- **google-adk**: Google ADK (Agent Development Kit) Python skill for building AI agents with Gemini models,
  SequentialAgent, ParallelAgent, LoopAgent, FunctionTool, McpToolset, session management, memory, callbacks,
  and FastAPI integration. Reference files: `adk-core-patterns.md`, `adk-structured-output.md`,
  `adk-agent-types.md`, `adk-agent-handoff.md`, `adk-tools-basic.md`, `adk-tools-callbacks.md`,
  `adk-memory-artifacts.md`, `adk-fastapi-integration.md`, `adk-testing.md`, `adk-project-config.md`.
- **java-coding-standard**: Activated when reviewing Java code or enforcing coding standards in Spring Boot services, covering naming conventions, immutability patterns, Optional usage, streams, and exception handling.
- **java-spring-api**: Provides patterns and templates for Java 21 Spring Boot 3.5.x WebFlux REST API development, activated when creating controllers, services, repositories, DTOs, or reactive tests.
- **mcp-builder**: Used when building MCP (Model Context Protocol) servers to integrate external APIs or services, providing guides for Python (FastMCP) and Node/TypeScript (MCP SDK) implementations.
- **nestjs-api**: Provides patterns and templates for NestJS 11.x with Fastify, Prisma ORM, and TypeScript 5.x development, activated when creating modules, controllers, services, DTOs, guards, interceptors, or tests.
- **nestjs-coding-standard**: Activated when reviewing NestJS/TypeScript code or enforcing coding standards in NestJS 11.x services, covering naming conventions, TypeScript strictness, DTO patterns, and module organization.
- **python-dev**: Provides patterns and templates for Python 3.14 development with FastAPI and modern tooling, activated when creating Python APIs, scripts, data processing pipelines, or pytest tests.

### Frontend (7 skills)
- **a2ui-angular**: A2UI (Agent-to-User Interface) renderer development for Angular 21.x — protocol implementation, component catalog, recursive renderer, action handling, streaming A2UI payloads, and security validation. Reference files: `a2ui-protocol.md`, `a2ui-protocol-advanced.md`, `a2ui-security.md`, `a2ui-component-catalog.md`, `a2ui-component-containers.md`, `a2ui-renderer-patterns.md`, `a2ui-renderer-template.md`, `a2ui-chat-template.md`, `a2ui-renderer-services.md`.
- **ai-chat**: AI chat interface patterns for Angular 21.x and Flutter 3.38 — streaming markdown rendering, auto-scroll heuristics, memoized computed(), token context indicators, thumbs up/down feedback, multi-modal input, and AI error states.
- **angular-spa**: Angular 21.x SPA development skill with TailwindCSS 4.x and daisyUI 5.5.5, covering component scaffolding, UI/UX design, accessibility audits, and design systems.
- **flutter-mobile**: Provides patterns and templates for Flutter 3.38 / Dart 3.11 cross-platform mobile development, activated when building Flutter screens, Riverpod providers, Freezed models, or widget tests. Reference files: `mfri-scoring.md` (risk scoring before any UI implementation), `flutter-templates.md`, `flutter-architecture-patterns.md`, `flutter-performance-ux.md`, `flutter-design-polish.md`, `accessibility-audit-checklist.md`, `flutter-security-hardening.md`.
- **frontend-design**: Creative frontend design skill providing visual design principles, typography and color guidance, motion patterns, and anti-patterns for building distinctive production-grade UIs.
- **riverpod-patterns**: Provides Riverpod state management patterns and best practices for Flutter applications, covering providers, AsyncValue handling, ref usage, and provider lifecycle management.
- **ui-standards-tokens**: Provides design token definitions, theming patterns, and UI standards for Flutter applications, used when auditing UI compliance, implementing design systems, or ensuring consistent token usage.

### Mobile Deployment (13 skills)

**iOS App Store (7 skills — powered by `asc` CLI):**
- **asc-cli-usage**: Command discovery, flags, output formats, auth, and pagination for the `asc` CLI — load first before running any asc command.
- **asc-id-resolver**: Resolve App Store Connect IDs (app, build, version, group, tester, submission) from human-friendly names — use whenever a command requires an ID parameter.
- **asc-signing-setup**: Set up bundle IDs, capabilities, signing certificates, and provisioning profiles — use when onboarding a new app or rotating expired certs.
- **asc-release-flow**: End-to-end TestFlight and App Store release workflow covering upload, processing, version creation, submission, and release — the primary iOS release skill.
- **asc-testflight-orchestration**: Manage TestFlight groups, testers, build distribution, and What to Test notes — use for beta rollout management.
- **asc-submission-health**: Preflight checklist and submission health for App Store review — run all 7 checks before submitting. Reference: `reference/submission-preflight-checklist.md`.
- **asc-crash-triage**: Triage TestFlight crashes, beta feedback, and performance diagnostics — use when investigating crash reports after a build is distributed.

**Android Google Play (6 skills — powered by `gpd` CLI):**
- **gpd-cli-usage**: Command discovery, flags, output formats, auth, and edit lifecycle for the `gpd` CLI — load first before running any gpd command.
- **gpd-id-resolver**: Resolve Google Play identifiers (package names, track names, version codes, product IDs) — use whenever a command requires an exact identifier.
- **gpd-build-lifecycle**: Upload AAB, track build processing, check release status, and manage version codes — primary upload skill.
- **gpd-betagroups**: Manage internal/beta tester groups and build distribution — use for beta testing rollout management.
- **gpd-release-flow**: End-to-end Google Play release workflow covering upload, staged rollout, track promotions, and production release — the primary Android release skill.
- **gpd-submission-health**: Preflight checklist for Google Play production releases — run all 5 checks before promoting to production. Reference: `reference/submission-preflight-checklist.md`.

### Vector Database (3 skills)
- **vector-database**: Use for all vector database work — pgvector schema design, Weaviate collection creation, RAG pipeline scaffolding, embedding model selection, HNSW vs IVFFlat index tuning, and embedding model migration. Iron law: pin dimensions at model selection. Reference files: `references/pgvector-migration-template.md`, `references/weaviate-collection-patterns.md`, `references/rag-pipeline-patterns.md`, `references/embedding-migration-guide.md`.
- **weaviate**: Search, query, and manage Weaviate vector database collections — semantic search, hybrid search, keyword search, natural language queries, data import, collection inspection, and filtered fetching. Includes Python scripts in `scripts/`. Required env: `WEAVIATE_URL`, `WEAVIATE_API_KEY`.
- **weaviate-cookbooks**: Build complete AI applications with Weaviate — Query Agent Chatbot, PDF Multimodal RAG, Basic/Advanced/Agentic RAG, Basic Agents with DSPy. High-level blueprints and end-to-end project patterns. Read `references/project_setup.md` and `references/environment_requirements.md` first.

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
- **subagent-driven-development**: 3-role pipeline (Implementer -> Spec Reviewer -> Quality Reviewer) for plan-driven multi-task implementation supporting subagent dispatch and Agent Teams. Reference files: `parallel-dispatch-checklist.md` (independence check + conflict detection before/after parallel dispatch), `implementer-prompt.md`, `spec-reviewer-prompt.md`.
- **verification-before-completion**: Used when about to claim work is complete, fixed, or passing, requiring verification commands and confirmed output before any success claims.
- **writing-skills**: Used when creating a new Claude Code skill from scratch, extending an existing skill, or reviewing a skill for structure compliance.
- **the-fool**: Challenge ideas, plans, and decisions using structured adversarial reasoning — devil's advocate, pre-mortem, red team, Socratic questioning, and evidence falsification.
- **feature-forge**: Used when defining new features, gathering requirements, or writing specifications before implementation starts. Runs PM+Dev dual-perspective interview, produces EARS-format functional requirements and Given/When/Then acceptance criteria saved to `specs/{feature}.spec.md`.
- **brainstorm** (`/brainstorm`): Divergent exploration before committing to an approach — generates ≥3 distinct alternatives with trade-offs and Mermaid diagram. No code; use before feature-forge or architecture-design when the solution space is still open.
- **debug** (`/debug`): Slash command entry point for systematic-debugging skill. Enforces root-cause-first investigation with structured Symptom → Root Cause → Fix → Prevention output format.
- **iterate-pr**: Autonomous PR completion loop — fetches CI failures and review feedback, fixes and pushes until all checks are green. Classifies feedback by LOGAF scale (high/medium auto-fix, low asks user), polls CI, and posts GitHub thread replies.

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

### iOS App Store Release
1. **flutter-mobile** — Build and archive the iOS app (`flutter build ios --release`)
2. **asc-cli-usage** — Verify asc auth and learn flags before running any command
3. **asc-signing-setup** — Verify bundle ID, capabilities, and provisioning profiles
4. **asc-id-resolver** — Resolve app ID, group IDs, and build IDs
5. **asc-release-flow** — Upload IPA, wait for processing, create version, submit
6. **asc-testflight-orchestration** — Distribute to groups and manage What to Test notes
7. **asc-submission-health** — Run all 7 preflight checks before App Store submission
8. **asc-crash-triage** — Investigate crashes after TestFlight distribution

### Android Google Play Release
1. **flutter-mobile** — Build the Android AAB (`flutter build appbundle --release`)
2. **gpd-cli-usage** — Verify gpd auth and learn flags before running any command
3. **gpd-id-resolver** — Resolve package name, track names, and version codes
4. **gpd-build-lifecycle** — Upload AAB and wait for build processing
5. **gpd-betagroups** — Distribute to internal/beta tester groups
6. **gpd-release-flow** — Staged rollout and promotion to production track
7. **gpd-submission-health** — Run all 5 preflight checks before production release

### Angular SPA Feature
1. **angular-spa** — Build standalone components, services, routes with TailwindCSS
2. **frontend-design** — Apply visual design principles
3. **browser-testing** — E2E test the new flow
4. **code-reviewer** — Final review

### AI Chat UI Feature (Angular or Flutter)
1. **ai-chat** — Streaming messages, auto-scroll, token indicator, feedback, error states
2. **angular-spa** or **flutter-mobile** — Platform-specific component patterns
3. **security-reviewer** — File upload, innerHTML rendering, token exposure

### pgvector Schema + RAG Pipeline
1. **vector-database** — Design pgvector migration (model, dimensions, index type, distance metric)
2. **database-schema-designer** — Design surrounding relational schema for the table
3. **pgvector-schema-reviewer** agent — Review migration for operator/index alignment, dimension match, null guards
4. **agentic-ai-dev** (or **python-dev**) — Implement embedding + retrieval layer
5. **rag-pipeline-reviewer** agent — Review pipeline for model pinning, batch embedding, silent failure risks

### Weaviate Collection + Application
1. **weaviate** — Inspect existing cluster, list collections, explore schema
2. **vector-database** — Design collection schema (vectorizer, named vectors, multi-tenancy)
3. **weaviate-schema-reviewer** agent — Review collection for v4 API, distance metric, multi-tenancy flag
4. **weaviate-cookbooks** — Pick application blueprint (RAG, chatbot, agentic RAG, DSPy agent)
5. **agentic-ai-dev** (or **python-dev**) — Implement FastAPI layer

### AI Agent Development
1. **agentic-ai-dev** — Build LangGraph agent, RAG system, tools
2. **agentic-ai-coding-standard** — Enforce state management, tool definitions, guardrails
3. **python-dev** — FastAPI layer, Pydantic models, tests
4. **mcp-builder** — Add MCP server integration if needed
5. **security-reviewer** — Review for prompt injection, data exposure

### Google ADK Agent Development
1. **google-adk** — Scaffold agent, define tools, configure session management
2. **adk-eval-guide** — Write evalsets and run `adk eval` before shipping
3. **adk-observability-guide** — Enable Cloud Trace and prompt logging
4. **adk-deploy-guide** — Deploy to Agent Engine or Cloud Run with Terraform
5. **security-reviewer** — Review tools that call external APIs or handle user PII

### A2UI Agent-Driven UI (Angular)
1. **a2ui-angular** — Build A2UI renderer, catalog, and action handler
2. **angular-spa** — Platform-specific Angular component patterns
3. **google-adk** (or **agentic-ai-dev**) — Agent backend that emits A2UI payloads
4. **security-reviewer** — Validate allowlist enforcement and injection prevention

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
- **Google ADK agent (Gemini-based)** -> google-adk
- **A2UI agent-driven UI** -> a2ui-angular
- **AI chat UI (streaming, copilot, chatbot)** -> ai-chat
- **Angular SPA** -> angular-spa
- **Flutter mobile app (iOS/Android)** -> flutter-mobile
- **iOS App Store release / TestFlight distribution** -> asc-release-flow (+ asc-cli-usage, asc-id-resolver)
- **Android Google Play release / staged rollout** -> gpd-release-flow (+ gpd-cli-usage, gpd-id-resolver)
- **App Store signing / certificates / provisioning** -> asc-signing-setup
- **TestFlight crash investigation** -> asc-crash-triage
- **MCP server integration** -> mcp-builder
- **Database schema** -> database-schema-designer
- **pgvector schema / vector column migration** -> vector-database → `/design-vector-schema`
- **Weaviate collection creation** -> vector-database → `/design-weaviate-collection`
- **RAG pipeline (chunk → embed → retrieve → rerank)** -> vector-database → `/scaffold-rag-pipeline`
- **Vector index tuning (HNSW vs IVFFlat)** -> vector-database → `/tune-vector-index`
- **Switch embedding model (re-embedding migration)** -> vector-database → `/migrate-embedding-model`
- **Search/query an existing Weaviate cluster** -> weaviate → `/weaviate:search` or `/weaviate:ask`
- **Build a Weaviate-based application (chatbot, RAG app)** -> weaviate-cookbooks

### What review do I need?
- **General code quality** -> code-reviewer
- **Security vulnerabilities / OWASP** -> security-reviewer
- **Static analysis configuration** -> sast-configuration
- **Threat model for new system** -> threat-modeling
- **PR review for GitHub (before merge)** -> pr-review
- **Fix CI failures + feedback loop after PR opened** -> iterate-pr
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
- **Debug failing test or error** -> `/debug` (loads systematic-debugging)

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
- **Debug unexpected behavior** -> `/debug` (loads systematic-debugging)
- **Explore options before committing to an approach** -> `/brainstorm`
- **Multi-agent implementation pipeline** -> subagent-driven-development
- **Iterate PR until CI is green** -> iterate-pr
- **Create a new skill** -> writing-skills
- **Find a domain name** -> domain-finder
- **Get copy-paste agent invocation templates** -> `docs/workflows/agent-activation-prompts.md`

---

## Skill Combinations

> Common multi-skill patterns for compound tasks.

### Full Java API Feature
java-spring-api + java-coding-standard + openapi-spec-generation + database-schema-designer + code-reviewer

### Full NestJS API Feature
nestjs-api + nestjs-coding-standard + openapi-spec-generation + database-schema-designer + code-reviewer

### Flutter Mobile App
flutter-mobile + riverpod-patterns + ui-standards-tokens + code-reviewer

### iOS App Store Release Pipeline
flutter-mobile + asc-cli-usage + asc-signing-setup + asc-id-resolver + asc-release-flow + asc-testflight-orchestration + asc-submission-health

### Android Google Play Release Pipeline
flutter-mobile + gpd-cli-usage + gpd-id-resolver + gpd-build-lifecycle + gpd-betagroups + gpd-release-flow + gpd-submission-health

### Angular SPA
angular-spa + frontend-design + ui-standards-tokens + browser-testing

### AI Chat UI (Angular or Flutter)
ai-chat + angular-spa (or flutter-mobile) + security-reviewer

### PR Lifecycle (full loop)
pr-review + iterate-pr + verification-before-completion

### pgvector RAG Stack
vector-database + database-schema-designer + agentic-ai-dev + python-dev + pgvector-schema-reviewer agent + rag-pipeline-reviewer agent

### Weaviate Application Stack
weaviate + vector-database + weaviate-cookbooks + agentic-ai-dev + weaviate-schema-reviewer agent

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

### Google ADK Agent (Full Stack)
google-adk + adk-eval-guide + adk-observability-guide + adk-deploy-guide + security-reviewer

### A2UI Agent-Driven UI (Angular)
a2ui-angular + angular-spa + google-adk + security-reviewer

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
- "Fix all CI failures and address review comments" -> iterate-pr
- "Build a streaming chat UI with Angular" -> ai-chat + angular-spa + security-reviewer
- "Build a Flutter chat screen with streaming AI" -> ai-chat + flutter-mobile + riverpod-patterns
- "Debug this NullPointerException in production" -> systematic-debugging + verification-before-completion
- "Set up Semgrep rules for our Python codebase" -> sast-configuration + security-reviewer
- "Generate OpenAPI spec from my Spring controllers" -> openapi-spec-generation + java-spring-api
- "Write a README for our Flutter app" -> documentation-generation + flutter-mobile
- "Generate release notes from our git history" -> changelog-generator
- "Build an MCP server for our internal Jira API" -> mcp-builder + python-dev
- "Model threats for our new auth microservice" -> threat-modeling + security-reviewer + architecture-design
- "Build a Gemini-based ADK agent with tools and sessions" -> google-adk + adk-eval-guide + security-reviewer
- "Deploy an ADK agent to Cloud Run with Terraform" -> adk-deploy-guide + google-adk
- "Build an A2UI renderer for an Angular agent-driven UI" -> a2ui-angular + angular-spa + security-reviewer
- "Evaluate ADK agent quality with rubric-based scoring" -> adk-eval-guide + google-adk
- "Upload my Flutter iOS build to TestFlight" -> asc-cli-usage + asc-id-resolver + asc-release-flow
- "Submit my iOS app to App Store review" -> asc-submission-health + asc-release-flow
- "Rotate expired iOS signing certificate" -> asc-signing-setup + asc-id-resolver
- "Investigate TestFlight crash after beta release" -> asc-crash-triage + asc-id-resolver
- "Upload Android AAB to Google Play internal track" -> gpd-cli-usage + gpd-id-resolver + gpd-build-lifecycle
- "Staged rollout to 10% on Google Play" -> gpd-release-flow + gpd-submission-health
- "Add testers to our Android beta group" -> gpd-betagroups + gpd-id-resolver
- "Run preflight before promoting Android to production" -> gpd-submission-health
- "Add pgvector to Cloud SQL for vendor matching" -> vector-database + database-schema-designer
- "Design a Weaviate collection for scraped reviews" -> vector-database → `/design-weaviate-collection`
- "Build a RAG pipeline for PDF documents" -> vector-database + weaviate-cookbooks + agentic-ai-dev
- "Switch from text-embedding-3-small to voyage-3-large" -> vector-database → `/migrate-embedding-model`
- "Tune HNSW index for 500K vendor embeddings" -> vector-database → `/tune-vector-index`
- "Search Weaviate collection with hybrid search" -> weaviate → `/weaviate:search`
- "Build a Query Agent chatbot on Weaviate" -> weaviate-cookbooks + agentic-ai-dev
- "Review my pgvector migration for correctness" -> pgvector-schema-reviewer agent
- "Set up Weaviate Cloud and load example data" -> weaviate → `/weaviate:quickstart`

---

## Metadata Index

> Filter skills by domain, role, scope, or output type.

| Skill | Domain | Role | Scope | Output |
|-------|--------|------|-------|--------|
| a2ui-angular | frontend | specialist | implementation | code |
| adk-deploy-guide | infrastructure | specialist | deployment | code |
| adk-eval-guide | agentic-ai | specialist | evaluation | code |
| adk-observability-guide | backend | specialist | observability | code |
| agentic-ai-coding-standard | backend | specialist | review | report |
| agentic-ai-dev | backend | specialist | implementation | code |
| ai-chat | frontend | specialist | implementation | code |
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
| google-adk | backend | specialist | implementation | code |
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
| iterate-pr | workflow | autonomous | pr-lifecycle | actions |
| feature-forge | workflow | specialist | design | document |
| brainstorm | workflow | specialist | exploration | document |
| debug | quality | specialist | analysis | analysis |
| asc-cli-usage | mobile-deployment | specialist | deployment | commands |
| asc-id-resolver | mobile-deployment | specialist | deployment | commands |
| asc-signing-setup | mobile-deployment | specialist | deployment | commands |
| asc-release-flow | mobile-deployment | specialist | deployment | commands |
| asc-testflight-orchestration | mobile-deployment | specialist | deployment | commands |
| asc-submission-health | mobile-deployment | specialist | deployment | commands |
| asc-crash-triage | mobile-deployment | specialist | deployment | report |
| gpd-cli-usage | mobile-deployment | specialist | deployment | commands |
| gpd-id-resolver | mobile-deployment | specialist | deployment | commands |
| gpd-build-lifecycle | mobile-deployment | specialist | deployment | commands |
| gpd-betagroups | mobile-deployment | specialist | deployment | commands |
| gpd-release-flow | mobile-deployment | specialist | deployment | commands |
| gpd-submission-health | mobile-deployment | specialist | deployment | commands |
| vector-database | vector-db | specialist | implementation | code |
| weaviate | vector-db | specialist | implementation | code |
| weaviate-cookbooks | vector-db | specialist | implementation | code |
