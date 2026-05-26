# First Principles Thinking

Break a problem down to its most fundamental truths — things that are undeniably true — then rebuild a solution from there. Ignore convention, analogy, and inherited assumptions.

## Core Principle

Most thinking is analogy-based: "We do it this way because that's how it's done." First principles thinking asks: **"What is actually true here, and what follows from that?"** It is not about being contrarian — it is about finding the real foundation beneath the conventions.

## The Three-Step Process

1. **Identify the problem and its assumed constraints** — List everything the user believes to be true or fixed about the situation.
2. **Challenge each constraint** — For each one, ask: "Is this actually true, or is it inherited?" If it cannot be proven from evidence, it is an assumption, not a fact.
3. **Rebuild from what remains** — Starting only from the verified truths, reason toward a solution without borrowing from convention.

## Interactive Method

Do not produce a monologue. Work through this with the user in steps.

### Step 1: State the Problem

Ask the user to describe the problem in one or two sentences. Confirm your understanding before proceeding.

### Step 2: Surface All Assumptions

Ask: *"What are you taking for granted about this problem? List every constraint you believe exists — cost, time, people, technology, process."*

Then for each constraint, ask: *"How do you know this is true? Can you prove it from evidence, or is it inherited from how things have always been done?"*

**Assumption categories to probe:**

| Category | Example Inherited Assumption |
|----------|----------------------------|
| **Cost** | "This would be too expensive to build" |
| **Time** | "This would take too long to change" |
| **People** | "We don't have the skills internally" |
| **Technology** | "The current stack can't support this" |
| **Process** | "Regulation requires us to do it this way" |
| **Market** | "Customers wouldn't pay for that" |
| **Competition** | "Everyone in this industry does it this way" |

**The test for each assumption:**
- Can you point to a specific piece of evidence that proves this is true?
- Or are you inferring from past experience, convention, or what others do?
- Has anyone in any industry, at any scale, done this differently?

### Step 3: Classify Each Constraint

After probing, classify every constraint as one of:

| Class | Meaning | Action |
|-------|---------|--------|
| **Fundamental truth** | Provably true from evidence or physical law | Keep — build on this |
| **Context-dependent** | True for your specific situation, not universally | Keep with caveat — note what would have to change |
| **Inherited assumption** | True because everyone does it this way, not because it must be | Challenge — rebuild without it |
| **Fear-based** | True because of past failure or risk aversion | Surface — decide consciously whether to accept |

### Step 4: Rebuild

Starting only from what is provably true, ask: *"If we had none of the inherited constraints, how would we design a solution to this problem?"*

Then reintroduce only the constraints that are proven to be real, one at a time. Each reintroduction narrows the solution space — make sure each narrowing is earned.

**Rebuilding questions:**
- What is the actual goal (not the assumed method)?
- What is the minimum required to achieve that goal?
- What would we build if we were starting today with no legacy?
- Which constraints, once removed, unlock the most solution space?

## Pushing for Specificity

Reject vague answers at every step. Examples:

| Vague Answer | Push Back |
|-------------|-----------|
| "It would be too costly" | "How much, specifically? What drives that cost? Is the cost in the constraint or in how we've chosen to approach it?" |
| "We've always done it this way" | "When was that decision made, and under what conditions? Are those conditions still true?" |
| "Customers expect this" | "Which customers? When did you last test that expectation? Did you ask, or did you assume?" |
| "The technology can't support it" | "What specifically can't it do? At what scale? When was that tested?" |
| "It's too risky" | "What specifically happens if this fails? How likely is that, and how reversible is it?" |

## Output Template

```markdown
## First Principles Analysis: [Problem]

### The Problem (restated)
[One sentence — confirmed with user]

### Assumptions Inventory

| Assumption | Type | Verdict | Evidence |
|------------|------|---------|----------|
| [Constraint 1] | Cost / Time / People / Tech / Process | Fundamental / Context-dependent / Inherited / Fear-based | [Proof or absence of proof] |
| [Constraint 2] | ... | ... | ... |

### Proven Truths (what we are actually working with)
- [Truth 1 — with evidence]
- [Truth 2 — with evidence]
- [Truth 3 — with evidence]

### Inherited Assumptions Removed
- [Assumption X] — removed because [evidence it was inherited]
- [Assumption Y] — removed because [evidence it was inherited]

### Rebuilt Solution Space
Starting from only the proven truths, the solution space opens to:

[Describe the options that become available when inherited constraints are removed]

### The First Principles Solution
[Specific solution or direction that would not have been visible before the analysis]

### Re-introduced Constraints (if any)
[Any constraints that are genuinely real and must be designed around, with evidence for why they are real]
```

## Common Mistakes

| Mistake | What to Do Instead |
|---------|-------------------|
| Accepting "everyone does it this way" as proof | Ask who decided that and when; look for exceptions in other industries |
| Stopping at the first layer of assumptions | Keep probing — most real assumptions are two layers deep |
| Rebuilding with inherited assumptions still in place | Check every element of the rebuilt solution against the proven truths list |
| Confusing "hard" with "impossible" | Distinguish cost/effort constraints from physical impossibility |
