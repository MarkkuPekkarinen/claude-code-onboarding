---
name: subagent-driven-development
description: 3-role pipeline (Implementer -> Spec Reviewer -> Quality Reviewer) for plan-driven multi-task implementation. Supports subagent dispatch (Agent tool) and Agent Teams (TeamCreate). Use when a plan file exists in docs/plans/ and work spans 3+ tasks.
allowed-tools: Read, Glob, Bash
metadata:
  triggers: subagent, SDD pipeline, multi-agent, agent teams, parallel agents, plan-driven implementation, TeamCreate
  related-skills: plan-mode-review, writing-skills, test-driven-development
  domain: workflow
  role: architect
  scope: design
  output-format: document
---

# Subagent-Driven Development (SDD)

Turns an approved plan into working, reviewed code using a 3-role pipeline:
**Implementer → Spec Reviewer → Quality Reviewer**.

Works in two dispatch modes: subagent (Agent tool, sequential) and team (TeamCreate, concurrent).

---

## When to Use

Prerequisites — both must be true:
- A plan file exists at `docs/plans/YYYY-MM-DD-<feature>.md` (created via `/plan-review`)
- The plan has 3 or more distinct implementation tasks

Mode selection:

| Condition | Use |
|-----------|-----|
| ≤5 tasks OR tech stack has no specialized implementer agent | **Subagent mode** |
| 6+ tasks OR Java / NestJS / Flutter / Python with tech-specific implementer adds value | **Team mode** |

Present to the developer at start:
```
Plan: [file]. [N] tasks detected.
1. Subagent mode — Agent tool, general-purpose agents, best for ≤5 tasks
2. Team mode    — TeamCreate with tech-specific agents, best for 6+ tasks
```

---

## The Pipeline

This pipeline runs identically in both modes — only the dispatch mechanism differs.

### Step 0 — Parse the Plan Once

Read the full plan file once. Extract every task as a structured object:

```
Task N:
  title: [task title from plan]
  full_text: [complete task description including acceptance criteria]
  tech_stack: [inferred from context — Java / NestJS / Python / Flutter / Angular / General]
  files_affected: [list if stated]
```

Create a `TaskCreate` entry for each task before starting any implementation.

### Step 1 — Per-Task Implementer

Dispatch the implementer with:
- Full task text (do NOT tell implementer to read the plan — provide it inline)
- Tech-stack skill reference (e.g., "consult `.claude/skills/java-spring-api/`")
- The implementer-prompt.md template content

Implementer flow:
1. Implementer may ask clarifying questions → answer them → re-dispatch
2. Implementer implements, writes tests (TDD per `leverage-patterns.md` test-first), self-reviews
3. Implementer returns: what was built, tests, files changed, self-review findings

### Step 2 — Spec Compliance Review

Dispatch the spec reviewer with:
- The task's full_text from Step 0 (the spec)
- The implementer's output from Step 1
- The spec-reviewer-prompt.md template content

Spec reviewer flow:
- Issues found → implementer fixes → spec review re-runs (no cap on iterations)
- No issues → advance to Step 3

### Step 3 — Quality Review

Dispatch the quality reviewer (routed by tech stack — see routing table below) with:
- The files changed by the implementer
- Tech-stack reviewer instructions

Quality reviewer flow:
- Issues found → implementer fixes → quality review re-runs (no cap on iterations)
- No issues → mark `TaskUpdate: completed` → advance to next task

### Step 4 — Final Pass and PR

After all tasks complete:
1. Dispatch `code-reviewer` agent on all changed files for a final cross-task consistency check
2. Create PR per CLAUDE.md git workflow (conventional commits, branch naming, squash merge target)

---

## Tech-Stack Routing Table (Quality Reviewer)

| Tech Stack | Agent |
|------------|-------|
| Java / Spring Boot | `spring-reactive-reviewer` |
| NestJS | `nestjs-reviewer` |
| Python / FastAPI | `code-reviewer` |
| Flutter | `riverpod-reviewer` |
| Agentic AI | `agentic-ai-reviewer` |
| Angular / General | `code-reviewer` |

---

## Subagent Mode Dispatch

All agents dispatched via the `Agent` tool.

**Implementer:**
```
Agent tool:
  subagent_type: general-purpose
  prompt: [implementer-prompt.md content] + [task full_text] + [tech-stack skill reference]
```

**Spec Reviewer:**
```
Agent tool:
  subagent_type: general-purpose
  prompt: [spec-reviewer-prompt.md content] + [task spec] + [implementer output]
```

**Quality Reviewer:**
```
Agent tool:
  subagent_type: [from routing table above]
  prompt: "Review the following files for [tech stack] quality, patterns, and standards.
           Files changed: [list]. Focus on: correctness, error handling, test coverage,
           naming, and adherence to project conventions in .claude/rules/."
```

Do NOT dispatch implementer and spec reviewer in parallel — spec review depends on implementer output.
Do NOT dispatch multiple implementers in parallel — file conflicts are guaranteed.

---

## Team Mode Dispatch

Use when 6+ tasks or when a tech-specific implementer agent provides meaningful leverage.

### Setup

```
1. TeamCreate — name the team after the feature (e.g., "auth-service")
2. Spawn agents:
   - implementer: subagent_type = tech-specific developer agent
     (java-spring-api | nestjs-api | python-dev | agentic-ai-dev | angular-spa | flutter-mobile)
   - spec-reviewer: subagent_type = general-purpose
   - quality-reviewer: subagent_type = from routing table above
3. Assign tasks via TaskUpdate (owner field) + SendMessage with full task context
```

### Coordination

- Use `TaskList` to track progress across all tasks
- Assign tasks to implementer one at a time (pipeline is sequential per task)
- After implementer completes → SendMessage to spec-reviewer with task spec + output
- After spec-reviewer approves → SendMessage to quality-reviewer with changed files
- After quality-reviewer approves → mark TaskUpdate: completed → assign next task
- When all tasks complete → SendMessage shutdown_request to all agents → TeamDelete

### Message format to teammates

Always send full task context in the message body — never tell teammates to "read the plan".
Include: task title, acceptance criteria, files affected, and any prior reviewer findings.

---

## Red Flags — Never Do These

- **Never dispatch parallel implementers** — file conflicts are guaranteed
- **Never skip spec review** — quality review does not check spec compliance
- **Never reverse pipeline order** — spec compliance before quality review, always
- **Never skip a review loop** — reviewer found issues = implementer fixes = re-review required
- **Never let implementer self-review replace spec/quality review** — both are required
- **Never tell implementer or reviewer to read the plan file** — provide full task text inline
- **Never declare a task complete while a reviewer has open issues**

---

## Integration References

| When | Reference |
|------|-----------|
| Implementer hits a bug during implementation | `systematic-debugging` skill |
| Before marking any task complete | `verification-before-completion` skill |
| Creating the PR | CLAUDE.md git workflow (conventional commits, feature branch, squash merge) |
| Plan file must exist | `docs/plans/` convention — `/plan-review` creates it |
| Security findings during review | `security-reviewer` agent |

---

## Error Handling

**No plan file found:**
```
BLOCKED: No plan file found in docs/plans/.
Run /plan-review to generate and save a plan before invoking SDD.
```

**Implementer asks questions before starting:**
Answer them directly. Do not dispatch another implementer — respond to the current one and let it proceed.

**Review loop exceeds 3 iterations on same issue:**
```
STOPPED: [reviewer] has flagged [issue] 3 times without resolution.
Options:
A) Escalate — bring in the human to resolve the design conflict
B) Waive — mark issue as known gap with explicit approval
C) Redesign — scrap this task's implementation and start fresh
```

**Team mode: teammate goes unresponsive:**
Check `TaskList` for stuck in_progress tasks. Send a follow-up `SendMessage`. If still unresponsive after one retry, stop and notify the developer.
