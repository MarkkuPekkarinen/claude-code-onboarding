# Claude Code Onboarding Kit — Setup Audit Report

**Date:** 2026-03-30
**Audit type:** Read-only rule quality audit
**Scope:** All `.claude/rules/*.md`, 5 key `SKILL.md` files, all `commands/*.md`
**Files audited:**

| File | Type |
|------|------|
| `CLAUDE.md` | Root config |
| `.claude/rules/core-behaviors.md` | Always-loaded rule |
| `.claude/rules/first-principles.md` | Always-loaded rule |
| `.claude/rules/code-standards.md` | Always-loaded rule |
| `.claude/rules/verification-and-reporting.md` | Always-loaded rule |
| `.claude/rules/leverage-patterns.md` | Always-loaded rule |
| `.claude/rules/blackbox-policy.md` | Always-loaded rule |
| `.claude/rules/skill-triggers.md` | Always-loaded rule |
| `.claude/rules/lessons.md` | Always-loaded correction log |
| `.claude/skills/systematic-debugging/SKILL.md` | Skill |
| `.claude/skills/verification-before-completion/SKILL.md` | Skill |
| `.claude/skills/plan-mode-review/SKILL.md` | Skill |
| `.claude/skills/clean-code/SKILL.md` | Skill |
| `.claude/skills/the-fool/SKILL.md` | Skill |
| `.claude/commands/add-feature.md` | Command |
| `.claude/commands/status-check.md` | Command |
| `.claude/commands/project-status.md` | Command |
| `.claude/commands/scaffold-angular-app.md` | Command |

> Note: ~90 additional SKILL.md files exist in `.claude/skills/` but are technology-specific reference materials (Spring Boot templates, Flutter patterns, etc.) rather than behavioral rule files. This audit focuses on cross-cutting behavioral rules, not technology-specific coding conventions.

---

## A. Rules Flagged for Removal or Consolidation

### A1 — Diagram Creation Mandate (CONFLICT — see also §B)

**Rule:** "If a new service, flow, or integration was built and no diagram exists yet: Generate a Mermaid diagram of the new component. Save to `docs/diagrams/[feature-name]-flow.md`"
**Source:** `.claude/rules/blackbox-policy.md` — "Diagram Update Trigger" section
**Filter failed:** Filter 2 (Contradicts), Filter 4 (Bandaid pattern)
**Reason:** Directly contradicts `first-principles.md` Layer 3 which states "Never create `.md` files, reports, READMEs, **diagrams**, or summaries unless the human explicitly asks for them." The blackbox-policy mandate for proactive diagram creation is not listed in the explicit exceptions in first-principles (only `blackbox/session-log.md` and `lessons.md` are excepted). See §B for the full conflict analysis.

---

### A2 — "For Every Task: UNDERSTAND-PLAN" Header vs. Adaptive Depth Minimal Mode

**Rule:** "For every task: 1. UNDERSTAND: Restate the task. Flag ambiguity. 2. PLAN: 3-5 bullet approach before coding. 3. DECISIONS..."
**Source:** `.claude/rules/leverage-patterns.md` — "Task Response Protocol"
**Filter failed:** Filter 2 (Contradicts), Filter 5 (Vague)
**Reason:** The "For every task" header conflicts with the Minimal depth profile ("Write code, run existing tests, done"). The file partially resolves this with "For small/obvious tasks, compress — but NEVER skip UNDERSTAND or VERIFY," but "small/obvious" is undefined. A reader encounters "For every task" with 6 mandatory steps, then later finds a depth level that says just "Write code, done." Resolution: change the header from "For every task" to "Standard/non-trivial task template" and define what compresses at Minimal depth.

---

### A3 — Exit Signal List Duplication

**Rule:** Full list of exit phrases ("that's all for now", "done for today", "heading out", etc.)
**Source (primary):** `.claude/rules/blackbox-policy.md` — "Exit Signal Detection" (10+ phrases, full procedure, edge case handling, mid-task pause detection)
**Source (duplicate):** `.claude/rules/skill-triggers.md` — "Exit Signals" (same phrases, abbreviated procedure, no edge-case handling)
**Filter failed:** Filter 3 (Redundant)
**Reason:** Identical phrase list in two files. `blackbox-policy.md` is the authoritative source with complete logic; `skill-triggers.md` has a simplified subset that omits the "Exit Signal ≠ Mid-Task Pause" disambiguation. The abbreviated version could cause false triggers on mid-task pauses like "hold on" or "hmm". Recommendation: remove exit signal definition from `skill-triggers.md` P1 table and replace with a reference pointer to `blackbox-policy.md`.

---

### A4 — Edit Tool Fallback Protocol (Bandaid)

**Rule:** "If the Edit tool fails twice on the same file: After 2nd failure: switch to Bash with sed/awk. If Bash approach also fails: use Write tool to recreate the entire file. Never silently retry Edit a 3rd time."
**Source:** `.claude/rules/first-principles.md` — Layer 3 "Edit fallback protocol"
**Filter failed:** Filter 4 (Bandaid)
**Reason:** This is a hyper-specific procedure for a particular tool failure mode. It reads like a reactive patch added after Claude repeatedly retried a failing Edit call. The rule is correct and actionable, but its placement in `first-principles.md` (the "hard constraint" layer) is mismatched — this is an operational tip, not a principle. Should be moved to `code-standards.md` under a "Tool Use Patterns" section, or to `leverage-patterns.md` alongside other operational patterns.

---

### A5 — "Demand Elegance" Subsection (Vague)

**Rule:** "For non-trivial changes, pause and ask: 'Is there a more elegant way?' If a fix feels hacky: 'Knowing everything I know now, what's the clean solution?' — then implement that instead. Challenge your own work before presenting it — not just 'does it work?' but 'is this how I'd want to find it in 6 months?'"
**Source:** `.claude/rules/core-behaviors.md` — §4 "Enforce Simplicity" subsection "Demand Elegance (Balanced)"
**Filter failed:** Filter 5 (Too vague)
**Reason:** "Non-trivial," "hacky," and "elegant" are undefined. The instruction to skip this "for simple, obvious fixes" reintroduces vagueness (simple and obvious are also undefined). The "6-month test" is evocative but not a concrete criterion. Compare with the measurable gates in `first-principles.md` (exact grep commands, numeric thresholds) — this section lacks any operationalization. The underlying principle (prefer cleaner solutions) is already covered more concretely in `code-standards.md` "Output Quality" ("No bloated abstractions or premature generalization") and in the Rule of Three. Recommendation: collapse this into §4's existing simplicity rules with one concrete criterion, or delete entirely since it largely restates "enforce simplicity."

---

### A6 — Orphan Prevention "Useful Findings" (Vague)

**Rule:** "After any session using sub-agents or teams: Check for `.claude/agent-memory/` files. Consolidate useful findings into `lessons.md` or skill reference files. Delete the orphaned files."
**Source:** `.claude/rules/leverage-patterns.md` — "Orphan Prevention"
**Filter failed:** Filter 5 (Too vague)
**Reason:** "Useful findings" is undefined. No criteria given for what qualifies to be promoted vs discarded. Should specify: "Consolidate findings that match the lessons.md format (a mistake + rule + applies-to scope). Discard everything else." Without this, the rule is too vague to apply consistently.

---

### A7 — Error Handling Rules in Three Places (Redundant)

**Rule:** "Every catch block MUST log the error. Every catch block MUST either rethrow OR return an error state. NEVER return empty list/null/default on error."
**Source (primary):** `.claude/rules/code-standards.md` — "Error Handling"
**Source (duplicate 1):** `.claude/rules/first-principles.md` — Layer 2 "Error Handling" thresholds
**Source (duplicate 2):** `.claude/skills/clean-code/SKILL.md` — §6 "Error Handling"
**Filter failed:** Filter 3 (Redundant)
**Reason:** The core error handling rule is stated in all three places. The versions in `first-principles.md` (numeric metric: "Bare catch(e) {} = 0") and `code-standards.md` (code examples) are complementary and serve different purposes (enforcement gate vs. how-to). But `clean-code/SKILL.md` adds "Don't Return Null" and "Don't Pass Null" framed as Clean Code principles — these are not duplicates but the error handling framing overlaps. Minor issue; the duplication is mostly intentional for layered enforcement.

---

### A8 — Scope Discipline in Two Places (Structural Redundancy)

**Rule:** "Touching files outside the stated task → STOP. Ask first."
**Source (rule):** `.claude/rules/core-behaviors.md` — §5 "Scope Discipline"
**Source (enforcement gate):** `.claude/rules/first-principles.md` — Layer 1 "Code Safety"
**Filter failed:** Filter 3 (Redundant)
**Reason:** By design — core-behaviors gives the behavioral guidance, first-principles adds the hard-stop enforcement. This duplication is intentional and acceptable, but it's worth noting that the dead code sub-rule (pre-existing vs. your-changes-created) only appears in `core-behaviors.md` and is not in `first-principles.md`. The hard stop in `first-principles.md` only covers "touching files outside the stated task" — it doesn't cover the nuanced dead-code rule. This is an under-specification in `first-principles.md`, not a redundancy. Actually this may deserve a separate flag.

---

### A9 — Binary Status Rules in Verification + Status-Check Command (Redundant)

**Rule:** "Binary status: 'Works' or 'Doesn't work'. Forbidden: 'mostly', 'almost', 'nearly', 'partially'. NO PERCENTAGES."
**Source (primary):** `.claude/rules/verification-and-reporting.md` — "Honest Status Reporting"
**Source (duplicate):** `.claude/commands/status-check.md` — rules 1-5
**Filter failed:** Filter 3 (Redundant)
**Reason:** The command is largely a formatted version of the verification rule, with nearly identical wording ("NO PERCENTAGES", "BINARY ONLY", "NO HEDGING"). Acceptable as a UX convenience (the command provides a ready-to-use template), but new maintainers editing `verification-and-reporting.md` might not know to also update `status-check.md`. Recommendation: add a comment to `status-check.md` noting it mirrors `verification-and-reporting.md` so changes are kept in sync.

---

## B. Conflicts Between Files

### Conflict 1 — Unsolicited Diagrams: Banned vs. Mandatory

**Rule A:** "Never create `.md` files, reports, READMEs, **diagrams**, or summaries unless the human explicitly asks for them. Proactively generating docs no one requested is scope creep."
— `.claude/rules/first-principles.md`, Layer 3 "No unsolicited documentation"

**Rule B:** "If a new service, flow, or integration was built and no diagram exists yet: Generate a Mermaid diagram of the new component. Save to `docs/diagrams/[feature-name]-flow.md`. Note in Decisions: 'Created docs/diagrams/[name].md'"
— `.claude/rules/blackbox-policy.md`, "Diagram Update Trigger" section

**Nature of conflict:** Direct and unambiguous. Rule A categorically prohibits unsolicited diagrams. Rule B mandates creating them after building new services. Rule A lists two explicit exceptions (blackbox session log entries and lessons.md entries) — diagrams are not in that exception list.

**Suggested resolution:** Either (a) add diagrams to the explicit exception list in `first-principles.md` Layer 3 (alongside session log and lessons.md), or (b) add "unless the user explicitly asked for it" to the `blackbox-policy.md` diagram trigger. Option (a) is preferable since it preserves the blackbox-policy intent of maintaining diagrams as architecture documentation alongside code changes.

---

### Conflict 2 — "For Every Task" Protocol vs. Minimal Depth

**Rule A:** "For every task: 1. UNDERSTAND: Restate the task. Flag ambiguity. 2. PLAN: 3-5 bullet approach before coding. 3. DECISIONS: List design choices and tradeoffs. 4. IMPLEMENT..."
— `.claude/rules/leverage-patterns.md`, "Task Response Protocol"

**Rule B:** "Minimal [depth] — Single-file fix, clear requirement, trivial change: Write code, run existing tests, done."
— `.claude/rules/leverage-patterns.md`, "Adaptive Depth Levels" (same file)

**Nature of conflict:** The "For every task" heading implies the 6-step protocol applies universally, but the Minimal depth profile compresses it down to a single sentence. The text does add "For small/obvious tasks, compress — but NEVER skip UNDERSTAND or VERIFY," which partially resolves this, but "small/obvious" is itself vague, and the Minimal depth profile doesn't mention UNDERSTAND or VERIFY steps.

**Suggested resolution:** Rename "For every task:" to "Standard task template (non-trivial work):" and add one line to the Minimal depth row: "Run UNDERSTAND implicitly (restate = proceed), skip PLAN, run VERIFY before reporting."

---

### Conflict 3 — Exit Signal Procedures: Complete vs. Incomplete

**Rule A (complete):** `blackbox-policy.md` "Exit Signal Detection" — includes mid-task pause disambiguation ("NOT trigger on: 'hold on'/'hmm'/'let me think' — user is pausing, not leaving").
**Rule B (incomplete):** `skill-triggers.md` "Exit Signals" — same phrase list but missing the mid-task pause disambiguation.

**Nature of conflict:** `skill-triggers.md` could trigger blackbox writes on "hold on" or "hmm" if a developer follows only that section. Not a hard conflict, but an incomplete duplicate that could cause false positives.

**Suggested resolution:** Replace the exit signal list in `skill-triggers.md` with a single line: "Exit signals are defined and handled in `blackbox-policy.md` — see that file for the full trigger list and procedures."

---

## C. Summary Statistics

| Metric | Count |
|--------|-------|
| **Total distinct rules/directives inventoried** | ~240 |
| **Rules that passed all 5 filters** | ~218 |
| **Rules flagged by at least one filter** | ~22 |
| **Filter 1 (Already Default)** | 3 borderline (none recommended for removal) |
| **Filter 2 (Contradicts another rule)** | 8 instances across 3 conflicts |
| **Filter 3 (Redundant/Already Covered)** | 9 instances |
| **Filter 4 (Bandaid)** | 3 instances |
| **Filter 5 (Too Vague)** | 4 instances |

> Note: The 240-rule estimate covers the 8 always-loaded rules files + 5 SKILL.md files + 4 commands. The ~90 additional SKILL.md files contain technology-specific coding conventions (Spring Boot templates, Flutter patterns, etc.) which are reference material rather than behavioral directives and were excluded from the count. If included, the total would be ~800+ items.

### Files With the Most Flagged Rules

| Rank | File | Flagged Rules | Notes |
|------|------|---------------|-------|
| 1 | `.claude/rules/leverage-patterns.md` | 7 | Both conflict victims (#2, #3) and vague rules (#A6) |
| 2 | `.claude/rules/first-principles.md` | 5 | Conflict victim (#1), bandaid (#A4), scope under-spec (#A8) |
| 3 | `.claude/rules/blackbox-policy.md` | 4 | Source of conflict #1, exit signal duplication |
| 4 | `.claude/rules/core-behaviors.md` | 3 | Demand Elegance vagueness (#A5) |
| 5 | `.claude/rules/skill-triggers.md` | 3 | Exit signal duplication, abbreviated procedures |

---

## D. Top 5 Recommendations

### 1. Resolve the Diagram Conflict (Priority: HIGH)

**Action:** Add "docs/diagrams/ entries (when new services are built this session)" to the explicit exceptions list in `first-principles.md` Layer 3, alongside `blackbox/session-log.md` and `lessons.md`.

**Impact:** Eliminates a direct contradiction between two always-loaded rule files. Currently the AI faces a hard choice at session end when new services were built: follow first-principles (don't create diagrams) or follow blackbox-policy (create diagrams). This creates unpredictable behavior.

**Effort:** ~2 lines added to `first-principles.md` Layer 3.

---

### 2. Collapse Exit Signals to a Single Source (Priority: HIGH)

**Action:** Remove the exit signal definition from `skill-triggers.md` P1 and replace with a one-line pointer: "Exit signals: see `blackbox-policy.md` for full list and procedures."

**Impact:** Eliminates the risk of false positives from the abbreviated procedure (missing mid-task pause handling). Simplifies maintenance — exit signal phrase list only needs updating in one place.

**Effort:** ~10 lines removed from `skill-triggers.md`, 1 line added.

---

### 3. Rename "For Every Task" Protocol Header (Priority: MEDIUM)

**Action:** In `leverage-patterns.md`, change "For every task:" to "Standard task template (non-trivial work):" and add one line to the Minimal depth row: "UNDERSTAND: implicit (restate goal silently). PLAN: skip. VERIFY: run before reporting done."

**Impact:** Eliminates the contradiction between the 6-step protocol and the "just write code" Minimal depth profile. New team members reading both sections currently get conflicting instructions about what's required for simple tasks.

**Effort:** ~4 lines modified across `leverage-patterns.md`.

---

### 4. Operationalize or Delete "Demand Elegance" (Priority: MEDIUM)

**Action:** Either (a) replace the "Demand Elegance" subsection in `core-behaviors.md §4` with a single concrete check: "Before submitting: does this solution pass the Rule of Three and KISS checks? If not, simplify." Or (b) delete it entirely — the simplicity principle is already enforced by §4's existing bullets and `code-standards.md`.

**Impact:** Removes the most actionably vague rule in the always-loaded files. "Demand elegance" cannot be applied consistently without a concrete criterion. The section currently tells Claude to ask itself a feeling ("is this how I'd want to find it in 6 months?") — feelings are not enforcement-grade rules.

**Effort:** 10 lines removed or rewritten in `core-behaviors.md`.

---

### 5. Move Edit Fallback Protocol to leverage-patterns.md (Priority: LOW)

**Action:** Cut the "Edit fallback protocol" from `first-principles.md` Layer 3 and paste it into `leverage-patterns.md` under a new "Tool Use Patterns" section (alongside the existing Orchestrator Pre-Flight section).

**Impact:** `first-principles.md` is the "hard constraint" file — it should contain data safety, code safety, and scope rules. The Edit tool fallback is an operational tip for handling a specific tool failure mode, not a first-principles constraint. Misclassification in a file labeled "invariants" dilutes the signal of that file. Moving it to `leverage-patterns.md` (where practical patterns live) makes both files cleaner.

**Effort:** Cut and paste ~12 lines between two files.

---

## Appendix: Filter Verdicts by Rule Category

### Filter 1 — Rules That Are Borderline "Already Default"

These rules address LLM-specific biases, not truly default behavior. All are recommended to KEEP:

- "You are not a yes-machine. Sycophancy is a failure mode." (`core-behaviors.md §3`) — LLMs have a documented sycophancy bias. This is NOT default behavior.
- "Don't trust that it 'looks right.' Prove it works." (`core-behaviors.md §8`) — LLMs confabulate. Explicit verification requirements are necessary.
- "Re-read your own code before presenting it." (`core-behaviors.md §7`) — Valuable anti-confabulation rule.

None of these truly belong to Filter 1 because they all address documented LLM failure modes, not generic "write good code" platitudes.

### Filter 4 — Reactive Rules With Legitimate Value

These read like reactive patches but are defensible:

- `verification-before-completion/SKILL.md` "Post-Merge Verification" — CI passing does not guarantee deployment success. The rule is narrow but addresses a real failure mode in GitHub Actions workflows. Keep, but consider adding a note about when to skip (e.g., repos without CI/CD).
- `leverage-patterns.md` "Orchestrator Pre-Flight" — Directly addresses the documented lesson in `lessons.md` (scaffold commands fail in sub-agents). The lesson has been correctly graduated to a rule. Keep.

---

*Audit complete. No files were modified. All findings are recommendations only.*
