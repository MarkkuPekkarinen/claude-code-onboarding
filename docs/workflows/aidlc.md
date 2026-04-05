# AI-DLC Workflow (`/aidlc`)

> **When to use**: Any non-trivial software development task — new features, brownfield changes, or system design — where you want a structured, auditable development lifecycle with explicit approval gates at each phase
> **Command**: `/aidlc`
> **Credit**: Adapted from [AWS Labs AI-DLC Workflows](https://github.com/awslabs/aidlc-workflows) — an open-source AI-assisted development methodology originally built for Amazon Q Developer, Cursor, Cline, and Kiro IDE

## What Is AI-DLC?

AI-DLC (AI-Driven Development Lifecycle) is a structured methodology that guides Claude through the full arc of software development — from requirements gathering to code generation — using a multi-phase, approval-gated workflow. Rather than generating code immediately, it first builds shared understanding, then designs, then implements.

The key idea: **the AI adapts its depth to the work**. A simple bug fix skips most stages and goes straight to code. A new multi-service feature runs the full lifecycle with requirements, user stories, design, and unit decomposition.

---

## How It Fits With This Kit

`/aidlc` doesn't replace this kit's skills, agents, and rules — it **orchestrates on top of them**. Both the CLAUDE.md project rules and the AI-DLC workflow apply concurrently. Project-specific constraints always win.

```
/aidlc invoked
    │
    ├── Loads .aidlc-rule-details/ (phase-specific rules, loaded lazily)
    ├── Loads extensions/*.opt-in.md (security, testing — user opts in/out)
    │
    ├── INCEPTION PHASE (plan)
    │   ├── Workspace Detection → brownfield or greenfield?
    │   ├── Reverse Engineering → (brownfield only) map existing code
    │   ├── Requirements Analysis → always runs, depth scales to complexity
    │   ├── User Stories → conditional on user impact
    │   ├── Workflow Planning → which phases to run, which to skip
    │   ├── Application Design → new components only
    │   └── Units Generation → decompose into parallel work units
    │
    ├── CONSTRUCTION PHASE (build — per unit)
    │   ├── Functional Design → data models, business rules
    │   ├── NFR Requirements → performance, security, scalability
    │   ├── NFR Design → apply NFR patterns
    │   ├── Infrastructure Design → cloud resources, deployment topology
    │   └── Code Generation → plan first, then generate (two-part)
    │       └── Build & Test → instructions for all units
    │
    └── OPERATIONS PHASE (placeholder — future)
```

### Where This Kit's Components Plug In

| AI-DLC Stage | Skills That Activate | Agents That Help |
|---|---|---|
| Requirements Analysis | `feature-forge`, `ddd-architect` | `architect`, `plan-challenger` |
| Workflow Planning | `plan-mode-review`, `architecture-design` | `architect` |
| Application Design | `architecture-design`, `database-schema-designer` | `architect`, `database-designer` |
| Code Generation | Stack skill (e.g., `flutter-mobile`, `nestjs-api`) | Stack agent |
| NFR Requirements | `systematic-debugging`, `threat-modeling` | `security-reviewer` |
| Build & Test | `test-driven-development`, `browser-testing` | `tdd-guide`, `browser-testing` |

---

## Running the Workflow

```
> /aidlc
```

Claude displays a welcome message, detects whether the workspace is greenfield or brownfield, then presents the planned execution stages for your approval before doing any work.

**Approval gates:** Every phase ends with an explicit user confirmation — Claude will not advance until you confirm. This keeps you in control of pace and scope.

**Audit trail:** Every interaction (your inputs, Claude's responses, approvals) is logged verbatim with ISO timestamps in `aidlc-docs/audit.md`. Append-only — never overwritten.

**Progress tracking:** `aidlc-docs/aidlc-state.md` tracks which stages ran and which were skipped. Resuming a session picks up exactly where you left off.

---

## Adaptive Depth — What Gets Skipped

The workflow is not a checklist you always run in full. Claude intelligently skips stages that don't add value:

| Scenario | Stages Skipped |
|---|---|
| Simple bug fix | User Stories, Application Design, Units Generation, most NFR stages |
| Pure refactoring | User Stories, Application Design, Infrastructure Design |
| New greenfield feature | Reverse Engineering |
| Single-component change | Units Generation |
| Infrastructure-only change | Functional Design, User Stories |

You can also override — explicitly request a stage be included or excluded at the Workflow Planning approval gate.

---

## Extensions

Two opt-in extensions ship with this kit:

| Extension | What It Adds | When to Enable |
|---|---|---|
| `security/baseline` | Security constraints applied at every construction stage | Features touching auth, crypto, file uploads, external APIs |
| `testing/property-based` | Property-based testing patterns added to test generation | Complex business logic, data transformation, state machines |

Extensions are presented as opt-in/opt-out during Requirements Analysis. Full rule files are only loaded if you opt in — keeping context lean by default.

---

## Output Artifacts

All documentation lands in `aidlc-docs/` — never mixed with application code:

```
aidlc-docs/
  aidlc-state.md              # stage tracking and extension config
  audit.md                    # complete verbatim interaction log
  inception/
    requirements/             # functional and NFR requirements
    user-stories/             # personas and acceptance criteria
    application-design/       # component and service design
  construction/
    {unit-name}/
      functional-design/      # data models, business rules
      nfr-requirements/       # performance, security specs
      nfr-design/             # NFR pattern application
      infrastructure-design/  # cloud resource mapping
      code/                   # markdown summaries (code goes to workspace root)
    build-and-test/           # build and test instructions
```

Application code always goes to the workspace root — never inside `aidlc-docs/`.

---

## Credit

The AI-DLC methodology and `.aidlc-rule-details/` ruleset are adapted from the open-source **[awslabs/aidlc-workflows](https://github.com/awslabs/aidlc-workflows)** project by AWS Labs. The original framework was built for Amazon Q Developer, Cursor, Cline, and Kiro IDE. This kit adapts it for Claude Code while keeping the full ruleset intact and project-agnostic.
