---
name: domain-finder
description: Brainstorm creative domain names and check real availability using DNS/WHOIS lookups. Use when starting a new project, product, or brand and need to find a registrable domain.
allowed-tools: Bash, WebFetch, WebSearch
---

# Domain Finder Skill

Generate creative, brandable domain names and verify which ones are actually available to register.

## Workflow

### Step 1 — Understand the Project
Gather from the user (ask if not provided):
- What they're building (product, SaaS, agency, portfolio, etc.)
- Target audience (developers, consumers, enterprise, etc.)
- Preferred keywords or themes (optional)
- TLD preferences (default: .com, .io, .dev, .ai, .app)
- Constraints (max length, no hyphens, must include a word, etc.)

### Step 2 — Generate Names
Create 15–20 candidates across these categories:

- **Descriptive** — says what it does (e.g. `codeshare`, `snippetbox`)
- **Compound** — two short words fused (e.g. `devpaste`, `buildkit`)
- **Invented** — brandable neologisms (e.g. `codezy`, `snipflow`)
- **Short & punchy** — ≤ 8 chars, memorable (e.g. `clipp`, `patchd`)

**Naming rules:**
- Under 15 characters (shorter is better)
- No hyphens — hard to say out loud
- No numbers — confusing verbally
- Easy to spell and pronounce
- Doesn't accidentally spell something bad in another language

### Step 3 — Check Availability

Read `reference/domain-check-scripts.md` for DNS batch check scripts, WHOIS deep check commands, and result interpretation guide.

### Step 4 — Present Results

Read `reference/domain-check-scripts.md` for the output format template and TLD quick reference table.

### Step 5 — Social Handle Check (Optional)

Read `reference/domain-check-scripts.md` for social media handle checking scripts.

## Reference Files

| File | Content |
|------|---------|
| `reference/domain-check-scripts.md` | DNS/WHOIS scripts, TLD reference, output template, social handle checks |
