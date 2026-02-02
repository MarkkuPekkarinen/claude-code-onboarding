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

Use DNS lookup to check each candidate. An `NXDOMAIN` or `SERVFAIL` response strongly suggests the domain is unregistered:

```bash
# Quick batch check — NXDOMAIN = likely available
for domain in snippetbox.com codeclip.io devpaste.dev; do
  result=$(dig +short "$domain" 2>/dev/null)
  if [ -z "$result" ]; then
    status=$(dig "$domain" +noall +comments 2>/dev/null | grep -o 'NXDOMAIN\|NOERROR\|SERVFAIL')
    if [ "$status" = "NXDOMAIN" ]; then
      echo "✅ $domain — likely available"
    else
      echo "⚠️  $domain — parked or no A record (check registrar)"
    fi
  else
    echo "❌ $domain — taken ($result)"
  fi
done
```

For deeper verification, use WHOIS:

```bash
# WHOIS check for a specific domain
whois snippetbox.com 2>/dev/null | grep -iE "^(Domain Name|Registry|Creation|Expir|No match|NOT FOUND|No Data)"
```

**Interpreting results:**
- `No match` / `NOT FOUND` / `No Data Provided` → available
- `Creation Date` present → registered
- No WHOIS response → try the DNS method above

### Step 4 — Present Results

Format output as:

```
🎯 Domain Name Results for [Project Description]

AVAILABLE
  ✅ snippet.dev         — short, .dev signals developer tool
  ✅ codeclip.com        — 8 chars, memorable compound word
  ✅ snipflow.io         — brandable, implies movement

LIKELY AVAILABLE (verify at registrar)
  ⚠️  devpaste.app       — no DNS record, WHOIS inconclusive

TAKEN
  ❌ codeshare.com       — registered, has active site
  ❌ snippets.com        — premium domain

🏆 TOP PICK: snippet.dev
   Short, memorable, perfect TLD for developer audience

🥈 RUNNER-UP: codeclip.com
   .com credibility, only 8 characters, highly brandable

NEXT STEPS
  1. Register your pick before it's gone
  2. Grab the .com + one alt TLD to protect the brand
  3. Check @handle availability on GitHub/Twitter/LinkedIn
```

### Step 5 — Social Handle Check (Optional)

If the user wants, verify social media availability:

```bash
# Check if GitHub username/org is taken (404 = available)
for name in snippetdev codeclip snipflow; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "https://github.com/$name")
  if [ "$status" = "404" ]; then
    echo "✅ github.com/$name — available"
  else
    echo "❌ github.com/$name — taken"
  fi
done
```

## TLD Quick Reference

| TLD | Best For | Price Range |
|-----|----------|-------------|
| `.com` | Universal, trusted, any business | ~$10–15/yr |
| `.io` | Tech startups, developer tools | ~$30–50/yr |
| `.dev` | Developer-focused products | ~$12–15/yr |
| `.ai` | AI/ML products | ~$30–80/yr |
| `.app` | Mobile or web applications | ~$12–15/yr |
| `.co` | Startups, .com alternative | ~$25–35/yr |
| `.xyz` | Creative/experimental projects | ~$10–12/yr |

## Tips to Share with User
- **Act fast** — good domains disappear quickly
- **Register 2 TLDs** — primary + .com to protect brand
- **Say it out loud** — if it's awkward to say, pick another
- **Search trademarks** — check USPTO/EUIPO before committing
- **Think 5 years out** — avoid trend-dependent names