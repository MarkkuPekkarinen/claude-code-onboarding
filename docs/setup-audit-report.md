# Setup Audit Report

**Date:** 2026-04-13
**Scope:** All always-loaded rule files, CLAUDE.md, settings.json, commands, hookify rules, and SKILLS_GUIDE.md
**Auditor:** Automated setup-audit task

---

## Files Audited

| File | Type | Token Impact |
|------|------|-------------|
| `CLAUDE.md` | Project root instructions | Always loaded |
| `.claude/rules/core-behaviors.md` | Behavioral rules | Always loaded |
| `.claude/rules/first-principles.md` | Numeric enforcement gates | Always loaded |
| `.claude/rules/code-standards.md` | Coding conventions | Always loaded |
| `.claude/rules/verification-and-reporting.md` | Verification methodology | Always loaded |
| `.claude/rules/leverage-patterns.md` | Workflow patterns | Always loaded |
| `.claude/rules/blackbox-policy.md` | Session logging policy | Always loaded |
| `.claude/rules/skill-triggers.md` | Security audit + skill routing | Always loaded |
| `.claude/rules/lessons.md` | Correction log | Always loaded |
| `.claude/SKILLS_GUIDE.md` | Skill catalog (92 skills) | Not auto-loaded |
| `.claude/settings.json` | Permissions, hooks, env | Always loaded |
| `.claude/commands/*.md` (4 files) | Slash commands | On-demand |
| `.claude/hookify.*.local.md` (7 files) | Design lint rules | Hook-triggered |

**Total always-loaded rule files:** 9 (estimated ~12,000–15,000 tokens of always-on context)

---

## A. Rules Flagged for Removal

### A1. Filter 1 — Already Default Claude Behavior (11 rules)

| # | Rule (summarized) | Source | Reason |
|---|-------------------|--------|--------|
| 1 | "Be direct. No filler ('Certainly!', 'Of course!')" | CLAUDE.md, Communication | Claude's default tone already avoids these. No project-specific nuance added. |
| 2 | "Meaningful variable names (no `temp`, `data`, `result` without context)" | code-standards.md, Output Quality | Standard coding practice Claude follows without instruction. |
| 3 | "No bloated abstractions or premature generalization" | code-standards.md, Output Quality | Restates what YAGNI/KISS already cover in core-behaviors.md §4. |
| 4 | "No clever tricks without comments explaining why" | code-standards.md, Output Quality | Standard practice — Claude comments non-obvious code by default. |
| 5 | "Match the project's idioms — don't introduce a different paradigm mid-file" | code-standards.md, Output Quality | Claude naturally maintains consistency within files. |
| 6 | "Edge cases: null, empty, zero, negative, concurrent, out-of-order" | core-behaviors.md §7, Think Before You Code | Claude already considers edge cases during code generation. The list adds no actionable threshold. |
| 7 | "Off-by-one errors" | core-behaviors.md §7 | Claude checks these by default. No project-specific gate. |
| 8 | "Type mismatches" | core-behaviors.md §7 | Compilers catch these. No added value as a prose rule. |
| 9 | "Re-read your own code before presenting it" | core-behaviors.md §7 | Default Claude behavior — it self-reviews before outputting. |
| 10 | "Trace with a concrete example" | core-behaviors.md §8 | Claude already does mental execution. This doesn't add a measurable gate. |
| 11 | "When human says 'couldn't you just do X?' — take it seriously" | core-behaviors.md §4 | Claude already incorporates user feedback. Stating it doesn't change behavior. |

### A2. Filter 3 — Redundant / Already Covered (18 rules)

| # | Rule A | Rule B | Keep |
|---|--------|--------|------|
| 1 | Exit signals list in `blackbox-policy.md` (10 phrases) | Identical exit signals list in `skill-triggers.md` (8 phrases, subset) | **blackbox-policy.md** — it's the canonical source and has the full list with trigger behavior. Remove the duplicate from skill-triggers.md. |
| 2 | "Pre-Submit Checklist → Use Quality Gates in verification-and-reporting.md" (code-standards.md) | "Self-Check → Use Quality Gates in verification-and-reporting.md" (first-principles.md) | **verification-and-reporting.md** is the single source. Both pointers are fine, but the pointer in code-standards.md adds zero information beyond first-principles.md already saying the same thing. Remove one. |
| 3 | "`console.log` / `print()` → STOP. Use Logger." (first-principles.md Layer 1) | "No `print()` or `console.log` in production code" (code-standards.md Logging Standards) | **first-principles.md** — it has the enforcement action (STOP). The code-standards mention is redundant. |
| 4 | Scope Safety: "Touching files outside the stated task → STOP" (first-principles.md Layer 1) | "Touch only what you're asked to touch" with 4 bullet points (core-behaviors.md §5) | **Both serve a purpose** but the bullets in §5 overlap. Consolidate by having §5 reference first-principles Layer 1 instead of restating. |
| 5 | "Modify existing files first" decision tree (code-standards.md) | "Path of least resistance" bias counter: "Default to modifying existing files. Always." (core-behaviors.md Guard Rails) | **code-standards.md** — it has the decision tree. Remove the one-liner from Guard Rails or make it a reference. |
| 6 | Security rules in code-standards.md (8 bullets) | Security thresholds in first-principles.md Layer 2 (4 items) | **Overlap on 3 items** (plaintext passwords, SQL injection, input validation). code-standards.md has the broader set; first-principles.md has the enforcement. Merge into one location. |
| 7 | "Always write tests" (CLAUDE.md, Important Rules) | Test Coverage table (first-principles.md Layer 2) | Test-First (leverage-patterns.md) | Quality Gates Feature/PR Gate (verification-and-reporting.md) | **first-principles.md Layer 2** is the canonical gate. The other three are redundant restatements. |
| 8 | Task management "Creating Tasks" (CLAUDE.md) | Task Quantification Rule (leverage-patterns.md) | **Significant overlap** — both define task creation rules. Consolidate into one location. |
| 9 | Change descriptions (code-standards.md) | Quality Gates require "Change description written" (verification-and-reporting.md) | **verification-and-reporting.md** — it's the enforcement point. code-standards.md template is the format spec. These are complementary but the rule "you must write one" is stated twice. |
| 10 | "Never commit secrets" (CLAUDE.md Important Rules) | Committing `.env`, `*.pem`, `*.key` → STOP (first-principles.md Layer 1) | `deny` rules in settings.json for `Read(./.env)`, `Read(./**/*.pem)`, etc. | **settings.json** already enforces this mechanically. The prose rules add defense-in-depth but three layers saying "don't commit secrets" is excessive. Keep first-principles.md (strongest) + settings.json (mechanical). |
| 11 | "Don't remove comments you don't understand" (core-behaviors.md §5) | "Deleting pre-existing code you don't fully understand → STOP" (first-principles.md Layer 1) | **first-principles.md** is stricter and covers this. §5 bullet is redundant. |
| 12 | Dead code rule table (core-behaviors.md §5) | "Dead code created by YOUR changes removed immediately" (first-principles.md Layer 3) | **Same rule, two locations.** Keep core-behaviors.md table (more detailed), remove first-principles restatement. |
| 13 | "Errors must be loud. Never swallow exceptions" (core-behaviors.md Guard Rails) | "No Silent Failures" (code-standards.md Error Handling) | Bare catch threshold = 0 (first-principles.md Layer 2) | **Three places.** Keep code-standards.md (has code examples) + first-principles.md (has threshold). Remove one-liner from Guard Rails. |
| 14 | Optimism bias: "Use binary status" (core-behaviors.md Guard Rails) | "Binary status: Works or Doesn't work" (verification-and-reporting.md) | **Same directive.** Keep verification-and-reporting.md (has full format). Remove from Guard Rails. |
| 15 | Confabulation bias: "If you can't point to file:line, say 'I haven't verified this yet'" (core-behaviors.md Guard Rails) | Confidence Levels on Research Claims (verification-and-reporting.md) | **verification-and-reporting.md** is more nuanced (HIGH/MEDIUM/LOW). Guard Rails one-liner is redundant. |
| 16 | "Don't re-read files you already have in context" (leverage-patterns.md Context Window) | General principle, not project-specific | Claude already optimizes tool calls. |
| 17 | "Prefer Grep/Glob over exploratory reads" (leverage-patterns.md Context Window) | General Claude Code behavior | Not project-specific — Claude already uses efficient tools. |
| 18 | Conflict avoidance bias: "Re-verify with file:line evidence" (core-behaviors.md Guard Rails) | "When User Challenges Your Analysis — Don't flip. Re-verify" (verification-and-reporting.md) | **verification-and-reporting.md** has the full protocol. Guard Rails entry is redundant. |

### A3. Filter 4 — Bandaid for One Bad Output (5 rules)

| # | Rule | Source | Why it looks reactive |
|---|------|--------|----------------------|
| 1 | "Edit fallback protocol: If Edit tool fails twice, switch to Bash sed/awk; if that fails, use Write tool" | first-principles.md, Layer 3 | Hyper-specific workaround for Claude's Edit tool behavior. This is tool-use strategy, not a project rule. Should be in a troubleshooting doc, not an always-loaded rules file. |
| 2 | Orchestrator Pre-Flight — entire section | leverage-patterns.md | Directly reacts to the lesson in lessons.md about scaffold failure. The lesson itself is sufficient; the 40-line section in leverage-patterns.md is overkill for a one-time mistake. |
| 3 | "Do not ask 'what were we working on?' if TaskList has the answer" | core-behaviors.md §9 | Reads like a correction from a session where Claude asked this unnecessarily. |
| 4 | "Angular: `shared/components/` components have zero `inject()` calls (dumb rule enforced)" | verification-and-reporting.md, UI Gate | The "(dumb rule enforced)" annotation suggests this was added reactively. The rule itself may be valid, but the phrasing signals it was a one-off fix. |
| 5 | "Flutter: `packages/shared_ui/` widgets extend `StatelessWidget` — no `ConsumerWidget` (dumb rule enforced)" | verification-and-reporting.md, UI Gate | Same as above — "(dumb rule enforced)" phrasing. |

### A4. Filter 5 — Too Vague to Be Actionable (7 rules)

| # | Rule | Source | Problem |
|---|------|--------|---------|
| 1 | "Demand Elegance (Balanced)" | core-behaviors.md §4 | "Is there a more elegant way?" is subjective. No criteria for what "elegant" means. The sub-bullet "Elegance ≠ complexity" helps but the trigger ("non-trivial changes, pause and ask") has no threshold for "non-trivial." |
| 2 | "Content Validation: Validate diagram syntax before writing. Test renders in target environment." | code-standards.md | What validation? Which diagrams? Which target environment? No tools or commands specified. |
| 3 | "Browser MCP in the Loop: When applicable, use a browser MCP for real-time validation." | leverage-patterns.md | "When applicable" is undefined. No criteria for when to use vs skip. |
| 4 | "Performance: Never optimize without evidence. Profile first." | code-standards.md | Good principle, but "evidence" is vague here. The follow-up bullets (DevTools, EXPLAIN ANALYZE) partially address this, but the lead sentence stands alone as too vague. |
| 5 | "Is this the simplest correct solution? NO → Simplify before proceeding." | code-standards.md, Documentation Before Code flowchart | "Simplest" is subjective. There's no concrete test for this gate. |
| 6 | "Elegance ≠ complexity. The elegant solution is usually the simpler one, not the clever one" | core-behaviors.md §4 | Philosophically true but not actionable as a rule. |
| 7 | "Don't load blackbox/session-log.md or other append-only logs into context unless explicitly asked." | leverage-patterns.md | Repeated in blackbox-policy.md and here — the "other append-only logs" part is vague (which other logs?). |

---

## B. Conflicts Between Files

### B1. Exit Signal Lists Are Inconsistent

- **Rule A:** blackbox-policy.md lists 10 exit signal phrases including "bye"/"goodbye", "going out now", "closing this", "talk to you later"
- **Rule B:** skill-triggers.md lists 8 exit signal phrases — missing "bye/goodbye", "going out now", "closing this"
- **Conflict:** A user saying "bye" triggers blackbox-policy.md but NOT skill-triggers.md routing
- **Resolution:** Consolidate into one canonical list in blackbox-policy.md. skill-triggers.md should reference it, not duplicate a subset.

### B2. "No Unsolicited Documentation" vs Mandatory Diagram Updates

- **Rule A:** "No unsolicited documentation. Never create `.md` files, reports, READMEs, diagrams, or summaries unless the human explicitly asks." — first-principles.md Layer 3
- **Rule B:** "If files modified this session are covered by an existing diagram in `docs/diagrams/`: Update that diagram before ending the session." AND "If a new service, flow, or integration was built and no diagram exists yet: Generate a Mermaid diagram" — blackbox-policy.md
- **Conflict:** Diagram generation for new services IS unsolicited documentation. The first-principles exception only covers `blackbox/session-log.md` and `lessons.md`, not diagrams.
- **Resolution:** Add diagram updates to the first-principles exception list, or qualify the blackbox-policy rule to only update existing diagrams (not create new ones unsolicited).

### B3. Adaptive Depth "Start at Minimal" vs Overconfidence Prevention "When in Doubt, Ask"

- **Rule A:** "Default: Start at Minimal. Escalate only when a factor above applies. Do not gold-plate simple requests." — leverage-patterns.md
- **Rule B:** "Required pattern: 'When in doubt, ask'" with 5 mandatory question triggers — core-behaviors.md §10
- **Acknowledged:** leverage-patterns.md explicitly notes this interaction ("These triggers override Adaptive Depth")
- **Status:** Not a true conflict since the interaction is documented, but the two rules pull in opposite directions and the "override" clause is easy to miss in a long file. Consider co-locating.

### B4. "Act First" Autonomy vs "Surface Assumptions" Before Implementing

- **Rule A:** "Clear signal → Act first — fix it, run tests, report what you did. Don't ask 'should I fix this?'" — leverage-patterns.md Autonomy Ladder
- **Rule B:** "Before implementing anything non-trivial: Surface assumptions" — core-behaviors.md §1
- **Conflict:** A failing test with a clear stack trace triggers "Act first" but technically also requires surfacing assumptions "before implementing anything non-trivial." The boundary between "trivial fix" and "non-trivial" is not defined.
- **Resolution:** Define "non-trivial" with a concrete threshold (e.g., >3 files changed, or >30 lines modified) to avoid judgment calls on every bug fix.

### B5. CLAUDE.md Role vs Precedence System

- **Rule A:** CLAUDE.md states "Rule precedence: `core-behaviors` > `first-principles` > `code-standards` > `verification-and-reporting` > `leverage-patterns`"
- **Rule B:** first-principles.md states "Precedence: This file sits between `core-behaviors` and `code-standards`."
- **Status:** These are consistent, but CLAUDE.md is the only place that lists the full precedence chain. If an agent can't see CLAUDE.md (as noted in leverage-patterns.md), they can't resolve precedence conflicts. The chain should be in a rules file, not just CLAUDE.md.

---

## C. Summary Statistics

| Metric | Count |
|--------|-------|
| Total distinct rules/directives identified | ~187 |
| Rules that passed all 5 filters | ~146 |
| Rules flagged by at least one filter | ~41 |

### Breakdown by Filter

| Filter | Flagged |
|--------|---------|
| 1 — Already Default Behavior | 11 |
| 2 — Contradicts Another Rule | 5 conflicts (involving 10 rules) |
| 3 — Redundant / Already Covered | 18 redundancy clusters |
| 4 — Bandaid for One Bad Output | 5 |
| 5 — Too Vague to Be Actionable | 7 |

*(Some rules are flagged by multiple filters, so the sum exceeds the unique count.)*

### Files with the Most Flagged Rules (ranked)

| Rank | File | Flags | Notes |
|------|------|-------|-------|
| 1 | `core-behaviors.md` | 12 | Guard Rails section has 5 one-liners redundant with verification-and-reporting.md. §7 "Think Before You Code" has 4 default-behavior items. |
| 2 | `code-standards.md` | 8 | Output Quality section (4 default-behavior), error handling (redundant with first-principles.md), security (redundant overlap). |
| 3 | `leverage-patterns.md` | 7 | Context Window section (2 default-behavior), Orchestrator Pre-Flight (bandaid), Browser MCP (vague), Autonomy Ladder conflict. |
| 4 | `first-principles.md` | 6 | Edit fallback (bandaid), scope safety (redundant with core-behaviors), dead code (redundant), console.log (redundant with code-standards). |
| 5 | `verification-and-reporting.md` | 4 | Binary status (redundant with Guard Rails), UI Gate items (bandaid phrasing), change description (redundant with code-standards). |
| 6 | `blackbox-policy.md` | 3 | Diagram creation (conflicts with no-unsolicited-docs), exit signals (redundant with skill-triggers.md). |
| 7 | `skill-triggers.md` | 2 | Exit signals (redundant with blackbox-policy.md). |

---

## D. Top 5 Recommendations

### 1. Eliminate the Guard Rails Table from core-behaviors.md (saves ~40 lines, removes 5 redundancies)

The Guard Rails table in core-behaviors.md §Guard Rails has 5 entries (Optimism, Path of least resistance, Safety instinct, Conflict avoidance, Confabulation) that are each restated more completely in other files (verification-and-reporting.md, code-standards.md). The table format makes them memorable but they consume always-loaded tokens saying what's already enforced elsewhere. Either delete the table entirely (relying on the canonical versions) or replace it with a 2-line "See verification-and-reporting.md for bias counters" reference.

**Impact:** Removes 5 redundancy pairs, saves ~500 tokens of always-loaded context.

### 2. Consolidate Exit Signals into One Canonical List (removes duplication across 2 files)

Exit signals are listed in both blackbox-policy.md and skill-triggers.md with slightly different phrase sets. This creates a maintenance burden and inconsistent behavior. Move the canonical list to blackbox-policy.md (which has the full trigger behavior) and have skill-triggers.md reference it with a one-liner.

**Impact:** Removes one source of contradictions, simplifies maintenance.

### 3. Trim "Think Before You Code" (§7) and "Verify After You Code" (§8) in core-behaviors.md

These two sections contain 12+ items that are standard Claude behavior (check edge cases, check type mismatches, re-read your code). The valuable parts are the items Claude wouldn't naturally do: "Run the tests" (§8), "Diff review" (§8), "Contract check" (§8). Keep those three. The rest ("null, empty, zero, negative, concurrent, out-of-order", "off-by-one errors", "race conditions in async code", "re-read your own code") are Claude's default reasoning process and add no measurable enforcement.

**Impact:** Saves ~400 tokens of always-loaded context. Makes the remaining rules more prominent.

### 4. Resolve the "No Unsolicited Documentation" vs "Mandatory Diagram Updates" Conflict

first-principles.md Layer 3 says "never create .md files unless asked" with two exceptions (blackbox log and lessons.md). But blackbox-policy.md says "generate a Mermaid diagram of the new component" for new services. This is a real conflict that will cause inconsistent behavior depending on which rule Claude weighs more heavily. Fix by adding diagram updates to the first-principles exception list.

**Impact:** Eliminates a conflict that could cause Claude to either skip diagram updates or create unsolicited docs unpredictably.

### 5. Move the Orchestrator Pre-Flight Section from leverage-patterns.md to a Skill

The 40-line Orchestrator Pre-Flight section in leverage-patterns.md is loaded on every session even if no project creation is happening. It was written in reaction to a single scaffold failure (documented in lessons.md). This would be better placed in each scaffold skill's SKILL.md (where it's contextually relevant) rather than consuming always-on context. The lesson in lessons.md already prevents the original mistake.

**Impact:** Saves ~600 tokens of always-loaded context. Moves the rule closer to where it's needed.

---

## Appendix: Estimated Token Savings

If all 5 recommendations are implemented:

| Change | Tokens Saved |
|--------|-------------|
| Guard Rails consolidation | ~500 |
| Exit signals dedup | ~200 |
| §7/§8 trim | ~400 |
| Diagram conflict resolution | ~50 (fix, not removal) |
| Pre-Flight to skills | ~600 |
| **Total** | **~1,750 tokens** |

This represents roughly 12-15% of the always-loaded rule context, which is meaningful for staying within attention budgets on long sessions.
